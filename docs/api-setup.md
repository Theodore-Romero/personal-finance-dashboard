# API Setup Guide

## Alpha Vantage (Stock & ETF Prices)

1. Go to https://www.alphavantage.co/support/#api-key
2. Enter your email and get a free API key (instant)
3. Save the key — you'll need it in your n8n workflow

**Limits:** 25 requests/day, 5 requests/minute (free tier)

**Test your key:**
```
https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=AAPL&apikey=YOUR_KEY
```

## CoinGecko (Cryptocurrency Prices)

No API key required for basic endpoints.

**Rate limit:** 10-30 calls/minute

**Test endpoint:**
```
https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=usd&include_24hr_change=true
```

## FRED API (Economic Indicators)

1. Go to https://fred.stlouisfed.org/docs/api/api_key.html
2. Create a free account
3. Request an API key

**Useful series IDs:**

| Series ID | Description |
|-----------|-------------|
| DFF | Federal Funds Rate |
| CPIAUCSL | Consumer Price Index (Inflation) |
| UNRATE | Unemployment Rate |
| SP500 | S&P 500 Index |
| VIXCLS | VIX Volatility Index |

**Test your key:**
```
https://api.stlouisfed.org/fred/series/observations?series_id=DFF&api_key=YOUR_KEY&file_type=json&limit=1&sort_order=desc
```
