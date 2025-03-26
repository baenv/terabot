# Terabot Trading System - Dashboard Interaction Guide

This guide provides step-by-step instructions for setting up and using the Terabot Trading System dashboard locally.

## Local Setup

### Step 1: Start the Application

1. Open your terminal
2. Navigate to the project directory:
   ```bash
   cd /path/to/terabot
   ```
3. Start the development environment using Devbox:
   ```bash
   devbox shell
   ```
4. Start the main application (which includes the web dashboard):
   ```bash
   make run
   ```
   
   This runs the command `cd trading_system/trading_system_main && mix run --no-halt`

> **Note:** Currently, there are dependency issues with the web dashboard component. If you encounter compilation errors, you may need to resolve these dependencies first.

### Step 2: Access the Dashboard

1. Open your web browser
2. Navigate to `http://localhost:4000`
3. You should see the Terabot dashboard homepage with portfolio overview

> **Troubleshooting:** If you can't access the dashboard at http://localhost:4000, there might be configuration issues. Check the terminal output for any errors related to the web server startup.

## Account Management

### Step 3: Register a CEX Account

1. Click on "Accounts" in the top navigation bar
2. Click the "Add CEX Account" button
3. Fill out the account form:
   - **Name**: Enter a descriptive name (e.g., "Binance Main")
   - **Provider**: Select your exchange (e.g., "binance")
   - **Account ID**: Enter your exchange account ID
   - **API Key**: Enter your exchange API key
   - **API Secret**: Enter your exchange API secret
4. Click "Register Account" to save

### Step 4: Register a Wallet with Private Key

1. Click on "Wallets" in the top navigation bar
2. Fill out the wallet form:
   - **Wallet Name**: Enter a name (e.g., "Ethereum Main")
   - **Provider/Network**: Select network (e.g., "ethereum")
   - **Wallet Address**: Enter your wallet's public address
   - **Private Key**: Enter your wallet's private key
   - **Encryption Password**: Create a password to encrypt your key
3. Click "Register Wallet" to save

## Portfolio Management

### Step 5: View Your Portfolio

1. Return to the Dashboard page
2. View your portfolio summary showing:
   - Total portfolio value
   - 7-day change
   - Active accounts
   - Top assets

### Step 6: Manage Accounts

1. Go to the "Accounts" page
2. Here you can:
   - View all registered accounts
   - Click "View" to see account details
   - Toggle accounts active/inactive using the button in the Actions column

### Step 7: View Transactions

1. Click on "Transactions" in the navigation
2. View the history of all transactions across your accounts
3. Filter transactions as needed

### Step 8: Analyze Portfolio Performance

1. Go to the "Portfolio" page
2. View detailed portfolio value history
3. Analyze asset allocation and performance metrics

## Security Features

The system prioritizes security for your private keys:

1. Private keys are encrypted using AES-256-CBC encryption
2. The encryption password is never stored
3. All API keys and private keys are stored securely

## Troubleshooting

If you encounter issues:

1. Check the terminal for error messages
2. Ensure your API keys have correct permissions
3. Verify your wallet addresses and private keys are entered correctly
4. If the web dashboard doesn't load:
   - Verify that the Phoenix server has started properly
   - Check for any port conflicts (default is 4000)
   - Try running individual components with `make run-core`, `make run-dashboard`, etc.

## Known Issues

1. **Dependency conflicts**: The web dashboard module may have dependency conflicts that prevent proper compilation
2. **Phoenix LiveView**: Some required Phoenix dependencies may be missing or have version conflicts
3. **Port conflicts**: The application may fail to start if port 4000 is already in use

## Data Refresh

- Portfolio data is updated automatically at regular intervals
- For immediate updates, you can manually trigger a sync from the account details page
- Historical performance metrics are calculated daily

For additional assistance or to report issues, please contact the development team. 
