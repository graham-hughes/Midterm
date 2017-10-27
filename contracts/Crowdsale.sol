pragma solidity ^0.4.15;

import './Queue.sol';
import './Token.sol';

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

    Event Transfer(address from, address to, uint256 amount);
    Event Refund(address refunded, uint256 amount);
    Event EndSale(); //end of the sale when now >=end_time

    modifier timeCheck() {
        if (now >= end_time) {
            EndSale();
        }
        else  {
            _;
        }
    }

    modifier ownerOnly() {
        if (msg.sender == owner) {
            _;
        } else {
            revert();
        }
    }

    modifier buyable() {
        // will first check queue to potentially dequeue first in line
        buyerQueue.checkTime();
        if (buyerQueue.qsize() > 1) && (buyerQueue.getFirst()==msg.sender) {
            _;
        } else {
            revert();
        }
    }

    modifier checkTokens() {
        if  (msg.value*oneWeiValue + tokensSold > tokenReward.totalSupply) {
            revert()
        } else {
            _;
        }
    }

    /* Constructor */
    function Crowdsale(uint256 _initialSupply, uint _queueLimit, uint _durationInMinutes, uint256 _valueOneWei) {
        owner = msg.sender;
        tokenReward = new Token(_initialSupply);
        Queue = new Queue(_queueLimit);
        start_time = now;
        end_time = start_time + (_durationInMinutes * 1 minutes);
        oneWeiValue = _valueOneWei;
        tokensSold = 0;
    }

    function mintTokens(uint256 _newTokensAmount) ownerOnly {

    }

    function burnTokens(uint256 _burnTokenAmout) ownerOnly {

    }

    function external enqueueBuyer() timeCheck {
        buyerQueue.checkTime();
        buyerQueue.enqueue(msg.sender);
    }

    function external buyTokens() timeCheck, buyable, checkTokens{

    }

    function external refundTokens(uint256 _amountRefund) timeCheck {

    }

    /* refunds the user all tokens and wei */
    function external refundAll() timeCheck {

    }

    function() payable {
        revert();
    }
}
