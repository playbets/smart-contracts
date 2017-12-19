pragma solidity 0.4.15;

import './PlayBetsToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract PlayBetsPreSale is Ownable {
    string public constant name = "PlayBets Closed Pre-Sale";

    using SafeMath for uint256;

    PlayBetsToken public token;
    address public beneficiary;

    uint256 public tokensPerEth;

    uint256 public weiRaised = 0;
    uint256 public tokensSold = 0;
    uint256 public investorCount = 0;

    uint public startTime;
    uint public endTime;

    bool public crowdsaleFinished = false;

    event GoalReached(uint256 raised, uint256 tokenAmount);
    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    modifier onlyAfter(uint time) {
        require(currentTime() > time);
        _;
    }

    modifier onlyBefore(uint time) {
        require(currentTime() < time);
        _;
    }

    function PlayBetsPreSale (
        address _tokenAddr,
        address _beneficiary,

        uint256 _tokensPerEth,

        uint _startTime,
        uint _duration
    ) {
        token = PlayBetsToken(_tokenAddr);
        beneficiary = _beneficiary;

        tokensPerEth = _tokensPerEth;

        startTime = _startTime;
        endTime = _startTime + _duration * 1 days;
    }

    function () payable {
        require(msg.value >= 0.01 * 1 ether);
        doPurchase();
    }

    function withdraw(uint256 _value) onlyOwner {
        beneficiary.transfer(_value);
    }

    function finishCrowdsale() onlyOwner {
        token.transfer(beneficiary, token.balanceOf(this));
        crowdsaleFinished = true;
    }

    function doPurchase() private onlyAfter(startTime) onlyBefore(endTime) {
        
        require(!crowdsaleFinished);
        require(msg.sender != address(0));

        uint256[5] memory _bonusPattern = [ uint256(120), 115, 110, 105, 100];
        uint[4] memory _periodPattern = [ uint(24), 24 * 2, 24 * 7, 24 * 14];

        uint256 tokenCount = tokensPerEth * msg.value;

        uint calcPeriod = startTime;
        uint prevPeriod = 0;
        uint256 _now = currentTime();

        for(uint8 i = 0; i < _periodPattern.length; ++i) {
            calcPeriod = startTime.add(_periodPattern[i] * 1 hours);

            if (prevPeriod < _now && _now <= calcPeriod) {
                tokenCount = tokenCount.mul(_bonusPattern[i]).div(100);
                break;
            }
            prevPeriod = calcPeriod;
        }

        uint256 _wei = msg.value;
        uint256 _availableTokens = token.balanceOf(this);

        if (_availableTokens < tokenCount) {
          uint256 expectingTokenCount = tokenCount;
          tokenCount = _availableTokens;
          _wei = msg.value.mul(tokenCount).div(expectingTokenCount);
          msg.sender.transfer(msg.value.sub(_wei));
        }

        if (token.balanceOf(msg.sender) == 0) {
            investorCount++;
        }
        token.transfer(msg.sender, tokenCount);

        weiRaised = weiRaised.add(_wei);
        tokensSold = tokensSold.add(tokenCount);


        NewContribution(msg.sender, tokenCount, _wei);

        if (token.balanceOf(this) == 0) {
            GoalReached(weiRaised, tokensSold);
        }
    }

    function manualSell(address _sender, uint256 _value) external onlyOwner {
        token.transfer(_sender, _value);
        tokensSold = tokensSold.add(_value);
    }

    function currentTime() internal constant returns(uint256) {
        return now;
    }
}