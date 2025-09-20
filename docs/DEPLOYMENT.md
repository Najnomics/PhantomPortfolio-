# Deployment Guide

## Overview

This guide covers deploying PhantomPortfolio to various networks including testnet, mainnet, and local development environments.

## Prerequisites

### Required Software
- Node.js 18+
- Foundry (forge)
- Git

### Required Accounts
- Fhenix Protocol account
- Ethereum wallet with testnet/mainnet ETH
- API keys for RPC providers

## Environment Setup

### 1. Clone Repository
```bash
git clone https://github.com/your-org/phantom-portfolio-hook
cd phantom-portfolio-hook
```

### 2. Install Dependencies
```bash
# Install Node.js dependencies
npm install

# Install Foundry dependencies
forge install
```

### 3. Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

### 4. Build Project
```bash
# Build with FHE support
forge build --via-ir

# Or use make command
make build
```

## Network-Specific Deployment

### Testnet Deployment (Sepolia)

#### 1. Configure Environment
```bash
# Set testnet RPC URL
export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"

# Set private key
export PRIVATE_KEY="your_private_key"

# Set pool manager address (get from Uniswap v4 deployment)
export POOL_MANAGER_ADDRESS="0x..."
```

#### 2. Deploy Contract
```bash
# Deploy using Foundry
forge script script/DeployTestnet.s.sol --broadcast --rpc-url sepolia

# Or use make command
make deploy-testnet
```

#### 3. Verify Deployment
```bash
# Verify contract on Etherscan
forge verify-contract --chain-id 11155111 --num-of-optimizations 200 --watch --constructor-args $(cast abi-encode "constructor(address)" $POOL_MANAGER_ADDRESS) --etherscan-api-key $ETHERSCAN_API_KEY $CONTRACT_ADDRESS src/PhantomPortfolio.sol:PhantomPortfolio
```

### Mainnet Deployment

#### 1. Configure Environment
```bash
# Set mainnet RPC URL
export MAINNET_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY"

# Set private key
export PRIVATE_KEY="your_private_key"

# Set pool manager address
export POOL_MANAGER_ADDRESS="0x..."
```

#### 2. Deploy Contract
```bash
# Deploy using Foundry
forge script script/DeployMainnet.s.sol --broadcast --rpc-url mainnet

# Or use make command
make deploy-mainnet
```

#### 3. Verify Deployment
```bash
# Verify contract on Etherscan
forge verify-contract --chain-id 1 --num-of-optimizations 200 --watch --constructor-args $(cast abi-encode "constructor(address)" $POOL_MANAGER_ADDRESS) --etherscan-api-key $ETHERSCAN_API_KEY $CONTRACT_ADDRESS src/PhantomPortfolio.sol:PhantomPortfolio
```

### Local Development (Anvil)

#### 1. Start Local Node
```bash
# Start Anvil
anvil

# Or in background
anvil &
```

#### 2. Deploy Contract
```bash
# Deploy using Foundry
forge script script/DeployAnvil.s.sol --broadcast --rpc-url anvil

# Or use make command
make deploy-anvil
```

## Post-Deployment Setup

### 1. Initialize Hook
```solidity
// Initialize the hook with pool manager
hook.initialize(poolManager);
```

### 2. Create Test Portfolio
```solidity
// Create a test portfolio
address[] memory tokens = [token0, token1, token2];
InEuint128[] memory allocations = [createInEuint128(4000, owner), createInEuint128(3500, owner), createInEuint128(2500, owner)];
InEuint128[] memory limits = [createInEuint128(100e18, owner), createInEuint128(100e18, owner), createInEuint128(100e18, owner)];

hook.setupPhantomPortfolio(
    tokens,
    allocations,
    limits,
    createInEuint64(86400, owner), // 24 hours
    createInEuint32(500, owner)    // 5% tolerance
);
```

### 3. Test Functionality
```bash
# Run tests to verify deployment
forge test --via-ir

# Run specific tests
forge test --match-test test_CreatePhantomPortfolio --via-ir
```

## Configuration

### Pool Manager Address
The pool manager address is required for deployment. Get this from:
- Uniswap v4 deployment documentation
- Uniswap v4 testnet/mainnet deployments
- Local Uniswap v4 deployment

### Fhenix Configuration
Ensure your deployment is compatible with Fhenix Protocol:
- Use Fhenix-compatible RPC endpoints
- Configure proper FHE parameters
- Test with Fhenix testnet first

## Monitoring

### Contract Verification
- Verify contract on Etherscan
- Check deployment transaction
- Verify constructor parameters

### Functionality Testing
- Test portfolio creation
- Test rebalancing functionality
- Test access controls
- Test FHE operations

### Gas Optimization
- Monitor gas usage
- Optimize if necessary
- Update gas estimates

## Troubleshooting

### Common Issues

#### 1. Compilation Errors
```bash
# Ensure FHE dependencies are installed
forge install @fhenixprotocol/cofhe-contracts
forge install @fhenixprotocol/cofhe-mock-contracts

# Rebuild with FHE support
forge build --via-ir
```

#### 2. Deployment Failures
```bash
# Check RPC URL
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $RPC_URL

# Check private key
cast wallet address --private-key $PRIVATE_KEY

# Check gas prices
cast gas-price --rpc-url $RPC_URL
```

#### 3. Verification Failures
```bash
# Check constructor arguments
cast abi-encode "constructor(address)" $POOL_MANAGER_ADDRESS

# Verify manually on Etherscan
# Check contract source code
# Verify compiler version
# Check optimization settings
```

## Security Considerations

### Private Key Management
- Use hardware wallets for mainnet
- Never commit private keys
- Use environment variables
- Consider multi-sig for production

### Contract Verification
- Always verify contracts
- Check constructor parameters
- Verify source code
- Test thoroughly before mainnet

### Access Control
- Verify access controls
- Test permission systems
- Monitor for unauthorized access
- Implement proper logging

## Production Checklist

- [ ] Contract compiled successfully
- [ ] All tests passing
- [ ] Environment variables configured
- [ ] Private key secured
- [ ] RPC endpoints working
- [ ] Gas prices acceptable
- [ ] Contract deployed successfully
- [ ] Contract verified on Etherscan
- [ ] Initial functionality tested
- [ ] Access controls verified
- [ ] Monitoring setup
- [ ] Documentation updated
