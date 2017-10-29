const PlayBetsToken = artifacts.require("./PlayBetsToken.sol");
const _1ether = 1000000000000000000;

contract('PlayBetsToken', function(accounts) {
    it("should put 300 000 000 PlayBetsToken in the first account", function() {
      return PlayBetsToken.deployed().then(function(instance) {
        return instance.balanceOf.call(accounts[0]);
      }).then(function(balance) {
        assert.equal(balance.valueOf(), 300 * 1000000 * _1ether, "300 000 000 wasn't in the first account");
      });
    });

    it ("should send coins correctly", function () {
        var acc1 = accounts[0];
        var acc2 = accounts[1];

        var amount = 100;

        var plt;
        var acc1balance1;
        var acc2balance1;
        var acc1balance2;
        var acc2balance2;

        return PlayBetsToken.deployed().then(function (inst) {
            plt = inst;
            return plt.balanceOf.call(acc1);
        }).then(function (balance) {
            acc1balance1 = balance.toNumber();
            return plt.balanceOf.call(acc2);
        }).then(function (balance) {
            acc2balance1 = balance.toNumber();
            return plt.transfer(acc2, amount, {from: acc1});
        }).then(function () {
            return plt.balanceOf.call(acc1);
        }).then(function (balance) {
            acc1balance2 = balance.toNumber();
            return plt.balanceOf.call(acc2);
        }).then(function (balance) {
            acc2balance2 = balance.toNumber();

            assert.equal(acc1balance2, acc1balance1 - amount, "Amount wasn't correctly taken from the sender");
            assert.equal(acc2balance2, acc2balance1 + amount, "Amount wasn't correctly sent to the receiver");
        })
    });
});
