
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {VulnerableContract} from "./VulnerableContract.sol";

contract Attacker {
    VulnerableContract public contractAddress;
    address public owner;

    constructor(VulnerableContract _contractAddress) payable {
        contractAddress = _contractAddress;
        owner = msg.sender;
    }

    // drain the VulnerableContract
    function attack() external payable {
        // Code me!
    }
}