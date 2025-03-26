# Portfolio Manager

The Portfolio Manager is a module of the trading system that handles portfolio tracking and management across different blockchain networks and decentralized exchanges (DEXes).

## Features

- Real-time portfolio tracking
- Multi-chain support (currently Ethereum)
- Multi-DEX support (Uniswap and SushiSwap)
- Balance monitoring for:
  - Native tokens (ETH)
  - ERC20 tokens
  - Liquidity pool positions
- Event-based updates via PubSub
- Configurable update intervals
- Error handling and logging

## Components

### Adapters

1. **Ethereum Adapter**
   - Handles ETH balance tracking
   - Token balance monitoring
   - Transaction history tracking

2. **Uniswap Adapter**
   - Liquidity pool position tracking
   - Token price fetching
   - Pool reserves monitoring

3. **SushiSwap Adapter**
   - Liquidity pool position tracking
   - Token price fetching
   - Pool reserves monitoring

### Tracker

The tracker system consists of:

1. **Supervisor**
   - Manages portfolio tracker processes
   - Handles process lifecycle
   - Provides monitoring and control

2. **Worker**
   - Tracks individual portfolio status
   - Updates balances and positions
   - Broadcasts portfolio updates

## Configuration

The module requires the following environment variables:

```bash
# Ethereum Configuration
ETH_RPC_URL=http://localhost:8545
ETH_CHAIN_ID=1

# Uniswap Configuration
UNISWAP_FACTORY_ADDRESS=0x...
UNISWAP_ROUTER_ADDRESS=0x...

# SushiSwap Configuration
SUSHISWAP_FACTORY_ADDRESS=0x...
SUSHISWAP_ROUTER_ADDRESS=0x...
```

## Usage

### Starting a Portfolio Tracker

```elixir
# Start a new portfolio tracker
PortfolioManager.Tracker.Supervisor.start_tracker(portfolio_id, account_id)

# Get portfolio status
PortfolioManager.Tracker.Worker.get_status(portfolio_id, account_id)

# Stop a portfolio tracker
PortfolioManager.Tracker.Supervisor.stop_tracker(portfolio_id)
```

### Subscribing to Portfolio Updates

```elixir
# Subscribe to portfolio updates
Phoenix.PubSub.subscribe(PortfolioManager.PubSub, "portfolio:update")

# Handle portfolio updates
def handle_info({:portfolio_updated, portfolio_id, status}, state) do
  # Handle portfolio update
  {:noreply, %{state | portfolio_status: status}}
end
```

## Dependencies

- Core module for shared functionality
- Phoenix PubSub for event broadcasting
- Ethereumex for Ethereum client
- Decimal for precise calculations
- Various monitoring and testing libraries

## Testing

Run the test suite:

```bash
mix test
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
