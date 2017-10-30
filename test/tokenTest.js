'use strict';

/* Add the dependencies you're testing */
const Token = artifacts.require("./Token.sol");
// // YOUR CODE HERE
// var Web3 = require('web3');
// var web3 = new Web3();
// web3.setProvider(new web3.providers.HttpProvider("http://localhost:8545"));

contract('tokenTest', function(accounts) {
	/* Define your constant variables and instantiate constantly changing
	 * ones
	 */
	const args = {_zero: 0};
	let token;
	// YOUR CODE HERE
	let owner;

	/* Do something before every `describe` method */
	beforeEach(async function() {
		// deploy new token to use with 100 coin initial supply
		owner = accounts[0];
		token = await Token.new(100, { from:  owner});
	});

	/* Group test cases together
	 * Make sure to provide descriptive strings for method arguements and
	 * assert statements
	 */
	describe('--Instantiation--', function() {
		it("The newly instantiated token should have 100 coin supply", async function() {
			let totalSupply = await token.totalSupply.call();

			assert.equal(totalSupply, 100, "Newly instantiated token has correct supply");
		});
		it("The balanceOf the creator should be 100, the initial coin supply", async function() {
			let balanceCreator = await token.balanceOf(owner);

			assert.equal(balanceCreator, 100, "Creator of token has correct balance");
		});
	});
	describe('--Transferring--', function() {
		it("The owner should be able to transfer entire balance to receiver", async function() {
			await token.transfer(accounts[1], 100, { from: owner} );
			let balanceReceiver = await token.balanceOf(accounts[1]);
			let balanceCreator = await token.balanceOf(owner);

			assert.equal(balanceReceiver.valueOf(), 100, "Receiver of token has correct balance");
			assert.equal(balanceCreator.valueOf(), 0, "Sender of token has correct balance");
		});
	});
	describe('--Burning--', function() {
		it("The owner should be able to burn, reflected in totalSupply and balance", async function() {
			await token.burn(100, { from: owner} );
			let totalSupply = await token.totalSupply.call();
			let balanceCreator = await token.balanceOf(owner);

			assert.equal(totalSupply.valueOf(), 0, "totalSupply now 0");
			assert.equal(balanceCreator.valueOf(), 0, "Sender of token has burned entire balance");
		});
		it("Buyers should be able to burn, reflected in totalSupply and balance", async function() {
			await token.transfer(accounts[1], 50, { from: owner} );
			await token.burn(25, { from: accounts[1]} );
			let totalSupply = await token.totalSupply.call();
			let balanceBuyer = await token.balanceOf(accounts[1]);

			assert.equal(totalSupply.valueOf(), 75, "totalSupply now 75");
			assert.equal(balanceBuyer.valueOf(), 25, "Buyer burned half of balance, 25 left");
		});
	});
	describe('--Minting--', function() {
		it("The owner should be mint coins, reflected in totalSupply and balance", async function() {
			await token.mint(100, { from: owner} );
			let totalSupply = await token.totalSupply.call();
			let balanceCreator = await token.balanceOf(owner);

			assert.equal(totalSupply.valueOf(), 200, "totalSupply now 0");
			assert.equal(balanceCreator.valueOf(), 200, "Sender of token has burned entire balance");
		});
	});
	describe('--Allowances--', function() {
		it("The owner should be able to assign allowance", async function() {
			await token.approve(accounts[1], 100, { from: owner} );
			let allowance = await token.allowance(owner, accounts[1]);

			assert.equal(allowance.valueOf(), 100, "Allowance correct");
		});
		it("The sender should be able to spend allowance, and allowance should decrease", async function() {
			await token.approve(accounts[1], 100, { from: owner} );
			await token.transferFrom(owner, accounts[2], 50, {from : accounts[1]})
			let allowance = await token.allowance(owner, accounts[1]);
			let balanceReceiver = await token.balanceOf(accounts[2]);
			let balanceOwner = await token.balanceOf(owner);

			assert.equal(balanceOwner.valueOf(), 50, "Balance of owner correct");
			assert.equal(balanceReceiver.valueOf(), 50, "Balance of reciever correct");
			assert.equal(allowance.valueOf(), 50, "Allowance after spending correct");
		});
	});
});
