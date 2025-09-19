// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {PhantomPortfolio} from "../src/PhantomPortfolio.sol";
import {PortfolioToken} from "../test/utils/PortfolioToken.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {InEuint128, InEuint64, InEuint32} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

/// @title Portfolio Rebalancing Test
/// @notice Tests for portfolio rebalancing functionality
contract PortfolioRebalancingTest is Test, CoFheTest {
    
    // Test infrastructure
    IPoolManager manager;
    PhantomPortfolio hook;
    
    // Test tokens
    PortfolioToken token0;
    PortfolioToken token1;
    PortfolioToken token2;
    
    // Test addresses
    address portfolioOwner = makeAddr("portfolioOwner");
    
    // Test constants
    uint256 constant TOKEN_SUPPLY = 1000000 ether;
    uint256 constant TARGET_ALLOCATION_1 = 4000; // 40%
    uint256 constant TARGET_ALLOCATION_2 = 3500; // 35%
    uint256 constant TARGET_ALLOCATION_3 = 2500; // 25%
    uint256 constant TRADING_LIMIT = 100000 ether;
    uint256 constant REBALANCE_FREQUENCY = 86400; // 24 hours
    uint256 constant TOLERANCE_BAND = 500; // 5%

    // Events to test
    event PhantomPortfolioCreated(
        address indexed owner,
        uint256 indexed portfolioId,
        uint256 tokenCount,
        uint256 timestamp
    );
    
    event PortfolioRebalanced(
        address indexed owner,
        uint256 indexed portfolioId,
        uint256 rebalanceType,
        uint256 timestamp
    );

    function setUp() public {
        // Create tokens
        token0 = new PortfolioToken("Token0", "TOK0", 18);
        token1 = new PortfolioToken("Token1", "TOK1", 18);
        token2 = new PortfolioToken("Token2", "TOK2", 18);

        // Deploy a mock pool manager
        manager = IPoolManager(address(0x123));

        // Deploy the hook to an address with the correct flags
        address flags = address(
            uint160(
                Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
            ) ^ (0x4444 << 144) // Namespace to avoid collisions
        );
        bytes memory constructorArgs = abi.encode(manager);
        deployCodeTo("PhantomPortfolio.sol:PhantomPortfolio", constructorArgs, flags);
        hook = PhantomPortfolio(flags);

        // Setup token balances
        token0.mint(portfolioOwner, TOKEN_SUPPLY);
        token1.mint(portfolioOwner, TOKEN_SUPPLY);
        token2.mint(portfolioOwner, TOKEN_SUPPLY);
    }

    function test_CreateAndTriggerRebalance() public {
        vm.startPrank(portfolioOwner);

        // Create portfolio with encrypted parameters
        address[] memory tokens = new address[](3);
        tokens[0] = address(token0);
        tokens[1] = address(token1);
        tokens[2] = address(token2);

        // Create encrypted parameters
        InEuint128[] memory allocations = new InEuint128[](3);
        allocations[0] = createInEuint128(uint128(TARGET_ALLOCATION_1), portfolioOwner);
        allocations[1] = createInEuint128(uint128(TARGET_ALLOCATION_2), portfolioOwner);
        allocations[2] = createInEuint128(uint128(TARGET_ALLOCATION_3), portfolioOwner);

        InEuint128[] memory limits = new InEuint128[](3);
        limits[0] = createInEuint128(uint128(TRADING_LIMIT), portfolioOwner);
        limits[1] = createInEuint128(uint128(TRADING_LIMIT), portfolioOwner);
        limits[2] = createInEuint128(uint128(TRADING_LIMIT), portfolioOwner);

        InEuint64 memory frequency = createInEuint64(uint64(REBALANCE_FREQUENCY), portfolioOwner);
        InEuint32 memory tolerance = createInEuint32(uint32(TOLERANCE_BAND), portfolioOwner);

        // Create portfolio
        vm.expectEmit(true, true, false, true);
        emit PhantomPortfolioCreated(portfolioOwner, 1, 3, block.timestamp);

        hook.setupPhantomPortfolio(
            tokens,
            allocations,
            limits,
            frequency,
            tolerance
        );

        // Verify portfolio was created
        assertEq(hook.portfolioCounter(), 1);

        // Trigger rebalancing - expect the actual trade count from advanced logic
        vm.expectEmit(true, true, false, true);
        emit PortfolioRebalanced(portfolioOwner, 1, 1, block.timestamp);

        hook.triggerRebalance(portfolioOwner);

        vm.stopPrank();
    }

    function test_RebalanceAfterTimeElapsed() public {
        vm.startPrank(portfolioOwner);

        // Create portfolio first
        address[] memory tokens = new address[](3);
        tokens[0] = address(token0);
        tokens[1] = address(token1);
        tokens[2] = address(token2);

        InEuint128[] memory allocations = new InEuint128[](3);
        allocations[0] = createInEuint128(uint128(TARGET_ALLOCATION_1), portfolioOwner);
        allocations[1] = createInEuint128(uint128(TARGET_ALLOCATION_2), portfolioOwner);
        allocations[2] = createInEuint128(uint128(TARGET_ALLOCATION_3), portfolioOwner);

        InEuint128[] memory limits = new InEuint128[](3);
        limits[0] = createInEuint128(uint128(TRADING_LIMIT), portfolioOwner);
        limits[1] = createInEuint128(uint128(TRADING_LIMIT), portfolioOwner);
        limits[2] = createInEuint128(uint128(TRADING_LIMIT), portfolioOwner);

        InEuint64 memory frequency = createInEuint64(uint64(REBALANCE_FREQUENCY), portfolioOwner);
        InEuint32 memory tolerance = createInEuint32(uint32(TOLERANCE_BAND), portfolioOwner);

        hook.setupPhantomPortfolio(
            tokens,
            allocations,
            limits,
            frequency,
            tolerance
        );

        // Advance time beyond rebalance frequency
        vm.warp(block.timestamp + REBALANCE_FREQUENCY + 1);

        // Trigger rebalancing - should work now
        vm.expectEmit(true, true, false, true);
        emit PortfolioRebalanced(portfolioOwner, 1, 1, block.timestamp);

        hook.triggerRebalance(portfolioOwner);

        vm.stopPrank();
    }

    function test_MultiplePortfolioRebalancing() public {
        address owner1 = makeAddr("owner1");
        address owner2 = makeAddr("owner2");

        // Create two portfolios
        vm.startPrank(owner1);
        _createTestPortfolio(owner1);
        vm.stopPrank();

        vm.startPrank(owner2);
        _createTestPortfolio(owner2);
        vm.stopPrank();

        // Verify both portfolios exist
        assertEq(hook.portfolioCounter(), 2);

        // Trigger rebalancing for both
        vm.startPrank(owner1);
        hook.triggerRebalance(owner1);
        vm.stopPrank();

        vm.startPrank(owner2);
        hook.triggerRebalance(owner2);
        vm.stopPrank();
    }

    function _createTestPortfolio(address owner) internal {
        address[] memory tokens = new address[](3);
        tokens[0] = address(token0);
        tokens[1] = address(token1);
        tokens[2] = address(token2);

        InEuint128[] memory allocations = new InEuint128[](3);
        allocations[0] = createInEuint128(uint128(TARGET_ALLOCATION_1), owner);
        allocations[1] = createInEuint128(uint128(TARGET_ALLOCATION_2), owner);
        allocations[2] = createInEuint128(uint128(TARGET_ALLOCATION_3), owner);

        InEuint128[] memory limits = new InEuint128[](3);
        limits[0] = createInEuint128(uint128(TRADING_LIMIT), owner);
        limits[1] = createInEuint128(uint128(TRADING_LIMIT), owner);
        limits[2] = createInEuint128(uint128(TRADING_LIMIT), owner);

        InEuint64 memory frequency = createInEuint64(uint64(REBALANCE_FREQUENCY), owner);
        InEuint32 memory tolerance = createInEuint32(uint32(TOLERANCE_BAND), owner);

        hook.setupPhantomPortfolio(
            tokens,
            allocations,
            limits,
            frequency,
            tolerance
        );
    }
}
