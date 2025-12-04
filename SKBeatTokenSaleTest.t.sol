// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SKBEATTokenSale.sol";
import "../src/SKBEATToken.sol";
import "../src/MockUSDCToken.sol";


contract SKBEATTokenSaleTest is Test {
    SKBEATTokenSale public tokenSale;
    SKBEATToken public skbeatToken;
    MockUSDCToken public usdcToken;
    
    address public owner;
    address public buyer1;
    address public buyer2;
    
    uint256 constant INITIAL_SKBEAT_SUPPLY = 1_000_000 * 10**8; // 1M SKBEAT
    uint256 constant SALE_ALLOCATION = 500_000 * 10**8; // 500K for sale
    uint256 constant INITIAL_USDC_BALANCE = 100_000 * 10**6; // 100K USDC per buyer
    
    event TokensPurchased(address indexed buyer, uint256 usdcPaid, uint256 skbeatReceived);
    event PriceUpdated(uint256 newSkbeatPerUsdc);
    event UsdcWithdrawn(address indexed owner, uint256 amount);
    event EmergencyWithdraw(address indexed token, uint256 amount);
    
    function setUp() public {
        owner = address(this);
        buyer1 = makeAddr("buyer1");
        buyer2 = makeAddr("buyer2");
        
        // Deploy tokens
        skbeatToken = new SKBEATToken("SKBEAT Token", "SKBEAT");
        usdcToken = new MockUSDCToken();
        
        // Deploy token sale
        tokenSale = new SKBEATTokenSale(
            address(skbeatToken),
            address(usdcToken)
        );
        
        // Setup: mint and distribute tokens
        skbeatToken.mint(INITIAL_SKBEAT_SUPPLY);
        skbeatToken.transfer(address(tokenSale), SALE_ALLOCATION);
        
        usdcToken.mint(buyer1, INITIAL_USDC_BALANCE);
        usdcToken.mint(buyer2, INITIAL_USDC_BALANCE);
    }
    
    // ==================== DEPLOYMENT TESTS ====================
    
    function test_Deployment_CorrectAddresses() public view {
        assertEq(address(tokenSale.SKBEAT_TOKEN()), address(skbeatToken));
        assertEq(address(tokenSale.USDC_TOKEN()), address(usdcToken));
        assertEq(tokenSale.OWNER(), owner);
    }
    
    function test_Deployment_CorrectConstants() public view {
        assertEq(tokenSale.SKBEAT_DECIMALS(), 8);
        assertEq(tokenSale.USDC_DECIMALS(), 6);
        assertEq(tokenSale.DECIMAL_MULTIPLIER(), 100);
        assertEq(tokenSale.MIN_PURCHASE(), 10**8);
    }
    
    function test_Deployment_DefaultPrice() public view {
        assertEq(tokenSale.skbeatPerUsdc(), 1); // 1 SKBEAT = 1 USDC
    }
    
    function test_Deployment_RevertInvalidSkbeatAddress() public {
        vm.expectRevert("Invalid skBEAT token");
        new SKBEATTokenSale(address(0), address(usdcToken));
    }
    
    function test_Deployment_RevertInvalidUsdcAddress() public {
        vm.expectRevert("Invalid USDC token");
        new SKBEATTokenSale(address(skbeatToken), address(0));
    }
    
    // ==================== BUY TOKENS TESTS (DEFAULT PRICE 1:1) ====================
    
    function test_BuyTokens_Success_1to1Price() public {
        uint256 skbeatAmount = 100 * 10**8; // 100 SKBEAT
        uint256 expectedUsdc = 100 * 10**6; // 100 USDC
        
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), expectedUsdc);
        
        vm.expectEmit(true, false, false, true);
        emit TokensPurchased(buyer1, expectedUsdc, skbeatAmount);
        
        tokenSale.buyTokens(skbeatAmount);
        vm.stopPrank();
        
        assertEq(skbeatToken.balanceOf(buyer1), skbeatAmount);
        assertEq(usdcToken.balanceOf(address(tokenSale)), expectedUsdc);
        assertEq(tokenSale.totalSkbeatSold(), skbeatAmount);
        assertEq(tokenSale.totalUsdcReceived(), expectedUsdc);
    }
    
    function test_BuyTokens_MinimumPurchase() public {
        uint256 minAmount = 10**8; // Exactly 1 SKBEAT (minimum)
        uint256 expectedUsdc = 1 * 10**6; // 1 USDC
        
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), expectedUsdc);
        tokenSale.buyTokens(minAmount);
        vm.stopPrank();
        
        assertEq(skbeatToken.balanceOf(buyer1), minAmount);
    }
    
    function test_BuyTokens_RevertBelowMinimum() public {
        uint256 tooSmall = 10**8 - 1; // Just below 1 SKBEAT
        
        vm.prank(buyer1);
        vm.expectRevert("Must purchase at least 1 SKBEAT");
        tokenSale.buyTokens(tooSmall);
    }
    
    function test_BuyTokens_RevertInsufficientContractBalance() public {
        uint256 tooMuch = SALE_ALLOCATION + 1;
        
        vm.prank(buyer1);
        vm.expectRevert("Insufficient skBEAT in contract");
        tokenSale.buyTokens(tooMuch);
    }
    
    function test_BuyTokens_RevertAmountTooSmall() public {
        // Set a very high price so calculation results in 0 USDC
        // For usdcRequired to be 0: skbeatAmount < (skbeatPerUsdc * 100)
        // With MIN_PURCHASE = 10^8, we need skbeatPerUsdc > 10^6
        tokenSale.setPrice(2_000_000); // 2 million SKBEAT = 1 USDC
        uint256 skbeatAmount = 10**8; // 1 SKBEAT (minimum purchase)
        // Calculation: 10^8 / (2,000,000 * 100) = 10^8 / 2*10^8 = 0.5 (rounds to 0)
        
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), 1 * 10**6); // Approve some amount
        vm.expectRevert("Amount too small to purchase");
        tokenSale.buyTokens(skbeatAmount);
        vm.stopPrank();
    }
    
    function test_BuyTokens_MultiplePurchasesSameBuyer() public {
        vm.startPrank(buyer1);
        
        // First purchase
        usdcToken.approve(address(tokenSale), 50 * 10**6);
        tokenSale.buyTokens(50 * 10**8);
        
        // Second purchase
        usdcToken.approve(address(tokenSale), 30 * 10**6);
        tokenSale.buyTokens(30 * 10**8);
        
        vm.stopPrank();
        
        assertEq(skbeatToken.balanceOf(buyer1), 80 * 10**8);
        assertEq(tokenSale.totalSkbeatSold(), 80 * 10**8);
    }
    
    function test_BuyTokens_MultipleBuyers() public {
        // Buyer1 purchases
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), 100 * 10**6);
        tokenSale.buyTokens(100 * 10**8);
        vm.stopPrank();
        
        // Buyer2 purchases
        vm.startPrank(buyer2);
        usdcToken.approve(address(tokenSale), 50 * 10**6);
        tokenSale.buyTokens(50 * 10**8);
        vm.stopPrank();
        
        assertEq(skbeatToken.balanceOf(buyer1), 100 * 10**8);
        assertEq(skbeatToken.balanceOf(buyer2), 50 * 10**8);
        assertEq(tokenSale.totalSkbeatSold(), 150 * 10**8);
        assertEq(tokenSale.totalUsdcReceived(), 150 * 10**6);
    }
    
    // ==================== CUSTOM PRICE TESTS ====================
    
    function test_BuyTokens_CustomPrice_6SkbeatPer1Usdc() public {
        tokenSale.setPrice(6); // 6 SKBEAT = 1 USDC
        
        uint256 skbeatAmount = 600 * 10**8; // 600 SKBEAT
        uint256 expectedUsdc = 100 * 10**6; // 100 USDC
        
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), expectedUsdc);
        tokenSale.buyTokens(skbeatAmount);
        vm.stopPrank();
        
        assertEq(skbeatToken.balanceOf(buyer1), skbeatAmount);
        assertEq(usdcToken.balanceOf(address(tokenSale)), expectedUsdc);
    }
    
    function test_BuyTokens_CustomPrice_5SkbeatPer1Usdc() public {
        tokenSale.setPrice(5); // 5 SKBEAT = 1 USDC
        
        uint256 skbeatAmount = 500 * 10**8; // 500 SKBEAT
        uint256 expectedUsdc = 100 * 10**6; // 100 USDC
        
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), expectedUsdc);
        tokenSale.buyTokens(skbeatAmount);
        vm.stopPrank();
        
        assertEq(skbeatToken.balanceOf(buyer1), skbeatAmount);
    }
    
    function test_BuyTokens_CustomPrice_200SkbeatPer1Usdc() public {
        tokenSale.setPrice(200); // 200 SKBEAT = 1 USDC (cheaper SKBEAT)
        
        uint256 skbeatAmount = 2000 * 10**8; // 2000 SKBEAT
        uint256 expectedUsdc = 10 * 10**6; // 10 USDC
        
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), expectedUsdc);
        tokenSale.buyTokens(skbeatAmount);
        vm.stopPrank();
        
        assertEq(skbeatToken.balanceOf(buyer1), skbeatAmount);
    }
    
    // ==================== SET PRICE TESTS ====================
    
    function test_SetPrice_Success() public {
        vm.expectEmit(false, false, false, true);
        emit PriceUpdated(10);
        
        tokenSale.setPrice(10);
        
        assertEq(tokenSale.skbeatPerUsdc(), 10);
    }
    
    function test_SetPrice_RevertNonOwner() public {
        vm.prank(buyer1);
        vm.expectRevert("Caller is not the owner");
        tokenSale.setPrice(5);
    }
    
    // ==================== CALCULATE USDC REQUIRED TESTS ====================
    
    function test_CalculateUsdcRequired_DefaultPrice() public view {
        assertEq(tokenSale.calculateUsdcRequired(100 * 10**8), 100 * 10**6);
        assertEq(tokenSale.calculateUsdcRequired(1 * 10**8), 1 * 10**6);
        assertEq(tokenSale.calculateUsdcRequired(1000 * 10**8), 1000 * 10**6);
    }
    
    function test_CalculateUsdcRequired_CustomPrice() public {
        tokenSale.setPrice(6);
        
        assertEq(tokenSale.calculateUsdcRequired(600 * 10**8), 100 * 10**6);
        assertEq(tokenSale.calculateUsdcRequired(6 * 10**8), 1 * 10**6);
    }
    
    // ==================== GET AVAILABLE SKBEAT TESTS ====================
    
    function test_GetAvailableSkbeat_Initial() public view {
        assertEq(tokenSale.getAvailableSkbeat(), SALE_ALLOCATION);
    }
    
    function test_GetAvailableSkbeat_AfterPurchase() public {
        uint256 purchaseAmount = 1000 * 10**8;
        
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), 1000 * 10**6);
        tokenSale.buyTokens(purchaseAmount);
        vm.stopPrank();
        
        assertEq(tokenSale.getAvailableSkbeat(), SALE_ALLOCATION - purchaseAmount);
    }
    
    // ==================== PAUSE/UNPAUSE TESTS ====================
    
    function test_Pause_Success() public {
        tokenSale.pause();
        assertTrue(tokenSale.paused());
    }
    
    function test_Pause_RevertNonOwner() public {
        vm.prank(buyer1);
        vm.expectRevert("Caller is not the owner");
        tokenSale.pause();
    }
    
    function test_Unpause_Success() public {
        tokenSale.pause();
        tokenSale.unpause();
        assertFalse(tokenSale.paused());
    }
    
    function test_Unpause_RevertNonOwner() public {
        tokenSale.pause();
        
        vm.prank(buyer1);
        vm.expectRevert("Caller is not the owner");
        tokenSale.unpause();
    }
    
    function test_BuyTokens_RevertWhenPaused() public {
        tokenSale.pause();
        
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), 100 * 10**6);
        vm.expectRevert(); // EnforcedPause() custom error
        tokenSale.buyTokens(100 * 10**8);
        vm.stopPrank();
    }
    
    // ==================== WITHDRAW USDC TESTS ====================
    
    function test_WithdrawUsdc_Success() public {
        // First, buyer makes a purchase
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), 500 * 10**6);
        tokenSale.buyTokens(500 * 10**8);
        vm.stopPrank();
        
        uint256 contractBalance = usdcToken.balanceOf(address(tokenSale));
        uint256 ownerBalanceBefore = usdcToken.balanceOf(owner);
        
        vm.expectEmit(true, false, false, true);
        emit UsdcWithdrawn(owner, contractBalance);
        
        tokenSale.withdrawUsdc(contractBalance);
        
        assertEq(usdcToken.balanceOf(owner), ownerBalanceBefore + contractBalance);
        assertEq(usdcToken.balanceOf(address(tokenSale)), 0);
    }
    
    function test_WithdrawUsdc_PartialWithdrawal() public {
        // Setup: buyer makes purchase
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), 1000 * 10**6);
        tokenSale.buyTokens(1000 * 10**8);
        vm.stopPrank();
        
        uint256 withdrawAmount = 500 * 10**6;
        tokenSale.withdrawUsdc(withdrawAmount);
        
        assertEq(usdcToken.balanceOf(address(tokenSale)), 500 * 10**6);
    }
    
    function test_WithdrawUsdc_RevertZeroAmount() public {
        vm.expectRevert("Amount must be greater than 0");
        tokenSale.withdrawUsdc(0);
    }
    
    function test_WithdrawUsdc_RevertInsufficientBalance() public {
        vm.expectRevert("Insufficient USDC balance");
        tokenSale.withdrawUsdc(1000 * 10**6);
    }
    
    function test_WithdrawUsdc_RevertNonOwner() public {
        vm.prank(buyer1);
        vm.expectRevert("Caller is not the owner");
        tokenSale.withdrawUsdc(100 * 10**6);
    }
    
    // ==================== EMERGENCY WITHDRAW TESTS ====================
    
    function test_EmergencyWithdraw_Skbeat() public {
        uint256 withdrawAmount = 10000 * 10**8;
        uint256 ownerBalanceBefore = skbeatToken.balanceOf(owner);
        
        vm.expectEmit(true, false, false, true);
        emit EmergencyWithdraw(address(skbeatToken), withdrawAmount);
        
        tokenSale.emergencyWithdraw(address(skbeatToken), withdrawAmount);
        
        assertEq(skbeatToken.balanceOf(owner), ownerBalanceBefore + withdrawAmount);
    }
    
    function test_EmergencyWithdraw_Usdc() public {
        // Send USDC to contract
        vm.prank(buyer1);
        usdcToken.transfer(address(tokenSale), 1000 * 10**6);
        
        uint256 withdrawAmount = 500 * 10**6;
        uint256 ownerBalanceBefore = usdcToken.balanceOf(owner);
        
        tokenSale.emergencyWithdraw(address(usdcToken), withdrawAmount);
        
        assertEq(usdcToken.balanceOf(owner), ownerBalanceBefore + withdrawAmount);
    }
    
    function test_EmergencyWithdraw_RevertInvalidToken() public {
        vm.expectRevert("Invalid token");
        tokenSale.emergencyWithdraw(address(0), 1000);
    }
    
    function test_EmergencyWithdraw_RevertNonOwner() public {
        vm.prank(buyer1);
        vm.expectRevert("Caller is not the owner");
        tokenSale.emergencyWithdraw(address(skbeatToken), 1000 * 10**8);
    }
    
    // ==================== FUZZ TESTS ====================
    
    function testFuzz_BuyTokens_DefaultPrice(uint256 skbeatAmount) public {
        // Bound to reasonable range
        skbeatAmount = bound(skbeatAmount, 10**8, SALE_ALLOCATION);
        uint256 expectedUsdc = skbeatAmount / 100;
        
        // Ensure buyer has enough USDC
        if (expectedUsdc > INITIAL_USDC_BALANCE) {
            usdcToken.mint(buyer1, expectedUsdc - INITIAL_USDC_BALANCE + 1000 * 10**6);
        }
        
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), expectedUsdc);
        tokenSale.buyTokens(skbeatAmount);
        vm.stopPrank();
        
        assertEq(skbeatToken.balanceOf(buyer1), skbeatAmount);
    }
    
    function testFuzz_CalculateUsdcRequired(uint256 skbeatAmount) public view {
        skbeatAmount = bound(skbeatAmount, 0, type(uint128).max);
        uint256 expectedUsdc = skbeatAmount / 100;
        
        assertEq(tokenSale.calculateUsdcRequired(skbeatAmount), expectedUsdc);
    }
    
    function testFuzz_SetPrice(uint256 newPrice) public {
        newPrice = bound(newPrice, 1, 10000);
        
        tokenSale.setPrice(newPrice);
        assertEq(tokenSale.skbeatPerUsdc(), newPrice);
    }
    
    // ==================== INTEGRATION TESTS ====================
    
    function test_Integration_FullSaleCycle() public {
        // Multiple buyers purchase at default price
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), 5000 * 10**6);
        tokenSale.buyTokens(5000 * 10**8);
        vm.stopPrank();
        
        vm.startPrank(buyer2);
        usdcToken.approve(address(tokenSale), 3000 * 10**6);
        tokenSale.buyTokens(3000 * 10**8);
        vm.stopPrank();
        
        // Owner changes price
        tokenSale.setPrice(5); // 5 SKBEAT = 1 USDC
        
        // Buyer1 buys more at new price
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), 2000 * 10**6);
        tokenSale.buyTokens(10000 * 10**8); // 10000 SKBEAT for 2000 USDC
        vm.stopPrank();
        
        // Owner withdraws USDC
        uint256 contractUsdc = usdcToken.balanceOf(address(tokenSale));
        tokenSale.withdrawUsdc(contractUsdc);
        
        // Verify final state
        assertEq(skbeatToken.balanceOf(buyer1), 15000 * 10**8);
        assertEq(skbeatToken.balanceOf(buyer2), 3000 * 10**8);
        assertEq(tokenSale.totalSkbeatSold(), 18000 * 10**8);
        assertEq(usdcToken.balanceOf(address(tokenSale)), 0);
    }
    
    function test_Integration_EmergencyScenario() public {
        // Sale starts normally
        vm.startPrank(buyer1);
        usdcToken.approve(address(tokenSale), 1000 * 10**6);
        tokenSale.buyTokens(1000 * 10**8);
        vm.stopPrank();
        
        // Emergency: pause the sale
        tokenSale.pause();
        
        // Verify purchases are blocked
        vm.startPrank(buyer2);
        usdcToken.approve(address(tokenSale), 500 * 10**6);
        vm.expectRevert(); // EnforcedPause() custom error
        tokenSale.buyTokens(500 * 10**8);
        vm.stopPrank();
        
        // Owner withdraws remaining tokens
        uint256 remainingSkbeat = tokenSale.getAvailableSkbeat();
        tokenSale.emergencyWithdraw(address(skbeatToken), remainingSkbeat);
        
        assertEq(skbeatToken.balanceOf(address(tokenSale)), 0);
    }
}
