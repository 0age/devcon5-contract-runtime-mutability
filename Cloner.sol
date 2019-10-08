pragma solidity 0.5.11;


/**
 * @title Cloner
 * @author 0age, adapted from Martin Holst Swende's Cloner
 * @notice A standard, non-metamorphic cloner implementation.
 * 
 * 0x73<address>3d803b3d3d82943cf3
 * 
 * pc op name             [stack] + <memory> + *runtime!*
 * -- -- ---------------- -------------------------------
 * 00 73 PUSH20 <address> [address]
 * 21 3d RETURNDATASIZE   [address, 0]
 * 22 80 DUP1             [address, 0, address]
 * 23 3b EXTCODESIZE      [address, 0, size]
 * 24 3d RETURNDATASIZE   [address, 0, size, 0]
 * 25 3d RETURNDATASIZE   [address, 0, size, 0, 0]
 * 26 82 DUP3             [address, 0, size, 0, 0, size]
 * 27 94 SWAP5            [size, 0, size, 0, 0, address]
 * 28 3c EXTCODECOPY      [size, 0] <code_to_clone>
 * 29 f3 RETURN           [] *code_to_clone*
 */
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