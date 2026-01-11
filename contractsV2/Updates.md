# SKBEATToken.sol
1. Uses OpenZeppelin Ownable: We initially made our custom Ownable implementation since we just wanted a check of onlyOwner and no other functionalities. However, we decided it might be safer to allow a transferOwnership option as a safety net. Hence, we used Ownable. AccessControl would have been better if they were multiple wallets concerned with management/organization of contract. However, since that is not the case here, AccessControl will bring more complications than benefits.
2. Implemented EIP-1046 : More friendly for wallets (tokenURI() instead of logoURI() or metadataURI()). tokenURI is initialized in the constructor.

# SKBEATTokenSale.sol
1. Uses OZ Ownable: Same reason as that of SKEABTToken.sol
2. Pricing Logic: Replaced floor division with ceil division when calculating required USDC
```javascript
uint256 usdcRequired = (skbeatAmount + denominator - 1) / denominator;
```

This ensures buyer never underpays due to integer divison truncation.
3. skbeatPerUsdc: Added bounds on skbeatPerUsdc to prevent invalid or unsafe pricing values.   
4. Helper function consistency: calculateUsdcRequired() now uses the same logic as buyTokens().


# Deploy.s.sol
Single script to deploy SKBEATToken.sol and SKBEATTokenSale.sol, initialize them, and mint few tokens.

# SKBEATTokenSaleTest.t.sol
Updated tests for the changes in contract
