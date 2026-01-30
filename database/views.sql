-- =====================================================
-- VIEWS FOR POWER BI
-- Run this in Supabase SQL Editor after schema.sql
-- =====================================================

-- =====================================================
-- VIEW: Current portfolio with latest prices
-- =====================================================
CREATE OR REPLACE VIEW v_portfolio_current AS
SELECT 
    h.id as holding_id,
    a.symbol,
    a.name as asset_name,
    at.name as asset_type,
    at.category,
    acc.name as account_name,
    acc.account_type,
    acc.is_tax_advantaged,
    h.quantity,
    h.cost_basis,
    h.average_cost_per_share,
    
    -- Get latest price (stock or crypto)
    COALESCE(sp.close_price, cp.price_usd) as current_price,
    COALESCE(sp.price_date, cp.price_date) as price_date,
    
    -- Calculate current value
    h.quantity * COALESCE(sp.close_price, cp.price_usd) as current_value,
    
    -- Calculate gain/loss
    (h.quantity * COALESCE(sp.close_price, cp.price_usd)) - h.cost_basis as gain_loss,
    
    -- Calculate gain/loss percentage
    CASE 
        WHEN h.cost_basis > 0 THEN
            ROUND(((h.quantity * COALESCE(sp.close_price, cp.price_usd)) - h.cost_basis) 
                  / h.cost_basis * 100, 2)
        ELSE 0
    END as gain_loss_pct

FROM holdings h
JOIN assets a ON h.asset_id = a.id
JOIN asset_types at ON a.asset_type_id = at.id
JOIN accounts acc ON h.account_id = acc.id
LEFT JOIN LATERAL (
    SELECT close_price, price_date 
    FROM stock_prices 
    WHERE asset_id = a.id 
    ORDER BY price_date DESC 
    LIMIT 1
) sp ON at.name IN ('stock', 'etf', 'mutual_fund')
LEFT JOIN LATERAL (
    SELECT price_usd, price_date 
    FROM crypto_prices 
    WHERE asset_id = a.id 
    ORDER BY price_date DESC 
    LIMIT 1
) cp ON at.name = 'crypto'
WHERE h.quantity > 0;

-- =====================================================
-- VIEW: Portfolio allocation summary
-- =====================================================
CREATE OR REPLACE VIEW v_allocation_summary AS
SELECT 
    category,
    SUM(current_value) as total_value,
    ROUND(100.0 * SUM(current_value) / 
          NULLIF((SELECT SUM(current_value) FROM v_portfolio_current), 0), 2) as allocation_pct
FROM v_portfolio_current
GROUP BY category
ORDER BY total_value DESC;

-- =====================================================
-- VIEW: Allocation by asset type (more granular)
-- =====================================================
CREATE OR REPLACE VIEW v_allocation_by_type AS
SELECT 
    asset_type,
    category,
    COUNT(*) as holding_count,
    SUM(current_value) as total_value,
    ROUND(100.0 * SUM(current_value) / 
          NULLIF((SELECT SUM(current_value) FROM v_portfolio_current), 0), 2) as allocation_pct
FROM v_portfolio_current
GROUP BY asset_type, category
ORDER BY total_value DESC;

-- =====================================================
-- VIEW: Performance by holding
-- =====================================================
CREATE OR REPLACE VIEW v_holding_performance AS
SELECT 
    symbol,
    asset_name,
    asset_type,
    account_name,
    quantity,
    average_cost_per_share,
    current_price,
    current_value,
    cost_basis,
    gain_loss,
    gain_loss_pct,
    CASE 
        WHEN gain_loss_pct >= 20 THEN 'Strong Gain'
        WHEN gain_loss_pct >= 5 THEN 'Moderate Gain'
        WHEN gain_loss_pct >= -5 THEN 'Flat'
        WHEN gain_loss_pct >= -20 THEN 'Moderate Loss'
        ELSE 'Significant Loss'
    END as performance_category
FROM v_portfolio_current
ORDER BY current_value DESC;

