-- =====================================================
-- SEED DATA FOR TESTING
-- Run this in Supabase SQL Editor after functions.sql
-- This creates a sample portfolio for testing
-- =====================================================

-- =====================================================
-- SAMPLE ACCOUNTS
-- =====================================================
INSERT INTO accounts (name, account_type, institution, is_tax_advantaged) VALUES
('Fidelity Brokerage', 'brokerage', 'Fidelity', FALSE),
('Fidelity 401k', 'retirement', 'Fidelity', TRUE),
('Roth IRA', 'retirement', 'Vanguard', TRUE),
('Coinbase', 'crypto', 'Coinbase', FALSE),
('High-Yield Savings', 'savings', 'Marcus', FALSE);

-- =====================================================
-- SAMPLE ASSETS
-- =====================================================
INSERT INTO assets (symbol, name, asset_type_id, sector, exchange) VALUES
-- Stocks
('AAPL', 'Apple Inc.', (SELECT id FROM asset_types WHERE name = 'stock'), 'Technology', 'NASDAQ'),
('MSFT', 'Microsoft Corporation', (SELECT id FROM asset_types WHERE name = 'stock'), 'Technology', 'NASDAQ'),
('GOOGL', 'Alphabet Inc.', (SELECT id FROM asset_types WHERE name = 'stock'), 'Technology', 'NASDAQ'),
('AMZN', 'Amazon.com Inc.', (SELECT id FROM asset_types WHERE name = 'stock'), 'Technology', 'NASDAQ'),
('NVDA', 'NVIDIA Corporation', (SELECT id FROM asset_types WHERE name = 'stock'), 'Technology', 'NASDAQ'),
('JPM', 'JPMorgan Chase & Co.', (SELECT id FROM asset_types WHERE name = 'stock'), 'Financial', 'NYSE'),
('JNJ', 'Johnson & Johnson', (SELECT id FROM asset_types WHERE name = 'stock'), 'Healthcare', 'NYSE'),
-- ETFs
('VOO', 'Vanguard S&P 500 ETF', (SELECT id FROM asset_types WHERE name = 'etf'), 'Broad Market', 'NYSE'),
('VTI', 'Vanguard Total Stock Market ETF', (SELECT id FROM asset_types WHERE name = 'etf'), 'Broad Market', 'NYSE'),
('QQQ', 'Invesco QQQ Trust', (SELECT id FROM asset_types WHERE name = 'etf'), 'Technology', 'NASDAQ'),
('BND', 'Vanguard Total Bond Market ETF', (SELECT id FROM asset_types WHERE name = 'etf'), 'Bonds', 'NYSE'),
-- Crypto
('BTC', 'Bitcoin', (SELECT id FROM asset_types WHERE name = 'crypto'), 'Cryptocurrency', 'CRYPTO'),
('ETH', 'Ethereum', (SELECT id FROM asset_types WHERE name = 'crypto'), 'Cryptocurrency', 'CRYPTO'),
('SOL', 'Solana', (SELECT id FROM asset_types WHERE name = 'crypto'), 'Cryptocurrency', 'CRYPTO'),
-- Cash
('CASH', 'Cash', (SELECT id FROM asset_types WHERE name = 'cash'), 'Cash', 'N/A');

-- =====================================================
-- SAMPLE HOLDINGS
-- =====================================================
-- Fidelity Brokerage
INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Fidelity Brokerage'),
    (SELECT id FROM assets WHERE symbol = 'AAPL'),
    50, 8750.00, 175.00, '2023-06-15';

INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Fidelity Brokerage'),
    (SELECT id FROM assets WHERE symbol = 'MSFT'),
    30, 10500.00, 350.00, '2023-08-01';

INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Fidelity Brokerage'),
    (SELECT id FROM assets WHERE symbol = 'NVDA'),
    25, 11250.00, 450.00, '2024-01-10';

-- Fidelity 401k
INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Fidelity 401k'),
    (SELECT id FROM assets WHERE symbol = 'VOO'),
    100, 42000.00, 420.00, '2022-01-01';

INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Fidelity 401k'),
    (SELECT id FROM assets WHERE symbol = 'VTI'),
    80, 17600.00, 220.00, '2022-01-01';

INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Fidelity 401k'),
    (SELECT id FROM assets WHERE symbol = 'BND'),
    50, 3750.00, 75.00, '2022-06-01';

-- Roth IRA
INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Roth IRA'),
    (SELECT id FROM assets WHERE symbol = 'QQQ'),
    40, 16000.00, 400.00, '2023-01-15';

INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Roth IRA'),
    (SELECT id FROM assets WHERE symbol = 'GOOGL'),
    20, 2800.00, 140.00, '2023-03-01';

-- Coinbase
INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Coinbase'),
    (SELECT id FROM assets WHERE symbol = 'BTC'),
    0.5, 21000.00, 42000.00, '2023-09-01';

INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Coinbase'),
    (SELECT id FROM assets WHERE symbol = 'ETH'),
    5, 9000.00, 1800.00, '2023-09-01';

INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Coinbase'),
    (SELECT id FROM assets WHERE symbol = 'SOL'),
    50, 5000.00, 100.00, '2024-02-01';

-- High-Yield Savings (Cash)
INSERT INTO holdings (account_id, asset_id, quantity, cost_basis, average_cost_per_share, first_purchase_date)
SELECT 
    (SELECT id FROM accounts WHERE name = 'High-Yield Savings'),
    (SELECT id FROM assets WHERE symbol = 'CASH'),
    15000, 15000.00, 1.00, '2022-01-01';

-- =====================================================
-- SAMPLE STOCK PRICES (Last 7 days)
-- =====================================================
-- Generate dates for last 7 days
DO $$
DECLARE
    d DATE;
    base_prices RECORD;
BEGIN
    FOR i IN 0..6 LOOP
        d := CURRENT_DATE - i;
        
        -- Skip weekends for stocks
        IF EXTRACT(DOW FROM d) NOT IN (0, 6) THEN
            -- AAPL
            INSERT INTO stock_prices (asset_id, price_date, open_price, high_price, low_price, close_price, volume)
            SELECT (SELECT id FROM assets WHERE symbol = 'AAPL'), d,
                   185 + random() * 5, 188 + random() * 3, 183 + random() * 3, 185 + random() * 5, 50000000 + random() * 20000000
            ON CONFLICT (asset_id, price_date) DO NOTHING;
            
            -- MSFT
            INSERT INTO stock_prices (asset_id, price_date, open_price, high_price, low_price, close_price, volume)
            SELECT (SELECT id FROM assets WHERE symbol = 'MSFT'), d,
                   415 + random() * 10, 420 + random() * 5, 410 + random() * 5, 415 + random() * 10, 20000000 + random() * 10000000
            ON CONFLICT (asset_id, price_date) DO NOTHING;
            
            -- GOOGL
            INSERT INTO stock_prices (asset_id, price_date, open_price, high_price, low_price, close_price, volume)
            SELECT (SELECT id FROM assets WHERE symbol = 'GOOGL'), d,
                   175 + random() * 5, 178 + random() * 3, 173 + random() * 3, 175 + random() * 5, 25000000 + random() * 10000000
            ON CONFLICT (asset_id, price_date) DO NOTHING;
            
            -- NVDA
            INSERT INTO stock_prices (asset_id, price_date, open_price, high_price, low_price, close_price, volume)
            SELECT (SELECT id FROM assets WHERE symbol = 'NVDA'), d,
                   875 + random() * 20, 890 + random() * 15, 865 + random() * 15, 875 + random() * 25, 40000000 + random() * 20000000
            ON CONFLICT (asset_id, price_date) DO NOTHING;
            
            -- VOO
            INSERT INTO stock_prices (asset_id, price_date, open_price, high_price, low_price, close_price, volume)
            SELECT (SELECT id FROM assets WHERE symbol = 'VOO'), d,
                   480 + random() * 5, 483 + random() * 3, 478 + random() * 3, 480 + random() * 5, 5000000 + random() * 2000000
            ON CONFLICT (asset_id, price_date) DO NOTHING;
            
            -- VTI
            INSERT INTO stock_prices (asset_id, price_date, open_price, high_price, low_price, close_price, volume)
            SELECT (SELECT id FROM assets WHERE symbol = 'VTI'), d,
                   265 + random() * 3, 267 + random() * 2, 263 + random() * 2, 265 + random() * 3, 4000000 + random() * 1500000
            ON CONFLICT (asset_id, price_date) DO NOTHING;
            
            -- QQQ
            INSERT INTO stock_prices (asset_id, price_date, open_price, high_price, low_price, close_price, volume)
            SELECT (SELECT id FROM assets WHERE symbol = 'QQQ'), d,
                   485 + random() * 8, 490 + random() * 5, 482 + random() * 5, 485 + random() * 8, 35000000 + random() * 15000000
            ON CONFLICT (asset_id, price_date) DO NOTHING;
            
            -- BND
            INSERT INTO stock_prices (asset_id, price_date, open_price, high_price, low_price, close_price, volume)
            SELECT (SELECT id FROM assets WHERE symbol = 'BND'), d,
                   72 + random() * 0.5, 72.5 + random() * 0.3, 71.5 + random() * 0.3, 72 + random() * 0.5, 6000000 + random() * 2000000
            ON CONFLICT (asset_id, price_date) DO NOTHING;
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- SAMPLE CRYPTO PRICES (Last 7 days, including weekends)
-- =====================================================
DO $$
DECLARE
    d DATE;
