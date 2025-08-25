# Token Vesting Smart Contract Suite

A comprehensive decentralized token streaming and vesting service built for HyperEVM, supporting both ERC20 tokens and native HYPE with flexible stream management and cost-efficient deployment.

## Features

- ✅ **ERC20 & Native HYPE support** – Stream either fungible tokens or chain-native currency
- ✅ **Multiple streams per user** – One beneficiary can have multiple active schedules
- ✅ **Merkle-proof based streams** – Bulk vesting with lightweight claims
- ✅ **Editable & Cancelable streams** – Owners can modify or revoke allocations
- ✅ **ERC20 allocation tokens** – Streams mint transferable ERC20 "vesting shares," making allocations composable with other DeFi protocols
- ✅ **Minimal Proxy Clones (EIP-1167)** – Every new stream is a cheap clone deployed by the factory, minimizing gas and storage costs

## Architecture Overview

The system consists of three core contracts:

### VestingFactory
- Entry point for deploying vesting contracts
- Uses minimal proxy clones (EIP-1167) for gas-efficient deployments
- Supports multiple streams per user (both ERC20 and native HYPE)

### TokenVesting
- Manages linear vesting schedules with optional cliffs
- Supports editable and cancelable streams
- Mints an ERC20 "allocation token" to represent the beneficiary's claimable allocation, making streams composable with other DeFi protocols

### TokenVestingMerkle
- Optimized for bulk vesting distributions
- Stores a Merkle root of vesting schedules, allowing beneficiaries to prove and claim allocations with a Merkle proof
- Shares the same features as TokenVesting (linear release, cliff, cancelation), but for many users at once

## Repository Structure

### Contracts (`src/`)
- `Token.sol` — Simple ERC-20 token for testing and local development
- `TokenVesting.sol` — Single-beneficiary vesting contract with linear release and optional cliff
- `TokenVestingMerkle.sol` — Merkle-root-based vesting/claim contract for bulk distributions
- `VestingFactory.sol` — Factory that deploys vesting contracts using clones

### Scripts (`script/`)
- `Token.s.sol` — Deploy the test token
- `TokenVesting.s.sol` — Deploy and exercise a `TokenVesting` instance
- `ClaimVesting.s.sol` — Example claim flow demonstration
- `VestingFactory.s.sol` — Factory deployment for mainnet/testnet
- `VestingFactoryLocal.s.sol` — Factory deployment for local demos

### Tests (`test/`)
- `TokenVesting.t.sol` — Unit tests for single-beneficiary vesting
- `TokenVestingMerkle.t.sol` — Tests for Merkle claims and edge cases

## Quick Start

### Prerequisites
- Install [Foundry](https://book.getfoundry.sh/) (forge, cast, anvil)
- POSIX shell (bash), curl, and Git

### Local Development

1. **Start a local node:**
   ```bash
   anvil
   ```

2. **Build and test in a separate terminal:**
   ```bash
   forge build
   forge test
   ```

3. **Deploy to local Anvil node:**
   ```bash
   # Replace <ANVIL_KEY> with a private key from Anvil output
   forge script script/Token.s.sol:TokenScript --rpc-url http://127.0.0.1:8545 --private-key <ANVIL_KEY> --broadcast

   forge script script/VestingFactoryLocal.s.sol:VestingFactoryLocalScript --rpc-url http://127.0.0.1:8545 --private-key <ANVIL_KEY> --broadcast
   ```

## Usage Examples

### Single Vesting (ERC20)
```solidity
vestingFactory.createVesting(
    tokenAddress,      // ERC20 token address
    beneficiary,       // Beneficiary address
    block.timestamp,   // Start time
    30 days,          // Cliff period
    365 days,         // Total duration
    1000 ether        // Total allocation
);
```

### Single Vesting (Native HYPE)
```solidity
vestingFactory.createVesting{value: 100 ether}(
    address(0),       // Native HYPE marker
    beneficiary,      // Beneficiary address
    block.timestamp,  // Start time
    90 days,         // Cliff period
    730 days,        // Total duration
    100 ether        // Total allocation
);
```

### Merkle Vesting (Bulk Distribution)
```solidity
// Deploy merkle vesting contract
vestingFactory.createMerkleVesting(
    tokenAddress,
    merkleRoot,
    block.timestamp,
    90 days,         // Cliff period
    730 days         // Total duration
);

// Beneficiary claims their allocation
tokenVestingMerkle.claim(beneficiary, allocation, proof);
```

## Interacting with Contracts

### Using Cast Commands

**Read token balance:**
```bash
cast call <token_address> "balanceOf(address)" <address> --rpc-url http://127.0.0.1:8545
```

**Send transaction (approve example):**
```bash
cast send --from <from_address> --private-key <ANVIL_KEY> <token_address> "approve(address,uint256)" <spender_address> <amount> --rpc-url http://127.0.0.1:8545
```

**Call vesting view method:**
```bash
cast call <vesting_address> "getVestingSchedule(address)" <beneficiary> --rpc-url http://127.0.0.1:8545
```

## Testing

**Run all tests:**
```bash
forge test
```

**Run specific test file:**
```bash
forge test --match-path test/TokenVesting.t.sol
```

**Run tests matching pattern:**
```bash
forge test --match-test "testClaim*"
```

**Verbose test output:**
```bash
forge test --match-test "<test_name>" -vv
```

## Deployment

### Testnet/Mainnet Deployment

1. Configure your RPC provider (Alchemy, Infura, etc.)
2. Ensure your deployer account is funded
3. Run deployment scripts with verification (optional)

```bash
forge script script/VestingFactory.s.sol:VestingFactoryScript \
    --rpc-url https://your-rpc-endpoint \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --broadcast \
    --verify
```

## Project Layout

```
├── src/                 # Solidity contracts
├── script/             # Foundry deployment and demo scripts
├── test/               # Solidity tests
├── broadcast/          # Forge script broadcast outputs
└── lib/                # External dependencies (OpenZeppelin, forge-std, etc.)
```

## Contributing

1. Follow existing code style and patterns
2. Add comprehensive tests for new features
3. Run `forge test` locally before submitting
4. Keep deployment scripts idempotent
5. Document any side effects or breaking changes

## Troubleshooting

**Script broadcast failures:**
- Check `broadcast/` directory for partial outputs
- Verify RPC node connectivity and transaction status
- Ensure deployer account has sufficient funds

**Test failures:**
- Run with verbose flags (`-v`, `-vv`, `-vvv`) for detailed output
- Check for proper contract state setup in test fixtures

## License

See the repository license or individual license headers in `src/` files.

---

For additional examples and advanced usage patterns, refer to the scripts in the `script/` directory.