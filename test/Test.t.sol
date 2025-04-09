// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Attacker} from "../src/Attacker_SOLUTION.sol";
import {VulnerableContract} from "../src/VulnerableContract.sol";
import {RewardToken} from "../src/ERC20.sol";

contract ContractTest is Test {
    VulnerableContract public c;
    Attacker public attacker;
    RewardToken public rewardToken;
    uint256 donationEpochs = 10;
    uint256 donationAmount = 1000e18;
    uint256 rewardPoolAmount = 100e18;

    function setUp() public {
        address owner = makeAddr("owner");
        vm.startPrank(owner);
        // deploy the reward token from the owner account
        rewardToken = new RewardToken("RewardToken", "RT", 18);
        // deploy the vulnerable contract from the owner account
        c = new VulnerableContract(rewardToken, donationEpochs);
        // mint 1000 reward tokens to the donation contract
        rewardToken.mint(address(c), rewardPoolAmount);

        vm.stopPrank();

        attacker = new Attacker(c);

        // fund the contract
        address donator = makeAddr("donator");
        vm.deal(donator, donationAmount);
        vm.prank(donator);
        c.donate{value: donationAmount}(address(attacker));
    }

    // The prewritten tests here should pass
    function testDrain() public {
        uint256 bal = address(c).balance;
        assertGt(bal, 0, "Contract should have a balance before draining");

        address badActor = makeAddr("kju");
        assertEq(c.balanceOf(badActor), 0, "Bad actor should have 0 balance");
        assertEq(badActor.balance, 0, "Bad actor should have 0 balance");

        /////////// insert code here ///////////
        attacker.attack{value: 1 ether}();

        uint256 balAfter = address(c).balance;
        assertEq(balAfter, 0, "Contract should have 0 balance after draining");
    }
}
