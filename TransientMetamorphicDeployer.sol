pragma solidity 0.5.11;


/**
 * @title TransientMetamorphicDeployer
 * @author 0age
 * @notice A metamorphic deployment implementation that deploys a transient
 * contract that retrieves the creation code to deploy from the fallback
 * function of the deployer and uses that to deploy the metamorphic contract via
 * CREATE and then triggers a SELFDESTRUCT.
 * 
 * 0x58593d59335afa3d59343d59593ef080601a573d81ed81803efd5bff
 * 
 * pc op name             [stack] + <memory> + {return_buffer} + -contract- + *return*
 * -- -- ---------------- ------------------------------------------------------------
 * 00 58 PC               [0]
 * 01 59 MSIZE            [0, 0]
 * 02 3d RETURNDATASIZE   [0, 0, 0]
 * 03 59 MSIZE            [0, 0, 0, 0]
 * 04 33 CALLER           [0, 0, 0, 0, caller]
 * 05 5a GAS              [0, 0, 0, 0, caller, gas]   
 * 06 fa STATICCALL       [1 (if successful)] {creation_code}
 * 07 3d RETURNDATASIZE   [x, size]
 * 08 59 MSIZE            [x, size, 0]
 * 09 34 CALLVALUE        [x, size, 0, Ξ]
 * 10 3d RETURNDATASIZE   [x, size, 0, Ξ, size]
 * 11 59 MSIZE            [x, size, 0, Ξ, size, 0]
 * 12 59 MSIZE            [x, size, 0, Ξ, size, 0, 0]
 * 13 3e RETURNDATACOPY   [x, size, 0, Ξ] <creation_code>
 * 14 f0 CREATE           [x, address (if successful)] -contract- or {revert_reason}
 * 15 80 DUP1             [x, address, address]
 * 16 60 PUSH1 0x1a       [x, address, address, 26]
 * 18 57 JUMPI            [x, 0]
 * 19 3d RETURNDATASIZE   [x, 0, size]
 * 20 81 DUP2             [x, 0, size, 0]
 * 21 3d RETURNDATASIZE   [x, 0, size, 0, size]
 * 22 81 DUP2             [x, 0, size, 0, size, 0]
 * 23 80 DUP1             [x, 0, size, 0, size, 0, 0]
 * 24 3e RETURNDATACOPY   [x, 0, size, 0 <revert_reason>
 * 25 fd REVERT           [x, 0] *revert_reason*
 * 26 5b JUMPDEST         [x, address] 
 * 27 ff SELFDESTRUCT     [x] さよなら
 */
contract TransientMetamorphicDeployer { 
  // We'll store the creation code to deploy (temporarily).
  bytes private _creationCodeToDeploy; 

  // The fallback function will return this creation code when called.
  function () external { 
    // Move creation code from storage into memory.
    bytes memory creationCode = _creationCodeToDeploy; 
    
    // Return using data offset (skip first 32-byte word) + size (first word).
    assembly { return(add (32, creationCode), mload(creationCode)) }
  } 

  function deployViaTransient(
    bytes calldata creationCode
  ) external returns (address metamorphic) { 
    // Set the creation code in contract storage.
    _creationCodeToDeploy = creationCode; 

    // Deploy the contract with fixed, non-deterministic creation code.
    assembly { 
      mstore(0, 0x58593d59335afa3d59343d59593ef080601a573d81ed81803efd5bff00000000) 

      let transient := create2(0, 0, 28, 0)
      if iszero(transient) {
        // "bubble up" any revert and pass along reason. 
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }

      // Use hashed RLP encoding of deployer address + nonce to get deployed address.
      mstore(0, or(
        0xd694600000000000000000000000000000000000000001000000000000000000, 
        shl(80, transient)
      ))
      metamorphic := keccak256(0, 23) //_solidity will mask upper dirty bits 
    }

    // Clear out storage once we're done.
    delete _creationCodeToDeploy;
  }
}