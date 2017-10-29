pragma solidity 0.4.15;

import './PlayBetsToken.sol';
import './PlayBetsTokenSale.sol';

contract PlayBetsTokenSaleMock is PlayBetsTokenSale {
	uint256 private _now;

	function PlayBetsTokenSaleMock (
        address _tokenAddr,
        address _beneficiary,

        uint256 _tokensPerEth,

        uint256 _softCap,
        uint256 _hardCap,

        uint _startTime,
        uint _duration
    ) PlayBetsTokenSale (_tokenAddr, _beneficiary, _tokensPerEth, _softCap, _hardCap, _startTime, _duration) public {
		_now = _startTime;
    }

    function currentTime() internal constant returns(uint256) {
        return _now;
    }

    function changeTime(uint256 _newTime) external {
    	_now = _newTime;
    }
}