BEGIN
    FOR i IN 0..6 LOOP
        d := CURRENT_DATE - i;
        
        -- BTC
        INSERT INTO crypto_prices (asset_id, price_date, price_usd, change_24h_pct, market_cap, volume_24h)
        SELECT (SELECT id FROM assets WHERE symbol = 'BTC'), d,
               65000 + random() * 5000, -2 + random() * 4, 1200000000000 + random() * 100000000000, 25000000000 + random() * 10000000000
        ON CONFLICT (asset_id, price_date) DO NOTHING;
        
        -- ETH
        INSERT INTO crypto_prices (asset_id, price_date, price_usd, change_24h_pct, market_cap, volume_24h)
        SELECT (SELECT id FROM assets WHERE symbol = 'ETH'), d,
               3400 + random() * 300, -3 + random() * 6, 400000000000 + random() * 50000000000, 12000000000 + random() * 5000000000
        ON CONFLICT (asset_id, price_date) DO NOTHING;
        
        -- SOL
        INSERT INTO crypto_prices (asset_id, price_date, price_usd, change_24h_pct, market_cap, volume_24h)
        SELECT (SELECT id FROM assets WHERE symbol = 'SOL'), d,
               180 + random() * 30, -4 + random() * 8, 80000000000 + random() * 15000000000, 3000000000 + random() * 1500000000
        ON CONFLICT (asset_id, price_date) DO NOTHING;
    END LOOP;
END $$;

-- =====================================================
-- SAMPLE GOALS
-- =====================================================
INSERT INTO goals (name, target_amount, target_date, current_amount, monthly_contribution, priority, status) VALUES
('Emergency Fund', 20000, '2025-06-01', 15000, 500, 1, 'active'),
('House Down Payment', 80000, '2027-01-01', 25000, 1500, 2, 'active'),
('New Car Fund', 35000, '2026-06-01', 8000, 800, 3, 'active'),
('Retirement', 1500000, '2055-01-01', 75000, 1000, 4, 'active'),
('Vacation Fund', 5000, '2025-03-01', 3500, 300, 5, 'active');

-- =====================================================
-- SAMPLE ECONOMIC INDICATORS
-- =====================================================
INSERT INTO economic_indicators (indicator_name, indicator_code, observation_date, value, unit) VALUES
('Federal Funds Rate', 'DFF', CURRENT_DATE, 5.25, 'percent'),
('Federal Funds Rate', 'DFF', CURRENT_DATE - 30, 5.25, 'percent'),
('Federal Funds Rate', 'DFF', CURRENT_DATE - 60, 5.50, 'percent'),
('Consumer Price Index', 'CPIAUCSL', CURRENT_DATE - 15, 314.5, 'index'),
('Consumer Price Index', 'CPIAUCSL', CURRENT_DATE - 45, 313.2, 'index'),
('Unemployment Rate', 'UNRATE', CURRENT_DATE - 15, 3.9, 'percent'),
('Unemployment Rate', 'UNRATE', CURRENT_DATE - 45, 3.7, 'percent'),
('VIX Volatility Index', 'VIXCLS', CURRENT_DATE, 14.5, 'index'),
('VIX Volatility Index', 'VIXCLS', CURRENT_DATE - 7, 15.2, 'index');

