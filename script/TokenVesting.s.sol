// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../src/TokenVesting.sol";

contract DeployTokenVesting is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address token = 0xd3744684A2b11296Be8DcE34f67aaA16Bc1C4B3b;
        TokenVesting vesting = new TokenVesting();

        console.log("TokenVesting deployed at:", address(vesting));
        vm.stopBroadcast();
    }
}