-- =====================================================
-- VIEW: Portfolio history for time series charts
-- =====================================================
CREATE OR REPLACE VIEW v_portfolio_history AS
SELECT 
    snapshot_date,
    total_value,
    total_cost_basis,
    total_gain_loss,
    total_gain_loss_pct,
    day_change,
    day_change_pct,
    stocks_value,
    crypto_value,
    cash_value,
    bonds_value,
    
    -- Calculate moving averages
    AVG(total_value) OVER (
        ORDER BY snapshot_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as ma_7d,
    AVG(total_value) OVER (
        ORDER BY snapshot_date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) as ma_30d
    
FROM portfolio_snapshots
ORDER BY snapshot_date;

-- =====================================================
-- VIEW: Goal progress
-- =====================================================
CREATE OR REPLACE VIEW v_goal_progress AS
SELECT 
    id as goal_id,
    name as goal_name,
    target_amount,
    current_amount,
    target_date,
    monthly_contribution,
    priority,
    ROUND(100.0 * current_amount / NULLIF(target_amount, 0), 2) as progress_pct,
    target_amount - current_amount as amount_remaining,
    
    -- Calculate months to goal at current rate
    CASE 
        WHEN monthly_contribution > 0 THEN
            CEIL((target_amount - current_amount) / monthly_contribution)
        ELSE NULL
    END as months_to_goal,
    
    -- Is on track?
    CASE 
        WHEN target_date IS NULL THEN 'No deadline'
        WHEN current_amount >= target_amount THEN 'Completed'
        WHEN monthly_contribution <= 0 THEN 'No contributions'
        WHEN current_amount + (monthly_contribution * 
             (EXTRACT(YEAR FROM target_date) * 12 + EXTRACT(MONTH FROM target_date) -
              EXTRACT(YEAR FROM CURRENT_DATE) * 12 - EXTRACT(MONTH FROM CURRENT_DATE)))
             >= target_amount THEN 'On Track'
        ELSE 'Behind'
    END as status_indicator
FROM goals
WHERE status = 'active';

-- =====================================================
-- VIEW: Monthly transaction summary
-- =====================================================
CREATE OR REPLACE VIEW v_monthly_transactions AS
SELECT 
    DATE_TRUNC('month', transaction_date)::DATE as month,
    transaction_type,
    COUNT(*) as transaction_count,
    SUM(total_amount) as total_amount,
    SUM(fees) as total_fees
FROM transactions
GROUP BY DATE_TRUNC('month', transaction_date), transaction_type
ORDER BY month DESC, transaction_type;

-- =====================================================
-- VIEW: Benchmark comparison (portfolio vs S&P 500)
-- =====================================================
CREATE OR REPLACE VIEW v_benchmark_comparison AS
WITH portfolio_returns AS (
    SELECT 
        snapshot_date,
        total_value,
        LAG(total_value) OVER (ORDER BY snapshot_date) as prev_value,
        ROUND((total_value - LAG(total_value) OVER (ORDER BY snapshot_date)) / 
            NULLIF(LAG(total_value) OVER (ORDER BY snapshot_date), 0) * 100, 4) as daily_return
    FROM portfolio_snapshots
),
benchmark_returns AS (
    SELECT 
        price_date,
        close_value,
        LAG(close_value) OVER (ORDER BY price_date) as prev_value,
        ROUND((close_value - LAG(close_value) OVER (ORDER BY price_date)) / 
            NULLIF(LAG(close_value) OVER (ORDER BY price_date), 0) * 100, 4) as daily_return
    FROM benchmark_prices
    WHERE benchmark_code = 'SP500'
)
SELECT 
    p.snapshot_date as date,
    p.total_value as portfolio_value,
    p.daily_return as portfolio_daily_return,
    b.close_value as sp500_value,
    b.daily_return as sp500_daily_return,
    ROUND(p.daily_return - COALESCE(b.daily_return, 0), 4) as alpha
FROM portfolio_returns p
LEFT JOIN benchmark_returns b ON p.snapshot_date = b.price_date
WHERE p.prev_value IS NOT NULL;

-- =====================================================
-- VIEW: Account summary
-- =====================================================
CREATE OR REPLACE VIEW v_account_summary AS
SELECT 
    acc.id as account_id,
    acc.name as account_name,
    acc.account_type,
    acc.institution,
    acc.is_tax_advantaged,
    COUNT(DISTINCT h.asset_id) as holding_count,
    COALESCE(SUM(vpc.current_value), 0) as total_value,
    COALESCE(SUM(vpc.cost_basis), 0) as total_cost_basis,
    COALESCE(SUM(vpc.gain_loss), 0) as total_gain_loss
FROM accounts acc
LEFT JOIN holdings h ON acc.id = h.account_id
LEFT JOIN v_portfolio_current vpc ON h.id = vpc.holding_id
GROUP BY acc.id, acc.name, acc.account_type, acc.institution, acc.is_tax_advantaged
ORDER BY total_value DESC;

-- =====================================================
-- VIEW: Latest economic indicators
-- =====================================================
CREATE OR REPLACE VIEW v_latest_economic_indicators AS
SELECT DISTINCT ON (indicator_code)
    indicator_name,
    indicator_code,
    observation_date,
    value,
    unit
FROM economic_indicators
ORDER BY indicator_code, observation_date DESC;
