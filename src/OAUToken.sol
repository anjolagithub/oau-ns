// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from  "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OAUToken
 * @dev ERC20 Token for OAU Name Service
 * This contract implements the ERC20 standard with additional features:
 * - Burning capability
 * - Minting by owner
 * - Initial supply allocation according to tokenomics structure
 */
contract OAUToken is ERC20, ERC20Burnable, Ownable {
    // Tokenomics constants
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 million tokens with 18 decimals
    
    // Allocation addresses
    address public airdropFund;     // 40% - For early users, students, referrals
    address public teamFund;        // 20% - Team & Dev Fund
    address public ecosystemFund;   // 20% - Grants, growth incentives, community
    address public liquidityFund;   // 10% - For listings or LP pools if needed
    address public reserveFund;     // 10% - Held for future usage or burns

    /**
     * @dev Constructor - Initializes the token with name, symbol, and distributes initial supply
     * @param _airdropFund Address for airdrop allocation (40%)
     * @param _teamFund Address for team allocation (20%)
     * @param _ecosystemFund Address for ecosystem/DAO allocation (20%)
     * @param _liquidityFund Address for liquidity allocation (10%)
     * @param _reserveFund Address for reserve allocation (10%)
     */
    constructor(
        address _airdropFund,
        address _teamFund,
        address _ecosystemFund,
        address _liquidityFund,
        address _reserveFund
    ) ERC20("OAU Token", "OAU") Ownable(msg.sender) {
        require(_airdropFund != address(0), "Invalid airdrop fund address");
        require(_teamFund != address(0), "Invalid team fund address");
        require(_ecosystemFund != address(0), "Invalid ecosystem fund address");
        require(_liquidityFund != address(0), "Invalid liquidity fund address");
        require(_reserveFund != address(0), "Invalid reserve fund address");
        
        airdropFund = _airdropFund;
        teamFund = _teamFund;
        ecosystemFund = _ecosystemFund;
        liquidityFund = _liquidityFund;
        reserveFund = _reserveFund;
        
        // Distribute initial supply according to tokenomics
        _mint(airdropFund, INITIAL_SUPPLY * 40 / 100);    // 40% to airdrop fund
        _mint(teamFund, INITIAL_SUPPLY * 20 / 100);       // 20% to team fund
        _mint(ecosystemFund, INITIAL_SUPPLY * 20 / 100);  // 20% to ecosystem fund
        _mint(liquidityFund, INITIAL_SUPPLY * 10 / 100);  // 10% to liquidity fund
        _mint(reserveFund, INITIAL_SUPPLY * 10 / 100);    // 10% to reserve fund
    }

    /**
     * @dev Creates new tokens and assigns them to an address
     * @param to Address to receive the tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}