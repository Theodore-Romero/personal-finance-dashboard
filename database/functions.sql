-- =====================================================
-- UTILITY FUNCTIONS
-- Run this in Supabase SQL Editor after views.sql
-- =====================================================

-- =====================================================
-- FUNCTION: Calculate portfolio value on a specific date
-- Usage: SELECT fn_portfolio_value_on_date('2024-01-15');
-- =====================================================
CREATE OR REPLACE FUNCTION fn_portfolio_value_on_date(p_date DATE)
RETURNS DECIMAL AS $$
DECLARE
    v_total DECIMAL := 0;
BEGIN
    SELECT COALESCE(SUM(
        h.quantity * COALESCE(
            (SELECT close_price FROM stock_prices 
             WHERE asset_id = a.id AND price_date <= p_date 
             ORDER BY price_date DESC LIMIT 1),
            (SELECT price_usd FROM crypto_prices 
             WHERE asset_id = a.id AND price_date <= p_date 
             ORDER BY price_date DESC LIMIT 1),
            0
        )
    ), 0) INTO v_total
    FROM holdings h
    JOIN assets a ON h.asset_id = a.id;
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: Get asset ID by symbol
-- Usage: SELECT fn_get_asset_id('AAPL');
-- =====================================================
CREATE OR REPLACE FUNCTION fn_get_asset_id(p_symbol VARCHAR)
RETURNS UUID AS $$
DECLARE
    v_asset_id UUID;
BEGIN
    SELECT id INTO v_asset_id
    FROM assets
    WHERE symbol = p_symbol;
    
    RETURN v_asset_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: Record daily portfolio snapshot
-- Called by n8n after price updates
-- Usage: SELECT fn_record_daily_snapshot();
-- =====================================================
CREATE OR REPLACE FUNCTION fn_record_daily_snapshot()
RETURNS VOID AS $$
DECLARE
    v_total DECIMAL := 0;
    v_cost DECIMAL := 0;
    v_prev_value DECIMAL;
    v_stocks DECIMAL := 0;
    v_etfs DECIMAL := 0;
    v_crypto DECIMAL := 0;
    v_cash DECIMAL := 0;
    v_bonds DECIMAL := 0;
BEGIN
    -- Get current total value and cost basis
    SELECT 
        COALESCE(SUM(current_value), 0),
        COALESCE(SUM(cost_basis), 0)
    INTO v_total, v_cost
    FROM v_portfolio_current;
    
    -- Get value by category
    SELECT COALESCE(SUM(current_value), 0) INTO v_stocks
    FROM v_portfolio_current 
    WHERE asset_type = 'stock';
    
    SELECT COALESCE(SUM(current_value), 0) INTO v_etfs
    FROM v_portfolio_current 
    WHERE asset_type = 'etf';
    
    SELECT COALESCE(SUM(current_value), 0) INTO v_crypto
    FROM v_portfolio_current 
    WHERE asset_type = 'crypto';
    
    SELECT COALESCE(SUM(current_value), 0) INTO v_cash
    FROM v_portfolio_current 
    WHERE asset_type = 'cash';
    
    SELECT COALESCE(SUM(current_value), 0) INTO v_bonds
    FROM v_portfolio_current 
    WHERE asset_type = 'bond';
    
    -- Get previous day's value
    SELECT total_value INTO v_prev_value
    FROM portfolio_snapshots
    WHERE snapshot_date = CURRENT_DATE - 1;
    
    -- Insert or update today's snapshot
    INSERT INTO portfolio_snapshots (
        snapshot_date,
        total_value,
        total_cost_basis,
        total_gain_loss,
        total_gain_loss_pct,
        day_change,
        day_change_pct,
        stocks_value,
        etfs_value,
        crypto_value,
        cash_value,
        bonds_value,
        stocks_pct,
        crypto_pct,
        cash_pct
    ) VALUES (
        CURRENT_DATE,
        v_total,
        v_cost,
        v_total - v_cost,
        CASE WHEN v_cost > 0 THEN ROUND((v_total - v_cost) / v_cost * 100, 4) ELSE 0 END,
        v_total - COALESCE(v_prev_value, v_total),
        CASE WHEN v_prev_value > 0 THEN ROUND((v_total - v_prev_value) / v_prev_value * 100, 4) ELSE 0 END,
        v_stocks,
        v_etfs,
        v_crypto,
        v_cash,
        v_bonds,
        CASE WHEN v_total > 0 THEN ROUND(v_stocks / v_total * 100, 2) ELSE 0 END,
        CASE WHEN v_total > 0 THEN ROUND(v_crypto / v_total * 100, 2) ELSE 0 END,
        CASE WHEN v_total > 0 THEN ROUND(v_cash / v_total * 100, 2) ELSE 0 END
    )
    ON CONFLICT (snapshot_date) DO UPDATE SET
        total_value = EXCLUDED.total_value,
        total_cost_basis = EXCLUDED.total_cost_basis,
        total_gain_loss = EXCLUDED.total_gain_loss,
        total_gain_loss_pct = EXCLUDED.total_gain_loss_pct,
        day_change = EXCLUDED.day_change,
        day_change_pct = EXCLUDED.day_change_pct,
        stocks_value = EXCLUDED.stocks_value,
        etfs_value = EXCLUDED.etfs_value,
        crypto_value = EXCLUDED.crypto_value,
        cash_value = EXCLUDED.cash_value,
        bonds_value = EXCLUDED.bonds_value,
        stocks_pct = EXCLUDED.stocks_pct,
        crypto_pct = EXCLUDED.crypto_pct,
        cash_pct = EXCLUDED.cash_pct;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: Update holding after transaction
