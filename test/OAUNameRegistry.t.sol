// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from  "forge-std/Test.sol";
import {OAUToken} from  "../src/OAUToken.sol";
import {OAUNameRegistry} from "../src/OAUNameRegistry.sol";

contract OAUNameRegistryTest is Test {
    OAUToken public oauToken;
    OAUNameRegistry public oauNameRegistry;
    
    address public owner;
    address public airdropFund;
    address public user1;
    address public user2;
    
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100M tokens
    uint256 public constant REGISTRATION_FEE = 100 * 10**18; // 100 OAU tokens
    
    function setUp() public {
        owner = address(this);
        airdropFund = makeAddr("airdropFund");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy OAU Token with simplified allocation (all to airdropFund for testing)
        oauToken = new OAUToken(
            airdropFund,
            airdropFund, // teamFund
            airdropFund, // ecosystemFund
            airdropFund, // liquidityFund
            airdropFund  // reserveFund
        );
        
        // Deploy OAU Name Registry
        oauNameRegistry = new OAUNameRegistry(address(oauToken));
        
        // Transfer tokens to users for testing
        vm.startPrank(airdropFund);
        oauToken.transfer(user1, 1000 * 10**18);
        oauToken.transfer(user2, 1000 * 10**18);
        vm.stopPrank();
    }
    
    function testNameAvailability() public {
        assertTrue(oauNameRegistry.isNameAvailable("alice"), "New name should be available");
    }
    
    function testFreeRegistration() public {
        vm.startPrank(user1);
        oauNameRegistry.registerName("alice");
        vm.stopPrank();
        
        // Check registration was successful
        assertFalse(oauNameRegistry.isNameAvailable("alice"), "Name should be registered");
        assertEq(oauNameRegistry.resolveName("alice"), user1, "Name should resolve to user1");
        assertEq(oauNameRegistry.balanceOf(user1), 1, "User1 should have 1 NFT");
        
        // Check that it was a free registration
        assertEq(oauToken.balanceOf(user1), 1000 * 10**18, "No tokens should have been spent");
        assertEq(oauNameRegistry.freeRegistrationsRemaining(), 99, "Free registrations should decrease by 1");
    }
    
    function testPaidRegistrationAfterFreeOnesExhausted() public {
        // Exhaust free registrations
        oauNameRegistry.updateRegistrationFee(1 * 10**18); // Set lower fee for easier testing
        
        // Register 100 free names to exhaust free registrations
        for (uint i = 0; i < 100; i++) {
            string memory name = string(abi.encodePacked("test", vm.toString(i)));
            vm.prank(makeAddr(name));
            oauNameRegistry.registerName(name);
        }
        
        assertEq(oauNameRegistry.freeRegistrationsRemaining(), 0, "Free registrations should be exhausted");
        
        // Now try a paid registration
        vm.startPrank(user1);
        oauToken.approve(address(oauNameRegistry), 1 * 10**18);
        oauNameRegistry.registerName("alice");
        vm.stopPrank();
        
        // Check registration was successful
        assertFalse(oauNameRegistry.isNameAvailable("alice"), "Name should be registered");
        assertEq(oauNameRegistry.resolveName("alice"), user1, "Name should resolve to user1");
        
        // Check that tokens were spent
        assertEq(oauToken.balanceOf(user1), 1000 * 10**18 - 1 * 10**18, "Tokens should have been spent");
        assertEq(oauToken.balanceOf(address(oauNameRegistry)), 1 * 10**18, "Registry should have received tokens");
    }
    
    function testRegistrationFailsIfNameTaken() public {
        vm.prank(user1);
        oauNameRegistry.registerName("alice");
        
        vm.startPrank(user2);
        vm.expectRevert();
        oauNameRegistry.registerName("alice");
        vm.stopPrank();
    }
    
    function testUpdateProfile() public {
        vm.startPrank(user1);
        oauNameRegistry.registerName("alice");
        
        // Get token ID
        uint256 tokenId = oauNameRegistry.tokenOfOwnerByIndex(user1, 0);
        
        // Update profile
        oauNameRegistry.updateProfile(
            tokenId,
            "alice_twitter",
            "alice_telegram",
            "alice_discord",
            "ipfs://example",
            "This is Alice's bio"
        );
        vm.stopPrank();
        
        // Check profile data
        OAUNameRegistry.Profile memory profile = oauNameRegistry.getProfileByName("alice");
        assertEq(profile.twitter, "alice_twitter", "Twitter handle should match");
        assertEq(profile.telegram, "alice_telegram", "Telegram handle should match");
        assertEq(profile.discord, "alice_discord", "Discord handle should match");
        assertEq(profile.profileImage, "ipfs://example", "Profile image should match");
        assertEq(profile.bio, "This is Alice's bio", "Bio should match");
    }
    
    function testProfileUpdateOnlyByOwner() public {
        vm.prank(user1);
        oauNameRegistry.registerName("alice");
        
        // Get token ID
        uint256 tokenId = oauNameRegistry.tokenOfOwnerByIndex(user1, 0);
        
        vm.startPrank(user2);
        vm.expectRevert();
        oauNameRegistry.updateProfile(
            tokenId,
            "hacked",
            "hacked",
            "hacked",
            "hacked",
            "hacked"
        );
        vm.stopPrank();
    }
    
    function testVerifyStudent() public {
        vm.prank(user1);
        oauNameRegistry.registerName("alice");
        
        // Verify student
        oauNameRegistry.verifyStudent(user1);
        
        // Check if profile is marked as verified
        OAUNameRegistry.Profile memory profile = oauNameRegistry.getProfileByName("alice");
        assertTrue(profile.verified, "Profile should be marked as verified");
    }
    
    function testVerifyStudentOnlyByOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        oauNameRegistry.verifyStudent(user1);
        vm.stopPrank();
    }
    
    function testWithdrawTokens() public {
        // Set up: exhaust free registrations and register a paid name
        oauNameRegistry.updateRegistrationFee(1 * 10**18);
        
        // Register 100 free names to exhaust free registrations
        for (uint i = 0; i < 100; i++) {
            string memory name = string(abi.encodePacked("test", vm.toString(i)));
            vm.prank(makeAddr(name));
            oauNameRegistry.registerName(name);
        }
        
        // Register paid name
        vm.startPrank(user1);
        oauToken.approve(address(oauNameRegistry), 1 * 10**18);
        oauNameRegistry.registerName("alice");
        vm.stopPrank();
        
        // Contract should have tokens now
        assertEq(oauToken.balanceOf(address(oauNameRegistry)), 1 * 10**18, "Registry should have tokens");
        
        // Withdraw tokens
        uint256 ownerBalanceBefore = oauToken.balanceOf(owner);
        oauNameRegistry.withdrawTokens();
        uint256 ownerBalanceAfter = oauToken.balanceOf(owner);
        
        // Check balances
        assertEq(ownerBalanceAfter - ownerBalanceBefore, 1 * 10**18, "Owner should receive tokens");
        assertEq(oauToken.balanceOf(address(oauNameRegistry)), 0, "Registry should have no tokens left");
    }
    
    function testTransferUpdatesNameResolution() public {
        vm.startPrank(user1);
        oauNameRegistry.registerName("alice");
        
        // Get token ID
        uint256 tokenId = oauNameRegistry.tokenOfOwnerByIndex(user1, 0);
        
        // Transfer NFT to user2
        oauNameRegistry.transferFrom(user1, user2, tokenId);
        vm.stopPrank();
        
        // Check that name resolution is updated
        assertEq(oauNameRegistry.resolveName("alice"), user2, "Name should resolve to user2 after transfer");
    }
    
    function testInvalidNameRejection() public {
        vm.startPrank(user1);
        
        // Test capital letters (invalid)
        vm.expectRevert();
        oauNameRegistry.registerName("Alice");
        
        // Test spaces (invalid)
        vm.expectRevert();
        oauNameRegistry.registerName("alice bob");
        
        // Test special characters except hyphen (invalid)
        vm.expectRevert();
        oauNameRegistry.registerName("alice_bob");
        
        // Test valid name with numbers and hyphen
        oauNameRegistry.registerName("alice-123");
        assertFalse(oauNameRegistry.isNameAvailable("alice-123"), "Valid name should be registered");
        
        vm.stopPrank();
    }
}