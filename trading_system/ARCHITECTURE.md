# Terabot Trading System Architecture

## System Overview

Terabot is an Elixir-based cryptocurrency trading system built using the "poncho" architecture pattern. This architecture consists of multiple independent OTP applications that communicate through well-defined interfaces, allowing for modular development, testing, and deployment.

## Architectural Principles

1. **Modularity**: Each component is an independent OTP application
2. **Fault Tolerance**: Proper supervision trees ensure system resilience
3. **Clear Interfaces**: Well-defined APIs between components
4. **Shared Database**: Centralized PostgreSQL database with schemas in the core application
5. **Process Isolation**: Components run in isolated processes with proper message passing

## OTP Application Structure

The system consists of the following OTP applications, each with its own supervision tree:

### Core

The foundation of the system, providing shared functionality:

- **Core.Repo**: Ecto repository for database interactions
- **Core.Schema**: Database schemas for accounts, balances, transactions, and portfolio snapshots

### Data Collector

Responsible for gathering market data:

- Connects to Binance API
- Collects real-time and historical data for trading pairs (BTCUSDT, ETHUSDT, BNBUSDT)
- Stores raw market data in the database

### Data Processor

Processes raw market data:

- Applies technical analysis algorithms
- Generates signals and indicators
- Prepares data for the decision engine

### Decision Engine

Implements trading strategies:

- Evaluates market conditions based on processed data
- Generates trading signals
- Applies risk management rules
- Sends trade decisions to the order manager

### Order Manager

Handles order execution:

- Translates trading decisions into exchange orders
- Monitors order status
- Handles order lifecycle (creation, filling, cancellation)
- Reports execution results back to the system

### Portfolio Manager

Tracks portfolio performance:

- **PortfolioManager.Tracker**: Maintains real-time portfolio state
- **PortfolioManager.Metrics**: Calculates performance metrics
  - ROI calculation (daily, weekly, monthly, yearly)
  - Volatility calculation with annualization
  - Sharpe ratio calculation
  - Maximum drawdown calculation
  - Asset allocation analysis
- **PortfolioManager.API**: Public interface for other components
- **PortfolioManager.Adapters**: Exchange-specific implementations
  - Binance adapter for account synchronization
- **PortfolioManager.Web.Server**: HTTP server for portfolio management API

### Trading System Main

The entry point and orchestrator:

- **TradingSystemMain.Supervisor**: Root supervisor
- **TradingSystemMain.Web.Server**: HTTP server for system-wide API
- **TradingSystemMain.Web.Router**: API routing

## Supervision Tree

The system uses a hierarchical supervision structure where each application has its own supervisor tree. The applications are started independently but have dependencies on each other. Here's the actual supervision hierarchy:

```
# Root Application Supervisors (Started in this order based on dependencies)

Core.Supervisor (one_for_one)
├── Core.Repo

DataCollector.Supervisor (one_for_one)
├── DataCollector.Worker

DataProcessor.Supervisor (one_for_one)
├── DataProcessor.Worker

DecisionEngine.Supervisor (one_for_one)
├── DecisionEngine.Worker

OrderManager.Supervisor (one_for_one)
├── OrderManager.Worker

PortfolioManager.Supervisor (one_for_one)
├── Registry (PortfolioManager.AdapterRegistry)
├── PortfolioManager.Tracker
├── PortfolioManager.Adapters.Supervisor (DynamicSupervisor)
│   └── [Dynamic adapter processes - one per account]
└── PortfolioManager.Web.Server

TradingSystemMain.Supervisor (one_for_one)
└── TradingSystemMain.Web.Server
```

Each application is started as a separate OTP application with its own supervision tree. The applications are started in dependency order, with Core starting first as it provides the database access needed by all other applications.

## Process Flow Examples

### Account Registration Flow

When a user registers a new account in the system, the following process flow occurs:

1. **API Call Initiation**:
   - The process begins with a call to `PortfolioManager.API.register_account(account_params)` with parameters including account name, type, provider, account_id, and configuration.
   - This is a public API function that delegates to the Tracker module.

2. **Tracker GenServer Processing**:
   - The API call is forwarded to `PortfolioManager.Tracker.register_account(account_params)`.
   - This function makes a GenServer call to the Tracker process: `GenServer.call(__MODULE__, {:register_account, account_params})`.
   - The Tracker process handles this message in its `handle_call({:register_account, account_params}, _from, state)` callback.