-- =====================================================
-- SAMPLE BENCHMARK PRICES (S&P 500)
-- =====================================================
DO $$
DECLARE
    d DATE;
BEGIN
    FOR i IN 0..30 LOOP
        d := CURRENT_DATE - i;
        
        IF EXTRACT(DOW FROM d) NOT IN (0, 6) THEN
            INSERT INTO benchmark_prices (benchmark_name, benchmark_code, price_date, close_value)
            VALUES ('S&P 500', 'SP500', d, 5200 + random() * 100)
            ON CONFLICT (benchmark_code, price_date) DO NOTHING;
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- SAMPLE PORTFOLIO SNAPSHOTS (Last 30 days)
-- =====================================================
DO $$
DECLARE
    d DATE;
    base_value DECIMAL := 180000;
    daily_change DECIMAL;
BEGIN
    FOR i IN REVERSE 30..0 LOOP
        d := CURRENT_DATE - i;
        daily_change := -500 + random() * 1000;
        base_value := base_value + daily_change;
        
        INSERT INTO portfolio_snapshots (
            snapshot_date, total_value, total_cost_basis, total_gain_loss, total_gain_loss_pct,
            day_change, day_change_pct, stocks_value, etfs_value, crypto_value, cash_value,
            stocks_pct, crypto_pct, cash_pct
        ) VALUES (
            d,
            base_value,
            150000,
            base_value - 150000,
            ROUND((base_value - 150000) / 150000 * 100, 2),
            daily_change,
            ROUND(daily_change / base_value * 100, 2),
            base_value * 0.35,
            base_value * 0.40,
            base_value * 0.15,
            15000,
            35,
            15,
            ROUND(15000 / base_value * 100, 2)
        )
        ON CONFLICT (snapshot_date) DO NOTHING;
    END LOOP;
END $$;

-- =====================================================
-- SAMPLE TRANSACTIONS
-- =====================================================
INSERT INTO transactions (account_id, asset_id, transaction_type, transaction_date, quantity, price_per_unit, total_amount, fees, notes)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Fidelity Brokerage'),
    (SELECT id FROM assets WHERE symbol = 'AAPL'),
    'buy', '2023-06-15', 30, 175.00, 5250.00, 0, 'Initial purchase';

INSERT INTO transactions (account_id, asset_id, transaction_type, transaction_date, quantity, price_per_unit, total_amount, fees, notes)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Fidelity Brokerage'),
    (SELECT id FROM assets WHERE symbol = 'AAPL'),
    'buy', '2023-09-20', 20, 175.00, 3500.00, 0, 'Added to position';

INSERT INTO transactions (account_id, asset_id, transaction_type, transaction_date, quantity, price_per_unit, total_amount, fees, notes)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Coinbase'),
    (SELECT id FROM assets WHERE symbol = 'BTC'),
    'buy', '2023-09-01', 0.5, 42000.00, 21000.00, 25.00, 'First Bitcoin purchase';

INSERT INTO transactions (account_id, asset_id, transaction_type, transaction_date, quantity, price_per_unit, total_amount, fees, notes)
SELECT 
    (SELECT id FROM accounts WHERE name = 'Fidelity 401k'),
    (SELECT id FROM assets WHERE symbol = 'VOO'),
    'buy', '2024-01-02', 10, 450.00, 4500.00, 0, '401k contribution';

-- =====================================================
-- VERIFICATION QUERIES
-- Run these to verify seed data loaded correctly
-- =====================================================
-- SELECT 'Accounts' as table_name, COUNT(*) as row_count FROM accounts
-- UNION ALL SELECT 'Assets', COUNT(*) FROM assets
-- UNION ALL SELECT 'Holdings', COUNT(*) FROM holdings
-- UNION ALL SELECT 'Stock Prices', COUNT(*) FROM stock_prices
-- UNION ALL SELECT 'Crypto Prices', COUNT(*) FROM crypto_prices
-- UNION ALL SELECT 'Goals', COUNT(*) FROM goals
-- UNION ALL SELECT 'Snapshots', COUNT(*) FROM portfolio_snapshots;
