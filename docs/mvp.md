# Terabot Trading System - Ethereum MVP Specification

## Executive Summary

This document outlines the Minimum Viable Product (MVP) for the Terabot Trading System, an Elixir-based decentralized trading platform utilizing a "poncho" architecture pattern. The MVP will focus on Ethereum blockchain integration instead of Binance, establishing a complete workflow from signal generation to position management with both automated and manual controls.

## MVP Core Features

1. **Framework and Workflow Completion**: The full system structure and end-to-end trading flow
2. **Wallet Integration**: Capability to connect Ethereum wallets for trading
3. **Signal Generation and Alerting**: Production of trading signals and notifications
4. **Order Execution**: Ability to enter positions based on signals via Ethereum smart contracts
5. **Position Tracking**: Monitoring of open positions and their performance
6. **Automated Order Management**: Logic to automatically close positions
7. **Manual Intervention**: Capability for users to override automated decisions

## Technical Architecture

### Poncho Structure

The system will maintain the existing poncho project structure, consisting of multiple independent OTP applications that communicate through well-defined interfaces. This provides better isolation and clarity compared to umbrella projects.

### Component Responsibilities

#### Core
- **Purpose**: Provide shared functionality and database access
- **MVP Features**:
  - Database schema definitions for wallets, balances, transactions
  - Enhanced schemas for positions, signals, and orders
  - Shared utility functions and Ethereum-specific configurations
  - Web3 utility functions for blockchain interactions

#### Data Collector
- **Purpose**: Gather Ethereum market data
- **MVP Features**:
  - Ethereum node integration for retrieving real-time market data
  - WebSocket connections to Ethereum nodes for block and price updates
  - Integration with decentralized exchange (DEX) APIs for pricing data
  - Storage of collected data in the database

#### Data Processor
- **Purpose**: Process blockchain data into actionable insights
- **MVP Features**:
  - Data transformation for strategy evaluation
  - Analysis of gas prices and network conditions
  - Signal preparation based on indicator calculations

#### Decision Engine
- **Purpose**: Generate trading signals based on processed data
- **MVP Features**:
  - Single trading strategy implementation for Ethereum tokens
  - Buy/sell signal generation
  - Signal notification mechanism

#### Order Manager
- **Purpose**: Execute and track Ethereum transactions
- **MVP Features**:
  - Translation of signals into Ethereum transactions
  - Smart contract interaction for DEX trades
  - Transaction submission and confirmation tracking
  - Manual transaction cancellation capability (when possible)
  - Automatic position closing based on predefined rules

#### Portfolio Manager
- **Purpose**: Track wallet state and position performance
- **MVP Features**:
  - Token balance tracking across different assets
  - Position opening and management on DEXs
  - Position performance calculation (P&L)
  - Gas fee tracking 

#### Trading System Main
- **Purpose**: Orchestrate the entire system
- **MVP Features**:
  - System initialization and coordination
  - API for manual interventions

## Data Flow and Process Design

### Signal Generation and Alert Flow

1. Data Collector continuously fetches price data from Ethereum nodes and DEX APIs
2. Data Processor analyzes this data using technical indicators
3. Decision Engine evaluates processed data against strategy rules
4. When conditions are met, a signal is generated and stored in the database
5. The system notifies users of new signals

### Order Execution Flow

1. Decision Engine identifies a trading opportunity and creates a signal
2. Order Manager receives the signal and validates it against wallet balances
3. If valid, Order Manager creates an order record in the database
4. Order Manager prepares and signs the Ethereum transaction
5. Order Manager submits the transaction to the Ethereum network
6. Order Manager monitors transaction confirmation status
7. When confirmed, Portfolio Manager creates a position record

### Position Tracking Flow

1. Portfolio Manager continuously updates open position values based on current DEX prices
2. It calculates profit/loss in real-time
3. Position details are stored in the database
4. Users can view position performance through logs or API queries

### Automated Position Closing

1. Portfolio Manager periodically checks all open positions
2. For each position, it evaluates:
   - Stop-loss conditions: Close if price drops below threshold
   - Take-profit conditions: Close if price rises above threshold
   - Time-based conditions: Close if position age exceeds limit
3. When conditions are met, Portfolio Manager instructs Order Manager to create a closing transaction
4. Order Manager executes the transaction and updates the position status
5. System accounts for gas costs in profit/loss calculations

### Manual Intervention Mechanisms

1. The system exposes an API for manual control
2. Users can:
   - Manually close any open position
   - Attempt to speed up pending transactions (via gas price increases)
   - Override automated decisions
   - Create manual transactions outside of signal-based execution
3. Manual actions take precedence over automated processes

### Wallet Integration Process

1. Users connect their Ethereum wallet via private key or keystore file
2. The system securely stores wallet access information
3. Portfolio Manager scans and updates token balances
4. Funds become available for trading

## Database Design

The MVP requires extending the existing database schema to support Ethereum position management:

### Signals Table
- Signal ID, token pair, signal type (buy/sell)
- Signal strength, price, timestamp
- Processed flag, metadata
- Gas price recommendation

### Positions Table
- Position ID, token pair, direction (long/short)
- Entry price, quantity, current price
- Status (open/closed), P&L calculations
- Entry/exit timestamps, associated wallet
- Gas costs for entry/exit

### Orders Table
- Order ID, Ethereum transaction hash
- DEX protocol used (Uniswap, SushiSwap, etc.)
- Token in/out, amounts, slippage parameters
- Transaction status, gas price, gas used
- Associated position and wallet

### Wallets Table
- Wallet ID, Ethereum address
- Encrypted private key or keystore reference
- Name, description
- Creation timestamp

## Key Design Considerations

1. **Fault Tolerance**: Each component has its own supervision tree for resilience
2. **Concurrency**: Leveraging Elixir's OTP for concurrent processing of blockchain data
3. **State Management**: Using GenServers for maintaining critical state
4. **Blockchain Integration**: Robust Ethereum Web3 interaction with error handling
5. **Security**: Proper encryption of private keys and secure transaction signing
6. **Gas Optimization**: Intelligent gas price strategies to minimize costs
7. **Testability**: Each component can be tested in isolation

## Success Criteria

The MVP will be considered successful when it demonstrates:

1. End-to-end trading flow from signal generation to position closing on Ethereum DEXs
2. Accurate tracking of wallet value and position performance
3. Reliable operation with appropriate error handling for blockchain interactions
4. Ability for users to manually intervene in the automated process
5. Functional wallet integration to fund trading accounts
