// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract SendEth {
    function sendViaCall(address payable _to) public payable {
        (bool sent, bytes memory data) = _to.call{value: 123}("");
        require(sent, "Failed when sending ether");
    }
}
