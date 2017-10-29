const PlayBetsTokenSaleMock = artifacts.require("./PlayBetsTokenSaleMock.sol");
const PlayBetsToken = artifacts.require("./PlayBetsToken.sol");

const gasPrice = 100000000000;
const _1ether = 1000000000000000000;
const _1hour = 60 * 60;

const period3hours = 1;
const period3hours2 = 2;
const periodDay = 12;
const periodWeek = 72;
const periodWeekLast = 72 + 24 * 7;

const periodAfterLastWeek = 72 + 24 * 14;

contract('PlayBetsTokenSale', function(accounts) {
	it('should give +20% for the first 3 hours', async () => {
		await testTokensPerPeriod(accounts, 12000, period3hours);
	});
	it('should give +15% for the first day', async () => {
		await testTokensPerPeriod(accounts, 11500, periodDay);
	});
	it('should give +10% for the first week', async () => {
		await testTokensPerPeriod(accounts, 11000, periodWeek);
	});
	it('should give no discount the last week', async () => {
		await testTokensPerPeriod(accounts, 10000, periodWeekLast);
	}); 
	it('should give correct statistics during sale', async () => {
		const acc0 = accounts[0];
		const acc1 = accounts[1];

		const acc2 = accounts[3];
		const acc3 = accounts[4];
		const acc4 = accounts[5];

		const startDate = 1510876800;

		const {token, sale} = await initContracts(acc1, startDate);

		await token.transfer(sale.address, 3600000 * _1ether, {from: acc0});

		let tokens = 12000;
		let totalEther = 1;
		await testStatistics(sale, acc2, tokens, 1, totalEther, startDate + _1hour * period3hours, 1);

		tokens += 4 * 12000;
		totalEther += 4;
		await testStatistics(sale, acc3, tokens, 4, totalEther, startDate + _1hour * period3hours2, 2);

		tokens += 3 * 11000;
		totalEther += 3;
		await testStatistics(sale, acc3, tokens, 3, totalEther, startDate + _1hour * periodWeek, 2);

		tokens += 40 * 10000;
		totalEther += 40;
		await testStatistics(sale, acc4, tokens, 40, totalEther, startDate + _1hour * periodWeekLast, 3);

	});
	it('should make refund if soft cap is not reached', async () => {
		const acc0 = accounts[0];
		const acc1 = accounts[1];
		const acc2 = accounts[6];

		const startDate = 1510876800;

		const {token, sale} = await initContracts(acc1, startDate);

		await token.transfer(sale.address, 3600000 * _1ether, {from: acc0});

		await sale.changeTime(startDate + _1hour * periodDay);

		const ether = 11;
		const tx1 = await sale.sendTransaction({from: acc2, value: _1ether * ether});
		const tx1cost = tx1.receipt.gasUsed * gasPrice;

		await sale.changeTime(startDate + _1hour * periodAfterLastWeek, {from: acc0});

		const weiBeforeRefund = (await web3.eth.getBalance(acc2)).toNumber();

		const tx2 = await sale.refund({from: acc2});
		const tx2cost = tx2.receipt.gasUsed * gasPrice;

		const weiAfterRefund = (await web3.eth.getBalance(acc2)).toNumber();

		assert.equal(weiAfterRefund, weiBeforeRefund + _1ether * ether - tx2cost, "Balance after refund not equal to balance before payment");

		await expectThrow(sale.refund({from: acc2}), "Forbidden to refund more than one time");

		await expectThrow(sale.refund({from: acc0}), "Forbidden to refund if account didn't pay");
	});
	it('should finish sale if soft cap reached', async () => {
		const acc0 = accounts[0];
		const acc1 = accounts[1];

		const acc2 = accounts[7];
		const acc3 = accounts[8];
		const acc4 = accounts[9];

		const startDate = 1510876800;

		const {token, sale} = await initContracts(acc1, startDate);

		await token.transfer(sale.address, 3600000 * _1ether, {from: acc0});

		await expectThrow(sale.finishCrowdsale(), "Forbidden to finish sale if soft cap isn't reached");

		await sale.changeTime(startDate + _1hour * period3hours);
		await sale.sendTransaction({from: acc2, value: _1ether * 25});

		await sale.changeTime(startDate + _1hour * period3hours2);
		await sale.sendTransaction({from: acc4, value: _1ether * 25});

		await sale.changeTime(startDate + _1hour * periodDay);
		await sale.sendTransaction({from: acc3, value: _1ether * 25});

		await sale.changeTime(startDate + _1hour * periodWeekLast);
		await sale.sendTransaction({from: acc4, value: _1ether * 25});

		const weiBeforeFinish = (await web3.eth.getBalance(acc1)).toNumber();
		await sale.finishCrowdsale();
		const weiAfterFinish = (await web3.eth.getBalance(acc1)).toNumber();

		assert.equal(weiAfterFinish, weiBeforeFinish + _1ether * 100, "Balance after sale finished not equal to balance before payment + ether raised");

		const tokens1 = (await token.balanceOf.call(acc2)).toNumber();
		const target1 = 25 * 12000 * _1ether;
		assert.equal(tokens1, target1, "Token amount of acc2 not equal to " + target1);

		const tokens2 = (await token.balanceOf.call(acc3)).toNumber();
		const target2 = 25 * 11500 * _1ether;
		assert.equal(tokens2, target2, "Token amount of acc3 not equal to " + target2);

		const tokens3 = (await token.balanceOf.call(acc4)).toNumber();
		const target3 = 25 * (12000 + 10000) * _1ether;
		assert.equal(tokens3, target3, "Token amount of acc4 not equal to " + target3);
	});
});

async function initContracts (beneficiary, startDate) {
	const token = await PlayBetsToken.new();
	const sale = await PlayBetsTokenSaleMock.new(token.address, beneficiary, 10000, 90 * _1ether, 300 * _1ether, startDate, 14);

	return {token, sale};
};

async function testTokensPerPeriod(accounts, tokens, period) {
		const acc0 = accounts[0];
		const acc1 = accounts[1];
		const acc2 = accounts[2];

		const startDate = 1510876800;

		const {token, sale} = await initContracts(acc1, startDate);

		await token.transfer(sale.address, 3600000 * _1ether, {from: acc0});

		await sale.changeTime(startDate + _1hour * period);

		await sale.sendTransaction({from: acc2, value: _1ether});

		const weiAmount = await sale.weiBalances.call(acc2);
		const tokenAmount = await sale.tokenBalances.call(acc2);
		const investors = await sale.investorCount.call();

		assert.equal(weiAmount.toNumber(), _1ether, "Wei amount not equal to payed amount");
		assert.equal(tokenAmount.toNumber(), tokens * _1ether, "Token amount not equal to " + tokens);
		assert.equal(investors.toNumber(), 1, "Investors number must be 1");
};

async function testStatistics(sale, acc, tokens, ether, totalEther, time, investorsCount) {
		await sale.changeTime(time);
		await sale.sendTransaction({from: acc, value: _1ether * ether});

		const weiRaised = await sale.weiRaised.call();
		const tokensSold = await sale.tokensSold.call();
		const investors = await sale.investorCount.call();

		assert.equal(weiRaised.toNumber(), totalEther * _1ether, "weiRaised not equal to payed amount");
		assert.equal(tokensSold.toNumber(), tokens * _1ether, "tokensSold not equal to sold amount");
		assert.equal(investors.toNumber(), investorsCount, "investorCount must be " + investorsCount);

};

async function expectThrow(promise, comment) {
	try {
		await promise;
	} catch (error) {
		return;
	}

	assert.fail(comment);
}