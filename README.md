# Terabot Trading System

An Elixir-based cryptocurrency trading system with integrated web dashboard.

## Overview

The Terabot Trading System is a comprehensive platform for cryptocurrency trading that includes:

- Market data collection from exchanges
- Technical analysis and data processing  
- Advanced trading strategies
- Order execution and management
- Portfolio tracking and risk management
- Web dashboard for monitoring and control

## Quick Start

To run the complete system with the web dashboard:

```bash
./run.sh
```

For more detailed instructions on running the system, see [RUN_INSTRUCTIONS.md](RUN_INSTRUCTIONS.md).

## System Architecture

The system follows a "poncho" project pattern with independent OTP applications:

```
trading_system/
├── core/                # Core shared functionality
├── data_collector/      # Data collection service
├── data_processor/      # Data processing service 
├── decision_engine/     # Trading decision logic
├── order_manager/       # Order execution & management
├── portfolio_manager/   # Portfolio tracking & management
├── web_dashboard/       # Web interface dashboard
└── trading_system_main/ # Main application supervisor
```

## Documentation

For more detailed documentation, see:

- [Run Instructions](RUN_INSTRUCTIONS.md) - How to run the system
- [Architecture](docs/README.md) - System architecture and design
- [API Reference](docs/API.md) - API documentation

## Development

See the [Development Guide](docs/DEVELOPMENT.md) for instructions on setting up a development environment and contributing to the project.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
