// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FHE, euint128, euint64, euint32, ebool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/// @title Portfolio FHE Permission Management Library
/// @notice Centralizes FHE.allow() calls for consistent access control in portfolio operations
/// @dev This library implements the critical "Define Access" step in Fhenix's 3-step CoFHE pattern
library PortfolioFHEPermissions {
    
    /// @notice Grant comprehensive permissions for portfolio creation
    /// @param targetAllocations Encrypted target allocation percentages
    /// @param tradingLimits Encrypted maximum trade sizes
    /// @param rebalanceFrequency Encrypted rebalancing frequency
    /// @param toleranceBand Encrypted tolerance threshold
    /// @param owner Address of the portfolio owner
    /// @param tokens Array of token addresses
    /// @param portfolioContract Address of the portfolio contract
    function grantPortfolioCreationPermissions(
        euint128[] memory targetAllocations,
        euint128[] memory tradingLimits,
        euint64 rebalanceFrequency,
        euint32 toleranceBand,
        address owner,
        address[] memory tokens,
        address portfolioContract
    ) internal {
        // Owner permissions - owner needs access to view portfolio parameters
        for (uint256 i = 0; i < targetAllocations.length; i++) {
            FHE.allow(targetAllocations[i], owner);
            FHE.allow(tradingLimits[i], owner);
        }
        FHE.allow(rebalanceFrequency, owner);
        FHE.allow(toleranceBand, owner);
        
        // Contract permissions - portfolio contract needs access for calculations
        for (uint256 i = 0; i < targetAllocations.length; i++) {
            FHE.allowThis(targetAllocations[i]);
            FHE.allowThis(tradingLimits[i]);
        }
        FHE.allowThis(rebalanceFrequency);
        FHE.allowThis(toleranceBand);
        
        // Token permissions - token contracts need access for operations
        for (uint256 i = 0; i < tokens.length; i++) {
            FHE.allow(tradingLimits[i], tokens[i]);
        }
    }
    
    /// @notice Grant permissions for rebalancing operations
    /// @param currentHoldings Encrypted current token holdings
    /// @param rebalanceOrders Encrypted rebalancing orders
    /// @param totalValue Encrypted total portfolio value
    /// @param owner Address of the portfolio owner
    /// @param tokens Array of token addresses
    /// @param portfolioContract Address of the portfolio contract
    function grantRebalancingPermissions(
        euint128[] memory currentHoldings,
        euint128[] memory rebalanceOrders,
        euint128 totalValue,
        address owner,
        address[] memory tokens,
        address portfolioContract
    ) internal {
        // Owner permissions - owner needs access to their holdings and orders
        for (uint256 i = 0; i < currentHoldings.length; i++) {
            FHE.allow(currentHoldings[i], owner);
            FHE.allow(rebalanceOrders[i], owner);
        }
        FHE.allow(totalValue, owner);
        
        // Contract permissions - portfolio contract needs access for calculations
        for (uint256 i = 0; i < currentHoldings.length; i++) {
            FHE.allowThis(currentHoldings[i]);
            FHE.allowThis(rebalanceOrders[i]);
        }
        FHE.allowThis(totalValue);
        
        // Token permissions - token contracts need access for transfers
        for (uint256 i = 0; i < tokens.length; i++) {
            FHE.allow(rebalanceOrders[i], tokens[i]);
        }
    }
    
    /// @notice Grant permissions for portfolio state updates
    /// @param newHoldings Encrypted new token holdings
    /// @param newTotalValue Encrypted new total portfolio value
    /// @param lastRebalanceTime Encrypted last rebalancing timestamp
    /// @param owner Address of the portfolio owner
    /// @param portfolioContract Address of the portfolio contract
    function grantStateUpdatePermissions(
        euint128[] memory newHoldings,
        euint128 newTotalValue,
        euint64 lastRebalanceTime,
        address owner,
        address portfolioContract
    ) internal {
        // Owner permissions - owner needs access to updated state
        for (uint256 i = 0; i < newHoldings.length; i++) {
            FHE.allow(newHoldings[i], owner);
        }
        FHE.allow(newTotalValue, owner);
        FHE.allow(lastRebalanceTime, owner);
        
        // Contract permissions - portfolio contract needs access for storage
        for (uint256 i = 0; i < newHoldings.length; i++) {
            FHE.allowThis(newHoldings[i]);
        }
        FHE.allowThis(newTotalValue);
        FHE.allowThis(lastRebalanceTime);
    }
    
    /// @notice Grant permissions for compliance and auditing
    /// @param auditData Encrypted audit trail data
    /// @param complianceKey Encrypted compliance verification key
    /// @param auditor Address of the compliance auditor
    /// @param portfolioContract Address of the portfolio contract
    function grantCompliancePermissions(
        euint128[] memory auditData,
        euint128 complianceKey,
        address auditor,
        address portfolioContract
    ) internal {
        // Auditor permissions - auditor needs access to compliance data
        for (uint256 i = 0; i < auditData.length; i++) {
            FHE.allow(auditData[i], auditor);
        }
        FHE.allow(complianceKey, auditor);
        
        // Contract permissions - portfolio contract needs access for storage
        for (uint256 i = 0; i < auditData.length; i++) {
            FHE.allowThis(auditData[i]);
        }
        FHE.allowThis(complianceKey);
    }
    
    /// @notice Grant permissions for cross-pool coordination
    /// @param poolAmounts Encrypted amounts for different pools
    /// @param poolKeys Array of pool keys
    /// @param portfolioContract Address of the portfolio contract
    function grantCrossPoolPermissions(
        euint128[] memory poolAmounts,
        address[] memory poolKeys,
        address portfolioContract
    ) internal {
        // Contract permissions - portfolio contract needs access for coordination
        for (uint256 i = 0; i < poolAmounts.length; i++) {
            FHE.allowThis(poolAmounts[i]);
        }
        
        // Pool permissions - pools need access to their amounts
        for (uint256 i = 0; i < poolKeys.length; i++) {
            FHE.allow(poolAmounts[i], poolKeys[i]);
        }
    }
}
