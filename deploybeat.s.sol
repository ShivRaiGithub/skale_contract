// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SKBEATToken.sol";

/**
 * @title DeployBeatScript
 * @author SKBEAT Team
 * @notice Deployment script for SKBEAT token
 * @dev Uses Foundry's Script framework for deployment
 * 
 * Usage:
 * forge script script/deploybeat.s.sol:DeployBeatScript --rpc-url <RPC_URL> --broadcast --verify
 * 
 * Features:
 * - Deploys SKBEATToken contract
 * - Displays deployment summary with key information
 * - Saves deployment data to JSON file in deployments/ folder
 * - Includes chain ID, deployer address, and token address
 */
contract DeployBeatScript is Script {
    /**
     * @notice Main deployment function
     * @dev Deploys SKBEATToken and saves deployment information
     */
    function run() external {
        
        // Print deployment header
        console.log("========================================");
        console.log("Deploying skBEAT Token...");
        console.log("========================================");
        console.log("Deployer address:", msg.sender);
        console.log("Chain ID:", block.chainid);
        console.log("");

        // Start broadcasting transactions to the network
        vm.startBroadcast(msg.sender);

        // Deploy the SKBEAT token contract
        string memory name = "skBEAT";
        string memory symbol = "skBEAT";

        SKBEATToken skbeatToken = new SKBEATToken(name, symbol);
        
        console.log("skBEAT Token deployed at:", address(skbeatToken));
        console.log("");

        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        // Display comprehensive deployment summary
        console.log("========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Network Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("skBEAT Token:", address(skbeatToken));
        console.log("Owner Balance:", skbeatToken.balanceOf(msg.sender) / 10**8, "skBEAT");
        console.log("Decimals:", skbeatToken.decimals());
        console.log("========================================");
        
        // Create JSON deployment data for record-keeping
        string memory deploymentData = string(abi.encodePacked(
            '{\n',
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "deployer": "', vm.toString(msg.sender), '",\n',
            '  "skbeatToken": "', vm.toString(address(skbeatToken)), '",\n',
            '  "timestamp": ', vm.toString(block.timestamp), '\n',
            '}')
        );
        
        // Save deployment information to JSON file (named by chain ID)
        string memory fileName = string(abi.encodePacked("skbeat-deployment-", vm.toString(block.chainid), ".json"));
        vm.writeFile(string(abi.encodePacked("deployments/", fileName)), deploymentData);
        console.log("Deployment info saved to deployments/", fileName);
    }
}
