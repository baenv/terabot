# Running the Terabot Trading System

This document explains how to run the Terabot Trading System, including the web dashboard.

## Prerequisites

- Elixir/Erlang installed
- Devbox installed for database services
- Node.js installed for asset compilation

## Running Options

### Option 1: Using the Run Script (Recommended)

The simplest way to run the entire system is using the provided run script:

```bash
./run.sh
```

This will:
1. Build the web dashboard assets
2. Start the main application with the integrated web dashboard
3. Give you an interactive IEx console

### Option 2: Using Make Commands

Several make targets are available to run the system:

```bash
# Run the complete system with the web dashboard
make run

# Run the web dashboard standalone on port 4001
make run-web

# Run just the main trading system without the web dashboard
make run-trading

# Run using the run.sh script
make run-script
```

### Option 3: Manual Start

If you prefer to start components individually:

1. Build the assets:
```bash
cd trading_system/web_dashboard
mix deps.get
mix assets.deploy
```

2. Start the main application:
```bash
cd trading_system/trading_system_main
iex -S mix
```

## Accessing the Web Dashboard

Once the system is running, you can access the web dashboard at:

- When using the integrated approach: http://localhost:4000
- When running standalone: http://localhost:4001

## Troubleshooting

If you encounter issues:

1. Ensure all dependencies are installed:
```bash
make deps
```

2. Make sure the database services are running:
```bash
make start
```

3. Check for port conflicts if the web dashboard won't start

## Stopping the System

To stop the system, simply exit the IEx console by pressing `Ctrl+C` twice or typing `System.halt(0)`. 
