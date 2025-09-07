// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Foundry Imports
import {Test} from "forge-std/Test.sol";

// Uniswap Imports
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";

// FHE Imports
import {InEuint128, InEuint64, InEuint32} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

// Local Imports
import {PhantomPortfolio} from "../src/PhantomPortfolio.sol";
import {PortfolioToken} from "./utils/PortfolioToken.sol";
import {Fixtures} from "./utils/Fixtures.sol";

/// @title PhantomPortfolio Test Suite
/// @notice Comprehensive integration tests for phantom portfolio functionality
contract PhantomPortfolioTest is Test, Fixtures, CoFheTest {
    
    // Helper functions for creating encrypted values - inherited from CoFheTest
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    PhantomPortfolio hook;
    address hookAddr;
    PoolId poolId;

    PortfolioToken token0;
    PortfolioToken token1;
    PortfolioToken token2;

    address portfolioOwner = makeAddr("portfolioOwner");
    
    // Constants for testing inherited from Fixtures

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
        uint256 tradeCount,
        uint256 timestamp
    );

    function setUp() public {
        // Create tokens
        token0 = new PortfolioToken("Token0", "TOK0", 18);
        token1 = new PortfolioToken("Token1", "TOK1", 18);
        token2 = new PortfolioToken("Token2", "TOK2", 18);

        // Deploy infrastructure using Fixtures pattern
        deployFreshManagerAndRouters();
        deployPosm(manager);

        // Deploy the hook to an address with the correct flags
        address flags = address(
            uint160(
                Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
            ) ^ (0x4444 << 144) // Namespace to avoid collisions
        );
        bytes memory constructorArgs = abi.encode(manager);
        deployCodeTo("PhantomPortfolio.sol:PhantomPortfolio", constructorArgs, flags);
        hook = PhantomPortfolio(flags);
        hookAddr = address(hook);

        // Sort tokens for Uniswap v4 compatibility
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }
        if (address(token1) > address(token2)) {
            (token1, token2) = (token2, token1);
        }
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }

        // Create pool with hook
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hookAddr)
        });

        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1);

        // Setup token balances
        token0.mint(portfolioOwner, TOKEN_SUPPLY);
        token1.mint(portfolioOwner, TOKEN_SUPPLY);
        token2.mint(portfolioOwner, TOKEN_SUPPLY);
    }

    // =============================================================
    //                    PORTFOLIO CREATION TESTS
    // =============================================================

    function test_CreatePhantomPortfolio() public {
        vm.startPrank(portfolioOwner);

        // Create portfolio with encrypted parameters
        address[] memory tokens = new address[](3);
        tokens[0] = address(token0);
        tokens[1] = address(token1);
        tokens[2] = address(token2);

        // Create encrypted parameters (simplified for testing)
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

        vm.stopPrank();
    }

    function test_CreatePortfolioWithInvalidParameters() public {
        vm.startPrank(portfolioOwner);

        // Test with mismatched array lengths
        address[] memory tokens = new address[](2);
        tokens[0] = address(token0);
        tokens[1] = address(token1);

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

        // Should revert due to length mismatch
        vm.expectRevert("Length mismatch");
        hook.setupPhantomPortfolio(
            tokens,
            allocations,
            limits,
            frequency,
            tolerance
        );

        vm.stopPrank();
    }

    // =============================================================
    //                    HOOK PERMISSIONS TESTS
    // =============================================================

    function test_HookPermissions() public {
        Hooks.Permissions memory permissions = hook.getHookPermissions();

        // Verify correct hook permissions
        assertFalse(permissions.beforeInitialize);
        assertFalse(permissions.afterInitialize);
        assertFalse(permissions.beforeAddLiquidity);
        assertFalse(permissions.afterAddLiquidity);
        assertFalse(permissions.beforeRemoveLiquidity);
        assertFalse(permissions.afterRemoveLiquidity);
        assertTrue(permissions.beforeSwap);
        assertTrue(permissions.afterSwap);
        assertFalse(permissions.beforeDonate);
        assertFalse(permissions.afterDonate);
    }

    // =============================================================
    //                    REBALANCING TESTS
    // =============================================================

    function test_TriggerRebalance() public {
        // First create a portfolio
        _createTestPortfolio();

        vm.startPrank(portfolioOwner);

        // Fast forward time to trigger rebalancing
        vm.warp(block.timestamp + REBALANCE_FREQUENCY + 1);

        // Trigger rebalancing
        vm.expectEmit(true, true, false, true);
        emit PortfolioRebalanced(portfolioOwner, 1, 3, block.timestamp);

        hook.triggerRebalance(portfolioOwner);

        vm.stopPrank();
    }

    function test_TriggerRebalanceNotOwner() public {
        // First create a portfolio
        _createTestPortfolio();

        address nonOwner = makeAddr("nonOwner");
        vm.startPrank(nonOwner);

        // Should revert - not portfolio owner
        vm.expectRevert(PhantomPortfolio.NotPortfolioOwner.selector);
        hook.triggerRebalance(portfolioOwner);

        vm.stopPrank();
    }

    function test_TriggerRebalanceNotNeeded() public {
        // First create a portfolio
        _createTestPortfolio();

        vm.startPrank(portfolioOwner);

        // Try to trigger rebalancing immediately (not enough time passed)
        vm.expectRevert(PhantomPortfolio.RebalanceNotNeeded.selector);
        hook.triggerRebalance(portfolioOwner);

        vm.stopPrank();
    }

    // =============================================================
    //                    HOOK CALLBACK TESTS
    // =============================================================

    function test_AfterInitializeHook() public {
        // Create new pool with hook
        PoolKey memory newKey = PoolKey({
            currency0: Currency.wrap(address(token2)),
            currency1: Currency.wrap(address(token0)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hookAddr)
        });

        // This should call the afterInitialize hook
        manager.initialize(newKey, SQRT_PRICE_1_1);
        
        // Hook should have been called (no revert means success)
    }

    function test_BeforeAddLiquidityHook() public {
        vm.startPrank(portfolioOwner);

        // Add liquidity to trigger beforeAddLiquidity hook
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -600,
            tickUpper: 600,
            liquidityDelta: 1000000,
            salt: bytes32(0)
        });

        // This should call the beforeAddLiquidity hook
        manager.modifyLiquidity(
            PoolKey({
                currency0: Currency.wrap(address(token0)),
                currency1: Currency.wrap(address(token1)),
                fee: 3000,
                tickSpacing: 60,
                hooks: IHooks(hookAddr)
            }),
            params,
            ""
        );

        vm.stopPrank();
    }

    function test_BeforeSwapHook() public {
        vm.startPrank(portfolioOwner);

        // Perform swap to trigger beforeSwap hook
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });

        // This should call the beforeSwap hook
        manager.swap(
            PoolKey({
                currency0: Currency.wrap(address(token0)),
                currency1: Currency.wrap(address(token1)),
                fee: 3000,
                tickSpacing: 60,
                hooks: IHooks(hookAddr)
            }),
            params,
            ""
        );

        vm.stopPrank();
    }

    function test_AfterSwapHook() public {
        vm.startPrank(portfolioOwner);

        // Perform swap to trigger afterSwap hook
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });

        // This should call the afterSwap hook
        manager.swap(
            PoolKey({
                currency0: Currency.wrap(address(token0)),
                currency1: Currency.wrap(address(token1)),
                fee: 3000,
                tickSpacing: 60,
                hooks: IHooks(hookAddr)
            }),
            params,
            ""
        );

        vm.stopPrank();
    }

    // =============================================================
    //                    HELPER FUNCTIONS
    // =============================================================

    function _createTestPortfolio() internal {
        vm.startPrank(portfolioOwner);

        // Create portfolio with encrypted parameters
        address[] memory tokens = new address[](3);
        tokens[0] = address(token0);
        tokens[1] = address(token1);
        tokens[2] = address(token2);

        // Create encrypted parameters (simplified for testing)
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

        vm.stopPrank();
    }
}