3. **Database Persistence**:
   - The Tracker creates an Account changeset using `Account.create_changeset(account_params)`.
   - It then inserts the account into the database using `Core.Repo.insert(changeset)`.
   - This creates a record in the `accounts` table with the provided information.

4. **Adapter Initialization**:
   - After successful database insertion, the Tracker determines the appropriate adapter module based on the account provider (e.g., `PortfolioManager.Adapters.BinanceAdapter` for "binance").
   - It then calls `PortfolioManager.Adapters.Supervisor.start_adapter(adapter_module, adapter_config)` to start a new adapter process.

5. **Dynamic Supervision**:
   - The Adapters Supervisor, which is a DynamicSupervisor, creates a new child process for the adapter using `DynamicSupervisor.start_child(__MODULE__, {adapter_module, config})`.
   - The adapter process is registered in the `PortfolioManager.AdapterRegistry` with a key of `{adapter_module, account_id}`.

6. **Initial Synchronization**:
   - The newly created adapter process performs an initial synchronization with the exchange.
   - It fetches current balances and possibly transaction history from the exchange API.
   - The adapter updates the balances in the database through the `Balance` schema.

7. **Response**:
   - After successful registration and synchronization, the Tracker returns `{:ok, account}` with the created account record.
   - This response is passed back through the API to the caller.

### Sequence Diagram for Account Registration

```
Client                   API                 Tracker               Repo                AdapterSupervisor        Adapter
  |                       |                     |                    |                        |                       |
  | register_account()    |                     |                    |                        |                       |
  |---------------------> |                     |                    |                        |                       |
  |                       | register_account()  |                    |                        |                       |
  |                       |-------------------> |                    |                        |                       |
  |                       |                     | create_changeset() |                        |                       |
  |                       |                     |----------------    |                        |                       |
  |                       |                     |                |   |                        |                       |
  |                       |                     |<---------------    |                        |                       |
  |                       |                     | insert(changeset)  |                        |                       |
  |                       |                     |------------------> |                        |                       |
  |                       |                     |                    | insert account         |                       |
  |                       |                     |                    |----------------        |                       |
  |                       |                     |                    |               |        |                       |
  |                       |                     |                    |<---------------        |                       |
  |                       |                     |                    |                        |                       |
  |                       |                     | start_adapter()    |                        |                       |
  |                       |                     |----------------------------------------------> |                   |
  |                       |                     |                    |                        | start_child()         |
  |                       |                     |                    |                        |--------------------> |
  |                       |                     |                    |                        |                       | init()
  |                       |                     |                    |                        |                       |-------
  |                       |                     |                    |                        |                       |      |
  |                       |                     |                    |                        |                       |<------
  |                       |                     |                    |                        |                       |
  |                       |                     |                    |                        |                       | sync_balances()
  |                       |                     |                    |                        |                       |-------
  |                       |                     |                    |                        |                       |      |
  |                       |                     |                    |                        |                       |<------
  |                       |                     |                    |                        |<--------------------- |
  |                       |                     |<--------------------------------------------- |                   |
  |                       |<-------------------- |                    |                        |                       |
  |<--------------------- |                     |                    |                        |                       |
  |                       |                     |                    |                        |                       |
```

This flow demonstrates how the system uses OTP principles like supervision, GenServer processes, and message passing to handle account registration in a fault-tolerant way.

### Transaction Recording Flow

When a trade or other transaction occurs, the system records it through the following process:

1. **API Call Initiation**:
   - The process begins with a call to `PortfolioManager.API.record_transaction(transaction_params)` with parameters including account_id, tx_id, tx_type, asset, amount, price, and timestamp.
   - This public API function delegates to the Tracker module.

2. **Tracker GenServer Processing**:
   - The API call is forwarded to `PortfolioManager.Tracker.record_transaction(transaction_params)`.
   - This function makes a GenServer call to the Tracker process: `GenServer.call(__MODULE__, {:record_transaction, transaction_params})`.
   - The Tracker process handles this message in its `handle_call({:record_transaction, transaction_params}, _from, state)` callback.

3. **Database Persistence**:
   - The Tracker creates a Transaction changeset using `Transaction.create_changeset(transaction_params)`.
   - It then inserts the transaction into the database using `Core.Repo.insert(changeset)`.
   - This creates a record in the `transactions` table with the provided information.

