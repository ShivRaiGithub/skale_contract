// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title SKBEATToken
 * @author SKBEAT Team
 * @notice ERC20 token with 8 decimals, minting, burning, and gasless approval capabilities
 * @dev Extends OpenZeppelin's ERC20, ERC20Burnable, and ERC20Permit
 * 
 * Features:
 * - Fixed maximum supply: 1 quadrillion tokens (1,000,000,000,000,000)
 * - 8 decimal places (similar to Bitcoin)
 * - Owner-controlled minting up to MAX_SUPPLY
 * - Burnable: Anyone can burn their own tokens
 * - ERC20Permit: Gasless approvals via signatures (EIP-2612)
 * - Metadata URIs: Logo and metadata can be set by owner
 * - Immutable owner: Owner cannot be changed after deployment
 */
contract SKBEATToken is ERC20, ERC20Burnable, ERC20Permit {
    
    // ============ Constants ============
    
    /// @notice Maximum supply of SKBEAT tokens (1 quadrillion with 8 decimals)
    uint256 public constant MAX_SUPPLY = 1_000_000_000_000_000 * 10**8;
    
    // ============ State Variables ============
    
    /// @notice URI for the token logo image
    string private logoUri;
    
    /// @notice URI for the token metadata JSON
    string private metadataUri;
    
    /// @notice Immutable owner address (set at deployment, cannot be changed)
    address private immutable OWNER;
    
    // ============ Events ============
    
    /// @notice Emitted when new tokens are minted
    /// @param amount Amount of tokens minted
    event Minted(uint256 amount);
    
    /// @notice Emitted when total supply reaches MAX_SUPPLY
    event SupplyCapReached();
    
    /// @notice Emitted when logo URI is updated
    /// @param newURI New logo URI
    event LogoURIUpdated(string newURI);
    
    /// @notice Emitted when metadata URI is updated
    /// @param newURI New metadata URI
    event MetadataURIUpdated(string newURI);
    
    // ============ Constructor ============
    
    /**
     * @notice Initializes the SKBEAT token
     * @dev Sets deployer as immutable owner and initializes ERC20Permit
     * @param name Token name (e.g., "SKBEAT")
     * @param symbol Token symbol (e.g., "SKBEAT")
     */
    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) 
        ERC20Permit(name)
    {   
        OWNER = msg.sender;
    }

    // ============ Modifiers ============
    
    /// @notice Restricts function access to contract owner only
    modifier onlyOwner {
        require(msg.sender == OWNER, "Caller is not the owner");
        _;
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
        
        _mint(OWNER, amount);
        emit Minted(amount);
        
        if (totalSupply() == MAX_SUPPLY) {
            emit SupplyCapReached();
        }
    }
    
    // ============ Metadata Functions ============
    
    /**
     * @notice Set the logo URI for the token
     * @dev Only owner can update. Used for displaying token logo in wallets/explorers
     * @param newURI New logo URI (typically IPFS or HTTP URL)
     * Emits: LogoURIUpdated event
     */
    function setLogoURI(string memory newURI) external onlyOwner {
        logoUri = newURI;
        emit LogoURIUpdated(newURI);
    }
    
    /**
     * @notice Get the current logo URI
     * @return string Logo URI
     */
    function logoURI() external view returns (string memory) {
        return logoUri;
    }
    
    /**
     * @notice Set the metadata URI for the token
     * @dev Only owner can update. Should point to JSON with token information
     * @param newURI New metadata URI (typically IPFS or HTTP URL)
     * Emits: MetadataURIUpdated event
     */
    function setMetadataURI(string memory newURI) external onlyOwner {
        metadataUri = newURI;
        emit MetadataURIUpdated(newURI);
    }
    
    /**
     * @notice Get the current metadata URI
     * @return string Metadata URI
     */
    function metadataURI() external view returns (string memory) {
        return metadataUri;
    }

    /**
     * @notice Get the owner address
     * @return address Owner address (immutable)
     */
    function owner() external view returns (address) {
        return OWNER;
    }
}