pragma solidity ^0.4.15;

import './interfaces/ERC20Interface.sol';

/**
 * @title Token
 * @dev Contract that implements ERC20 token standard
 * Is deployed by `Crowdsale.sol`, keeps track of balances, etc.
 */

contract Token is ERC20Interface {
    /// total amount of tokens
    uint256 public totalSupply;
    // Owner of token contract
    address public owner;

    // Maps account addresses to balances
    mapping(address => uint256) balances;
    // Maps account addresses to other accounts and their corresponding allowances
    mapping(address => mapping(address => uint256)) allowances;
    
    modifier isOwner() {
    	require(msg.sender == owner);
    	_;
    }

    // Constructor
    function Token(uint256 _totalSupply) {
    	owner = msg.sender;
    	totalSupply = _totalSupply;
    	balances[owner] = _totalSupply;
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {
    	return balances[_owner];
    }

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {
    	// Check senders balance, make sure transfer is positive and doesn't cause overflow
    	if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
    		// Remove sent value from senders account first, then apply to receivers account (prevent reentrancy)
    		balances[msg.sender] -= _value;
    		balances[_to] += _value;
    		// Trigger transfer event
    		Transfer(msg.sender, _to, _value); 
    		return true;
    	}
    	// Return false if sender lacks adequate balance
    	return false;
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    	// Checks allowance and from balance has enough value, checks value positive and for overflow
    	if (allowances[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
    		// Removes value from allowance and balance, then transfers to _to
    		allowances[_from][msg.sender] -= _value;
    		balances[_from] -= _value;
    		balances[_to] += _value;
			// Triggers transfer event
			Transfer(_from, _to, _value); 
    		return true;
    	}
    	return false;
    }

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {
    	// Need to allow approver to remove approval, so this method directly sets value instead of adding to it
    	allowances[msg.sender][_spender] = value;
    	Approval(msg.sender, _spender, _value);
    	return true;
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    	return allowances[_owner][_spender];
    }

    /// @notice burn `_value` token from `msg.sender`
    /// @param _value The amount of token to be burned
    /// @return Whether the burn was successful or not
    function burn(uint256 _value) returns (bool success) {
    	// Check senders balance, make sure burn is positive and doesn't cause underflow in balance or supply
    	if (balances[msg.sender] >= _value && _value > 0 && balances[msg.sender] - _value < balances[msg.sender] && totalSupply - _value < totalSupply) {
    		// Remove burned value from senders account
    		balances[msg.sender] -= _value;
    		// Remove burned tokens from supply
    		totalSupply -= _value;
    		// Trigger burn event
    		Burn(msg.sender, _value); 
    		return true;
    	}
    	// Return false if sender lacks adequate balance to burn _value
    	return false;
    }

    /// @notice mint `_value` token to owner
    /// @param _value The amount of token to be minted
    /// @return Whether the mint was successful or not
    function mint(uint256 _value) returns (bool success) isOwner() {
    	// Prevents minting from overflowing totalSupply
    	if (_totalSupply + _value > totalSupply) {
    		// Adds minted value to owners account
    		balances[owner] += _value;
    		// Adds minted tokens to supply
    		totalSupply += _value;
    		return true;
    	}
    	// Return false if minting would overflow totalSupply
    	return false;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);}
    event Burn(address indexed _owner, uint256 _value);}

