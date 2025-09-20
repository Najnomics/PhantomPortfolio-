// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {PhantomPortfolio} from "../src/PhantomPortfolio.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

contract DeployAnvil is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("TEST_PRIVATE_KEY");
        
        // Use a mock pool manager for local testing
        address poolManager = address(0x1234567890123456789012345678901234567890);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy PhantomPortfolio hook
        PhantomPortfolio phantomHook = new PhantomPortfolio(IPoolManager(poolManager));
        
        console.log("PhantomPortfolio deployed to:", address(phantomHook));
        console.log("Pool Manager:", address(poolManager));
        
        vm.stopBroadcast();
    }
}
