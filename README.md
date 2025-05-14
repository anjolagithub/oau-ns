# OAU Name Service (OAU-NS)
A Web3 identity system for OAU students powered by the $OAU token, allowing students to register and own their .oau domain names.

# Overview
OAU Name Service (OAU-NS) is a decentralized identity and social flex system for Obafemi Awolowo University students. The project consists of:

OAU Token ($OAU): An ERC-20 token used for name registration, tipping, and community governance.
OAU Name Registry: An ENS-style system where users can register personalized .oau domain names as NFTs.

# Features

Register your unique .oau domain name (e.g., techboy.oau)
Link your social profiles (Twitter, Telegram, Discord)
Get verified as an OAU student
Buy, sell, and trade your domain names
Use $OAU tokens for name registration and tipping

# Project Structure
oau-ns/
├── src/
│   ├── OAUToken.sol          # ERC-20 token contract
│   └── OAUNameRegistry.sol   # ENS-style name registry
├── script/
│   └── DeployOAUNS.s.sol     # Deployment script
├── test/
│   ├── OAUToken.t.sol        # Token tests
│   └── OAUNameRegistry.t.sol # Registry tests
├── .env                      # Environment variables (private)
└── .env.template             # Template for environment variables

# Tokenomics
The $OAU token has a total supply of 100 million tokens, distributed as follows:

40% Airdrop & Users: For early users, students, referrals
20% Team & Dev Fund: For the project team and development
20% Ecosystem/DAO: For grants, growth incentives, and community
10% Liquidity & CEXs: For liquidity provision and exchange listings
10% Reserve: Held for future usage or token burns

## Installation

Clone the repository:

bashgit clone <repository-url>
cd oau-ns

Install Foundry (if not already installed):

bashcurl -L https://foundry.paradigm.xyz | bash
foundryup

## Install dependencies:

bashforge install

Create a .env file from the template:

bashcp .env.template .env

Edit the .env file with your deployment information.

## Testing

Run tests to ensure everything works as expected:
bashforge test
Run tests with gas reporting:
bashforge test --gas-report

## Deployment
To deploy the contracts to a network:

Fill in your .env file with the required information.
# Deploy to a test network (Base Sepolia):

bashforge script script/DeployOAUNS.s.sol --rpc-url $RPC_URL_TESTNET --broadcast --verify

# Deploy to mainnet:

bashforge script script/DeployOAUNS.s.sol --rpc-url $RPC_URL_MAINNET --broadcast --verify

## Frontend Integration
The contracts are designed to work with a frontend application (React/Next.js) that would allow users to:

Connect their wallet (MetaMask, WalletConnect)
Search for available .oau domain names
Register domain names using $OAU tokens
Edit their profile information
View a leaderboard of popular domains
Verify their OAU student status

## Roadmap

Phase 1: Name registration + $OAU token (MVP)
Phase 2: Profile editor + social linking
Phase 3: OAU Email verification
Phase 4: DAO & name governance
Phase 5: Inter-OAU or Nigeria-wide names

## License
This project is licensed under the MIT License - see the LICENSE file for details.
Contributing
Contributions are welcome! Please feel free to submit a Pull Request.