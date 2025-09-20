# PhantomPortfolio Makefile

.PHONY: build test test-unit test-integration test-fuzz test-security test-edge-cases test-coverage coverage clean deploy-testnet deploy-mainnet deploy-anvil

# Build the project
build:
	forge build --via-ir

# Run all tests
test:
	forge test --via-ir

# Run specific test categories
test-unit:
	forge test --match-path "test/unit/*" --via-ir

test-integration:
	forge test --match-path "test/integration/*" --via-ir

test-fuzz:
	forge test --match-path "test/fuzz/*" --via-ir

test-security:
	forge test --match-path "test/security/*" --via-ir

test-edge-cases:
	forge test --match-path "test/edge-cases/*" --via-ir

test-coverage:
	forge test --match-path "test/coverage/*" --via-ir

# Generate coverage report
coverage:
	forge coverage --ir-minimum --report summary

# Deploy to testnet
deploy-testnet:
	forge script script/DeployTestnet.s.sol --broadcast --rpc-url sepolia

# Deploy to mainnet
deploy-mainnet:
	forge script script/DeployMainnet.s.sol --broadcast --rpc-url mainnet

# Deploy to local anvil
deploy-anvil:
	forge script script/DeployAnvil.s.sol --broadcast --rpc-url anvil

# Clean build artifacts
clean:
	forge clean
	rm -rf out/
	rm -rf cache/

# Install dependencies
install:
	forge install
	npm install

# Format code
format:
	forge fmt

# Lint code
lint:
	forge fmt --check

# Run gas report
gas:
	forge test --gas-report --via-ir

# Run invariant tests
invariant:
	forge test --match-contract Invariant --via-ir

# Run fuzz tests with more runs
fuzz:
	forge test --fuzz-runs 10000 --via-ir

# Run specific test
test-specific:
	forge test --match-test $(TEST) --via-ir

# Run tests with verbose output
test-verbose:
	forge test --via-ir -vvv

# Run tests with gas reporting
test-gas:
	forge test --gas-report --via-ir

# Run tests with coverage
test-coverage-full:
	forge coverage --ir-minimum --report summary --report-file coverage.txt

# Run all tests and generate coverage
test-all:
	forge test --via-ir
	forge coverage --ir-minimum --report summary

# Help
help:
	@echo "Available commands:"
	@echo "  build              - Build the project"
	@echo "  test               - Run all tests"
	@echo "  test-unit          - Run unit tests"
	@echo "  test-integration   - Run integration tests"
	@echo "  test-fuzz          - Run fuzz tests"
	@echo "  test-security      - Run security tests"
	@echo "  test-edge-cases    - Run edge case tests"
	@echo "  test-coverage      - Run coverage tests"
	@echo "  coverage           - Generate coverage report"
	@echo "  deploy-testnet     - Deploy to testnet"
	@echo "  deploy-mainnet     - Deploy to mainnet"
	@echo "  deploy-anvil       - Deploy to local anvil"
	@echo "  clean              - Clean build artifacts"
	@echo "  install            - Install dependencies"
	@echo "  format             - Format code"
	@echo "  lint               - Lint code"
	@echo "  gas                - Run gas report"
	@echo "  invariant          - Run invariant tests"
	@echo "  fuzz               - Run fuzz tests with more runs"
	@echo "  test-specific      - Run specific test (TEST=testName)"
	@echo "  test-verbose       - Run tests with verbose output"
	@echo "  test-gas           - Run tests with gas reporting"
	@echo "  test-coverage-full - Run tests with full coverage report"
	@echo "  test-all           - Run all tests and generate coverage"
	@echo "  help               - Show this help message"
