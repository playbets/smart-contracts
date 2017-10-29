pragma solidity 0.4.15;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';


contract PlayBetsToken is StandardToken {

  string public constant name = "Play Bets Token";
  string public constant symbol = "PLT";
  uint256 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 300 * 1e6 * 1 ether;

  function PlayBetsToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}
