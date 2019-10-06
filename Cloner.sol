pragma solidity 0.5.11;


contract Cloner { 
  function deployClone(address target) external returns (address clone) { 
    assembly { 
      mstore(0, or(
        0x73000000000000000000000000000000000000000030803b3d3d82943cf30000, 
        shl(88, target)
      ))

      clone := create2(0, 0, 30, 0)
    }
  }
}