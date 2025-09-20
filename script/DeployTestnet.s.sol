// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {PhantomPortfolio} from "../src/PhantomPortfolio.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

contract DeployTestnet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy PhantomPortfolio hook
        PhantomPortfolio phantomHook = new PhantomPortfolio(IPoolManager(poolManager));
        
        console.log("PhantomPortfolio deployed to:", address(phantomHook));
        console.log("Pool Manager:", address(poolManager));
        
        vm.stopBroadcast();
    }
}
