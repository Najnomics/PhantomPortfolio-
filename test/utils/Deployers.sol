// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {SwapRouterNoChecks} from "@uniswap/v4-core/src/test/SwapRouterNoChecks.sol";
import {PoolDonateTest} from "@uniswap/v4-core/src/test/PoolDonateTest.sol";
import {PoolTakeTest} from "@uniswap/v4-core/src/test/PoolTakeTest.sol";
import {PoolClaimsTest} from "@uniswap/v4-core/src/test/PoolClaimsTest.sol";
import {ActionsRouter} from "@uniswap/v4-core/src/test/ActionsRouter.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {PortfolioToken} from "../utils/PortfolioToken.sol";

/// @title Deployers
/// @notice Shared utilities for deploying v4 pool infrastructure and portfolio tokens
contract Deployers is Test {
    using CurrencyLibrary for Currency;

    uint160 public constant SQRT_PRICE_1_1 = Constants.SQRT_PRICE_1_1;
    uint160 public constant SQRT_PRICE_1_2 = Constants.SQRT_PRICE_1_2;
    uint160 public constant SQRT_PRICE_1_4 = Constants.SQRT_PRICE_1_4;
    uint160 public constant SQRT_PRICE_2_1 = Constants.SQRT_PRICE_2_1;
    uint160 public constant SQRT_PRICE_4_1 = Constants.SQRT_PRICE_4_1;

    IPoolManager public manager;
    PoolModifyLiquidityTest public modifyLiquidityRouter;
    PoolSwapTest public swapRouter;
    SwapRouterNoChecks public swapRouterNoChecks;
    PoolDonateTest public donateRouter;
    PoolTakeTest public takeRouter;
    PoolClaimsTest public claimsRouter;
    ActionsRouter public actionsRouter;

    function deployFreshManagerAndRouters() internal {
        manager = new PoolManager(address(this));

        // Deploy routers for testing
        modifyLiquidityRouter = new PoolModifyLiquidityTest(manager);
        swapRouter = new PoolSwapTest(manager);
        swapRouterNoChecks = new SwapRouterNoChecks(manager);
        donateRouter = new PoolDonateTest(manager);
        takeRouter = new PoolTakeTest(manager);
        claimsRouter = new PoolClaimsTest(manager);
        actionsRouter = new ActionsRouter(manager);
    }

    function createPool(IHooks hooks, uint24 fee, uint160 sqrtPriceX96, bytes memory initData)
        internal
        returns (PoolKey memory key, PoolId id)
    {
        PortfolioToken tokenA = new PortfolioToken("Token A", "TOKENA", 18);
        PortfolioToken tokenB = new PortfolioToken("Token B", "TOKENB", 18);

        // Ensure tokenA < tokenB for proper ordering
        if (address(tokenA) > address(tokenB)) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        key = PoolKey({
            currency0: Currency.wrap(address(tokenA)),
            currency1: Currency.wrap(address(tokenB)),
            fee: fee,
            tickSpacing: 60,
            hooks: hooks
        });

        id = key.toId();
        manager.initialize(key, sqrtPriceX96);
    }

    function createPoolWithLiquidity(IHooks hooks, uint24 fee, uint160 sqrtPriceX96, bytes memory initData)
        internal
        returns (PoolKey memory key, PoolId id)
    {
        (key, id) = createPool(hooks, fee, sqrtPriceX96, initData);

        // Add initial liquidity
        PortfolioToken token0 = PortfolioToken(Currency.unwrap(key.currency0));
        PortfolioToken token1 = PortfolioToken(Currency.unwrap(key.currency1));

        // Mint tokens for liquidity provision
        token0.mint(address(this), 1000000 ether);
        token1.mint(address(this), 1000000 ether);

        // Approve tokens for the modify liquidity router
        token0.approve(address(modifyLiquidityRouter), type(uint256).max);
        token1.approve(address(modifyLiquidityRouter), type(uint256).max);

        // Add liquidity
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -600,
            tickUpper: 600,
            liquidityDelta: 1000000,
            salt: bytes32(0)
        });

        modifyLiquidityRouter.modifyLiquidity(key, params, "");
    }
}
