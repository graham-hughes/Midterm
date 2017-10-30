'use strict';

/* Add the dependencies you're testing */
const Crowdsale = artifacts.require("./Crowdsale.sol");
const Token = artifacts.require("./Token.sol");
// YOUR CODE HERE
// var Web3 = require('web3');
// var web3 = new Web3();
// web3.setProvider(new web3.providers.HttpProvider("http://localhost:8545"));

contract('crowdsaleTest', function(accounts) {
	/* Define your constant variables and instantiate constantly changing
	 * ones
	 */
	const args = {_zero: 0};
	let crowdsale;
	// YOUR CODE HERE
	let owner;

	function sleep(milliseconds) {
 		var start = new Date().getTime();
		for (var i = 0; i < 1e7; i++) {
    		if ((new Date().getTime() - start) > milliseconds){
      			break;
    		}
  		}
	}
	/* Do something before every `describe` method */
	beforeEach(async function() {
		// deploy new token to use with 100 coin initial supply
		owner = accounts[0];
		crowdsale = await Crowdsale.new(Math.pow(10,20), 30000, 1, 1, { from:  owner});
	});

	/* Group test cases together
	 * Make sure to provide descriptive strings for method arguements and
	 * assert statements
	 */
	describe('--Instantiation--', function() {
		it("The newly instantiated crowdsale should have zero tokens sold", async function() {
			let tokensSold = await crowdsale.tokensSold.call();

			assert.equal(tokensSold, 0, "Crowdsale starts with zero tokens");
		});
		it("The end time should be 30 minutes after the start time", async function() {
			let start_time = await crowdsale.start_time.call();
			let end_time = await crowdsale.end_time.call();

			assert.equal(start_time, end_time - (1*60), "The start and end times are correct");
		});
		it("oneWeiValue should be set to 1", async function() {
			let oneWeiValue = await crowdsale.oneWeiValue.call();

			assert.equal(oneWeiValue,1, "The token value of a wei is set correctly" );
		});
	});

	describe('--Minting and Burning money--', function() {
		it("The owner should be able to mint and burn tokens", async function() {
			let supplyTokens = await crowdsale.getTotalSupply();
			await crowdsale.burnTokens(Math.pow(10,20), {from: owner});
			let supplyAfterBurn = await crowdsale.getTotalSupply();
			await crowdsale.mintTokens(10000, {from: owner});
			let supplyAfterMint = await crowdsale.getTotalSupply();

			assert.equal(supplyAfterBurn, 0, "The supply after burning is 0");
			assert.equal(supplyAfterMint, 10000, "The supply after minting is 10000");
		});
	});

	describe('--Queueing, Transferring--', function() {
		it("Any address should be able to enqueue themselves", async function() {
			await crowdsale.enqueueBuyer({from: accounts[1]});
			let qsize = await crowdsale.getQSize();
			assert.equal(qsize, 1, "Correct queue size of 1");
			await crowdsale.enqueueBuyer({from: accounts[2]});
			let qsize2 = await crowdsale.getQSize();
			let firstBuyer = await crowdsale.getFirstBuyer();
			assert.equal(qsize2, 2, "Correct queue size of 2");
			assert.equal(firstBuyer, accounts[1], "Correct first buyer");
		});
		it("The first buyer should be able to purchase tokens", async function() {
			await crowdsale.enqueueBuyer({from: accounts[1]});
			await crowdsale.enqueueBuyer({from: accounts[2]});
			await crowdsale.buyTokens({from: accounts[1], value: 1});
			let tokensSold = await crowdsale.tokensSold.call();
			let tokenBalance = await crowdsale.getTokenBalance(accounts[1]);
			let qsize = await crowdsale.getQSize();
			let firstBuyer = await crowdsale.getFirstBuyer();

			assert.equal(tokensSold, 1, "Correct tokens Sold value");
			assert.equal(tokenBalance, 1, "Balance of account 1 is correct");
			assert.equal(qsize, 1, "Correct q size after purchase");
			assert.equal(firstBuyer, accounts[2], "Correct first buyer");
		});
	});

	describe('--Refunding--', function() {
		it("The buyer should be able refund their money during sale period", async function() {
			await crowdsale.enqueueBuyer({from: accounts[1]});
			await crowdsale.enqueueBuyer({from: accounts[2]});
			await crowdsale.buyTokens({from: accounts[1], value: 2});
			await crowdsale.refundTokens(1, {from:accounts[1]});
			let tokensSold = await crowdsale.tokensSold.call();
			let tokenBalance = await crowdsale.getTokenBalance(accounts[1]);

			assert.equal(tokensSold, 1, "Correct value of tokens sold");
			assert.equal(tokenBalance, 1, "Balance of account 1 is correct");
		});
		it("The buyer should be able refund all of their", async function() {
			await crowdsale.enqueueBuyer({from: accounts[1]});
			await crowdsale.enqueueBuyer({from: accounts[2]});
			await crowdsale.buyTokens({from: accounts[1], value: 1});
			await crowdsale.refundAll({from:accounts[1]});
			let tokensSold = await crowdsale.tokensSold.call();
			let tokenBalance = await crowdsale.getTokenBalance(accounts[1]);

			assert.equal(tokensSold, 0, "Correct 0 tokens sold");
			assert.equal(tokenBalance, 0, "Balance of account 1 is correct");
		});
	});
});
