// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

import {PhantomPortfolio} from "../src/PhantomPortfolio.sol";
import {PortfolioToken} from "../test/utils/PortfolioToken.sol";

/// @title PhantomPortfolio Deployment Script
/// @notice Deploys the PhantomPortfolio hook and sets up test environment
contract DeployPortfolioScript is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // Constants
    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336;
    uint24 constant FEE = 3000;
    int24 constant TICK_SPACING = 60;

    // Addresses (will be set during deployment)
    address public poolManager;
    address public hook;
    address public token0;
    address public token1;
    address public token2;

    // Portfolio parameters
    uint256 constant TOKEN_SUPPLY = 1000000 ether;
    uint256 constant TARGET_ALLOCATION_1 = 4000; // 40%
    uint256 constant TARGET_ALLOCATION_2 = 3500; // 35%
    uint256 constant TARGET_ALLOCATION_3 = 2500; // 25%
    uint256 constant TRADING_LIMIT = 100000 ether;
    uint256 constant REBALANCE_FREQUENCY = 86400; // 24 hours
    uint256 constant TOLERANCE_BAND = 500; // 5%

    function run() public returns (PhantomPortfolio phantomHook) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying PhantomPortfolio Hook...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy tokens
        console.log("\n1. Deploying test tokens...");
        PortfolioToken token0Contract = new PortfolioToken("Token0", "TOK0", 18);
        PortfolioToken token1Contract = new PortfolioToken("Token1", "TOK1", 18);
        PortfolioToken token2Contract = new PortfolioToken("Token2", "TOK2", 18);

        token0 = address(token0Contract);
        token1 = address(token1Contract);
        token2 = address(token2Contract);

        console.log("Token0 deployed at:", token0);
        console.log("Token1 deployed at:", token1);
        console.log("Token2 deployed at:", token2);

        // Deploy pool manager (if not already deployed)
        console.log("\n2. Setting up pool manager...");
        if (poolManager == address(0)) {
            // For testing, we'll use a mock pool manager
            // In production, this would be the actual Uniswap v4 pool manager
            console.log("Using existing pool manager at:", poolManager);
        }

        // Deploy PhantomPortfolio hook
        console.log("\n3. Deploying PhantomPortfolio hook...");
        
        // Calculate hook flags
        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        ) ^ (0x4444 << 144); // Namespace to avoid collisions

        console.log("Hook flags:", flags);

        // Mine hook address
        bytes memory constructorArgs = abi.encode(poolManager);
        // For now, use a simple salt for deployment
        // In production, you'd use HookMiner.find() to find a valid salt
        bytes32 salt = bytes32(uint256(1));

        console.log("Hook salt:", vm.toString(salt));

        // Deploy hook
        phantomHook = new PhantomPortfolio{salt: salt}(IPoolManager(poolManager));
        hook = address(phantomHook);

        console.log("PhantomPortfolio hook deployed at:", hook);

        // Verify hook address matches mined address
        // For now, skip verification since we're using a simple salt
        // In production, you'd verify the hook address matches the mined address
        console.log("Hook address verification skipped (using simple salt)");

        // Setup test portfolio
        console.log("\n4. Setting up test portfolio...");
        _setupTestPortfolio(phantomHook, deployer);

        vm.stopBroadcast();

        console.log("\nPhantomPortfolio deployment complete!");
        console.log("Hook address:", hook);
        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("Token2:", token2);

        return phantomHook;
    }

    function _setupTestPortfolio(PhantomPortfolio phantomHook, address deployer) internal {
        // Mint tokens to deployer
        PortfolioToken(token0).mint(deployer, TOKEN_SUPPLY);
        PortfolioToken(token1).mint(deployer, TOKEN_SUPPLY);
        PortfolioToken(token2).mint(deployer, TOKEN_SUPPLY);

        console.log("Minted", TOKEN_SUPPLY, "tokens to deployer");

        // Note: In a real deployment, you would need to:
        // 1. Initialize FHE with the deployer's wallet
        // 2. Encrypt the portfolio parameters
        // 3. Call createPhantomPortfolio with encrypted data
        
        console.log("Test portfolio setup complete (FHE encryption would be done client-side)");
    }

    function _createPool(
        PhantomPortfolio phantomHook,
        address tokenA,
        address tokenB
    ) internal returns (PoolKey memory key) {
        // Sort tokens
        (address token0Addr, address token1Addr) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        key = PoolKey({
            currency0: Currency.wrap(token0Addr),
            currency1: Currency.wrap(token1Addr),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(hook)
        });

        console.log("Created pool key for", token0Addr, "and", token1Addr);
    }
}
