// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "forge-std/Script.sol";
import "../src/TokenVesting.sol";
import "../src/VestingFactory.sol";
import "../src/TokenVestingMerkle.sol";
import "../src/Token.sol";

contract VestingFactoryLocal is Script {
    function run() external {
        // Use anvil's first default account which has the most ETH
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        
        vm.startBroadcast(deployerPrivateKey);

        TokenVesting vestingImpl = new TokenVesting();
        console.log(
            "TokenVesting implementation deployed at:",
            address(vestingImpl)
        );

        TokenVestingMerkle vestingMerkleImpl = new TokenVestingMerkle();
        console.log(
            "TokenVestingMerkle implementation deployed at:",
            address(vestingMerkleImpl)
        );

        VestingFactory factory = new VestingFactory(
            address(vestingImpl),
            address(vestingMerkleImpl)
        );
        console.log("VestingFactory deployed at:", address(factory));

        // Deploy test token with larger supply for local testing
        address tokenAddr = address(
            new Token("VirtualToken", "VT", 18, 10_000_000 * 1e18)
        );
        IERC20Metadata token = IERC20Metadata(tokenAddr);
        console.log("Test token deployed at:", tokenAddr);

        // Deploy and setup merkle vesting
        _deployMerkleVesting(factory, token);

        vm.stopBroadcast();
    }

    function _deployMerkleVesting(VestingFactory factory, IERC20Metadata token) internal {
        // Define addresses
        address newOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address beneficiary1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address beneficiary2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

        // Fund amounts for each beneficiary
        uint256 amount1 = 1000 * 1e18;
        uint256 amount2 = 500 * 1e18;
        uint256 totalFunding = amount1 + amount2;

        // Transfer tokens and approve factory
        token.transfer(msg.sender, totalFunding * 2);
        token.approve(address(factory), totalFunding);

        // Create merkle tree data
        (bytes32 merkleRoot, bytes32 leaf1, bytes32 leaf2) = _createMerkleTree(
            beneficiary1, beneficiary2, amount1, amount2
        );

        // Deploy contract
        address vestingMerkleClone = factory.deployTokenVestingMerkle(
            token,
            "VestedVirtualToken",
            "VVT",
            merkleRoot,
            newOwner,
            totalFunding
        );

        _logResults(vestingMerkleClone, beneficiary1, beneficiary2, leaf1, leaf2, merkleRoot, amount1, amount2);
    }

    function _createMerkleTree(
        address beneficiary1,
        address beneficiary2, 
        uint256 amount1,
        uint256 amount2
    ) internal view returns (bytes32 merkleRoot, bytes32 leaf1, bytes32 leaf2) {
        uint256 startTime = block.timestamp + 120;
        uint256 cliffDuration = 60;
        uint256 vestingDuration = 604800;
        uint256 slicePeriod = 60;
        bool revokable = true;

        leaf1 = keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(beneficiary1, startTime, cliffDuration, vestingDuration, slicePeriod, revokable, amount1)
                )
            )
        );
        console.log("Start time:", startTime);
        console.log("Amount1:", amount1);

        leaf2 = keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(beneficiary2, startTime, cliffDuration, vestingDuration, slicePeriod, revokable, amount2)
                )
            )
        );
        console.log("Start time:", startTime);
        console.log("Amount1:", amount1);

        if (uint256(leaf1) < uint256(leaf2)) {
            merkleRoot = keccak256(abi.encodePacked(leaf1, leaf2));
        } else {
            merkleRoot = keccak256(abi.encodePacked(leaf2, leaf1));
        }
    }

    function _logResults(
        address vestingMerkleClone,
        address beneficiary1,
        address beneficiary2,
        bytes32 leaf1,
        bytes32 leaf2,
        bytes32 merkleRoot,
        uint256 amount1,
        uint256 amount2
    ) internal {
        console.log("Vesting Merkle clone deployed at:", vestingMerkleClone);
        console.log("=== Merkle Tree Data ===");
        console.log("Beneficiary1:", beneficiary1, "Amount:", amount1);
        console.log("Beneficiary2:", beneficiary2, "Amount:", amount2);
        console.log("Merkle Root:", vm.toString(merkleRoot));
        console.log("Leaf1:", vm.toString(leaf1));
        console.log("Leaf2:", vm.toString(leaf2));

        // Generate merkle proofs for claiming
        bytes32 proof1 = uint256(leaf1) < uint256(leaf2) ? leaf2 : leaf1;
        bytes32 proof2 = uint256(leaf1) < uint256(leaf2) ? leaf1 : leaf2;

        console.log("=== Claiming Instructions ===");
        console.log("Proof for beneficiary1:", vm.toString(proof1));
        console.log("Proof for beneficiary2:", vm.toString(proof2));
        console.log("");
        console.log("=== Copy this data for your .env file ===");
        console.log("VESTING_MERKLE_ADDRESS=", vm.toString(vestingMerkleClone));
        console.log("MERKLE_ROOT=", vm.toString(merkleRoot));
        console.log("BENEFICIARY1=", vm.toString(beneficiary1));
        console.log("BENEFICIARY2=", vm.toString(beneficiary2));
        console.log("LEAF1=", vm.toString(leaf1));
        console.log("LEAF2=", vm.toString(leaf2));
        console.log("PROOF1=", vm.toString(proof1));
        console.log("PROOF2=", vm.toString(proof2));
    }
}