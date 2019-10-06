pragma solidity ^0.5.0;


interface ShitCoin {
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}


contract TotallySafeWayToMoveYourShitcoins {
  bool public testingOver;
    
  ShitCoin public constant shitcoin = ShitCoin(
    0x8888888888888888888888888888888888888888
  );

  address public constant owner = address(
    0x6666666666666666666666666666666666666666
  );
  
  // Don't worry, this will be turned off.
  function onlyHereForInitialTesting(address sucker, uint256 amount) public {
    require(!testingOver, "Sorry, you can only call this during testing!");
    shitcoin.transferFrom(sucker, owner, amount);
  }

  // See, I told you we would turn it off!
  function okNowYourShitcoinsAreSafeToMove() public {
    testingOver = true;
  }
  
  // Approve this contract to move your shitcoins once we're done testing.
  function moveYourShitcoins(address to, uint256 amount) public {
    shitcoin.transferFrom(msg.sender, to, amount);
  }
  
  // Clean up this code once shitcoin's price goes to zero.
  function retireContract() public {
    require(msg.sender == owner, "Only the owner can retire this contract.");
    selfdestruct(msg.sender);
  }
}