-- Automatically updates holdings when a transaction is recorded
-- =====================================================
CREATE OR REPLACE FUNCTION fn_update_holding_from_transaction()
RETURNS TRIGGER AS $$
DECLARE
    v_existing_quantity DECIMAL;
    v_existing_cost DECIMAL;
    v_new_quantity DECIMAL;
    v_new_cost DECIMAL;
BEGIN
    -- Get existing holding
    SELECT quantity, cost_basis 
    INTO v_existing_quantity, v_existing_cost
    FROM holdings
    WHERE account_id = NEW.account_id AND asset_id = NEW.asset_id;
    
    IF NEW.transaction_type = 'buy' THEN
        v_new_quantity := COALESCE(v_existing_quantity, 0) + NEW.quantity;
        v_new_cost := COALESCE(v_existing_cost, 0) + NEW.total_amount + COALESCE(NEW.fees, 0);
        
        INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
        VALUES (
            NEW.account_id,
            NEW.asset_id,
            v_new_quantity,
            v_new_cost,
            v_new_cost / NULLIF(v_new_quantity, 0),
            NEW.transaction_date
        )
        ON CONFLICT (account_id, asset_id) DO UPDATE SET
            quantity = v_new_quantity,
            cost_basis = v_new_cost,
            average_cost_per_share = v_new_cost / NULLIF(v_new_quantity, 0),
            updated_at = NOW();
            
    ELSIF NEW.transaction_type = 'sell' THEN
        v_new_quantity := COALESCE(v_existing_quantity, 0) - NEW.quantity;
        -- Reduce cost basis proportionally
        v_new_cost := COALESCE(v_existing_cost, 0) * (v_new_quantity / NULLIF(v_existing_quantity, 0));
        
        UPDATE holdings
        SET quantity = v_new_quantity,
            cost_basis = v_new_cost,
            average_cost_per_share = CASE WHEN v_new_quantity > 0 THEN v_new_cost / v_new_quantity ELSE 0 END,
            updated_at = NOW()
        WHERE account_id = NEW.account_id AND asset_id = NEW.asset_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic holding updates
DROP TRIGGER IF EXISTS trg_update_holding ON transactions;
CREATE TRIGGER trg_update_holding
    AFTER INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_holding_from_transaction();

-- =====================================================
-- FUNCTION: Calculate returns for a date range
-- Usage: SELECT * FROM fn_calculate_returns('2024-01-01', '2024-12-31');
-- =====================================================
CREATE OR REPLACE FUNCTION fn_calculate_returns(p_start_date DATE, p_end_date DATE)
RETURNS TABLE (
    start_value DECIMAL,
    end_value DECIMAL,
    absolute_return DECIMAL,
    percentage_return DECIMAL,
    days_in_period INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT total_value FROM portfolio_snapshots 
         WHERE snapshot_date >= p_start_date ORDER BY snapshot_date LIMIT 1) as start_value,
        (SELECT total_value FROM portfolio_snapshots 
         WHERE snapshot_date <= p_end_date ORDER BY snapshot_date DESC LIMIT 1) as end_value,
        (SELECT total_value FROM portfolio_snapshots 
         WHERE snapshot_date <= p_end_date ORDER BY snapshot_date DESC LIMIT 1) -
        (SELECT total_value FROM portfolio_snapshots 
         WHERE snapshot_date >= p_start_date ORDER BY snapshot_date LIMIT 1) as absolute_return,
        ROUND(
            ((SELECT total_value FROM portfolio_snapshots 
              WHERE snapshot_date <= p_end_date ORDER BY snapshot_date DESC LIMIT 1) -
             (SELECT total_value FROM portfolio_snapshots 
              WHERE snapshot_date >= p_start_date ORDER BY snapshot_date LIMIT 1)) /
            NULLIF((SELECT total_value FROM portfolio_snapshots 
                    WHERE snapshot_date >= p_start_date ORDER BY snapshot_date LIMIT 1), 0) * 100
        , 2) as percentage_return,
        (p_end_date - p_start_date)::INTEGER as days_in_period;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: Check for significant portfolio changes
-- Returns alert level based on daily change
-- Usage: SELECT * FROM fn_check_daily_alert();
-- =====================================================
CREATE OR REPLACE FUNCTION fn_check_daily_alert()
RETURNS TABLE (
    snapshot_date DATE,
    day_change DECIMAL,
    day_change_pct DECIMAL,
    total_value DECIMAL,
    alert_level VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ps.snapshot_date,
        ps.day_change,
        ps.day_change_pct,
        ps.total_value,
        CASE 
            WHEN ABS(ps.day_change_pct) >= 5 THEN 'CRITICAL'
            WHEN ABS(ps.day_change_pct) >= 3 THEN 'SIGNIFICANT'
            WHEN ABS(ps.day_change_pct) >= 1.5 THEN 'NOTABLE'
            ELSE 'NORMAL'
        END as alert_level
    FROM portfolio_snapshots ps
    WHERE ps.snapshot_date = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;
