'use strict';

/* Add the dependencies you're testing */
const Token = artifacts.require("./Token.sol");
// YOUR CODE HERE
var Web3 = require('web3');
var web3 = new Web3();
web3.setProvider(new web3.providers.HttpProvider("http://localhost:8545"));

contract('tokenTest', function(accounts) {
	/* Define your constant variables and instantiate constantly changing 
	 * ones
	 */
	const args = {_zero: 0};
	let token;
	// YOUR CODE HERE

	/* Do something before every `describe` method */
	beforeEach(async function() {
		// deploy new token to use with 100 coin initial supply
		token = await Token.new(100, { from: accounts[0] });
	});

	/* Group test cases together 
	 * Make sure to provide descriptive strings for method arguements and
	 * assert statements
	 */
	describe('--Instantiation--', function() {
		it("The newly instantiated token should have 100 coin supply", async function() {
			let totalSupply = await token.totalSupply.call();

			let isEmpty = await queue.empty.call();
			assert.equal(totalSupply, 100, "Newly instantiated token has correct supply");
		});
		it("The balanceOf the creator should be 100, the initial coin supply", async function() {
			let balanceCreator = await token.balanceOf(accounts[0]);

			let isEmpty = await queue.empty.call();
			assert.equal(totalSupply, 100, "Creator of token has correct balance");
		});
	});
});
