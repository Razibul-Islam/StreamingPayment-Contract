// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StreamingPayment is Ownable, ReentrancyGuard {
    error Streaming__AlreadyProvider();
    error Streaming__AlreadySubscriber();
    error Streaming__NotEnoughBalance();
    error Streaming__NotActive();
    error Streaming__AlreadyActive();
    error Streaming__InvalidInterval();
    error Streaming__InvalidIntervalAmount();

    enum Role {
        Subscriber,
        Provider,
        Admin
    }

    enum SubscriptionStatus {
        Active,
        Inactive
    }

    struct Subscription {
        address subscriptionAddress;
        address providerAddress;
        uint256 amount;
        uint256 totalBalance;
        uint256 intervalDuration;
        uint256 nextPayment;
        SubscriptionStatus status;
    }

    mapping(address => Role) public userRole;
    mapping(address => Subscription) public subscriptions;
    mapping(address => SubscriptionStatus) public subscriptionStatus;
    mapping(address => bool) public subscriptionPerUser;

    event MakeProvider(address user, Role userRole);
    event Subscribed(
        address user,
        address provider,
        uint256 amountPerInterval,
        uint256 totalDiposit,
        uint256 IntervalDuration,
        uint256 startInterval
    );

    uint256 public constant AMOUNT_PER_INTERVAL = 0.0002 ether;
    uint256 public constant AMOUNT_WHEN_BECOME_PROVIDER = 0.0001 ether;

    constructor() Ownable(msg.sender) {
        userRole[msg.sender] = Role.Subscriber;
    }

    function becomeProvider() external payable {
        require(
            userRole[msg.sender] != Role.Provider,
            Streaming__AlreadyProvider()
        );
        require(
            msg.value == AMOUNT_WHEN_BECOME_PROVIDER,
            Streaming__NotEnoughBalance()
        );

        userRole[msg.sender] = Role.Provider;

        emit MakeProvider(msg.sender, Role.Provider);
    }

    function SubscriptionCreate(
        uint256 interval,
        address provider
    ) external payable {
        require(
            subscriptions[msg.sender].status == SubscriptionStatus.Inactive,
            Streaming__AlreadyActive()
        );
        require(interval > 0, Streaming__InvalidInterval());
        require(AMOUNT_PER_INTERVAL > 0, Streaming__InvalidIntervalAmount());
        require(
            msg.value == AMOUNT_PER_INTERVAL * interval,
            Streaming__NotEnoughBalance()
        );
        require(
            !subscriptionPerUser[msg.sender],
            Streaming__AlreadySubscriber()
        );

        subscriptions[msg.sender] = Subscription({
            subscriptionAddress: msg.sender,
            providerAddress: provider,
            amount: AMOUNT_PER_INTERVAL,
            totalBalance: interval * AMOUNT_PER_INTERVAL,
            intervalDuration: interval,
            nextPayment: interval + block.timestamp,
            status: SubscriptionStatus.Active
        });

        emit Subscribed(
            msg.sender,
            provider,
            AMOUNT_PER_INTERVAL,
            interval * AMOUNT_PER_INTERVAL,
            interval,
            block.timestamp
        );
    }
}
