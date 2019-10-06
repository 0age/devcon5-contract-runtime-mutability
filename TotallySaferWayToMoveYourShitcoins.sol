pragma solidity ^0.5.0;


  interface ShitCoin {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
  }


  contract TotallySaferWayToMoveYourShitcoins {
    // OK, this time we removed "testing mode" altogether, so you're ACTUALLY safe... 😈😈😈

    ShitCoin public constant shitcoin = ShitCoin(0x8888888888888888888888888888888888888888);

    address public constant owner = address(0x6666666666666666666666666666666666666666);
    
    // Approve this contract to move your shitcoins once we're done testing.
    function moveYourShitcoins(address to, uint256 amount) public {
      shitcoin.transferFrom(msg.sender, to, amount);
    }
    
    // Clean up this code once shitcoin's price goes to zero. 💩
    function retireContract() public {
      require(msg.sender == owner, "Only the owner can retire this contract.");
      selfdestruct(msg.sender);
    }
  }



