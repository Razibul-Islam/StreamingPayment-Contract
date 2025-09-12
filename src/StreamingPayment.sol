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
    error Streaming__NotProvider();
    error Streaming__ActiveServices();

    enum Role {
        Subscriber,
        Provider,
        Admin
    }

    enum Status {
        Active,
        Inactive
    }

    struct Subscription {
        address userAddress;
        address providerAddress;
        uint256 price;
        uint256 duration;
        uint256 nextPayment;
        Status ServiceStatus;
        Status subcriptionStatus;
    }

    mapping(address => Role) public userRole;
    mapping(address => Subscription) public subscriptions;
    mapping(address => Status) public subscriptionStatus;
    mapping(address => bool) public subscriptionPerUser;
    mapping(address => uint256) public hasActiveSubscriber;

    event MakeProvider(address user, Role userRole);
    event Subscribed(
        address user,
        address provider,
        uint256 amountPerInterval,
        uint256 totalDiposit,
        uint256 IntervalDuration,
        uint256 startInterval
    );
    event ProviderDowngraded(address provider);

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

    function becomeSubscriber() external {
        require(
            userRole[msg.sender] == Role.Provider,
            Streaming__NotProvider()
        );
        // Checking is there have any active service of this provider
        require(
            hasActiveSubscriber[msg.sender] == 0,
            Streaming__ActiveServices()
        );

        userRole[msg.sender] = Role.Subscriber;
        emit ProviderDowngraded(msg.sender);
    }
}
