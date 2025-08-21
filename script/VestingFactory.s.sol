// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "forge-std/Script.sol";
import "../src/TokenVesting.sol";
import "../src/VestingFactory.sol";
import "../src/TokenVestingMerkle.sol";
import "../src/Token.sol";


contract DeployVestingFactory is Script {
    function run() external {
        vm.startBroadcast();

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

        // address tokenAddr = address(
        //     new Token("VirtualToken", "VT", 18, 1_000_000 * 1e18)
        // );
        // IERC20Metadata token = IERC20Metadata(tokenAddr);

        // uint256 fundAmount = 1000 * 1e18;
        // token.transfer(newOwner, 2 * fundAmount);
        // token.approve(address(factory), 2 * fundAmount);

        // address vestingClone = factory.deployTokenVesting(
        //     token,
        //     "VestedVirtualToken",
        //     "VVT",
        //     newOwner,
        //     fundAmount
        // );
        // console.log("Vesting clone deployed at:", vestingClone);

        // address beneficiary1 = 0x3a7bb97697b245aAF5E725065E614B775dB86bc1;
        // address beneficiary2 = 0x77B03F0b9B30b82c1Da0F921FDB561Df2e1906F1;

        // bytes32 leaf = keccak256(
        //     bytes.concat(
        //         keccak256(
        //             abi.encode(
        //                 beneficiary1,
        //                 block.timestamp + 10,
        //                 200,
        //                 7 days,
        //                 60,
        //                 true,
        //                 fundAmount
        //             )
        //         )
        //     )
        // );
        // bytes32 merkleRoot = leaf;
        // console.log("Merkle root:", vm.toString(merkleRoot));

        // address vestingMerkleClone = factory.deployTokenVestingMerkle(
        //     token,
        //     "VestedVirtualToken",
        //     "VVT",
        //     merkleRoot,
        //     newOwner,
        //     fundAmount
        // );
        // console.log("Vesting Merkle clone deployed at:", vestingMerkleClone);

        vm.stopBroadcast();
    }
}
