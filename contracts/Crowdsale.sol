pragma solidity ^0.4.15;

import './Queue.sol';
import './Token.sol';
import './utils/SafeMath.sol';

/**
 * @title Crowdsale
 * @dev Contract that deploys `Token.sol`
 * Is timelocked, manages buyer queue, updates balances on `Token.sol`
 */

contract Crowdsale {
	address public owner;
    Queue public buyerQueue;
    Token private tokenReward;
    uint public start_time;
    uint public end_time;
    uint256 public oneWeiValue;
    uint256 public tokensSold;
    mapping(address => uint256) tokenBalances;
    address[] tokenAddresses;
    bool deployed;

    event tokenPurchase (address transfer, uint256 value);
    event tokenRefund (address refunded, uint256 value);

    modifier timeCheck() {
        require(!deployed);
        require(now<end_time);
        _;
    }

    modifier ownerOnly() {
        require(msg.sender==owner);
        _;
    }

    /* Constructor */
    function Crowdsale(uint256 _initialSupply, uint _queueTimeLimit, uint _durationInMinutes, uint256 _valueOneWei) {
        deployed = false;
        owner = msg.sender;
        tokenReward = new Token(_initialSupply);
        buyerQueue = new Queue(_queueTimeLimit);
        start_time = now;
        end_time = start_time + (_durationInMinutes * 1 minutes);
        oneWeiValue = _valueOneWei;
        tokensSold = 0;
    }

    function getFirstBuyer() constant returns(address) {
        return buyerQueue.getFirst();
    }

    function getQSize() constant returns(uint8) {
        return buyerQueue.qsize();
    }

    function getTotalSupply() constant returns(uint256) {
        return tokenReward.totalSupply();
    }

    function getTokenBalance(address _owner) constant returns(uint256) {
        return tokenBalances[_owner];
    }

    function checkQueueTime() {
        buyerQueue.checkTime();
    }

    function mintTokens(uint256 _mintTokens) ownerOnly returns (bool success) {
        return tokenReward.mint(_mintTokens);
    }

    function burnTokens(uint256 _burnTokens) ownerOnly returns (bool success) {
        require(tokensSold + _burnTokens <= tokenReward.totalSupply());
        return tokenReward.burn(_burnTokens);
    }

    /* checks the queue timer and enqueues the sender if possible */
    function enqueueBuyer() external timeCheck {
        buyerQueue.checkTime();
        buyerQueue.enqueue(msg.sender);
    }

    /* transfers tokens and takes wei based on if the buyer is in the first queue*/
    function buyTokens() external payable timeCheck returns (bool success) {
        // will first check queue to potentially dequeue first in line
        buyerQueue.checkTime();
        if ((buyerQueue.qsize() > 1) && (buyerQueue.getFirst()==msg.sender)) {
            uint256 value = SafeMath.mul(oneWeiValue, msg.value);
            // checks to see if overflow
            if (value+tokensSold <= tokenReward.totalSupply()) {
                tokensSold = SafeMath.add(tokensSold, value);
                tokenBalances[msg.sender] = SafeMath.add(tokenBalances[msg.sender], value);
                tokenAddresses.push(msg.sender);
                tokenPurchase(msg.sender, value);
                buyerQueue.dequeue();
                return true;
            } else {
                revert();
                return false;
            }
        } else {
            return false;
        }
    }

    /* allows user to refund a certain amount of tokens */
    function refundTokens(uint256 _tokenRefund) external timeCheck {
        require(_tokenRefund <= tokenBalances[msg.sender]);
        uint256 weiValue = SafeMath.mul(_tokenRefund, oneWeiValue);
        tokenBalances[msg.sender] -= _tokenRefund;
        tokensSold -= _tokenRefund;
        msg.sender.transfer(weiValue);
        tokenRefund(msg.sender, _tokenRefund);
    }

    /* refunds the user all tokens and wei */
    function refundAll() external timeCheck {
        uint256 _tokenRefund = tokenBalances[msg.sender];
        uint256 weiValue = SafeMath.mul(_tokenRefund, oneWeiValue);
        tokenBalances[msg.sender] -= _tokenRefund;
        tokensSold -= _tokenRefund;
        msg.sender.transfer(weiValue);
        tokenRefund(msg.sender, _tokenRefund);
    }

    /* actually transfers tokens based on mapping if time is after duration */
    function deployTokens() returns (bool success) {
        if (now < end_time || deployed) {
            return false;
        } else {
            deployed = true;
            for (uint i = 0; i < tokenAddresses.length; i++) {
                address tokenAdd = tokenAddresses[i];
                uint256 tokenValue = tokenBalances[tokenAdd];
                tokenBalances[tokenAdd] = 0;
                tokenReward.transfer(tokenAdd, tokenValue);
            }
        }
    }

    /* allows the owner to withdraw funds after end_time is reached. Will return
    false if it is still sale time */
    function withDrawFunds() ownerOnly returns (bool success) {
        if (now>=end_time) {
            owner.transfer(this.balance);
            return true;
        }
        return false;
    }

    function() payable {
        revert();
    }
}
