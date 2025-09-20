// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {PortfolioLibrary} from "../../src/lib/PortfolioLibrary.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";
import {FHE, euint128, euint64, euint32, ebool} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

contract PortfolioLibraryTest is Test, CoFheTest {
    
    function test_CalculateAllocationPercentages() public {
        // Test with normal holdings
        euint128[] memory currentHoldings = new euint128[](3);
        currentHoldings[0] = FHE.asEuint128(4000);
        currentHoldings[1] = FHE.asEuint128(3500);
        currentHoldings[2] = FHE.asEuint128(2500);
        
        euint128 totalValue = FHE.asEuint128(10000);
        
        euint128[] memory percentages = PortfolioLibrary.calculateAllocationPercentages(currentHoldings, totalValue);
        assertTrue(percentages.length == 3);
        
        // Test with zero holdings
        euint128[] memory zeroHoldings = new euint128[](2);
        zeroHoldings[0] = FHE.asEuint128(0);
        zeroHoldings[1] = FHE.asEuint128(0);
        
        euint128 zeroTotal = FHE.asEuint128(100);
        euint128[] memory zeroPercentages = PortfolioLibrary.calculateAllocationPercentages(zeroHoldings, zeroTotal);
        assertTrue(zeroPercentages.length == 2);
        
        // Test with single holding
        euint128[] memory singleHolding = new euint128[](1);
        singleHolding[0] = FHE.asEuint128(10000);
        
        euint128 singleTotal = FHE.asEuint128(10000);
        euint128[] memory singlePercentages = PortfolioLibrary.calculateAllocationPercentages(singleHolding, singleTotal);
        assertTrue(singlePercentages.length == 1);
    }
    
    function test_CalculateRebalanceNeeds() public {
        // Test with normal allocations
        euint128[] memory targetAllocations = new euint128[](3);
        targetAllocations[0] = FHE.asEuint128(4000);
        targetAllocations[1] = FHE.asEuint128(3500);
        targetAllocations[2] = FHE.asEuint128(2500);
        
        euint128[] memory currentAllocations = new euint128[](3);
        currentAllocations[0] = FHE.asEuint128(5000);
        currentAllocations[1] = FHE.asEuint128(3000);
        currentAllocations[2] = FHE.asEuint128(2000);
        
        euint32 threshold = FHE.asEuint32(500);
        
        ebool[] memory needsRebalance = PortfolioLibrary.calculateRebalanceNeeds(
            targetAllocations,
            currentAllocations,
            threshold
        );
        assertTrue(needsRebalance.length == 3);
        
        // Test with zero threshold
        ebool[] memory needsRebalanceZero = PortfolioLibrary.calculateRebalanceNeeds(
            targetAllocations,
            currentAllocations,
            FHE.asEuint32(0)
        );
        assertTrue(needsRebalanceZero.length == 3);
        
        // Test with high threshold
        ebool[] memory needsRebalanceHigh = PortfolioLibrary.calculateRebalanceNeeds(
            targetAllocations,
            currentAllocations,
            FHE.asEuint32(10000)
        );
        assertTrue(needsRebalanceHigh.length == 3);
    }
    
    function test_CalculateTradeSizes() public {
        euint128[] memory targetAllocations = new euint128[](3);
        targetAllocations[0] = FHE.asEuint128(4000);
        targetAllocations[1] = FHE.asEuint128(3500);
        targetAllocations[2] = FHE.asEuint128(2500);
        
        euint128[] memory currentAllocations = new euint128[](3);
        currentAllocations[0] = FHE.asEuint128(5000);
        currentAllocations[1] = FHE.asEuint128(3000);
        currentAllocations[2] = FHE.asEuint128(2000);
        
        euint128 totalValue = FHE.asEuint128(10000);
        
        euint128[] memory tradingLimits = new euint128[](3);
        tradingLimits[0] = FHE.asEuint128(1000);
        tradingLimits[1] = FHE.asEuint128(1000);
        tradingLimits[2] = FHE.asEuint128(1000);
        
        euint128[] memory tradeSizes = PortfolioLibrary.calculateTradeSizes(
            targetAllocations,
            currentAllocations,
            totalValue,
            tradingLimits
        );
        
        assertTrue(tradeSizes.length == 3);
        
        // Test with zero total value
        euint128[] memory zeroTradeSizes = PortfolioLibrary.calculateTradeSizes(
            targetAllocations,
            currentAllocations,
            FHE.asEuint128(0),
            tradingLimits
        );
        
        assertTrue(zeroTradeSizes.length == 3);
    }
    
    function test_OptimizeExecutionSequence() public {
        euint128[] memory tradeSizes = new euint128[](3);
        tradeSizes[0] = FHE.asEuint128(1000);
        tradeSizes[1] = FHE.asEuint128(2000);
        tradeSizes[2] = FHE.asEuint128(500);
        
        euint64 executionWindow = FHE.asEuint64(3600); // 1 hour
        
        euint64[] memory sequence = PortfolioLibrary.optimizeExecutionSequence(tradeSizes, executionWindow);
        assertTrue(sequence.length == 3);
        
        // Test with single trade
        euint128[] memory singleTrade = new euint128[](1);
        singleTrade[0] = FHE.asEuint128(1000);
        
        euint64 singleWindow = FHE.asEuint64(1800); // 30 minutes
        
        euint64[] memory singleSequence = PortfolioLibrary.optimizeExecutionSequence(singleTrade, singleWindow);
        assertTrue(singleSequence.length == 1);
        
        // Test with zero trades
        euint128[] memory zeroTrades = new euint128[](3);
        zeroTrades[0] = FHE.asEuint128(0);
        zeroTrades[1] = FHE.asEuint128(0);
        zeroTrades[2] = FHE.asEuint128(0);
        
        euint64 zeroWindow = FHE.asEuint64(0);
        euint64[] memory zeroSequence = PortfolioLibrary.optimizeExecutionSequence(zeroTrades, zeroWindow);
        assertTrue(zeroSequence.length == 3);
    }
    
    function test_CalculateRiskMetrics() public {
        euint128[] memory currentHoldings = new euint128[](3);
        currentHoldings[0] = FHE.asEuint128(100);
        currentHoldings[1] = FHE.asEuint128(200);
        currentHoldings[2] = FHE.asEuint128(150);
        
        euint128 totalValue = FHE.asEuint128(450);
        euint128 maxAssetWeight = FHE.asEuint128(5000); // 50%
        
        ebool[] memory riskMetrics = PortfolioLibrary.calculateRiskMetrics(currentHoldings, totalValue, maxAssetWeight);
        assertTrue(riskMetrics.length == 3);
        
        // Test with zero holdings
        euint128[] memory zeroHoldings = new euint128[](3);
        zeroHoldings[0] = FHE.asEuint128(0);
        zeroHoldings[1] = FHE.asEuint128(0);
        zeroHoldings[2] = FHE.asEuint128(0);
        
        ebool[] memory zeroRiskMetrics = PortfolioLibrary.calculateRiskMetrics(zeroHoldings, FHE.asEuint128(100), maxAssetWeight);
        assertTrue(zeroRiskMetrics.length == 3);
        
        // Test with single holding
        euint128[] memory singleHolding = new euint128[](1);
        singleHolding[0] = FHE.asEuint128(100);
        
        ebool[] memory singleRiskMetrics = PortfolioLibrary.calculateRiskMetrics(singleHolding, FHE.asEuint128(100), maxAssetWeight);
        assertTrue(singleRiskMetrics.length == 1);
    }
    
    function test_ValidateRiskLimits() public {
        euint128[] memory rebalanceOrders = new euint128[](3);
        rebalanceOrders[0] = FHE.asEuint128(500);
        rebalanceOrders[1] = FHE.asEuint128(300);
        rebalanceOrders[2] = FHE.asEuint128(700);
        
        euint128[] memory riskLimits = new euint128[](3);
        riskLimits[0] = FHE.asEuint128(1000);
        riskLimits[1] = FHE.asEuint128(1000);
        riskLimits[2] = FHE.asEuint128(1000);
        
        euint128[] memory validatedOrders = PortfolioLibrary.validateRiskLimits(rebalanceOrders, riskLimits);
        assertTrue(validatedOrders.length == 3);
        
        // Test with orders exceeding limits
        euint128[] memory highOrders = new euint128[](2);
        highOrders[0] = FHE.asEuint128(1500);
        highOrders[1] = FHE.asEuint128(2000);
        
        euint128[] memory lowLimits = new euint128[](2);
        lowLimits[0] = FHE.asEuint128(500);
        lowLimits[1] = FHE.asEuint128(600);
        
        euint128[] memory cappedOrders = PortfolioLibrary.validateRiskLimits(highOrders, lowLimits);
        assertTrue(cappedOrders.length == 2);
    }
    
    function test_CalculatePerformanceAttribution() public {
        euint128[] memory assetReturns = new euint128[](3);
        assetReturns[0] = FHE.asEuint128(50);
        assetReturns[1] = FHE.asEuint128(75);
        assetReturns[2] = FHE.asEuint128(25);
        
        euint128[] memory benchmarkReturns = new euint128[](3);
        benchmarkReturns[0] = FHE.asEuint128(40);
        benchmarkReturns[1] = FHE.asEuint128(60);
        benchmarkReturns[2] = FHE.asEuint128(30);
        
        euint128[] memory allocations = new euint128[](3);
        allocations[0] = FHE.asEuint128(4000);
        allocations[1] = FHE.asEuint128(3500);
        allocations[2] = FHE.asEuint128(2500);
        
        euint128 attribution = PortfolioLibrary.calculatePerformanceAttribution(assetReturns, benchmarkReturns, allocations);
        
        // Test with zero allocations
        euint128[] memory zeroAllocations = new euint128[](3);
        zeroAllocations[0] = FHE.asEuint128(0);
        zeroAllocations[1] = FHE.asEuint128(0);
        zeroAllocations[2] = FHE.asEuint128(0);
        
        euint128 zeroAttribution = PortfolioLibrary.calculatePerformanceAttribution(assetReturns, benchmarkReturns, zeroAllocations);
        
        // Test with zero returns
        euint128[] memory zeroAssetReturns = new euint128[](3);
        zeroAssetReturns[0] = FHE.asEuint128(0);
        zeroAssetReturns[1] = FHE.asEuint128(0);
        zeroAssetReturns[2] = FHE.asEuint128(0);
        
        euint128 zeroReturnsAttribution = PortfolioLibrary.calculatePerformanceAttribution(zeroAssetReturns, benchmarkReturns, allocations);
        
        // Test with single asset
        euint128[] memory singleAssetReturn = new euint128[](1);
        singleAssetReturn[0] = FHE.asEuint128(100);
        
        euint128[] memory singleBenchmark = new euint128[](1);
        singleBenchmark[0] = FHE.asEuint128(80);
        
        euint128[] memory singleAllocation = new euint128[](1);
        singleAllocation[0] = FHE.asEuint128(10000);
        
        euint128 singleAttribution = PortfolioLibrary.calculatePerformanceAttribution(singleAssetReturn, singleBenchmark, singleAllocation);
    }
    
    function test_EdgeCases() public {
        // Test with maximum values
        euint128[] memory maxAllocations = new euint128[](1);
        maxAllocations[0] = FHE.asEuint128(type(uint128).max);
        
        euint128 maxTotal = FHE.asEuint128(type(uint128).max);
        euint128[] memory maxPercentages = PortfolioLibrary.calculateAllocationPercentages(maxAllocations, maxTotal);
        assertTrue(maxPercentages.length == 1);
        
        // Test with minimum values
        euint128[] memory minAllocations = new euint128[](1);
        minAllocations[0] = FHE.asEuint128(1);
        
        euint128 minTotal = FHE.asEuint128(10);
        euint128[] memory minPercentages = PortfolioLibrary.calculateAllocationPercentages(minAllocations, minTotal);
        assertTrue(minPercentages.length == 1);
        
        // Test with mixed positive and zero values
        euint128[] memory mixedAllocations = new euint128[](3);
        mixedAllocations[0] = FHE.asEuint128(5000);
        mixedAllocations[1] = FHE.asEuint128(0);
        mixedAllocations[2] = FHE.asEuint128(5000);
        
        euint128 mixedTotal = FHE.asEuint128(10000);
        euint128[] memory mixedPercentages = PortfolioLibrary.calculateAllocationPercentages(mixedAllocations, mixedTotal);
        assertTrue(mixedPercentages.length == 3);
    }
    
    function test_ComplexScenarios() public {
        // Test with large number of assets
        uint256 assetCount = 10;
        euint128[] memory largeAllocations = new euint128[](assetCount);
        euint128[] memory largeCurrent = new euint128[](assetCount);
        address[] memory largeTokens = new address[](assetCount);
        
        for (uint i = 0; i < assetCount; i++) {
            largeAllocations[i] = FHE.asEuint128(1000);
            largeCurrent[i] = FHE.asEuint128(10000);
            largeTokens[i] = address(uint160(i + 1));
        }
        
        euint128 largeTotalValue = FHE.asEuint128(100000);
        euint128[] memory largePercentages = PortfolioLibrary.calculateAllocationPercentages(largeCurrent, largeTotalValue);
        assertTrue(largePercentages.length == assetCount);
        
        ebool[] memory largeNeedsRebalance = PortfolioLibrary.calculateRebalanceNeeds(
            largeAllocations,
            largeCurrent,
            FHE.asEuint32(500)
        );
        assertTrue(largeNeedsRebalance.length == assetCount);
        
        euint128[] memory largeLimits = new euint128[](assetCount);
        for (uint i = 0; i < assetCount; i++) {
            largeLimits[i] = FHE.asEuint128(50000);
        }
        
        euint128[] memory largeTradeSizes = PortfolioLibrary.calculateTradeSizes(
            largeAllocations,
            largeCurrent,
            largeTotalValue,
            largeLimits
        );
        assertTrue(largeTradeSizes.length == assetCount);
        
        euint64 largeWindow = FHE.asEuint64(7200); // 2 hours
        euint64[] memory largeSequence = PortfolioLibrary.optimizeExecutionSequence(largeTradeSizes, largeWindow);
        assertTrue(largeSequence.length == assetCount);
    }
}
