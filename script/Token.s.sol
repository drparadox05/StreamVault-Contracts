// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../src/Token.sol";

contract DeployToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        string memory name = "USDC";
        string memory symbol = "USDC";
        uint8 decimals_ = 18;
        uint256 initialSupply = 1_000_000 ether;

        Token token = new Token(name, symbol, decimals_, initialSupply);

        console.log("Token deployed at:", address(token));
        vm.stopBroadcast();
    }
}
