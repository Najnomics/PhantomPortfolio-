// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {PortfolioFHEPermissions} from "../src/lib/PortfolioFHEPermissions.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";
import {FHE, euint128, euint64, euint32} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

contract PortfolioFHEPermissionsTest is Test, CoFheTest {
    
    address public testContract;
    address public testOwner;
    
    function setUp() public {
        testContract = address(0x1234567890123456789012345678901234567890);
        testOwner = address(0x1);
    }
    
    function test_GrantPortfolioCreationPermissions() public {
        // Create test data
        euint128[] memory targetAllocations = new euint128[](2);
        targetAllocations[0] = FHE.asEuint128(4000);
        targetAllocations[1] = FHE.asEuint128(6000);
        
        euint128[] memory tradingLimits = new euint128[](2);
        tradingLimits[0] = FHE.asEuint128(100000);
        tradingLimits[1] = FHE.asEuint128(100000);
        
        euint64 rebalanceFrequency = FHE.asEuint64(86400);
        euint32 toleranceBand = FHE.asEuint32(500);
        
        address[] memory tokens = new address[](2);
        tokens[0] = address(0x1);
        tokens[1] = address(0x2);
        
        PortfolioFHEPermissions.grantPortfolioCreationPermissions(
            targetAllocations,
            tradingLimits,
            rebalanceFrequency,
            toleranceBand,
            testOwner,
            tokens,
            testContract
        );
    }
    
    function test_GrantRebalancingPermissions() public {
        // Create test data
        euint128[] memory currentHoldings = new euint128[](2);
        currentHoldings[0] = FHE.asEuint128(50000);
        currentHoldings[1] = FHE.asEuint128(30000);
        
        euint128[] memory rebalanceOrders = new euint128[](2);
        rebalanceOrders[0] = FHE.asEuint128(10000);
        rebalanceOrders[1] = FHE.asEuint128(5000);
        
        euint128 totalValue = FHE.asEuint128(80000);
        
        address[] memory tokens = new address[](2);
        tokens[0] = address(0x1);
        tokens[1] = address(0x2);
        
        PortfolioFHEPermissions.grantRebalancingPermissions(
            currentHoldings,
            rebalanceOrders,
            totalValue,
            testOwner,
            tokens,
            testContract
        );
    }
    
    function test_GrantStateUpdatePermissions() public {
        // Create test data
        euint128[] memory newHoldings = new euint128[](2);
        newHoldings[0] = FHE.asEuint128(60000);
        newHoldings[1] = FHE.asEuint128(40000);
        
        euint128 newTotalValue = FHE.asEuint128(100000);
        euint64 lastRebalanceTime = FHE.asEuint64(block.timestamp);
        
        PortfolioFHEPermissions.grantStateUpdatePermissions(
            newHoldings,
            newTotalValue,
            lastRebalanceTime,
            testOwner,
            testContract
        );
    }
    
    function test_GrantCompliancePermissions() public {
        // Create test data
        euint128[] memory auditData = new euint128[](3);
        auditData[0] = FHE.asEuint128(1000);
        auditData[1] = FHE.asEuint128(2000);
        auditData[2] = FHE.asEuint128(3000);
        
        euint128 complianceKey = FHE.asEuint128(12345);
        address auditor = address(0x999);
        
        PortfolioFHEPermissions.grantCompliancePermissions(
            auditData,
            complianceKey,
            auditor,
            testContract
        );
    }
    
    function test_GrantCrossPoolPermissions() public {
        // Create test data
        euint128[] memory poolAmounts = new euint128[](3);
        poolAmounts[0] = FHE.asEuint128(10000);
        poolAmounts[1] = FHE.asEuint128(15000);
        poolAmounts[2] = FHE.asEuint128(20000);
        
        address[] memory poolKeys = new address[](3);
        poolKeys[0] = address(0xA1);
        poolKeys[1] = address(0xA2);
        poolKeys[2] = address(0xA3);
        
        PortfolioFHEPermissions.grantCrossPoolPermissions(
            poolAmounts,
            poolKeys,
            testContract
        );
    }
    
    function test_AllPermissionsTogether() public {
        // Create comprehensive test data for all permission types
        euint128[] memory targetAllocations = new euint128[](2);
        targetAllocations[0] = FHE.asEuint128(4000);
        targetAllocations[1] = FHE.asEuint128(6000);
        
        euint128[] memory tradingLimits = new euint128[](2);
        tradingLimits[0] = FHE.asEuint128(100000);
        tradingLimits[1] = FHE.asEuint128(100000);
        
        address[] memory tokens = new address[](2);
        tokens[0] = address(0x1);
        tokens[1] = address(0x2);
        
        // Grant all permissions to the same contract
        PortfolioFHEPermissions.grantPortfolioCreationPermissions(
            targetAllocations,
            tradingLimits,
            FHE.asEuint64(86400),
            FHE.asEuint32(500),
            testOwner,
            tokens,
            testContract
        );
        
        // Additional test data for other permissions
        euint128[] memory currentHoldings = new euint128[](2);
        currentHoldings[0] = FHE.asEuint128(50000);
        currentHoldings[1] = FHE.asEuint128(30000);
        
        euint128[] memory rebalanceOrders = new euint128[](2);
        rebalanceOrders[0] = FHE.asEuint128(10000);
        rebalanceOrders[1] = FHE.asEuint128(5000);
        
        PortfolioFHEPermissions.grantRebalancingPermissions(
            currentHoldings,
            rebalanceOrders,
            FHE.asEuint128(80000),
            testOwner,
            tokens,
            testContract
        );
    }
    
    function test_EdgeCases() public {
        // Test with edge case values
        euint128[] memory maxAllocations = new euint128[](1);
        maxAllocations[0] = FHE.asEuint128(type(uint128).max);
        
        euint128[] memory maxLimits = new euint128[](1);
        maxLimits[0] = FHE.asEuint128(type(uint128).max);
        
        address[] memory tokens = new address[](1);
        tokens[0] = address(0x1);
        
        PortfolioFHEPermissions.grantPortfolioCreationPermissions(
            maxAllocations,
            maxLimits,
            FHE.asEuint64(type(uint64).max),
            FHE.asEuint32(type(uint32).max),
            testOwner,
            tokens,
            testContract
        );
    }
    
    function test_MultipleContracts() public {
        // Simplified test for different contracts
        euint128[] memory allocations = new euint128[](1);
        allocations[0] = FHE.asEuint128(10000);
        
        euint128[] memory limits = new euint128[](1);
        limits[0] = FHE.asEuint128(50000);
        
        address[] memory tokens = new address[](1);
        tokens[0] = address(0x1);
        
        address contract1 = address(0x100);
        address contract2 = address(0x200);
        
        PortfolioFHEPermissions.grantPortfolioCreationPermissions(
            allocations,
            limits,
            FHE.asEuint64(86400),
            FHE.asEuint32(500),
            testOwner,
            tokens,
            contract1
        );
        
        PortfolioFHEPermissions.grantPortfolioCreationPermissions(
            allocations,
            limits,
            FHE.asEuint64(86400),
            FHE.asEuint32(500),
            testOwner,
            tokens,
            contract2
        );
    }
    
    function test_PermissionOrder() public {
        // Test basic permission granting works
        euint128[] memory allocations = new euint128[](1);
        allocations[0] = FHE.asEuint128(5000);
        
        euint128[] memory limits = new euint128[](1);
        limits[0] = FHE.asEuint128(25000);
        
        address[] memory tokens = new address[](1);
        tokens[0] = address(0x1);
        
        // Grant permissions multiple times (should not fail)
        PortfolioFHEPermissions.grantPortfolioCreationPermissions(
            allocations,
            limits,
            FHE.asEuint64(3600),
            FHE.asEuint32(100),
            testOwner,
            tokens,
            testContract
        );
        
        PortfolioFHEPermissions.grantPortfolioCreationPermissions(
            allocations,
            limits,
            FHE.asEuint64(3600),
            FHE.asEuint32(100),
            testOwner,
            tokens,
            testContract
        );
    }
    
    function test_GasOptimization() public {
        // Test that functions don't consume excessive gas  
        euint128[] memory allocations = new euint128[](2);
        allocations[0] = FHE.asEuint128(3000);
        allocations[1] = FHE.asEuint128(7000);
        
        euint128[] memory limits = new euint128[](2);
        limits[0] = FHE.asEuint128(50000);
        limits[1] = FHE.asEuint128(50000);
        
        address[] memory tokens = new address[](2);
        tokens[0] = address(0x1);
        tokens[1] = address(0x2);
        
        uint256 gasStart = gasleft();
        PortfolioFHEPermissions.grantPortfolioCreationPermissions(
            allocations,
            limits,
            FHE.asEuint64(86400),
            FHE.asEuint32(500),
            testOwner,
            tokens,
            testContract
        );
        uint256 gasUsed1 = gasStart - gasleft();
        
        // Should use reasonable gas amounts
        assertTrue(gasUsed1 < 1000000);
    }
}
