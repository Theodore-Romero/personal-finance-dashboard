# Power BI Setup Guide

## 1. Install Power BI Desktop

Download Power BI Desktop for free from https://powerbi.microsoft.com/desktop/

## 2. Connect to Supabase

1. Open Power BI Desktop
2. **Home > Get Data > Database > PostgreSQL database**
3. Enter your connection details:
   - **Server:** `db.[your-project-id].supabase.co`
   - **Database:** `postgres`
4. Choose **Import** mode for better performance
5. Select **Database** authentication and enter your Supabase credentials
6. Select the tables and views to import:
   - All tables (`accounts`, `assets`, `holdings`, `transactions`, `stock_prices`, `crypto_prices`, `economic_indicators`, `benchmark_prices`, `goals`, `portfolio_snapshots`)
   - All views (`v_portfolio_current`, `v_holding_performance`, `v_portfolio_history`, `v_goal_progress`, `v_benchmark_comparison`, etc.)

## 3. Set Up the Data Model

In **Model view**:

1. Verify relationships between tables:
   - `assets.id` → `holdings.asset_id`
   - `assets.id` → `stock_prices.asset_id`
   - `assets.id` → `crypto_prices.asset_id`
   - `accounts.id` → `holdings.account_id`
   - `asset_types.id` → `assets.asset_type_id`
2. Create a **Date table** for time intelligence (Modeling > New Table)

## 4. Open the Dashboard

If using the included `.pbix` file from the `powerbi/` folder:

1. Open the file in Power BI Desktop
2. You'll need to update the data source to point to your Supabase instance
3. **Home > Transform data > Data source settings > Change Source**
4. Enter your Supabase connection details
5. Click **Refresh** to load your data

## 5. Dashboard Pages

The dashboard includes 7 pages:

1. **Portfolio Overview** — Net worth, allocation donut chart, holdings table
2. **Performance Analysis** — Gain/loss by holding, performance categories
3. **Goal Tracking** — Progress toward financial goals
4. **Holdings** — Detailed holdings table with slicers
5. **Holding Detail** — Drill-through page for individual assets
6. **Market Context** — Economic indicators and S&P 500 trend
7. **What-If Analysis** — Interactive projections with adjustable parameters
