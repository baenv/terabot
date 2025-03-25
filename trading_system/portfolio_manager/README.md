# Portfolio Manager Implementation Guide

## Overview

The Portfolio Manager is a critical component of your trading system, responsible for tracking and managing assets across different account types (DEX and CEX). This guide outlines the architecture, key modules, and implementation approach for building a scalable and flexible portfolio management system in Elixir.

## Core Functionality

The Portfolio Manager should:

1. Track assets across different platforms (DEX, CEX)
2. Provide real-time balance information
3. Record and track transactions
4. Calculate portfolio metrics and performance
5. Provide a unified API for other system components

## Architecture

### Adapter Pattern

Use an adapter pattern to integrate different account types:

1. Define a common behavior (protocol/interface) that all adapters must implement
2. Create specific adapters for different platforms (Binance, Uniswap, etc.)
3. Use dynamic supervision to manage adapter processes

### Data Model

**Core schemas:**

- `Account`: Stores account metadata and configuration
- `Balance`: Tracks asset balances
- `Transaction`: Records transaction history
- `PortfolioSnapshot`: Stores point-in-time portfolio values

### Module Structure

```
portfolio_manager/
├── lib/
│   ├── portfolio_manager/
│   │   ├── adapters/               # Account adapters
│   │   │   ├── adapter_behaviour.ex  # Common interface
│   │   │   ├── binance_adapter.ex   # Binance-specific adapter
│   │   │   ├── uniswap_adapter.ex   # Uniswap-specific adapter
│   │   │   └── supervisor.ex        # Adapter supervisor
│   │   ├── schema/                 # Database schemas
│   │   │   ├── account.ex
│   │   │   ├── balance.ex
│   │   │   ├── transaction.ex
│   │   │   └── portfolio_snapshot.ex
│   │   ├── tracker.ex              # Core portfolio tracking
│   │   ├── metrics.ex              # Performance metrics
│   │   ├── api.ex                  # Public API for other components
│   │   ├── repo.ex                 # Database repository
│   │   └── application.ex          # Application entry point
│   └── portfolio_manager.ex        # Main module
├── test/                           # Tests
├── priv/                           # Database migrations
├── config/                         # Configuration
└── mix.exs                         # Project file
```

## Implementation Guide

### Step 1: Define the Adapter Behaviour

Create a common interface for all platform adapters:

```elixir
defmodule PortfolioManager.Adapters.AdapterBehaviour do
  @callback get_balances() :: {:ok, map()} | {:error, any()}
  @callback get_transactions(opts :: map()) :: {:ok, list()} | {:error, any()}
  @callback get_asset_info(asset_id :: String.t()) :: {:ok, map()} | {:error, any()}
  @callback get_market_values(base_currency :: String.t()) :: {:ok, map()} | {:error, any()}
end
```

### Step 2: Implement Platform-Specific Adapters

For each platform (e.g., Binance, Uniswap), implement adapters that:

1. Connect to the specific platform API
2. Fetch account data (balances, transactions)
3. Transform platform-specific formats to a standardized format
4. Handle platform-specific error conditions

### Step 3: Create the Core Tracker Module

Implement a central tracking module that:

1. Manages account registrations
2. Schedules regular balance synchronization
3. Provides portfolio summary calculations
4. Maintains historical snapshots

### Step 4: Implement Performance Metrics

Build a metrics calculation module for:

1. ROI calculations (daily, weekly, monthly, yearly)
2. Risk metrics (volatility, drawdown)
3. Benchmark comparisons
4. Portfolio diversity analysis

### Step 5: Create a Public API

Implement a unified API that:

1. Provides portfolio summary data
2. Answers queries about available balances
3. Records transactions
4. Validates potential trades against available funds

## Database Design

### Accounts Table

```
- id (primary key)
- name (string)
- type (string, "dex" or "cex")
- provider (string, e.g., "binance", "uniswap")
- account_id (string, platform-specific ID)
- config (jsonb, platform-specific configuration)
- metadata (jsonb, additional data)
- active (boolean)
- inserted_at, updated_at (timestamps)
```

### Balances Table

```
- id (primary key)
- account_id (foreign key)
- asset (string)
- amount (decimal)
- available (decimal)
- locked (decimal)
- synced_at (timestamp)
- inserted_at, updated_at (timestamps)
```

### Transactions Table

```
- id (primary key)
- account_id (foreign key)
- tx_id (string, platform-specific transaction ID)
- tx_type (string, e.g., "buy", "sell", "deposit", "withdrawal")
- asset (string)
- amount (decimal)
- price (decimal, nullable)
- fee (decimal, nullable)
- fee_asset (string, nullable)
- timestamp (timestamp)
- metadata (jsonb, additional data)
- inserted_at, updated_at (timestamps)
```

### Portfolio Snapshots Table

```
- id (primary key)
- timestamp (timestamp)
- value (decimal)
- base_currency (string)
- asset_breakdown (jsonb)
- inserted_at, updated_at (timestamps)
```

## Synchronization Strategy

1. **Initial sync**: Perform a complete sync when an account is first registered
2. **Scheduled sync**: Configure regular sync intervals based on account type
3. **On-demand sync**: Allow other components to trigger syncs when needed
4. **Throttling**: Implement rate limiting to avoid API overuse
5. **Error handling**: Implement retry mechanisms for transient errors

## Extension Points

1. **Additional adapters**: Design the system so new platforms can be added easily
2. **Custom metrics**: Allow custom performance metrics to be defined
3. **Webhook support**: Implement webhook listeners for real-time updates
4. **Tax reporting**: Add modules for tax calculation and reporting
5. **Multi-currency support**: Allow portfolio valuation in different currencies

## Testing Strategy

1. **Mock adapters**: Create test adapters that simulate various platforms
2. **Snapshot testing**: Test portfolio calculations against known snapshots
3. **Property testing**: Use property-based testing for complex calculations
4. **Integration tests**: Test adapters against sandbox APIs where available

## Deployment Considerations

1. **Database partitioning**: Consider partitioning transaction data by time
2. **Scaling adapters**: Design for horizontal scaling of adapter processes
3. **Backup strategy**: Implement regular backups of portfolio data
4. **Monitoring**: Add metrics and logging for system health monitoring

## Next Steps

1. Implement the adapter behavior and basic account management
2. Create the database schemas and migrations
3. Implement one adapter (e.g., Binance) as a reference
4. Build the core tracking functionality
5. Implement the public API for other components
6. Add performance metrics calculation
7. Implement additional adapters as needed

This modular approach allows you to build and test components incrementally, starting with a single platform and expanding to additional platforms as needed.
