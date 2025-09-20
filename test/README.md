# PhantomPortfolio Test Suite

This directory contains a comprehensive test suite for the PhantomPortfolio Uniswap V4 hook, organized into logical categories for better maintainability and clarity.

## Test Structure

### 📁 `unit/` - Unit Tests
Basic functionality tests for individual components:
- `BasicPhantomPortfolio.t.sol` - Basic contract compilation and structure tests
- `PhantomPortfolio.t.sol` - Core hook functionality tests
- `SimplePhantomPortfolio.t.sol` - Simplified portfolio creation tests
- `PortfolioLibraryTest.t.sol` - Library function tests
- `PortfolioFHEPermissionsTest.t.sol` - FHE permissions tests

### 📁 `integration/` - Integration Tests
End-to-end workflow and complex scenario tests:
- `IntegrationTests.t.sol` - Cross-component integration tests
- `ComprehensivePhantomPortfolio.t.sol` - Comprehensive portfolio lifecycle tests

### 📁 `fuzz/` - Fuzz Tests
Random input testing and edge case discovery:
- `PhantomPortfolioFuzz.t.sol` - Basic fuzz testing
- `ComprehensiveFuzzTests.t.sol` - Advanced fuzz testing with multiple scenarios

### 📁 `security/` - Security Tests
Access control, reentrancy, and security vulnerability tests:
- `PhantomPortfolioSecurity.t.sol` - Security and vulnerability tests

### 📁 `edge-cases/` - Edge Case Tests
Boundary conditions and extreme value tests:
- `EdgeCaseTests.t.sol` - Edge case and boundary condition tests

### 📁 `coverage/` - Coverage Tests
Comprehensive coverage and performance testing:
- `CoverageTest.t.sol` - Basic coverage tests
- `SimpleCoverageTest.t.sol` - Simplified coverage tests
- `PortfolioRebalancing.t.sol` - Rebalancing-specific tests

## Running Tests

### Run All Tests
```bash
forge test
```

### Run Tests by Category
```bash
# Unit tests
forge test --match-path "test/unit/*"

# Integration tests
forge test --match-path "test/integration/*"

# Fuzz tests
forge test --match-path "test/fuzz/*"

# Security tests
forge test --match-path "test/security/*"

# Edge case tests
forge test --match-path "test/edge-cases/*"

# Coverage tests
forge test --match-path "test/coverage/*"
```

### Run Specific Test Files
```bash
# Run a specific test file
forge test --match-contract PhantomPortfolioTest

# Run with verbose output
forge test --match-contract PhantomPortfolioTest -vv

# Run with very verbose output
forge test --match-contract PhantomPortfolioTest -vvv
```

### Run Fuzz Tests
```bash
# Run fuzz tests with specific parameters
forge test --match-path "test/fuzz/*" --fuzz-runs 1000

# Run fuzz tests with gas reporting
forge test --match-path "test/fuzz/*" --gas-report
```

### Generate Coverage Report
```bash
# Generate coverage report
forge coverage --ir-minimum

# Generate coverage report with specific format
forge coverage --ir-minimum --report summary
```

## Test Statistics

- **Total Tests**: 146+ tests
- **Test Categories**: 6 categories
- **Coverage**: Comprehensive coverage across all smart contract components
- **Test Types**: Unit, Integration, Fuzz, Security, Edge Cases, Coverage

## Test Categories Breakdown

### Unit Tests (5 files)
- Basic functionality verification
- Individual component testing
- Contract compilation and deployment
- Library function validation

### Integration Tests (2 files)
- End-to-end workflow testing
- Cross-component interaction
- Complex scenario validation
- Portfolio lifecycle management

### Fuzz Tests (2 files)
- Random input testing
- Edge case discovery
- Property-based testing
- Stress testing with random data

### Security Tests (1 file)
- Access control validation
- Reentrancy protection
- Overflow/underflow protection
- Permission system testing

### Edge Case Tests (1 file)
- Boundary condition testing
- Extreme value handling
- Error condition validation
- Limit testing

### Coverage Tests (3 files)
- Comprehensive code coverage
- Performance testing
- Gas optimization validation
- Rebalancing functionality

## Best Practices

1. **Test Organization**: Tests are organized by functionality and complexity
2. **Naming Convention**: Test files follow the pattern `ComponentName.t.sol`
3. **Test Categories**: Each test file belongs to a specific category
4. **Coverage**: Aim for 100% test coverage across all components
5. **Documentation**: Each test file includes comprehensive documentation

## Contributing

When adding new tests:
1. Choose the appropriate category folder
2. Follow the existing naming conventions
3. Include comprehensive test coverage
4. Add proper documentation
5. Ensure tests are deterministic and reliable

## Test Dependencies

- **Foundry**: Testing framework
- **CoFheTest**: FHE testing utilities
- **Uniswap V4**: Core Uniswap V4 contracts
- **OpenZeppelin**: Security and utility contracts
