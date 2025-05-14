// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from  "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from  "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from  "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from  "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title OAUNameRegistry
 * @dev ERC721 contract for .oau domain names
 * Allows users to register unique .oau names and link their profiles
 */
contract OAUNameRegistry is ERC721, Ownable {
    using Strings for uint256;
    
    // Reference to OAU token
    IERC20 public oauToken;
    
    // Cost for registering a name (in OAU tokens)
    uint256 public registrationFee = 100 * 10**18; // 100 OAU tokens
    
    // Count of free registrations remaining
    uint256 public freeRegistrationsRemaining = 100;
    
    // Token ID counter
    uint256 private _nextTokenId = 1;
    
    // Name to token ID mapping
    mapping(string => uint256) private _nameToTokenId;
    
    // Token ID to name mapping
    mapping(uint256 => string) private _tokenIdToName;
    
    // Name to address resolution
    mapping(string => address) private _nameToAddress;
    
    // Token ID to token URI mapping (replaces ERC721URIStorage)
    mapping(uint256 => string) private _tokenURIs;
    
    // Address to owned tokens mapping (replaces ERC721Enumerable)
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(address => uint256) private _balances;
    
    // Profile data structure
    struct Profile {
        string twitter;
        string telegram;
        string discord;
        string profileImage;
        string bio;
        bool verified;
    }
    
    // Token ID to profile mapping
    mapping(uint256 => Profile) private _profiles;
    
    // Address to verified status mapping (for OAU student email verification)
    mapping(address => bool) private _verifiedStudents;
    
    // Events
    event NameRegistered(string name, address owner, uint256 tokenId);
    event ProfileUpdated(string name, uint256 tokenId);
    event FeeUpdated(uint256 newFee);
    event StudentVerified(address student);
    
    /**
     * @dev Constructor
     * @param _oauToken Address of the OAU token contract
     */
    constructor(address _oauToken) ERC721("OAU Name Service", "OAU-NS") Ownable(msg.sender) {
        require(_oauToken != address(0), "Invalid token address");
        oauToken = IERC20(_oauToken);
    }
    
    /**
     * @dev Checks if a name is available for registration
     * @param name The name to check (without .oau suffix)
     * @return True if the name is available
     */
    function isNameAvailable(string memory name) public view returns (bool) {
        return _nameToTokenId[name] == 0;
    }
    
    /**
     * @dev Register a new .oau name
     * @param name The name to register (without .oau suffix)
     */
    function registerName(string memory name) public {
        require(isNameAvailable(name), "Name already registered");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(_isValidName(name), "Name contains invalid characters");
        
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        
        // Handle payment
        if (freeRegistrationsRemaining > 0) {
            freeRegistrationsRemaining--;
        } else {
            require(
                oauToken.transferFrom(msg.sender, address(this), registrationFee),
                "Token transfer failed"
            );
        }
        
        // Mint NFT and store name data
        _safeMint(msg.sender, tokenId);
        _nameToTokenId[name] = tokenId;
        _tokenIdToName[tokenId] = name;
        _nameToAddress[name] = msg.sender;
        
        // Store token in owner's collection (ERC721Enumerable replacement)
        _ownedTokens[msg.sender][_balances[msg.sender]] = tokenId;
        _balances[msg.sender]++;
        
        // Generate and set token URI
        _tokenURIs[tokenId] = _generateTokenURI(tokenId, name);
        
        emit NameRegistered(name, msg.sender, tokenId);
    }
    
    /**
     * @dev Update profile information for a name
     * @param tokenId The token ID of the name
     * @param twitter Twitter handle
     * @param telegram Telegram handle
     * @param discord Discord handle
     * @param profileImage Profile image URL/IPFS hash
     * @param bio User bio
     */
    function updateProfile(
        uint256 tokenId,
        string memory twitter,
        string memory telegram,
        string memory discord,
        string memory profileImage,
        string memory bio
    ) public {
        require(_exists(tokenId), "Token does not exist");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized");
        
        Profile storage profile = _profiles[tokenId];
        profile.twitter = twitter;
        profile.telegram = telegram;
        profile.discord = discord;
        profile.profileImage = profileImage;
        profile.bio = bio;
        
        // Update token URI with new profile data
        _tokenURIs[tokenId] = _generateTokenURI(tokenId, _tokenIdToName[tokenId]);
        
        emit ProfileUpdated(_tokenIdToName[tokenId], tokenId);
    }
    
    /**
     * @dev Get profile information for a name
     * @param name The name to query (without .oau suffix)
     * @return Profile The profile data
     */
    function getProfileByName(string memory name) public view returns (Profile memory) {
        uint256 tokenId = _nameToTokenId[name];
        require(tokenId != 0, "Name not registered");
        return _profiles[tokenId];
    }
    
    /**
     * @dev Get the address associated with a name
     * @param name The name to resolve (without .oau suffix)
     * @return The address for the name
     */
    function resolveName(string memory name) public view returns (address) {
        return _nameToAddress[name];
    }
    
    /**
     * @dev Update the registration fee
     * @param newFee The new fee amount
     */
    function updateRegistrationFee(uint256 newFee) public onlyOwner {
        registrationFee = newFee;
        emit FeeUpdated(newFee);
    }
    
    /**
     * @dev Mark a student address as verified (to be called by authorized verification system)
     * @param student The address to verify
     */
    function verifyStudent(address student) public onlyOwner {
        _verifiedStudents[student] = true;
        
        // Update verified status in profiles owned by this student
        for (uint256 i = 0; i < _balances[student]; i++) {
            uint256 tokenId = _ownedTokens[student][i];
            _profiles[tokenId].verified = true;
            
            // Update token URI
            _tokenURIs[tokenId] = _generateTokenURI(tokenId, _tokenIdToName[tokenId]);
        }
        
        emit StudentVerified(student);
    }
    
    /**
     * @dev Withdraw OAU tokens to contract owner
     */
    function withdrawTokens() public onlyOwner {
        uint256 balance = oauToken.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(oauToken.transfer(owner(), balance), "Transfer failed");
    }
    
    /**
     * @dev Return the token URI for a given token ID
     * @param tokenId The token ID to query
     * @return string The token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
    
    /**
     * @dev Implementation of tokenOfOwnerByIndex
     * @param owner Address to get token from
     * @param index Token index
     * @return uint256 Token ID
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < _balances[owner], "Owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    
    /**
     * @dev Helper function to check if a token exists
     * @param tokenId The token ID to check
     * @return bool True if the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId != 0 && tokenId < _nextTokenId && _ownerOf(tokenId) != address(0);
    }
    
    /**
     * @dev Helper function to check if an address is approved or owner
     * @param spender The address to check
     * @param tokenId The token ID
     * @return bool True if approved or owner
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || 
                getApproved(tokenId) == spender || 
                isApprovedForAll(owner, spender));
    }
    
    /**
     * @dev Override transferFrom to update name resolution
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
        string memory name = _tokenIdToName[tokenId];
        _nameToAddress[name] = to;
        
        // Remove token from previous owner's collection
        _removeTokenFromOwnerEnumeration(from, tokenId);
        
        // Add token to new owner's collection
        _addTokenToOwnerEnumeration(to, tokenId);
        
        // Update verified status based on new owner
        _profiles[tokenId].verified = _verifiedStudents[to];
        _tokenURIs[tokenId] = _generateTokenURI(tokenId, name);
    }
    
    /**
     * @dev Override safeTransferFrom to update name resolution
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        super.safeTransferFrom(from, to, tokenId, data);
        string memory name = _tokenIdToName[tokenId];
        _nameToAddress[name] = to;
        
        // Remove token from previous owner's collection
        _removeTokenFromOwnerEnumeration(from, tokenId);
        
        // Add token to new owner's collection
        _addTokenToOwnerEnumeration(to, tokenId);
        
        // Update verified status based on new owner
        _profiles[tokenId].verified = _verifiedStudents[to];
        _tokenURIs[tokenId] = _generateTokenURI(tokenId, name);
    }
    
    /**
     * @dev Internal function to add a token to an owner's enumeration
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokens[to][_balances[to]] = tokenId;
        _balances[to]++;
    }
    
    /**
     * @dev Internal function to remove a token from an owner's enumeration
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // Get owner's balance
        uint256 lastTokenIndex = _balances[from] - 1;
        
        // Find the index of the token to remove
        uint256 tokenIndex = type(uint256).max; // Initialize with max value as sentinel
        for (uint256 i = 0; i < _balances[from]; i++) {
            if (_ownedTokens[from][i] == tokenId) {
                tokenIndex = i;
                break;
            }
        }
        
        // Token must be found
        require(tokenIndex != type(uint256).max, "Token not found in owner's list");
        
        // If not the last token, swap with the last one
        if (tokenIndex != lastTokenIndex) {
            _ownedTokens[from][tokenIndex] = _ownedTokens[from][lastTokenIndex];
        }
        
        // Delete the last token
        delete _ownedTokens[from][lastTokenIndex];
        _balances[from]--;
    }
    
    /**
     * @dev Internal function to generate token URI with metadata
     * @param tokenId The token ID
     * @param name The name registered
     * @return string The token URI with embedded metadata
     */
    function _generateTokenURI(uint256 tokenId, string memory name) internal view returns (string memory) {
        Profile memory profile = _profiles[tokenId];
        
        // Split the encoding into parts to reduce stack depth
        string memory part1 = string(abi.encodePacked(
            '{',
                '"name": "', name, '.oau",',
                '"description": "An OAU Name Service domain - Web3 identity for OAU students",',
                '"image": "', _generateSVGImage(name), '",'
        ));
        
        string memory part2 = string(abi.encodePacked(
                '"attributes": [',
                    '{"trait_type": "Twitter", "value": "', profile.twitter, '"},'
        ));
        
        string memory part3 = string(abi.encodePacked(
                    '{"trait_type": "Telegram", "value": "', profile.telegram, '"},',
                    '{"trait_type": "Discord", "value": "', profile.discord, '"},'
        ));
        
        string memory part4 = string(abi.encodePacked(
                    '{"trait_type": "Verified", "value": "', profile.verified ? 'true' : 'false', '"}',
                ']',
            '}'
        ));
        
        string memory combined = string(abi.encodePacked(part1, part2, part3, part4));
        
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(combined))
            )
        );
    }
    
    /**
     * @dev Generate a simple SVG image for the domain
     * @param name The registered name
     * @return SVG data URI
     */
    function _generateSVGImage(string memory name) internal pure returns (string memory) {
        // Break down the SVG generation to avoid stack too deep errors
        string memory svgPart1 = '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300">';
        string memory svgPart2 = '<rect width="100%" height="100%" fill="#FFD700"/>';
        string memory svgPart3 = '<text x="50%" y="50%" font-family="Arial" font-size="24" fill="#000000" text-anchor="middle" dominant-baseline="middle">';
        string memory svgPart4 = string(abi.encodePacked(name, '.oau'));
        string memory svgPart5 = '</text></svg>';
        
        string memory svg = string(abi.encodePacked(svgPart1, svgPart2, svgPart3, svgPart4, svgPart5));
        
        return string(
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                Base64.encode(bytes(svg))
            )
        );
    }
    
    /**
     * @dev Check if a name contains only valid characters
     * Allowed: a-z, 0-9, and -
     * @param name The name to validate
     * @return bool True if the name is valid
     */
    function _isValidName(string memory name) internal pure returns (bool) {
        bytes memory nameBytes = bytes(name);
        for (uint i = 0; i < nameBytes.length; i++) {
            bytes1 char = nameBytes[i];
            
            // Allow a-z (lowercase only)
            if (!(char >= 0x61 && char <= 0x7A) && 
                // Allow 0-9
                !(char >= 0x30 && char <= 0x39) &&
                // Allow hyphen
                !(char == 0x2D)) {
                return false;
            }
        }
        return true;
    }
}