// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ROSCA is Ownable {
    struct Pool {
        uint256 contributionAmount;
        uint256 roundDuration;
        address[] members;
        mapping(address => bool) hasJoined;
        mapping(address => bool) hasContributed;
        mapping(uint256 => address) roundRecipient;
        uint256 currentRound;
        bool started;
        uint256 lastRoundTimestamp;
    }

    uint256 public poolCount;
    mapping(uint256 => Pool) public pools;

    constructor() Ownable(msg.sender) {}

    function createPool(uint256 _contributionAmount, uint256 _roundDuration) external returns (uint256) {
        poolCount++;
        Pool storage pool = pools[poolCount];
        pool.contributionAmount = _contributionAmount;
        pool.roundDuration = _roundDuration;
        pool.currentRound = 0;
        pool.started = false;
        return poolCount;
    }

    function joinPool(uint256 poolId) external {
        Pool storage pool = pools[poolId];
        require(!pool.hasJoined[msg.sender], "Already joined");
        pool.members.push(msg.sender);
        pool.hasJoined[msg.sender] = true;
    }

    function startPool(uint256 poolId) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(!pool.started, "Already started");
        pool.started = true;
        pool.lastRoundTimestamp = block.timestamp;

        // Assign recipients for each round (round-robin)
        for (uint256 i = 0; i < pool.members.length; i++) {
            pool.roundRecipient[i] = pool.members[i];
        }
    }

    function contribute(uint256 poolId) external payable {
        Pool storage pool = pools[poolId];
        require(pool.started, "Pool not started");
        require(pool.hasJoined[msg.sender], "Not a pool member");
        require(!pool.hasContributed[msg.sender], "Already contributed this round");
        require(msg.value == pool.contributionAmount, "Incorrect contribution amount");

        pool.hasContributed[msg.sender] = true;
    }

    function executeRound(uint256 poolId) external {
        Pool storage pool = pools[poolId];
        require(pool.started, "Pool not started");
        require(block.timestamp >= pool.lastRoundTimestamp + pool.roundDuration, "Round duration not passed");

        // Check all members contributed
        for (uint256 i = 0; i < pool.members.length; i++) {
            require(pool.hasContributed[pool.members[i]], "Not all members contributed");
        }

        uint256 totalAmount = pool.contributionAmount * pool.members.length;
        require(address(this).balance >= totalAmount, "Insufficient funds");

        address recipient = pool.roundRecipient[pool.currentRound];

        // Safe transfer using call
        (bool success, ) = recipient.call{value: totalAmount}("");
        require(success, "Transfer failed");

        // Reset contributions for next round
        for (uint256 i = 0; i < pool.members.length; i++) {
            pool.hasContributed[pool.members[i]] = false;
        }

        pool.currentRound++;
        if (pool.currentRound >= pool.members.length) {
            pool.currentRound = 0;
        }

        pool.lastRoundTimestamp = block.timestamp;
    }

    // Fallback to accept ETH
    receive() external payable {}
}
