# PhantomPortfolio Architecture

## Overview

PhantomPortfolio is a Uniswap v4 hook that enables confidential portfolio rebalancing using Fully Homomorphic Encryption (FHE) through the Fhenix Protocol.

## Core Components

### 1. PhantomPortfolio.sol
The main hook contract that implements the Uniswap v4 hook interface and manages encrypted portfolios.

**Key Features:**
- Encrypted portfolio storage
- FHE-based rebalancing logic
- Cross-pool coordination
- Access control and permissions

### 2. PortfolioLibrary.sol
Library containing FHE-based portfolio calculations and mathematical operations.

**Key Functions:**
- `calculateRebalanceNeeds()` - Determines if rebalancing is needed
- `calculateTradeSizes()` - Calculates optimal trade sizes
- `calculatePerformanceAttribution()` - Tracks performance metrics
- `optimizeExecutionSequence()` - Optimizes trade execution order

### 3. PortfolioFHEPermissions.sol
Centralized management of FHE permissions and access controls.

**Key Functions:**
- `grantPortfolioCreationPermissions()` - Grants portfolio creation access
- `grantRebalancingPermissions()` - Grants rebalancing access
- `grantStateUpdatePermissions()` - Grants state update access
- `grantCompliancePermissions()` - Grants compliance access

## Data Structures

### EncryptedPortfolio
```solidity
struct EncryptedPortfolio {
    mapping(address => euint128) targetAllocations;  // Target allocation percentages
    mapping(address => euint128) currentHoldings;    // Current holdings
    mapping(address => euint128) tradingLimits;      // Maximum trade sizes
    euint64 rebalanceFrequency;                      // Rebalancing frequency
    euint128 totalValue;                             // Total portfolio value
    euint32 toleranceBand;                           // Rebalancing threshold
    ebool autoRebalanceEnabled;                      // Auto-rebalancing flag
    euint64 lastRebalance;                          // Last rebalance timestamp
    bool isActive;                                   // Portfolio active status
    address[] tokens;                                // Supported tokens
    uint256 rebalanceFrequencySeconds;              // Rebalancing frequency in seconds
    uint256 lastRebalanceTime;                      // Last rebalance time
}
```

### EncryptedRebalanceOrder
```solidity
struct EncryptedRebalanceOrder {
    address tokenIn;                    // Input token
    address tokenOut;                   // Output token
    euint128 amountIn;                 // Trade amount (encrypted)
    euint128 minAmountOut;             // Minimum output (encrypted)
    euint64 executionWindow;           // Execution window (encrypted)
    euint32 priority;                  // Execution priority (encrypted)
    ebool isActive;                    // Order active status (encrypted)
}
```

## FHE Operations

The contract uses Fhenix's CoFHE library for encrypted operations:

- **Arithmetic**: `FHE.add()`, `FHE.sub()`, `FHE.mul()`, `FHE.div()`
- **Comparison**: `FHE.gt()`, `FHE.gte()`, `FHE.lt()`, `FHE.lte()`, `FHE.eq()`
- **Boolean**: `FHE.and()`, `FHE.or()`, `FHE.not()`
- **Selection**: `FHE.select()` for conditional operations
- **Type Conversion**: `FHE.asEuint128()`, `FHE.asEuint64()`, `FHE.asEuint32()`, `FHE.asEbool()`

## Security Model

### Access Control
- Only portfolio owners can create and manage their portfolios
- Only the pool manager can call hook functions
- FHE permissions are managed through the PortfolioFHEPermissions library

### Privacy Guarantees
- All portfolio data is encrypted using FHE
- Rebalancing logic operates on encrypted data
- No plaintext portfolio information is exposed

### Reentrancy Protection
- All state changes are performed before external calls
- Proper access control prevents unauthorized rebalancing

## Integration Points

### Uniswap v4
- Implements `BaseHook` interface
- Uses `beforeSwap` and `afterSwap` callbacks
- Integrates with `IPoolManager` for pool operations

### Fhenix Protocol
- Uses CoFHE library for encrypted operations
- Leverages Fhenix's FHE infrastructure
- Follows Fhenix best practices for permission management

## Testing Strategy

### Unit Tests
- Individual function testing
- FHE operation validation
- Access control verification

### Integration Tests
- End-to-end workflow testing
- Cross-component interaction testing
- Hook callback testing

### Fuzz Tests
- Random input testing
- Edge case discovery
- Stress testing

### Security Tests
- Access control testing
- Reentrancy protection testing
- Overflow/underflow testing

## Deployment

### Prerequisites
- Fhenix Protocol access
- Uniswap v4 deployment
- Proper environment configuration

### Steps
1. Deploy to Fhenix testnet
2. Configure pool manager address
3. Deploy hook contract
4. Initialize with test portfolios
5. Verify functionality

## Monitoring

### Key Metrics
- Portfolio creation count
- Rebalancing frequency
- Gas usage
- Error rates

### Logging
- Portfolio creation events
- Rebalancing events
- Error events
- Performance metrics
