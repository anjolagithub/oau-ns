// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {OAUToken} from "../src/OAUToken.sol";
import {OAUNameRegistry} from "../src/OAUNameRegistry.sol";

contract DeployOAUNS is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Set up fund addresses
        address deployer = vm.addr(deployerPrivateKey);
        
        // For this example, we're using the deployer address for all funds
        // In production, you should use separate, secure multisig wallets
        address airdropFund = deployer;
        address teamFund = deployer;
        address ecosystemFund = deployer;
        address liquidityFund = deployer;
        address reserveFund = deployer;

        // Deploy OAU Token
        OAUToken oauToken = new OAUToken(
            airdropFund,
            teamFund,
            ecosystemFund,
            liquidityFund,
            reserveFund
        );
        
        console.log("OAU Token deployed at:", address(oauToken));

        // Deploy OAU Name Registry
        OAUNameRegistry oauNameRegistry = new OAUNameRegistry(address(oauToken));
        console.log("OAU Name Registry deployed at:", address(oauNameRegistry));

        vm.stopBroadcast();
    }
}