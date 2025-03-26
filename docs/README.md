# Trading System

An Elixir-based cryptocurrency trading system using the "poncho" architecture pattern.

## Project Structure

```
trading_system/
├── mix.exs                # Root project file for shared tasks
├── config/               # Shared configuration
├── core/                # Core shared functionality
├── data/                # Historical and processed data storage
├── data_collector/      # Data collection service
├── data_processor/      # Data processing service 
├── decision_engine/     # Trading decision logic
├── order_manager/       # Order execution & management
├── portfolio_manager/   # Portfolio tracking & management
└── trading_system_main/ # Main supervisor application
```

## Applications

- **core**: Shared libraries, utilities, and database schemas
- **data_collector**: Binance API integration for market data collection
- **data_processor**: Technical analysis and data processing
- **decision_engine**: Trading strategy implementation
- **order_manager**: Order execution and management
- **portfolio_manager**: Portfolio tracking and performance metrics
- **trading_system_main**: Main application supervisor and system orchestration

## Setup

1. Install devbox (if not already installed):
```bash
curl -fsSL https://get.jetpack.io/devbox | bash
```

2. Initialize development environment:
```bash
make init-shell  # Install required packages and enter devbox shell
make init-db     # Initialize the databases and start services
make init-mix    # Install Elixir dependencies
```

3. Configure environment variables in `.env`:
```bash
# Binance API configuration
BINANCE_API_KEY=your_api_key
BINANCE_API_SECRET=your_api_secret
```

4. Run the application:
```bash
mix run --no-halt
```

### Database Management

The project uses PostgreSQL managed through devbox. Common database commands:

```bash
make start     # Start database services
make stop      # Stop database services
make clean-db  # Clean database data
make reset-db  # Reset database (clean and reinitialize)
```

### Development Commands

The project provides several make commands for development:

```bash
make init-shell  # Enter devbox shell with required packages
make init-db     # Initialize and start databases
make init-mix    # Install Elixir dependencies
make test        # Run tests
make all         # Run init-mix and tests
```

## Development

Each application is independent and can be tested separately:

```bash
cd app_name
mix test
```

For running all tests including integration tests:
```bash
mix test.all
```

## Architecture

The system follows the "poncho" project pattern, where each component is an independent OTP application that can be developed and tested in isolation. The applications communicate through well-defined interfaces using direct process calls and shared database access.

### Key Features

- Fault-tolerant design using supervision trees
- PostgreSQL-based data persistence
- Real-time market data processing for multiple trading pairs (BTCUSDT, ETHUSDT, BNBUSDT)
- Extensible strategy framework
- Risk management controls
- Portfolio tracking and metrics

## Dependencies

The system is built as a collection of independent applications, each with its own dependencies. Core dependencies include:

- **dotenvy**: Environment variable management
- **ecto**: Database interactions and schemas
- **tai**: Trading infrastructure support
- Additional dependencies are managed within each application's mix.exs file

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
