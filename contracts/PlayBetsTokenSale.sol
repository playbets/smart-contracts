pragma solidity 0.4.15;

import './PlayBetsToken.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract PlayBetsTokenSale is Pausable {
    using SafeMath for uint256;

    PlayBetsToken public token;
    address public beneficiary;

    uint256 public tokensPerEth;
    uint256 public softCap;
    uint256 public hardCap;

    uint256 public weiRaised = 0;
    uint256 public tokensSold = 0;

    uint public startTime;
    uint public endTime;

    bool public saleFinished = false;
    bool public softCapReached = false;

    mapping (address => uint256) public tokenBalances;
    mapping (address => uint256) public weiBalances;
    address[] public tokenHolders;
    mapping (address => bool) public hasTokenHolder;

    event GoalReached(uint256 raised, uint256 tokenAmount);
    event SoftCapReached(uint256 tokenAmount);
    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    modifier onlyAfter(uint time) {
        require(currentTime() > time);
        _;
    }

    modifier onlyBefore(uint time) {
        require(currentTime() < time);
        _;
    }

    function PlayBetsTokenSale (
        address _tokenAddr,
        address _beneficiary,

        uint256 _tokensPerEth,

        uint256 _softCap,
        uint256 _hardCap,

        uint _startTime,
        uint _duration
    ) public {
        token = PlayBetsToken(_tokenAddr);
        beneficiary = _beneficiary;

        tokensPerEth = _tokensPerEth;

        hardCap = _hardCap;
        softCap = _softCap;

        startTime = _startTime;
        endTime = _startTime + _duration * 1 days;
    }

    function investorCount() external constant returns(uint256) {
        return tokenHolders.length;
    }

    function () external payable whenNotPaused {
        require(msg.value >= 0.01 * 1 ether);
        doPurchase();
    }

    function doPurchase() private onlyAfter(startTime) onlyBefore(endTime) {
        
        require(!saleFinished);
        require(msg.sender != address(0));

        uint256[5] memory _bonusPattern = [ uint256(120), 115, 110, 105, 100];
        uint[3] memory _periodPattern = [ uint(3), 24, 24 * 7];

        uint256 tokenCount = tokensPerEth * msg.value;

        uint calcPeriod = 0;
        uint prevPeriod = 0;
        uint256 _now = currentTime();

        for(uint8 i = 0; i < _periodPattern.length; ++i) {
            calcPeriod = calcPeriod.add(_periodPattern[i] * 1 hours);

            if (startTime + prevPeriod < _now && _now <= startTime + calcPeriod) {
                tokenCount = tokenCount.mul(_bonusPattern[i]).div(100);
                break;
            }
            prevPeriod = calcPeriod;
        }

        uint256 _wei = msg.value;
        uint256 _availableTokens = token.balanceOf(this).sub(tokensSold);

        if (_availableTokens < tokenCount) {
          uint256 expectingTokenCount = tokenCount;
          tokenCount = _availableTokens;
          _wei = msg.value.mul(tokenCount).div(expectingTokenCount);
          msg.sender.transfer(msg.value.sub(_wei));
        }

        if (!hasTokenHolder[msg.sender]) {
            hasTokenHolder[msg.sender] = true;
            tokenHolders.push(msg.sender);
        }

        weiRaised = weiRaised.add(_wei);
        tokensSold = tokensSold.add(tokenCount);

        tokenBalances[msg.sender] = tokenBalances[msg.sender].add(tokenCount);
        weiBalances[msg.sender] = weiBalances[msg.sender].add(_wei);

        NewContribution(msg.sender, tokenCount, _wei);

        if (!softCapReached && weiRaised >= softCap) {
            softCapReached = true;
            SoftCapReached(tokensSold);
        }

        if (token.balanceOf(this) == tokensSold || weiRaised >= hardCap) {
            GoalReached(weiRaised, tokensSold);
        }
    }

    function finishCrowdsale() external onlyOwner {
        require(softCapReached);
        beneficiary.transfer(this.balance);
        saleFinished = true;
        distributeTokens();
        token.transfer(beneficiary, token.balanceOf(this));
    }

    function distributeTokens() private {
        require(saleFinished);

        for(uint8 i = 0; i < tokenHolders.length; ++i) {
            address holder = tokenHolders[i];
            token.transfer(holder, tokenBalances[holder]);
            weiBalances[holder] = 0;
            tokenBalances[holder] = 0;
        }
    }

    function refund() public onlyAfter(endTime) {
        require(!softCapReached);
        require(hasTokenHolder[msg.sender]);

        msg.sender.transfer(weiBalances[msg.sender]);
        weiBalances[msg.sender] = 0;
        tokenBalances[msg.sender] = 0;
        hasTokenHolder[msg.sender] = false;
    }

    function currentTime() internal constant returns(uint256) {
        return now;
    }
}