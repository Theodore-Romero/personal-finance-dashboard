# Supabase Setup Guide

## 1. Create a Project

1. Go to https://supabase.com and sign up (free tier)
2. Click **New Project**
3. Choose a name and set a database password (save this — you'll need it for Power BI and n8n)
4. Select a region close to you
5. Wait for the project to provision

## 2. Run the Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Run the SQL files from the `database/` folder in this order:
   1. `schema.sql` — Creates all tables and indexes
   2. `views.sql` — Creates views used by Power BI
   3. `functions.sql` — Creates helper functions (snapshot recording, portfolio valuation)
   4. `seed-data.sql` — Inserts sample accounts, assets, and goals

## 3. Verify Setup

After running the SQL files, check that the following exist:

**Tables:** `asset_types`, `accounts`, `assets`, `holdings`, `transactions`, `stock_prices`, `crypto_prices`, `economic_indicators`, `benchmark_prices`, `goals`, `portfolio_snapshots`

**Views:** `v_portfolio_current`, `v_allocation_summary`, `v_holding_performance`, `v_portfolio_history`, `v_goal_progress`, `v_monthly_transactions`, `v_benchmark_comparison`

**Functions:** `fn_portfolio_value_on_date`, `fn_record_daily_snapshot`

## 4. Connection Details

For connecting Power BI and n8n, you'll need:

- **Host:** `db.[your-project-id].supabase.co`
- **Port:** `5432`
- **Database:** `postgres`
- **User:** `postgres`
- **Password:** The password you set when creating the project

Find these under **Settings > Database** in your Supabase dashboard.