4. **Balance Update**:
   - After successful database insertion, the Tracker calls `update_balances_from_transaction(transaction)` to update the relevant balances.
   - This function retrieves the account record and updates the corresponding balance based on the transaction type:
     - For "buy" transactions: Decreases the quote asset balance (e.g., USDT) and increases the base asset balance (e.g., BTC)
     - For "sell" transactions: Increases the quote asset balance and decreases the base asset balance
     - For "deposit" transactions: Increases the deposited asset balance
     - For "withdrawal" transactions: Decreases the withdrawn asset balance

5. **Response**:
   - After successful transaction recording and balance updating, the Tracker returns `{:ok, transaction}` with the created transaction record.
   - This response is passed back through the API to the caller.

### Performance Metrics Calculation Flow

When calculating performance metrics (e.g., ROI, volatility, Sharpe ratio), the system follows this process:

1. **API Call Initiation**:
   - The process begins with a call to a metrics function such as `PortfolioManager.API.calculate_roi(period, opts)` with parameters including the time period (:daily, :weekly, :monthly, :yearly) and options.
   - This public API function delegates to the Metrics module.

2. **Metrics Module Processing**:
   - The Metrics module implements the calculation logic for various performance metrics.
   - For ROI calculation, it follows these steps:
     - Retrieves portfolio snapshots for the specified time period from the database
     - Calculates the starting and ending portfolio values
     - Computes the ROI using the formula: (ending_value - starting_value) / starting_value
     - Annualizes the result if necessary based on the period

3. **Database Queries**:
   - The Metrics module queries the `portfolio_snapshots` table to retrieve historical portfolio values.
   - It uses Ecto queries to filter snapshots by date range and other criteria.

4. **Calculation Logic**:
   - Each metric has its own calculation logic:
     - **ROI**: Simple percentage return calculation
     - **Volatility**: Standard deviation of returns with annualization
     - **Sharpe Ratio**: (ROI - risk_free_rate) / volatility
     - **Maximum Drawdown**: Largest peak-to-trough decline
     - **Asset Allocation**: Percentage breakdown of portfolio by asset

5. **Response**:
   - After successful calculation, the function returns `{:ok, result}` with the calculated metric.
   - This response is passed back through the API to the caller.

### Portfolio Synchronization Flow

The system maintains up-to-date portfolio information through multiple synchronization mechanisms with exchanges:

#### Real-Time Synchronization

1. **WebSocket Connections**:
   - Each adapter establishes a persistent WebSocket connection to the exchange API.
   - The WebSocket connection receives real-time events for account updates, trades, and orders.
   - When an event is received, it's processed immediately and the database is updated.

2. **Webhook Integration**:
   - A webhook server listens for incoming notifications from exchanges.
   - Exchanges push events to our webhook endpoints when transactions or balance changes occur.
   - Each webhook request is validated for authenticity and then processed.

3. **Event Processing**:
   - Real-time events are processed by the appropriate adapter.
   - The adapter extracts relevant information and forwards it to the Tracker.
   - The Tracker updates the database and broadcasts events via PubSub.

4. **PubSub Broadcasting**:
   - When balances or transactions are updated, events are broadcast to interested subscribers.
   - This enables real-time updates in the UI and notifications to other system components.

#### Periodic Synchronization (Fallback)

1. **Scheduled Sync**:
   - Each adapter process has a timer that triggers periodic synchronization.
   - When WebSocket is active, this occurs less frequently (every 30 minutes).
   - When WebSocket is inactive, this occurs more frequently (every 5 minutes).

2. **Manual Sync**:
   - A sync can also be manually triggered via `PortfolioManager.API.sync_account(account_id)`.
   - This function delegates to the Tracker, which sends a cast message to itself: `GenServer.cast(__MODULE__, {:sync_account, account_id})`.

3. **Adapter Process**:
   - The Tracker locates the appropriate adapter process in the registry.
   - It sends a message to the adapter to perform the sync operation.

4. **Exchange API Interaction**:
   - The adapter makes API calls to the exchange to fetch current balances and possibly recent transactions.
   - For example, the Binance adapter uses the Binance API to retrieve account information.

5. **Database Update**:
   - The adapter updates the balances in the database through the `Balance` schema.
   - It uses upsert operations to ensure that balances are created or updated as needed.

