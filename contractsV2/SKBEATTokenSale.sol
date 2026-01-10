// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SKBEATTokenSale is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    // Contracts
    IERC20 public immutable USDC_TOKEN;
    IERC20 public immutable SKBEAT_TOKEN;
    
    // Token decimals
    uint8 public constant SKBEAT_DECIMALS = 8;
    uint8 public constant USDC_DECIMALS= 6;
    
    uint256 public constant DECIMAL_MULTIPLIER = 100;
    uint256 public constant MIN_PURCHASE = 1 * 10 ** SKBEAT_DECIMALS;
    
    // Price: how many SKBEAT tokens (not units) per 1 USDC token
    // Example: 1 means 1 SKBEAT = 1 USDC, 6 means 6 SKBEAT = 1 USDC
    uint256 public skbeatPerUsdc = 1; // Default: 1 SKBEAT = 1 USDC
    
    uint256 public totalSkbeatSold;
    uint256 public totalUsdcReceived;
    
    // Events
    event TokensPurchased(
        address indexed buyer,
        uint256 usdcPaid,
        uint256 skbeatReceived
    );
    event EmergencyWithdraw(address indexed token, uint256 amount);
    event UsdcWithdrawn(address indexed owner, uint256 amount);
    event PriceUpdated(uint256 newSkbeatPerUsdc);
    
    constructor(
        address _skbeatToken,
        address _usdcToken
    ) Ownable(msg.sender) {
        require(_usdcToken != address(0), "Invalid USDC token");
        require(_skbeatToken != address(0), "Invalid skBEAT token");
        
        SKBEAT_TOKEN = IERC20(_skbeatToken);
        USDC_TOKEN = IERC20(_usdcToken);
    }

    function buyTokens(uint256 skbeatAmount) external nonReentrant whenNotPaused {
        require(skbeatAmount >= MIN_PURCHASE, "Must purchase at least 1 SKBEAT");
        
        // Check contract has enough skBEAT
        uint256 contractBalance = SKBEAT_TOKEN.balanceOf(address(this));
        require(contractBalance >= skbeatAmount, "Insufficient skBEAT in contract");
        
        // Determine how much USDC the buyer must pay for the given SKBEAT amount.
        //
        // Price model:
        // - `skbeatPerUsdc` defines how many SKBEAT tokens equal 1 USDC.
        // - SKBEAT uses 8 decimals, USDC uses 6 decimals, so we scale by 100.
        //
        // Flow (Ceil Division):
        // 1. Combine the price and decimal scaling into a single denominator.
        // 2. Divide the SKBEAT amount by this denominator to get the USDC amount.
        // 3. Round UP to ensure the buyer never underpays due to integer division.

        uint256 denominator = skbeatPerUsdc * DECIMAL_MULTIPLIER;
        uint256 usdcRequired = (skbeatAmount + denominator - 1) / denominator;

        // Transfer USDC from buyer to contract (not directly to owner)
        USDC_TOKEN.safeTransferFrom(msg.sender, address(this), usdcRequired);
        
        // Transfer skBEAT to buyer
        SKBEAT_TOKEN.safeTransfer(msg.sender, skbeatAmount);
        
        // Update statistics
        totalSkbeatSold += skbeatAmount;
        totalUsdcReceived += usdcRequired;
        
        emit TokensPurchased(msg.sender, usdcRequired, skbeatAmount);
    }
    
    /**
     * @dev Calculate USDC required for a specific skBEAT amount
     * @param skbeatAmount Amount of skBEAT tokens (in 8 decimals)
     * @return usdcRequired Amount of USDC tokens required (in 6 decimals)
     */
    function calculateUsdcRequired(uint256 skbeatAmount) 
        external 
        view
        returns (uint256 usdcRequired) 
    {
        uint256 denominator = skbeatPerUsdc * DECIMAL_MULTIPLIER;
        usdcRequired = (skbeatAmount + denominator - 1) / denominator;
    }
    
    /**
     * @dev Get available skBEAT tokens in contract
     * @return available Amount of skBEAT tokens available for sale
     */
    function getAvailableSkbeat() external view returns (uint256) {
        return SKBEAT_TOKEN.balanceOf(address(this));
    }

    /**
     * @dev Set the price ratio for SKBEAT per USDC
     * @param _skbeatPerUsdc How many SKBEAT equal 1 USDC (accounting for decimal difference)
     *        Example: 6 means 6 SKBEAT = 1 USDC, 5 means 5 SKBEAT = 1 USDC
     *        Must be between 1 and 1000 for reasonable pricing
     */
    function setPrice(uint256 _skbeatPerUsdc) external onlyOwner {
        require(_skbeatPerUsdc > 0 && _skbeatPerUsdc <= 1000, "Invalid price");
        skbeatPerUsdc = _skbeatPerUsdc;
        emit PriceUpdated(_skbeatPerUsdc);
    }

    
    /**
     * @dev Pause the sale
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the sale
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    
    /**
     * @dev Withdraw collected USDC to owner
     */
    function withdrawUsdc(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        uint256 balance = USDC_TOKEN.balanceOf(address(this));
        require(amount <= balance, "Insufficient USDC balance");
        USDC_TOKEN.safeTransfer(owner(), amount);
        emit UsdcWithdrawn(owner(), amount);
    }

    /**
     * @dev Emergency withdraw tokens from contract
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token");
        IERC20(token).safeTransfer(owner(), amount);
        emit EmergencyWithdraw(token, amount);
    }   
}