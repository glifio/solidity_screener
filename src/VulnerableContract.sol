// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC20} from "./ERC20.sol";

/**
  @title VulnerableContract
  @notice A contract that allows users to contribute ETH to a contract, which entitles them to split a reward pool of tokens
  @notice The contract owner is using this as a fundraising mechanism for a charity
  @dev The contract is meant to allow users to withdraw their donation before the donation period ends, but after the donation period ends, the user should no longer be able to withdraw their eth
  @dev You can assume the contract deployer funds the reward pool by simply transferring the reward token to the contract address
 */
contract VulnerableContract {
    // the total amount of ETH deposited in the contract
    uint256 public totalBalances;
    // the address of the reward token
    ERC20 public rewardToken;
    // the epoch number when donations end and the reward pool is split
    uint256 public donationEndEpoch;
    // the amount of donation each user deposited
    mapping(address => uint256) private balances;

    // modifier that throws an error when the donation period is not open 
    modifier donationPeriodOpen() {
        require(block.number < donationEndEpoch, "Donation period has ended");
        _;
    }

    // modifier that throws an error when the donation period is open 
    modifier donationPeriodClosed() {
        require(block.number >= donationEndEpoch, "Donation period has not ended");
        _;
    }

    constructor(
      // the address of the reward token
      ERC20 _rewardToken,
      // the number of epochs to wait before the reward pool is split
      uint256 _donationEpochs
    ) payable {
      rewardToken = _rewardToken;
      donationEndEpoch = block.number + _donationEpochs;
    }

    /// @notice Allows users to donate to the contract
    function donate(address _to) public payable donationPeriodOpen {
        balances[_to] = balances[_to] + msg.value;
        totalBalances += msg.value;
    }

    /// @notice Allows users to check their balance
    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    /// @notice Allows users to withdraw their balance before the donation period ends
    function withdraw() public donationPeriodOpen {
        // as long as the donation period has not ended, the user can withdraw their balance
        require(block.number < donationEndEpoch, "Donation period has ended");

        if (balances[msg.sender] >= 1) {
            (bool result, ) = msg.sender.call{value: balances[msg.sender]}("");
            if (result) {
                balances[msg.sender];
            }
            balances[msg.sender] = 0;
            totalBalances -= balances[msg.sender];
        }
    }

    /// @notice Allows users to claim a share of the reward pool based on their balance
    function claimShare() public donationPeriodClosed {
        // get the user's donation amount
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "No balance");

        // calculate the share of the reward pool based on the user's donation amount as a total of the total donations
        uint256 share = (userBalance * rewardToken.balanceOf(address(this))) / totalBalances;
        require(share > 0, "Share too small");

        rewardToken.transfer(msg.sender, share);

        // update the total balances and account balances
        totalBalances -= userBalance;
        balances[msg.sender] = 0;
    }


    receive() external payable {}
}