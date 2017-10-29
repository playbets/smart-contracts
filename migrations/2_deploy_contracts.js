var PlayBetsToken = artifacts.require("./PlayBetsToken.sol");

module.exports = function(deployer) {
  deployer.deploy(PlayBetsToken);
};
