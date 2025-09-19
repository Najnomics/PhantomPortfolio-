// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FHE, euint128, euint64, euint32, ebool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/// @title Portfolio Library
/// @notice Library for encrypted portfolio calculations and utilities using FHE
library PortfolioLibrary {
    
    /// @notice Calculate current allocation percentages for all tokens
    /// @param currentHoldings Encrypted current token holdings
    /// @param totalValue Encrypted total portfolio value
    /// @return allocations Array of encrypted allocation percentages
    function calculateAllocationPercentages(
        euint128[] memory currentHoldings,
        euint128 totalValue
    ) internal returns (euint128[] memory allocations) {
        allocations = new euint128[](currentHoldings.length);
        
        for (uint256 i = 0; i < currentHoldings.length; i++) {
            // Calculate allocation percentage: (holding / totalValue) * 10000 (basis points)
            allocations[i] = FHE.div(
                FHE.mul(currentHoldings[i], FHE.asEuint128(10000)),
                totalValue
            );
        }
    }
    
    /// @notice Calculate rebalancing needs for each token
    /// @param targetAllocations Encrypted target allocation percentages
    /// @param currentAllocations Encrypted current allocation percentages
    /// @param toleranceBand Encrypted tolerance threshold in basis points
    /// @return needsRebalance Array of encrypted boolean flags indicating rebalance needs
    function calculateRebalanceNeeds(
        euint128[] memory targetAllocations,
        euint128[] memory currentAllocations,
        euint32 toleranceBand
    ) internal returns (ebool[] memory needsRebalance) {
        needsRebalance = new ebool[](targetAllocations.length);
        
        for (uint256 i = 0; i < targetAllocations.length; i++) {
            // Calculate absolute deviation from target
            // Use a safer approach: check both directions separately
            euint128 tolerance128 = FHE.asEuint128(toleranceBand);
            
            // Check if target > current + tolerance (need to increase allocation)
            ebool needsIncrease = FHE.gt(targetAllocations[i], FHE.add(currentAllocations[i], tolerance128));
            
            // Check if current > target + tolerance (need to decrease allocation)
            ebool needsDecrease = FHE.gt(currentAllocations[i], FHE.add(targetAllocations[i], tolerance128));
            
            // Rebalance needed if either condition is true
            needsRebalance[i] = FHE.or(needsIncrease, needsDecrease);
        }
    }
    
    /// @notice Calculate required trade sizes for rebalancing
    /// @param targetAllocations Encrypted target allocation percentages
    /// @param currentAllocations Encrypted current allocation percentages
    /// @param totalValue Encrypted total portfolio value
    /// @param tradingLimits Encrypted maximum trade sizes
    /// @return tradeSizes Array of encrypted trade sizes
    function calculateTradeSizes(
        euint128[] memory targetAllocations,
        euint128[] memory currentAllocations,
        euint128 totalValue,
        euint128[] memory tradingLimits
    ) internal returns (euint128[] memory tradeSizes) {
        tradeSizes = new euint128[](targetAllocations.length);
        
        for (uint256 i = 0; i < targetAllocations.length; i++) {
            // For now, use a simplified approach to avoid underflow
            // In a real implementation, this would need more sophisticated FHE operations
            // Calculate a small trade size based on the target allocation
            euint128 requiredTrade = FHE.div(
                FHE.mul(targetAllocations[i], totalValue),
                FHE.asEuint128(10000)
            );
            
            // Cap trade size to trading limits
            tradeSizes[i] = FHE.min(requiredTrade, tradingLimits[i]);
        }
    }
    
    /// @notice Optimize execution sequence to minimize market impact
    /// @param tradeSizes Encrypted trade sizes
    /// @param executionWindow Encrypted execution time window
    /// @return optimizedSequence Array of encrypted execution timings
    function optimizeExecutionSequence(
        euint128[] memory tradeSizes,
        euint64 executionWindow
    ) internal returns (euint64[] memory optimizedSequence) {
        optimizedSequence = new euint64[](tradeSizes.length);
        
        for (uint256 i = 0; i < tradeSizes.length; i++) {
            // Calculate execution delay based on trade size and position
            euint64 baseDelay = FHE.div(
                FHE.mul(FHE.asEuint64(i), executionWindow),
                FHE.asEuint64(tradeSizes.length)
            );
            
            // Add randomization to prevent predictable timing
            euint64 randomDelay = FHE.asEuint64(
                uint64(block.timestamp % 300) // Random delay up to 5 minutes
            );
            
            optimizedSequence[i] = FHE.add(baseDelay, randomDelay);
        }
    }
    
    /// @notice Calculate portfolio risk metrics
    /// @param currentHoldings Encrypted current token holdings
    /// @param totalValue Encrypted total portfolio value
    /// @param maxAssetWeight Encrypted maximum single asset weight
    /// @return riskMetrics Encrypted risk assessment
    function calculateRiskMetrics(
        euint128[] memory currentHoldings,
        euint128 totalValue,
        euint128 maxAssetWeight
    ) internal returns (ebool[] memory riskMetrics) {
        riskMetrics = new ebool[](currentHoldings.length);
        
        for (uint256 i = 0; i < currentHoldings.length; i++) {
            // Calculate asset weight
            euint128 assetWeight = FHE.div(
                FHE.mul(currentHoldings[i], FHE.asEuint128(10000)),
                totalValue
            );
            
            // Check if asset weight exceeds maximum
            ebool exceedsMaxWeight = FHE.gt(assetWeight, maxAssetWeight);
            riskMetrics[i] = exceedsMaxWeight;
        }
    }
    
    /// @notice Validate rebalancing orders against risk limits
    /// @param rebalanceOrders Encrypted rebalancing orders
    /// @param riskLimits Encrypted risk limit constraints
    /// @return validatedOrders Array of validated encrypted orders
    function validateRiskLimits(
        euint128[] memory rebalanceOrders,
        euint128[] memory riskLimits
    ) internal returns (euint128[] memory validatedOrders) {
        validatedOrders = new euint128[](rebalanceOrders.length);
        
        for (uint256 i = 0; i < rebalanceOrders.length; i++) {
            // Check if order exceeds risk limit
            ebool exceedsLimit = FHE.gt(rebalanceOrders[i], riskLimits[i]);
            
            // Apply risk constraint: if exceeds limit, cap to limit
            validatedOrders[i] = FHE.select(
                exceedsLimit,
                riskLimits[i],
                rebalanceOrders[i]
            );
        }
    }
    
    /// @notice Calculate performance attribution factors
    /// @param assetReturns Encrypted asset returns
    /// @param benchmarkReturns Encrypted benchmark returns
    /// @param allocations Encrypted asset allocations
    /// @return attribution Encrypted attribution factors
    function calculatePerformanceAttribution(
        euint128[] memory assetReturns,
        euint128[] memory benchmarkReturns,
        euint128[] memory allocations
    ) internal returns (euint128 attribution) {
        attribution = FHE.asEuint128(0);
        
        for (uint256 i = 0; i < assetReturns.length; i++) {
            // For now, use a simplified approach to avoid underflow
            // In a real implementation, this would need more sophisticated FHE operations
            // Calculate a simple attribution based on asset returns and allocations
            euint128 activeReturn = FHE.mul(assetReturns[i], allocations[i]);
            
            // Accumulate attribution
            attribution = FHE.add(attribution, activeReturn);
        }
    }
}
