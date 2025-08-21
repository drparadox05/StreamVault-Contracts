pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../src/TokenVestingMerkle.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClaimVestingScript is Script {
    function run() external {
        uint256 beneficiary1PrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        address beneficiary1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        address vestingMerkleAddress = 0x75537828f2ce51be7289709686A69CbFDbB714F1;
        address tokenAddress = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;

        bytes32 proof1 = 0x0248ce282036cd192f60c1fb9da8350ec178af2a3c98a430cd4c27c360e94f57;
        uint256 start = 1755695596;

        uint256 cliff = 300;
        uint256 duration = 604800;
        uint256 slicePeriodSeconds = 60;
        bool revokable = true;
        uint256 amount = 1000 * 1e18;

        vm.startBroadcast(beneficiary1PrivateKey);

        TokenVestingMerkle vesting = TokenVestingMerkle(
            payable(vestingMerkleAddress)
        );
        IERC20 token = IERC20(tokenAddress);

        // Check balance before claiming
        {
            uint256 balanceBefore = token.balanceOf(beneficiary1);
            console.log("Token balance before claim:", balanceBefore);
        }

        bytes32[] memory proofArray = new bytes32[](1);
        proofArray[0] = proof1;

        vesting.claimSchedule(
            proofArray,
            start,
            cliff,
            duration,
            slicePeriodSeconds,
            revokable,
            amount
        );

        // Check balance after claiming
        {
            uint256 balanceAfter = token.balanceOf(beneficiary1);
            console.log("Token balance after claim:", balanceAfter);
        }

        vm.stopBroadcast();
    }
}
