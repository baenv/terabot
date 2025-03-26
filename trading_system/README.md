# Terabot Trading System

A comprehensive trading system built with Elixir for managing cryptocurrency portfolios across multiple chains and DEXes.

## System Architecture

The system consists of several OTP applications, with `trading_system_main` as the primary coordinator:

1. **Trading System Main** - Main application coordinating all components
2. **Core** - Central business logic and data models
3. **Data Collector** - Collects market data and blockchain information
4. **Portfolio Manager** - Manages portfolio tracking and position monitoring
5. **Order Manager** - Handles order execution and transaction management
6. **Web Dashboard** - User interface for system interaction

Each application is an independent OTP application that can run separately or as part of the complete system. The `trading_system_main` application serves as the coordinator, starting and supervising all other applications when running the complete system.

### Running Individual Applications

Each application can be run independently for development or testing:

```bash
# Change to the application directory
cd trading_system/core
mix deps.get
mix compile
mix run --no-halt

# Or for other applications
cd trading_system/portfolio_manager
mix deps.get
mix compile
mix run --no-halt
```

### Running the Complete System

To run the entire system together:

```bash
# Using the Makefile
make run

# Or directly
cd trading_system/trading_system_main
mix deps.get
mix compile
mix run --no-halt
```

## Prerequisites

- Elixir 1.17 or later
- Erlang/OTP 26 or later
- PostgreSQL 14 or later
- Node.js 18 or later (for web dashboard assets)

## Environment Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/terabot.git
cd terabot
```

2. Install dependencies:
```bash
make deps
cd trading_system/web_dashboard/assets && npm install
```

3. Set up environment variables:
```bash
# Create a .env file in the root directory
cp .env.example .env

# Edit .env with your configuration
```

Required environment variables:
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost/terabot

# Ethereum
ETH_RPC_URL=http://localhost:8545
ETH_CHAIN_ID=1

# Uniswap
UNISWAP_FACTORY_ADDRESS=0x...
UNISWAP_ROUTER_ADDRESS=0x...

# SushiSwap
SUSHISWAP_FACTORY_ADDRESS=0x...
SUSHISWAP_ROUTER_ADDRESS=0x...

# Web Dashboard
SECRET_KEY_BASE=your_secret_key_base
```

4. Set up the database:
```bash
make migrate
```

## Running the System

1. Start the system:
```bash
# Start all applications through trading_system_main
make run
```

2. Access the web dashboard:
- Open your browser and navigate to `http://localhost:4000`
- Default admin credentials:
  - Email: admin@example.com
  - Password: admin123

## Development Commands

All development commands are executed through the Makefile:

```bash
# Initialize development environment
make init-mix

# Run tests
make test
make test.coverage

# Format code
make format
make format.check

# Run static analysis
make lint

# Database operations
make migrate
make migrate.up
make migrate.down

# Clean and build
make clean
make build

# Run with console
make run.console
```

## Web Dashboard Features

### Portfolio Management

1. **Adding an Account**
   - Navigate to "Portfolios" → "Add Account"
   - Enter your Ethereum wallet address
   - Select the account type (DEX or CEX)
   - Save the account

2. **Viewing Portfolio**
   - Click on your portfolio in the dashboard
   - View:
     - ETH balance
     - Token balances
     - Liquidity pool positions
     - Transaction history

3. **Portfolio Analytics**
   - View portfolio performance metrics
   - Check historical data
   - Analyze trading patterns

### Trading Interface

1. **Market Overview**
   - View current market prices
   - Monitor trading pairs
   - Track market trends

2. **Order Management**
   - Place new orders
   - View active orders
   - Cancel or modify orders

3. **Position Management**
   - Monitor open positions
   - View position details
   - Close positions

### System Monitoring

1. **Health Status**
   - View system component status
   - Monitor connection health
   - Check error logs

2. **Performance Metrics**
   - View system performance
   - Monitor resource usage
   - Track API response times

## API Interface

The system exposes a REST API for programmatic access:

### Authentication
```bash
# Get authentication token
curl -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password"}'
```

### Portfolio API
```bash
# Get portfolio status
curl -X GET http://localhost:4000/api/portfolios/{portfolio_id} \
  -H "Authorization: Bearer {token}"

# Get account balances
curl -X GET http://localhost:4000/api/accounts/{account_id}/balances \
  -H "Authorization: Bearer {token}"
```

### Trading API
```bash
# Place order
curl -X POST http://localhost:4000/api/orders \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "market",
    "side": "buy",
    "symbol": "ETH/USDT",
    "amount": "1.0"
  }'
```

## Development

### Running Tests
```bash
# Run all tests
mix test

# Run specific test file
mix test test/portfolio_manager/tracker/worker_test.exs
```

### Code Style
```bash
# Format code
mix format

# Check code style
mix credo
```

### Database Migrations
```bash
# Create migration
mix ecto.gen.migration add_new_field

# Run migrations
mix ecto.migrate

# Rollback migration
mix ecto.rollback
```

## Troubleshooting

### Common Issues

1. **Database Connection**
   - Check DATABASE_URL in .env
   - Ensure PostgreSQL is running
   - Verify database exists

2. **Ethereum Node Connection**
   - Verify ETH_RPC_URL is correct
   - Check network connectivity
   - Ensure Ethereum node is running

3. **Web Dashboard Issues**
   - Clear browser cache
   - Check browser console for errors
   - Verify asset compilation

### Logs
```bash
# View application logs
tail -f /var/log/terabot/application.log

# View error logs
tail -f /var/log/terabot/error.log
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
