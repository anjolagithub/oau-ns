// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {OAUToken} from  "../src/OAUToken.sol";

contract OAUTokenTest is Test {
    OAUToken public oauToken;
    
    address public owner;
    address public airdropFund;
    address public teamFund;
    address public ecosystemFund;
    address public liquidityFund;
    address public reserveFund;
    address public user;
    
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100M tokens
    
    function setUp() public {
        owner = address(this);
        airdropFund = makeAddr("airdropFund");
        teamFund = makeAddr("teamFund");
        ecosystemFund = makeAddr("ecosystemFund");
        liquidityFund = makeAddr("liquidityFund");
        reserveFund = makeAddr("reserveFund");
        user = makeAddr("user");
        
        // Deploy OAU Token
        oauToken = new OAUToken(
            airdropFund,
            teamFund,
            ecosystemFund,
            liquidityFund,
            reserveFund
        );
    }
    
    function testInitialDistribution() public {
        // Check if the total supply is correctly distributed
        assertEq(oauToken.totalSupply(), INITIAL_SUPPLY, "Total supply should be 100M tokens");
        
        // Check individual fund balances
        assertEq(oauToken.balanceOf(airdropFund), INITIAL_SUPPLY * 40 / 100, "Airdrop fund should have 40% of supply");
        assertEq(oauToken.balanceOf(teamFund), INITIAL_SUPPLY * 20 / 100, "Team fund should have 20% of supply");
        assertEq(oauToken.balanceOf(ecosystemFund), INITIAL_SUPPLY * 20 / 100, "Ecosystem fund should have 20% of supply");
        assertEq(oauToken.balanceOf(liquidityFund), INITIAL_SUPPLY * 10 / 100, "Liquidity fund should have 10% of supply");
        assertEq(oauToken.balanceOf(reserveFund), INITIAL_SUPPLY * 10 / 100, "Reserve fund should have 10% of supply");
    }
    
    function testMinting() public {
        uint256 mintAmount = 1000 * 10**18;
        oauToken.mint(user, mintAmount);
        
        assertEq(oauToken.balanceOf(user), mintAmount, "User should receive minted tokens");
        assertEq(oauToken.totalSupply(), INITIAL_SUPPLY + mintAmount, "Total supply should increase after minting");
    }
    
    function testMintingOnlyOwner() public {
        uint256 mintAmount = 1000 * 10**18;
        
        vm.startPrank(user);
        vm.expectRevert();
        oauToken.mint(user, mintAmount);
        vm.stopPrank();
    }
    
    function testBurning() public {
        uint256 transferAmount = 1000 * 10**18;
        uint256 burnAmount = 500 * 10**18;
        
        // Transfer some tokens to user
        vm.startPrank(airdropFund);
        oauToken.transfer(user, transferAmount);
        vm.stopPrank();
        
        assertEq(oauToken.balanceOf(user), transferAmount, "User should receive transferred tokens");
        
        // Burn tokens as user
        vm.startPrank(user);
        oauToken.burn(burnAmount);
        vm.stopPrank();
        
        assertEq(oauToken.balanceOf(user), transferAmount - burnAmount, "User balance should decrease after burning");
        assertEq(oauToken.totalSupply(), INITIAL_SUPPLY - burnAmount, "Total supply should decrease after burning");
    }
    
    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        
        vm.startPrank(airdropFund);
        oauToken.transfer(user, transferAmount);
        vm.stopPrank();
        
        assertEq(oauToken.balanceOf(user), transferAmount, "User should receive transferred tokens");
        assertEq(
            oauToken.balanceOf(airdropFund), 
            (INITIAL_SUPPLY * 40 / 100) - transferAmount, 
            "Airdrop fund balance should decrease after transfer"
        );
    }

    function testTransferFrom() public {
        uint256 transferAmount = 1000 * 10**18;
        
        // Approve user to spend tokens on behalf of airdrop fund
        vm.startPrank(airdropFund);
        oauToken.approve(user, transferAmount);
        vm.stopPrank();
        
        // Transfer tokens from airdrop fund to user
        vm.startPrank(user);
        oauToken.transferFrom(airdropFund, user, transferAmount);
        vm.stopPrank();
        
        assertEq(oauToken.balanceOf(user), transferAmount, "User should receive transferred tokens");
        assertEq(
            oauToken.balanceOf(airdropFund), 
            (INITIAL_SUPPLY * 40 / 100) - transferAmount, 
            "Airdrop fund balance should decrease after transfer"
        );
    }
}


    