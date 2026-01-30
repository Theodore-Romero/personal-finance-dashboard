# n8n Setup Guide

## 1. Install n8n

Use the cloud version at https://n8n.io or self-host with:

```bash
npx n8n
```

## 2. Create PostgreSQL Credential

1. In n8n, go to **Credentials > Add Credential > Postgres**
2. Enter your Supabase connection details:
   - **Host:** `db.[your-project-id].supabase.co`
   - **Port:** `5432`
   - **Database:** `postgres`
   - **User:** `postgres`
   - **Password:** Your Supabase database password
   - **SSL:** Enable (required for Supabase)

## 3. Import Workflows

1. In n8n, go to **Workflows > Import from File**
2. Import each workflow from the `n8n-workflows/` folder:

| File | Description | Schedule |
|------|-------------|----------|
| `01-stock-price-collection.json` | Fetches daily stock/ETF prices from Alpha Vantage | 6 PM ET, Mon-Fri |
| `02-crypto-price-collection.json` | Fetches crypto prices from CoinGecko | Daily |
| `03-economic-indicators.json` | Fetches Fed Rate, CPI, Unemployment from FRED | Weekly (Sunday) |
| `04-daily-snapshot.json` | Records portfolio value snapshot | After price updates |

## 4. Configure Credentials in Workflows

After importing, open each workflow and:

1. Click on each **Postgres** node and select your PostgreSQL credential
2. Click on each **HTTP Request** node and add your API keys where needed (Alpha Vantage, FRED)
3. Save the workflow

## 5. Activate Workflows

1. Toggle each workflow to **Active**
2. Verify the schedules are correct
3. Run each workflow manually once to confirm data flows into Supabase
