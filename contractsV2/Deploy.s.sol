// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SKBEATToken.sol";
import "../src/SKBEATTokenSale.sol";

contract DeployScript is Script {
    string constant TOKEN_URI = "ipfs://bafkreidm3tymj6bzntjux4rxtspsx4jukobknprxhzq76aa2k34aymtdo4";

    function run() external {
        address deployer = msg.sender;
        console.log("========================================");
        console.log("Starting deployment process...");
        console.log("========================================");
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Balance:", deployer.balance / 1e18);
        console.log("");

        vm.startBroadcast(msg.sender);

        // Step 1: Deploy skBEAT Token
        console.log("1. Deploying skBEAT Token...");
        string memory tokenName = "skBEAT";
        string memory tokenSymbol = "skBEAT";
        SKBEATToken skbeatToken = new SKBEATToken(tokenName, tokenSymbol, TOKEN_URI);
        console.log("   skBEAT Token deployed at:", address(skbeatToken));
        console.log("");

        // Step 2: Deploy or get USDC Token
        address usdcTokenAddress = vm.envAddress("USDC_TOKEN_ADDRESS");
        console.log("2. Using existing USDC Token at:", usdcTokenAddress);

        console.log("");

        // Step 3: Deploy Token Sale Contract
        console.log("3. Deploying skBEAT Token Sale...");
        SKBEATTokenSale tokenSale = new SKBEATTokenSale(
            address(skbeatToken),
            usdcTokenAddress
        );
        tokenSale.setPrice(6); // Set initial price: 6 skBEAT = 1 USDC
        console.log("   Token Sale deployed at:", address(tokenSale));
        console.log("");

        // Step 4: Mint skBEAT tokens
        console.log("4. Minting skBEAT tokens...");
        uint256 mintAmount = 1_000_000 * 10**8; // 1 million skBEAT
        skbeatToken.mint(mintAmount);
        console.log("   Minted:", mintAmount / 10**8, "skBEAT");
        console.log("");

        // Step 5: Transfer skBEAT to sale contract
        console.log("5. Transferring skBEAT to sale contract...");
        uint256 transferAmount = 500_000 * 10**8; // 500k skBEAT for sale
        skbeatToken.transfer(address(tokenSale), transferAmount);
        console.log("   Transferred:", transferAmount / 10**8, "skBEAT");
        console.log("");

        vm.stopBroadcast();

        // Display deployment summary
        console.log("========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Network Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("");
        console.log("Contract Addresses:");
        console.log("-------------------");
        console.log("skBEAT Token:", address(skbeatToken));
        console.log("USDC Token:", usdcTokenAddress);
        console.log("Token Sale:", address(tokenSale));
        console.log("");
        console.log("Balances:");
        console.log("---------");
        console.log("Sale Contract skBEAT:", skbeatToken.balanceOf(address(tokenSale)) / 10**8);
        console.log("Owner skBEAT:", skbeatToken.balanceOf(deployer) / 10**8);
        console.log("");
        console.log("Token Details:");
        console.log("--------------");
        console.log("skBEAT Decimals:", skbeatToken.decimals());
        console.log("Exchange Rate: 1 USDC =", tokenSale.skbeatPerUsdc(), "skBEAT");
        console.log("========================================");
        
        // Save deployment addresses to file
        string memory deploymentData = string(abi.encodePacked(
            '{\n',
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "deployer": "', vm.toString(deployer), '",\n',
            '  "skbeatToken": "', vm.toString(address(skbeatToken)), '",\n',
            '  "usdcToken": "', vm.toString(usdcTokenAddress), '",\n',
            '  "tokenSale": "', vm.toString(address(tokenSale)), '",\n',
            '  "timestamp": ', vm.toString(block.timestamp), '\n',
            '}')
        );
        
        string memory fileName = string(abi.encodePacked("deployment-", vm.toString(block.chainid), ".json"));
        vm.writeFile(string(abi.encodePacked("deployments/", fileName)), deploymentData);
        console.log("Deployment info saved to deployments/", fileName);
    }
}
