# PhantomPortfolio API Reference

## Overview

This document provides a comprehensive API reference for the PhantomPortfolio smart contract, including function signatures, parameters, return values, and usage examples.

## Contract Interface

### PhantomPortfolio

The main hook contract that implements confidential portfolio rebalancing using FHE.

## Core Functions

### setupPhantomPortfolio

Creates a new encrypted portfolio for the caller.

```solidity
function setupPhantomPortfolio(
    address[] calldata tokens,
    InEuint128[] calldata targetAllocations,
    InEuint128[] calldata tradingLimits,
    InEuint64 calldata rebalanceFrequency,
    InEuint32 calldata toleranceBand
) external
```

**Parameters:**
- `tokens`: Array of token addresses to include in the portfolio
- `targetAllocations`: Encrypted target allocation percentages (in basis points)
- `tradingLimits`: Encrypted maximum trade sizes for each token
- `rebalanceFrequency`: Encrypted rebalancing frequency in seconds
- `toleranceBand`: Encrypted tolerance band for rebalancing (in basis points)

**Requirements:**
- `tokens.length == targetAllocations.length`
- `tokens.length == tradingLimits.length`
- All arrays must have the same length
- Caller must not already have an active portfolio

**Events:**
- `PhantomPortfolioCreated(address indexed owner, uint256 tokenCount)`

### triggerRebalance

Triggers a rebalancing operation for the caller's portfolio.

```solidity
function triggerRebalance(address portfolioOwner) external onlyPortfolioOwner(portfolioOwner)
```

**Parameters:**
- `portfolioOwner`: Address of the portfolio owner

**Requirements:**
- Portfolio must be active
- Rebalancing must be needed (based on timing and tolerance)
- Caller must be the portfolio owner

**Events:**
- `PortfolioRebalanced(address indexed owner, uint256 indexed portfolioId, uint256 orderCount, uint256 timestamp)`

### getPortfolioCounter

Returns the total number of portfolios created.

```solidity
function getPortfolioCounter() external view returns (uint256)
```

**Returns:**
- `uint256`: Total number of portfolios created

### portfolios

Returns portfolio information for a given owner.

```solidity
function portfolios(address owner) external view returns (
    address[] memory tokens,
    uint256 rebalanceFrequencySeconds,
    uint256 lastRebalanceTime,
    bool isActive
)
```

**Parameters:**
- `owner`: Portfolio owner address

**Returns:**
- `tokens`: Array of token addresses in the portfolio
- `rebalanceFrequencySeconds`: Rebalancing frequency in seconds
- `lastRebalanceTime`: Timestamp of last rebalancing
- `isActive`: Whether the portfolio is active

## Hook Functions

### beforeSwap

Hook function called before a swap operation.

```solidity
function beforeSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    bytes calldata hookData
) external override returns (bytes4)
```

**Parameters:**
- `sender`: Address initiating the swap
- `key`: Pool key information
- `params`: Swap parameters
- `hookData`: Additional hook data

**Returns:**
- `bytes4`: Hook selector

### afterSwap

Hook function called after a swap operation.

```solidity
function afterSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) external override returns (bytes4)
```

**Parameters:**
- `sender`: Address initiating the swap
- `key`: Pool key information
- `params`: Swap parameters
- `delta`: Balance delta from the swap
- `hookData`: Additional hook data

**Returns:**
- `bytes4`: Hook selector

## Library Functions

### PortfolioLibrary

Library containing FHE-based portfolio calculations.

#### calculateRebalanceNeeds

Determines if a portfolio needs rebalancing.

```solidity
function calculateRebalanceNeeds(
    EncryptedPortfolio memory portfolio,
    address[] memory tokens,
    uint256[] memory currentPrices
) internal pure returns (EncryptedRebalanceOrder[] memory)
```

**Parameters:**
- `portfolio`: Encrypted portfolio data
- `tokens`: Array of token addresses
- `currentPrices`: Current token prices

**Returns:**
- `EncryptedRebalanceOrder[]`: Array of rebalancing orders

#### calculateTradeSizes

Calculates optimal trade sizes for rebalancing.

```solidity
function calculateTradeSizes(
    EncryptedRebalanceOrder[] memory orders,
    EncryptedPortfolio memory portfolio
) internal pure returns (EncryptedRebalanceOrder[] memory)
```

**Parameters:**
- `orders`: Array of rebalancing orders
- `portfolio`: Encrypted portfolio data

**Returns:**
- `EncryptedRebalanceOrder[]`: Optimized rebalancing orders

#### calculatePerformanceAttribution

Calculates performance attribution metrics.

```solidity
function calculatePerformanceAttribution(
    euint128[] memory assetReturns,
    euint128[] memory benchmarkReturns,
    euint128[] memory allocations
) internal pure returns (euint128)
```

**Parameters:**
- `assetReturns`: Encrypted asset returns
- `benchmarkReturns`: Encrypted benchmark returns
- `allocations`: Encrypted allocation percentages

