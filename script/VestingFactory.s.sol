// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../src/TokenVesting.sol";
import "../src/VestingFactory.sol";
import "../src/TokenVestingMerkle.sol";
import "../src/Token.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract DeployVestingScript is Script {
    function run() external {
        vm.startBroadcast();

        TokenVesting vestingImpl = new TokenVesting();
        console.log("TokenVesting implementation deployed at:", address(vestingImpl));

        TokenVestingMerkle vestingMerkleImpl = new TokenVestingMerkle();
        console.log("TokenVestingMerkle implementation deployed at:", address(vestingMerkleImpl));

        VestingFactory factory = new VestingFactory(
            address(vestingImpl),
            address(vestingMerkleImpl)
        );
        console.log("VestingFactory deployed at:", address(factory));

        address tokenAddr = address(new Token("DummyToken", "DUM", 18, 1_000_000 * 1e18));
        IERC20Metadata token = IERC20Metadata(tokenAddr);

        uint256 fundAmount = 1000 * 1e18;
        token.transfer(msg.sender, fundAmount);
        token.approve(address(factory), fundAmount);

        address newOwner = msg.sender;

        address vestingClone = factory.deployTokenVesting(
            token,
            "VestedDummy",
            "VDUM",
            newOwner,
            fundAmount
        );

        console.log("Vesting clone deployed at:", vestingClone);

        vm.stopBroadcast();
    }
}
