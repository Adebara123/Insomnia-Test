// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface ISablier {
    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256);
}