**Returns:**
- `euint128`: Encrypted performance attribution

### PortfolioFHEPermissions

Library for managing FHE permissions.

#### grantPortfolioCreationPermissions

Grants permissions for portfolio creation.

```solidity
function grantPortfolioCreationPermissions(
    address portfolioContract,
    euint128[] memory targetAllocations,
    euint128[] memory tradingLimits
) internal
```

**Parameters:**
- `portfolioContract`: Portfolio contract address
- `targetAllocations`: Encrypted target allocations
- `tradingLimits`: Encrypted trading limits

#### grantRebalancingPermissions

Grants permissions for rebalancing operations.

```solidity
function grantRebalancingPermissions(
    address portfolioContract,
    euint128[] memory currentHoldings,
    euint128[] memory targetAllocations
) internal
```

**Parameters:**
- `portfolioContract`: Portfolio contract address
- `currentHoldings`: Encrypted current holdings
- `targetAllocations`: Encrypted target allocations

## Data Structures

### EncryptedPortfolio

```solidity
struct EncryptedPortfolio {
    mapping(address => euint128) targetAllocations;
    mapping(address => euint128) currentHoldings;
    mapping(address => euint128) tradingLimits;
    euint64 rebalanceFrequency;
    euint128 totalValue;
    euint32 toleranceBand;
    ebool autoRebalanceEnabled;
    euint64 lastRebalance;
    bool isActive;
    address[] tokens;
    uint256 rebalanceFrequencySeconds;
    uint256 lastRebalanceTime;
}
```

### EncryptedRebalanceOrder

```solidity
struct EncryptedRebalanceOrder {
    address tokenIn;
    address tokenOut;
    euint128 amountIn;
    euint128 minAmountOut;
    euint64 executionWindow;
    euint32 priority;
    ebool isActive;
}
```

## Events

### PhantomPortfolioCreated

Emitted when a new portfolio is created.

```solidity
event PhantomPortfolioCreated(
    address indexed owner,
    uint256 tokenCount
);
```

### PortfolioRebalanced

Emitted when a portfolio is rebalanced.

```solidity
event PortfolioRebalanced(
    address indexed owner,
    uint256 indexed portfolioId,
    uint256 orderCount,
    uint256 timestamp
);
```

## Error Handling

### Custom Errors

```solidity
error PortfolioAlreadyExists();
error PortfolioNotActive();
error RebalanceNotNeeded();
error NotPortfolioOwner();
error InvalidTokenCount();
error InvalidAllocation();
error InvalidTradingLimit();
error InvalidToleranceBand();
error InvalidRebalanceFrequency();
```

## Usage Examples

### Creating a Portfolio

```solidity
// Setup tokens
address[] memory tokens = new address[](3);
tokens[0] = address(token0);
tokens[1] = address(token1);
tokens[2] = address(token2);

// Setup encrypted allocations (40%, 35%, 25%)
InEuint128[] memory allocations = new InEuint128[](3);
allocations[0] = createInEuint128(4000, msg.sender); // 40%
allocations[1] = createInEuint128(3500, msg.sender); // 35%
allocations[2] = createInEuint128(2500, msg.sender); // 25%

// Setup trading limits
InEuint128[] memory limits = new InEuint128[](3);
limits[0] = createInEuint128(100e18, msg.sender);
limits[1] = createInEuint128(100e18, msg.sender);
limits[2] = createInEuint128(100e18, msg.sender);

// Create portfolio
hook.setupPhantomPortfolio(
    tokens,
    allocations,
    limits,
    createInEuint64(86400, msg.sender), // 24 hours
    createInEuint32(500, msg.sender)    // 5% tolerance
);
```

### Triggering Rebalancing

```solidity
// Trigger rebalancing
hook.triggerRebalance(msg.sender);
```

### Checking Portfolio Status

```solidity
// Get portfolio counter
uint256 totalPortfolios = hook.getPortfolioCounter();

// Get portfolio info
(address[] memory tokens, uint256 rebalanceFreq, uint256 lastRebalance, bool isActive) = hook.portfolios(msg.sender);
```

## Gas Estimates

### Function Gas Costs

- `setupPhantomPortfolio`: ~2,000,000 gas
- `triggerRebalance`: ~400,000 gas
- `beforeSwap`: ~2,000,000 gas
- `afterSwap`: ~2,000,000 gas

### Optimization Tips

1. Use smaller arrays when possible
2. Batch operations together
3. Consider gas costs for FHE operations
4. Optimize rebalancing frequency

## Security Considerations

1. **Access Control**: Only portfolio owners can manage their portfolios
2. **FHE Permissions**: Proper permission management for encrypted data
3. **Reentrancy**: All state changes before external calls
4. **Input Validation**: Comprehensive parameter validation
5. **Error Handling**: Proper error messages and handling