6. **Event Publication**:
   - After successful synchronization, the adapter publishes an event to notify other parts of the system.
   - This allows components like the portfolio tracker to react to balance changes.

## Database Schema

All database schemas are defined in the Core application:

### Accounts

```elixir
schema "accounts" do
  field :name, :string
  field :type, :string  # "dex" or "cex"
  field :provider, :string  # e.g., "binance", "uniswap"
  field :account_id, :string  # platform-specific ID
  field :config, :map  # platform-specific configuration
  field :metadata, :map, default: %{}  # additional data
  field :active, :boolean, default: true
  
  has_many :balances, Core.Schema.Balance
  has_many :transactions, Core.Schema.Transaction
  
  timestamps()
end
```

### Balances

```elixir
schema "balances" do
  field :asset, :string
  field :total, :decimal
  field :available, :decimal
  field :locked, :decimal
  field :last_updated, :utc_datetime_usec
  
  belongs_to :account, Account
  
  timestamps()
end
```

### Transactions

```elixir
schema "transactions" do
  field :tx_id, :string  # platform-specific transaction ID
  field :tx_type, :string  # "buy", "sell", "deposit", "withdrawal"
  field :asset, :string
  field :amount, :decimal
  field :price, :decimal
  field :fee, :decimal
  field :fee_asset, :string
  field :timestamp, :utc_datetime_usec
  field :metadata, :map, default: %{}  # additional data
  
  belongs_to :account, Account
  
  timestamps()
end
```

### Portfolio Snapshots

```elixir
schema "portfolio_snapshots" do
  field :timestamp, :utc_datetime_usec
  field :base_currency, :string, default: "USDT"
  field :value, :decimal
  field :assets, :map  # Map of asset => value pairs
  field :accounts, :map  # Map of account_id => value pairs
  
  timestamps()
end
```

## Communication Flow

The system components communicate through the following patterns:

1. **Direct Function Calls**: Through public API modules (e.g., `PortfolioManager.API`)
2. **Database**: Shared database access for persistent data
3. **Message Passing**: GenServer calls/casts for process communication
4. **HTTP API**: Web interfaces for external communication

## Data Flow

1. **Data Collection**: Data Collector fetches market data from exchanges
2. **Data Processing**: Data Processor applies technical analysis to raw data
3. **Decision Making**: Decision Engine evaluates processed data and generates trading signals
4. **Order Execution**: Order Manager executes trades based on signals
5. **Portfolio Tracking**: Portfolio Manager records transactions and tracks performance

### Complete Trading System Flow

The following diagram illustrates the complete flow of data and control through the Terabot trading system:

```
External Exchange APIs
       ↑↓
+----------------+
| Data Collector |
+----------------+
       ↓
  Market Data
       ↓
+----------------+
| Data Processor |
+----------------+
       ↓
 Technical Indicators
       ↓
+----------------+     Strategy Parameters
| Decision Engine | ←------------------------+
+----------------+                          |
       ↓                                    |
  Trading Signals                           |
       ↓                                    |
+----------------+     Order Status         |
| Order Manager  | ------------------------>|
+----------------+                          |
       ↓                                    |
  Executed Orders                           |
       ↓                                    |
+----------------+     Performance Metrics  |
| Portfolio      | ------------------------>|
| Manager        |                          |
+----------------+                          |
       ↓                                    |
  Portfolio State                           |
       ↓                                    |
+----------------+                          |
| Trading System | -----------------------→+
| Main           |
+----------------+
       ↓
    API/UI
```

### Component Interaction Example: Trading Decision Process

Here's a detailed example of how the components interact during the trading decision process:

1. **Market Data Collection**:
   - The Data Collector connects to the Binance WebSocket API to receive real-time market data for configured trading pairs (BTCUSDT, ETHUSDT, BNBUSDT).
   - It also periodically fetches historical candlestick data via REST API calls.
   - The collected data is stored in the database and made available to other components.

2. **Technical Analysis**:
   - The Data Processor retrieves raw market data from the database.
   - It applies various technical analysis algorithms to generate indicators such as:
     - Moving Averages (SMA, EMA)
     - Relative Strength Index (RSI)
     - Moving Average Convergence Divergence (MACD)
     - Bollinger Bands
     - Volume indicators
   - The processed data and indicators are stored back in the database.

