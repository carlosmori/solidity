// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ReceiveEth {
    event Log(uint256 gas);

    receive() external payable {}

    fallback() external payable {
        emit Log(gasleft());
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
