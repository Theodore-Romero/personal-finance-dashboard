-- =====================================================
-- PERSONAL FINANCE DATABASE SCHEMA
-- Run this in Supabase SQL Editor
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- REFERENCE TABLES
-- =====================================================

-- Asset types (stock, ETF, crypto, etc.)
CREATE TABLE asset_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO asset_types (name, category) VALUES
('stock', 'equity'),
('etf', 'equity'),
('mutual_fund', 'equity'),
('crypto', 'alternative'),
('bond', 'fixed_income'),
('cash', 'cash'),
('real_estate', 'alternative');

-- Financial accounts (brokerage, 401k, crypto wallet, etc.)
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    institution VARCHAR(100),
    is_tax_advantaged BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Assets/Securities master list
CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(20) NOT NULL,
    name VARCHAR(255),
    asset_type_id UUID REFERENCES asset_types(id),
    sector VARCHAR(100),
    exchange VARCHAR(50),
    currency VARCHAR(10) DEFAULT 'USD',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(symbol)
);

-- =====================================================
-- PORTFOLIO TABLES
-- =====================================================

-- Current holdings
CREATE TABLE holdings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID REFERENCES accounts(id),
    asset_id UUID REFERENCES assets(id),
    quantity DECIMAL(18, 8) NOT NULL,
    cost_basis DECIMAL(18, 2),
    average_cost_per_share DECIMAL(18, 4),
    first_purchase_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(account_id, asset_id)
);

-- Transaction history
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID REFERENCES accounts(id),
    asset_id UUID REFERENCES assets(id),
    transaction_type VARCHAR(20) NOT NULL,
    transaction_date DATE NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    price_per_unit DECIMAL(18, 4) NOT NULL,
    total_amount DECIMAL(18, 2) NOT NULL,
    fees DECIMAL(18, 2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- MARKET DATA TABLES
-- =====================================================

-- Daily stock/ETF prices
CREATE TABLE stock_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID REFERENCES assets(id),
    price_date DATE NOT NULL,
    open_price DECIMAL(18, 4),
    high_price DECIMAL(18, 4),
    low_price DECIMAL(18, 4),
    close_price DECIMAL(18, 4) NOT NULL,
    adjusted_close DECIMAL(18, 4),
    volume BIGINT,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(asset_id, price_date)
);

-- Daily crypto prices
CREATE TABLE crypto_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID REFERENCES assets(id),
    price_date DATE NOT NULL,
    price_usd DECIMAL(18, 4) NOT NULL,
    price_24h_ago DECIMAL(18, 4),
    change_24h_pct DECIMAL(10, 4),
    market_cap DECIMAL(20, 2),
    volume_24h DECIMAL(20, 2),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(asset_id, price_date)
);

-- Economic indicators (Fed rate, CPI, unemployment, etc.)
CREATE TABLE economic_indicators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    indicator_name VARCHAR(100) NOT NULL,
    indicator_code VARCHAR(20) NOT NULL,
    observation_date DATE NOT NULL,
    value DECIMAL(18, 4) NOT NULL,
    unit VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(indicator_code, observation_date)
);

-- Benchmark indices (S&P 500, etc.)
CREATE TABLE benchmark_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    benchmark_name VARCHAR(50) NOT NULL,
    benchmark_code VARCHAR(20) NOT NULL,
    price_date DATE NOT NULL,
    close_value DECIMAL(18, 4) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(benchmark_code, price_date)
);

-- =====================================================
-- GOAL TRACKING
-- =====================================================

-- Financial goals
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    target_amount DECIMAL(18, 2) NOT NULL,
    target_date DATE,
    current_amount DECIMAL(18, 2) DEFAULT 0,
    monthly_contribution DECIMAL(18, 2) DEFAULT 0,
    priority INTEGER DEFAULT 1,
    status VARCHAR(20) DEFAULT 'active',
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- DAILY SNAPSHOTS
-- =====================================================

-- Daily portfolio value snapshot
CREATE TABLE portfolio_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    snapshot_date DATE NOT NULL,
    total_value DECIMAL(18, 2) NOT NULL,
    total_cost_basis DECIMAL(18, 2),
    total_gain_loss DECIMAL(18, 2),
    total_gain_loss_pct DECIMAL(10, 4),
    day_change DECIMAL(18, 2),
    day_change_pct DECIMAL(10, 4),
    stocks_value DECIMAL(18, 2),
    etfs_value DECIMAL(18, 2),
    crypto_value DECIMAL(18, 2),
    cash_value DECIMAL(18, 2),
    bonds_value DECIMAL(18, 2),
    stocks_pct DECIMAL(5, 2),
    crypto_pct DECIMAL(5, 2),
    cash_pct DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(snapshot_date)
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_stock_prices_date ON stock_prices(price_date);
CREATE INDEX idx_stock_prices_asset ON stock_prices(asset_id);
CREATE INDEX idx_crypto_prices_date ON crypto_prices(price_date);
CREATE INDEX idx_crypto_prices_asset ON crypto_prices(asset_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_asset ON transactions(asset_id);
CREATE INDEX idx_holdings_account ON holdings(account_id);
CREATE INDEX idx_holdings_asset ON holdings(asset_id);
CREATE INDEX idx_portfolio_snapshots_date ON portfolio_snapshots(snapshot_date);
CREATE INDEX idx_economic_date ON economic_indicators(observation_date);
CREATE INDEX idx_benchmark_date ON benchmark_prices(price_date);
