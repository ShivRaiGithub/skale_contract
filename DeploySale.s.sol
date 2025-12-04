// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SKBEATToken.sol";
import "../src/SKBEATTokenSale.sol";
import "../src/MockUSDCToken.sol";

/**
 * @title DeploySaleScript
 * @author SKBEAT Team
 * @notice Script to set up and launch SKBEAT token sale
 * @dev Deploys TokenSale contract, configures pricing, and prepares for sales
 * 
 * Usage:
 * forge script script/DeploySale.s.sol:DeploySaleScript --rpc-url <RPC_URL> --broadcast --verify
 * 
 * Prerequisites:
 * - SKBEAT token must already be deployed
 * - USDC token must be deployed (or use MockUSDC for testing)
 * - Deployer must be the owner of SKBEAT token
 * 
 * This script will:
 * 1. Mint SKBEAT tokens to owner (if needed)
 * 2. Deploy SKBEATTokenSale contract
 * 3. Set price to 6 SKBEAT = 1 USDC
 * 4. Transfer SKBEAT tokens to sale contract
 * 5. Unpause the contract (ready for sales)
 */
contract DeploySaleScript is Script {
    
    // ============ Configuration Variables ============
    // Modify these before deployment
    
    /// @notice Address of deployed SKBEAT token (REQUIRED - set before running)
    address constant SKBEAT_TOKEN_ADDRESS = address(0); // Replace with actual address
    
    /// @notice Address of USDC token (or MockUSDC for testing)
    address constant USDC_TOKEN_ADDRESS = address(0); 
    
    /// @notice Amount of SKBEAT to mint (if minting is needed)
    /// @dev Set to 0 if tokens are already minted
    uint256 constant MINT_AMOUNT = 100_000_000 * 10**8; // 100 million SKBEAT
    
    /// @notice Amount of SKBEAT to allocate for sale
    uint256 constant SALE_ALLOCATION = 50_000_000 * 10**8; // 50 million SKBEAT
    
    /// @notice Initial price: how many SKBEAT per 1 USDC
    uint256 constant INITIAL_PRICE = 6; // 6 SKBEAT = 1 USDC
    
    /**
     * @notice Main deployment and setup function
     * @dev Executes full sale setup workflow
     */
    function run() external {
        // Validate configuration
        require(SKBEAT_TOKEN_ADDRESS != address(0), "SKBEAT_TOKEN_ADDRESS not set");
        require(USDC_TOKEN_ADDRESS != address(0), "USDC_TOKEN_ADDRESS not set");
        require(SALE_ALLOCATION > 0, "SALE_ALLOCATION must be greater than 0");
        
        console.log("========================================");
        console.log("Setting up SKBEAT Token Sale");
        console.log("========================================");
        console.log("Deployer address:", msg.sender);
        console.log("Chain ID:", block.chainid);
        console.log("SKBEAT Token:", SKBEAT_TOKEN_ADDRESS);
        console.log("USDC Token:", USDC_TOKEN_ADDRESS);
        console.log("");
        
        // Get existing token contracts
        SKBEATToken skbeatToken = SKBEATToken(SKBEAT_TOKEN_ADDRESS);
        
        // Start broadcasting transactions
        vm.startBroadcast(msg.sender);
        
        // Step 1: Mint SKBEAT tokens if needed
        if (MINT_AMOUNT > 0) {
            console.log("Step 1: Minting SKBEAT tokens...");
            console.log("Mint amount:", MINT_AMOUNT / 10**8, "SKBEAT");
            
            skbeatToken.mint(MINT_AMOUNT);
            
            console.log("Tokens minted successfully");
            console.log("Owner balance:", skbeatToken.balanceOf(msg.sender) / 10**8, "SKBEAT");
            console.log("");
        } else {
            console.log("Step 1: Skipping mint (MINT_AMOUNT is 0)");
            console.log("Current owner balance:", skbeatToken.balanceOf(msg.sender) / 10**8, "SKBEAT");
            console.log("");
        }
        
        // Step 2: Deploy SKBEATTokenSale contract
        console.log("Step 2: Deploying SKBEATTokenSale contract...");
        
        SKBEATTokenSale tokenSale = new SKBEATTokenSale(
            SKBEAT_TOKEN_ADDRESS,
            USDC_TOKEN_ADDRESS
        );
        
        console.log("TokenSale deployed at:", address(tokenSale));
        console.log("");
        
        // Step 3: Set price to 6 SKBEAT per 1 USDC
        console.log("Step 3: Setting price...");
        console.log("Price ratio:", INITIAL_PRICE, "SKBEAT = 1 USDC");
        
        tokenSale.setPrice(INITIAL_PRICE);
        
        console.log("Price set successfully");
        console.log("");
        
        // Step 4: Transfer SKBEAT tokens to sale contract
        console.log("Step 4: Transferring SKBEAT to sale contract...");
        console.log("Sale allocation:", SALE_ALLOCATION / 10**8, "SKBEAT");
        
        // Verify owner has enough tokens
        uint256 ownerBalance = skbeatToken.balanceOf(msg.sender);
        require(ownerBalance >= SALE_ALLOCATION, "Insufficient SKBEAT balance for sale allocation");
        
        skbeatToken.transfer(address(tokenSale), SALE_ALLOCATION);
        
        console.log("Tokens transferred successfully");
        console.log("TokenSale balance:", skbeatToken.balanceOf(address(tokenSale)) / 10**8, "SKBEAT");
        console.log("");
        
        // Step 5: Unpause the contract (ready for sales)
        console.log("Step 5: Unpausing sale contract...");
        
        // Note: Contract starts paused by default, so we need to unpause it
        // Actually, the contract starts unpaused, but we'll call unpause to be explicit
        // Check if it's paused first
        if (tokenSale.paused()) {
            tokenSale.unpause();
            console.log("Contract unpaused - Sale is now ACTIVE");
        } else {
            console.log("Contract is already active (not paused)");
        }
        console.log("");
        
        // Stop broadcasting
        vm.stopBroadcast();
        
        // Display final summary
        console.log("========================================");
        console.log("SALE SETUP COMPLETE");
        console.log("========================================");
        console.log("Network Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("");
        console.log("Contract Addresses:");
        console.log("- SKBEAT Token:", SKBEAT_TOKEN_ADDRESS);
        console.log("- USDC Token:", USDC_TOKEN_ADDRESS);
        console.log("- Token Sale:", address(tokenSale));
        console.log("");
        console.log("Sale Configuration:");
        console.log("- Price:", tokenSale.skbeatPerUsdc(), "SKBEAT = 1 USDC");
        console.log("- Available for sale:", tokenSale.getAvailableSkbeat() / 10**8, "SKBEAT");
        console.log("- Minimum purchase:", tokenSale.MIN_PURCHASE() / 10**8, "SKBEAT");
        console.log("- Sale status:", tokenSale.paused() ? "PAUSED" : "ACTIVE");
        console.log("");
        console.log("Remaining owner balance:", skbeatToken.balanceOf(msg.sender) / 10**8, "SKBEAT");
        console.log("========================================");
        
        // Save deployment data to file
        string memory deploymentData = string(abi.encodePacked(
            '{\n',
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "deployer": "', vm.toString(msg.sender), '",\n',
            '  "skbeatToken": "', vm.toString(SKBEAT_TOKEN_ADDRESS), '",\n',
            '  "usdcToken": "', vm.toString(USDC_TOKEN_ADDRESS), '",\n',
            '  "tokenSale": "', vm.toString(address(tokenSale)), '",\n',
            '  "price": ', vm.toString(INITIAL_PRICE), ',\n',
            '  "saleAllocation": ', vm.toString(SALE_ALLOCATION), ',\n',
            '  "timestamp": ', vm.toString(block.timestamp), '\n',
            '}'
        ));
        
        string memory fileName = string(abi.encodePacked("sale-deployment-", vm.toString(block.chainid), ".json"));
        vm.writeFile(string(abi.encodePacked("deployments/", fileName)), deploymentData);
        console.log("Deployment info saved to deployments/", fileName);
    }
}
