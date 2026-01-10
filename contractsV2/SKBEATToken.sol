// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SKBEATToken
 * @author SKBEAT Team
 * @notice ERC20 token with 8 decimals, minting, burning, and gasless approval capabilities
 * @dev Extends OpenZeppelin's ERC20, ERC20Burnable, ERC20Permit, and Ownable
 * 
 * Features:
 * - Fixed maximum supply: 1 quadrillion tokens (1,000,000,000,000,000)
 * - 8 decimal places (similar to Bitcoin)
 * - Owner-controlled minting up to MAX_SUPPLY
 * - Ownership is transferable via OpenZeppelin Ownable
 * - Burnable: Anyone can burn their own tokens
 * - ERC20Permit: Gasless approvals via signatures (EIP-2612)
 * - Token URI metadata support (EIP-1046) : Mutable by owner

 * EIP-1046:
 * - Exposes tokenURI() for off-chain metadata discovery by wallets and explorers
 */

contract SKBEATToken is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    
    // ============ Constants ============
    
    /// @notice Maximum supply of SKBEAT tokens (1 quadrillion with 8 decimals)
    uint256 public constant MAX_SUPPLY = 1_000_000_000_000_000 * 10**8;
    
    // ============ Metadata ============
    
    /// @notice EIP-1046 metadata URI (JSON)
    string private tokenUri;
    
    // ============ Events ============
    
    /// @notice Emitted when new tokens are minted
    /// @param amount Amount of tokens minted
    event Minted(uint256 amount);
    
    /// @notice Emitted when total supply reaches MAX_SUPPLY
    event SupplyCapReached();
    
    /// @notice Emitted when token URI is updated
    /// @param newURI The new token metadata URI
    event TokenURIUpdated(string newURI);
    
    // ============ Constructor ============
    
    /**
     * @notice Initializes the SKBEAT token
     * @dev Sets deployer as initial owner
     * @param name Token name (e.g., "SKBEAT")
     * @param symbol Token symbol (e.g., "SKBEAT")
     */
    constructor(string memory name, string memory symbol, string memory initialTokenURI) 
        ERC20(name, symbol) 
        ERC20Permit(name)
        Ownable(msg.sender)
    {
        tokenUri = initialTokenURI;
    }

    // ============ Public Functions ============
    /**
     * @notice Returns the number of decimals used for token amounts
     * @dev Overrides ERC20 default (18) to use 8 decimals like Bitcoin
     * @return uint8 Number of decimals (8)
     */
    function decimals() public pure override returns (uint8) {
        return 8;
    }

    /**
     * @notice Mint new SKBEAT tokens to the owner address
     * @dev Only owner can mint. Total supply cannot exceed MAX_SUPPLY
     * @param amount Amount of tokens to mint (in units with 8 decimals)
     * 
     * Requirements:
     * - amount must be greater than 0
     * - totalSupply() + amount must not exceed MAX_SUPPLY
     * 
     * Emits: Minted event
     * Emits: SupplyCapReached event if MAX_SUPPLY is reached
     */
    function mint(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        
        _mint(owner(), amount);
        emit Minted(amount);
        
        if (totalSupply() == MAX_SUPPLY) {
            emit SupplyCapReached();
        }
    }

     // ============ EIP-1046 Metadata ============
    /**
     * @notice Sets the EIP-1046 token metadata URI
     * @dev Only owner can update
     * @param newURI URI pointing to a JSON metadata file (IPFS / HTTPS)
     */
    function setTokenURI(string memory newURI) external onlyOwner {
        require(bytes(newURI).length > 0, "Empty URI");
        tokenUri = newURI;
        emit TokenURIUpdated(newURI);
    }

    /**
     * @notice EIP-1046 token metadata URI
     * @return URI of the token metadata JSON
     */
    function tokenURI() external view returns (string memory) {
        return tokenUri;
    }
    
}