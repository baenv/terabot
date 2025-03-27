#!/bin/bash
# Run script for the Terabot Trading System
# This script builds assets and starts the main application with an interactive console

set -e  # Exit on error

echo "=== Building web dashboard assets ==="
cd trading_system/web_dashboard
mix deps.get
mix assets.deploy

echo "=== Starting the trading system with web dashboard ==="
cd ../trading_system_main
iex -S mix

echo "System shutdown." 