3. **Strategy Evaluation**:
   - The Decision Engine loads the processed data and indicators from the database.
   - It applies configured trading strategies to the data.
   - Each strategy evaluates market conditions and generates buy/sell signals based on predefined rules.
   - The signals are weighted and combined according to the strategy configuration.
   - Risk management rules are applied to determine position sizes and stop-loss levels.

4. **Order Generation**:
   - When a trading signal exceeds the configured threshold, the Decision Engine creates an order request.
   - The order request includes details such as:
     - Trading pair (e.g., BTCUSDT)
     - Order type (market, limit)
     - Side (buy, sell)
     - Quantity
     - Price (for limit orders)
     - Stop-loss and take-profit levels
   - The order request is sent to the Order Manager.

5. **Order Execution**:
   - The Order Manager receives the order request from the Decision Engine.
   - It validates the order against current market conditions and available balances.
   - If valid, it translates the order request into the exchange-specific format.
   - It submits the order to the exchange via the API.
   - It monitors the order status until it is filled, cancelled, or rejected.
   - It reports the order execution results back to the Decision Engine and Portfolio Manager.

6. **Portfolio Update**:
   - The Portfolio Manager receives notification of the executed order.
   - It records the transaction in the database.
   - It updates the account balances accordingly.
   - It creates a new portfolio snapshot to track the portfolio value over time.
   - It recalculates performance metrics based on the updated portfolio state.

7. **Strategy Adjustment**:
   - The Trading System Main component periodically evaluates the performance metrics.
   - Based on the performance, it may adjust strategy parameters such as:
     - Signal thresholds
     - Position sizing rules
     - Risk management parameters
   - These adjustments are fed back to the Decision Engine to influence future trading decisions.

This cycle continuously repeats, with each component performing its specialized role in the trading process while communicating with other components through well-defined interfaces.

## Performance Metrics

The Portfolio Manager calculates the following metrics:

1. **Return on Investment (ROI)**: For different time periods (daily, weekly, monthly, yearly)
2. **Volatility**: Standard deviation of returns with annualization
3. **Sharpe Ratio**: Risk-adjusted return metric with configurable risk-free rate
4. **Maximum Drawdown**: Largest peak-to-trough decline in portfolio value
5. **Asset Allocation**: Percentage breakdown of portfolio by asset

## Development Guidelines

### Database Migrations

All database migrations should be placed in the `core` application rather than in individual component applications:

- Correct location: `/trading_system/core/priv/repo/migrations/`
- Not in individual apps: e.g., NOT in `/trading_system/portfolio_manager/priv/repo/migrations/`

### Elixir Best Practices

1. **Functional Paradigm**: Adhere to functional programming principles
   - Favor immutability and pure functions
   - Use pattern matching effectively
   - Implement recursion and higher-order functions appropriately

2. **Pattern Matching**: Utilize pattern matching for control flow rather than if/else chains when applicable

3. **Pipeline Operator**: Use the `|>` pipeline operator for transforming data through a series of functions

4. **Module Organization**:
   - Group related functions together
   - Place public functions at the top, private functions below
   - Use `@moduledoc` and `@doc` consistently

5. **Error Handling**: Implement appropriate error handling with proper return tuples

### Testing

Each component should have comprehensive tests:

1. **Unit Tests**: Test individual functions and modules
2. **Integration Tests**: Test interactions between components
3. **System Tests**: Test the entire system workflow

Run tests for a specific application:
```bash
cd app_name
mix test
```

Run all tests including integration tests:
```bash
mix test.all
```

## Deployment

The system is designed to be deployed as a single umbrella application or as separate OTP applications depending on scaling needs.

### Environment Variables

Configure the system using environment variables in `.env`:

```
# Database configuration
DATABASE_URL=postgres://user:pass@localhost:5432/terabot_dev

# Binance API configuration
BINANCE_API_KEY=your_api_key
BINANCE_API_SECRET=your_api_secret

# System configuration
PORT=4000
```

## Extending the System

### Adding New Exchange Adapters

1. Create a new adapter module in `portfolio_manager/lib/portfolio_manager/adapters/`
2. Implement the required callback functions
3. Register the adapter in the supervisor

### Adding New Trading Strategies

1. Create a new strategy module in `decision_engine/lib/decision_engine/strategies/`
2. Implement the strategy interface
3. Configure the strategy in the system configuration
