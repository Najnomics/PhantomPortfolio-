// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {PhantomPortfolio} from "../src/PhantomPortfolio.sol";
import {PortfolioToken} from "./utils/PortfolioToken.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";
import {InEuint128, InEuint64, InEuint32} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";

contract CoverageTest is Test, CoFheTest {
    PhantomPortfolio public hook;
    PortfolioToken public token1;
    PortfolioToken public token2;
    PortfolioToken public token3;
    
    address public portfolioOwner;
    
    function setUp() public {
        // Deploy mock pool manager
        address poolManager = address(0x1234567890123456789012345678901234567890);
        
        // Deploy tokens
        token1 = new PortfolioToken("Token1", "TK1", 18);
        token2 = new PortfolioToken("Token2", "TK2", 18);
        token3 = new PortfolioToken("Token3", "TK3", 18);
        
        // Deploy hook using deployCodeTo method
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        ) ^ (0x4444 << 144); // Namespace to avoid collisions
        
        bytes memory constructorArgs = abi.encode(poolManager);
        deployCodeTo("PhantomPortfolio.sol:PhantomPortfolio", constructorArgs, address(flags));
        hook = PhantomPortfolio(address(flags));
        
        portfolioOwner = address(0x1);
        
        vm.label(address(hook), "PhantomPortfolio");
        vm.label(address(token1), "Token1");
        vm.label(address(token2), "Token2");
        vm.label(address(token3), "Token3");
    }
    
    // Test portfolio creation
    function test_CreatePhantomPortfolio() public {
        vm.startPrank(portfolioOwner);
        
        // Create encrypted inputs
        InEuint128[] memory targetAllocations = new InEuint128[](3);
        targetAllocations[0] = createInEuint128(4000, portfolioOwner);
        targetAllocations[1] = createInEuint128(3500, portfolioOwner);
        targetAllocations[2] = createInEuint128(2500, portfolioOwner);
        
        InEuint128[] memory tradingLimits = new InEuint128[](3);
        tradingLimits[0] = createInEuint128(10000, portfolioOwner);
        tradingLimits[1] = createInEuint128(8000, portfolioOwner);
        tradingLimits[2] = createInEuint128(6000, portfolioOwner);
        
        InEuint32 memory toleranceBand = createInEuint32(500, portfolioOwner);
        InEuint64 memory rebalanceFrequency = createInEuint64(3600, portfolioOwner);
        
        address[] memory tokens = new address[](3);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        tokens[2] = address(token3);
        
        // Create portfolio
        hook.setupPhantomPortfolio(
            tokens,
            targetAllocations,
            tradingLimits,
            rebalanceFrequency,
            toleranceBand
        );
        
        // Verify portfolio was created
        assertEq(hook.portfolioCounter(), 1);
        
        vm.stopPrank();
    }
    
    // Test rebalancing functionality
    function test_TriggerRebalance() public {
        vm.startPrank(portfolioOwner);
        
        // First create a portfolio
        _createTestPortfolio();
        
        // Trigger rebalancing (add small delay)
        vm.warp(block.timestamp + 1);
        hook.triggerRebalance(portfolioOwner);
        
        vm.stopPrank();
    }
    
    // Test portfolio counter
    function test_PortfolioCounter() public {
        assertEq(hook.portfolioCounter(), 0);
        
        vm.startPrank(portfolioOwner);
        _createTestPortfolio();
        assertEq(hook.portfolioCounter(), 1);
        
        vm.stopPrank();
    }
    
    // Test portfolio retrieval
    function test_GetPortfolio() public {
        vm.startPrank(portfolioOwner);
        
        // Create portfolio
        _createTestPortfolio();
        
        // Portfolio verification through counter
        assertEq(hook.portfolioCounter(), 1);
        
        vm.stopPrank();
    }
    
    // Test invalid parameters
    function test_InvalidParameters() public {
        vm.startPrank(portfolioOwner);
        
        // Test with mismatched array lengths
        InEuint128[] memory targetAllocations = new InEuint128[](2);
        targetAllocations[0] = createInEuint128(5000, portfolioOwner);
        targetAllocations[1] = createInEuint128(5000, portfolioOwner);
        
        InEuint128[] memory tradingLimits = new InEuint128[](3);
        tradingLimits[0] = createInEuint128(100000, portfolioOwner);
        tradingLimits[1] = createInEuint128(100000, portfolioOwner);
        tradingLimits[2] = createInEuint128(100000, portfolioOwner);
        
        InEuint32 memory toleranceBand = createInEuint32(500, portfolioOwner);
        InEuint64 memory rebalanceFrequency = createInEuint64(3600, portfolioOwner);
        
        address[] memory tokens = new address[](3);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        tokens[2] = address(token3);
        
        // Should revert due to array length mismatch
        vm.expectRevert();
        hook.setupPhantomPortfolio(
            tokens,
            targetAllocations,
            tradingLimits,
            rebalanceFrequency,
            toleranceBand
        );
        
        vm.stopPrank();
    }
    
    // Test rebalancing with non-existent portfolio
    function test_TriggerRebalanceNonExistentPortfolio() public {
        vm.startPrank(portfolioOwner);
        
        // Try to trigger rebalancing for non-existent portfolio
        vm.expectRevert();
        hook.triggerRebalance(portfolioOwner);
        
        vm.stopPrank();
    }
    
    // Test edge cases
    function test_EdgeCases() public {
        vm.startPrank(portfolioOwner);
        
        // Test with zero allocations
        InEuint128[] memory zeroAllocations = new InEuint128[](1);
        zeroAllocations[0] = createInEuint128(0, portfolioOwner);
        
        InEuint128[] memory zeroLimits = new InEuint128[](1);
        zeroLimits[0] = createInEuint128(0, portfolioOwner);
        
        InEuint32 memory zeroTolerance = createInEuint32(0, portfolioOwner);
        InEuint64 memory zeroFrequency = createInEuint64(0, portfolioOwner);
        
        address[] memory singleToken = new address[](1);
        singleToken[0] = address(token1);
        
        // This should work with zero values
        hook.setupPhantomPortfolio(
            singleToken,
            zeroAllocations,
            zeroLimits,
            zeroFrequency,
            zeroTolerance
        );
        
        vm.stopPrank();
    }
    
    // Test maximum values
    function test_MaximumValues() public {
        vm.startPrank(portfolioOwner);
        
        // Test with maximum uint128 values
        InEuint128[] memory maxAllocations = new InEuint128[](1);
        maxAllocations[0] = createInEuint128(type(uint128).max, portfolioOwner);
        
        InEuint128[] memory maxLimits = new InEuint128[](1);
        maxLimits[0] = createInEuint128(type(uint128).max, portfolioOwner);
        
        InEuint32 memory maxTolerance = createInEuint32(type(uint32).max, portfolioOwner);
        InEuint64 memory maxFrequency = createInEuint64(type(uint64).max, portfolioOwner);
        
        address[] memory tokens = new address[](1);
        tokens[0] = address(token1);
        
        hook.setupPhantomPortfolio(
            tokens,
            maxAllocations,
            maxLimits,
            maxFrequency,
            maxTolerance
        );
        
        vm.stopPrank();
    }
    
    // Test minimum values
    function test_MinimumValues() public {
        vm.startPrank(portfolioOwner);
        
        // Test with minimum values
        InEuint128[] memory minAllocations = new InEuint128[](1);
        minAllocations[0] = createInEuint128(1, portfolioOwner);
        
        InEuint128[] memory minLimits = new InEuint128[](1);
        minLimits[0] = createInEuint128(1, portfolioOwner);
        
        InEuint32 memory minTolerance = createInEuint32(1, portfolioOwner);
        InEuint64 memory minFrequency = createInEuint64(1, portfolioOwner);
        
        address[] memory tokens = new address[](1);
        tokens[0] = address(token1);
        
        hook.setupPhantomPortfolio(
            tokens,
            minAllocations,
            minLimits,
            minFrequency,
            minTolerance
        );
        
        vm.stopPrank();
    }
    
    // Test multiple portfolios for same owner (should work)
    function test_MultiplePortfoliosSameOwner() public {
        vm.startPrank(portfolioOwner);
        
        // Create first portfolio
        _createTestPortfolio();
        assertEq(hook.portfolioCounter(), 1);
        
        // Create second portfolio (should work as contract allows multiple portfolios)
        _createTestPortfolio();
        assertEq(hook.portfolioCounter(), 2);
        
        vm.stopPrank();
    }
    
    // Test rebalancing with different time scenarios
    function test_RebalancingTimeScenarios() public {
        vm.startPrank(portfolioOwner);
        
        // Create portfolio
        _createTestPortfolio();
        
        // Test immediate rebalancing (should work after small delay)
        vm.warp(block.timestamp + 1);
        hook.triggerRebalance(portfolioOwner);
        
        // Advance time by 1 second (less than frequency)
        vm.warp(block.timestamp + 1);
        vm.expectRevert(PhantomPortfolio.RebalanceNotNeeded.selector);
        hook.triggerRebalance(portfolioOwner);
        
        // Advance time by full frequency
        vm.warp(block.timestamp + 3600);
        hook.triggerRebalance(portfolioOwner);
        
        // Advance time by multiple frequencies
        vm.warp(block.timestamp + 3600 * 10);
        hook.triggerRebalance(portfolioOwner);
        
        vm.stopPrank();
    }
    
    // Helper function to create a test portfolio
    function _createTestPortfolio() internal {
        InEuint128[] memory targetAllocations = new InEuint128[](3);
        targetAllocations[0] = createInEuint128(4000, portfolioOwner);
        targetAllocations[1] = createInEuint128(3500, portfolioOwner);
        targetAllocations[2] = createInEuint128(2500, portfolioOwner);
        
        InEuint128[] memory tradingLimits = new InEuint128[](3);
        tradingLimits[0] = createInEuint128(100000, portfolioOwner);
        tradingLimits[1] = createInEuint128(100000, portfolioOwner);
        tradingLimits[2] = createInEuint128(100000, portfolioOwner);
        
        InEuint32 memory toleranceBand = createInEuint32(500, portfolioOwner);
        InEuint64 memory rebalanceFrequency = createInEuint64(3600, portfolioOwner);
        
        address[] memory tokens = new address[](3);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        tokens[2] = address(token3);
        
        hook.setupPhantomPortfolio(
            tokens,
            targetAllocations,
            tradingLimits,
            rebalanceFrequency,
            toleranceBand
        );
    }
}


