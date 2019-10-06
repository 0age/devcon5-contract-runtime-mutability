pragma solidity 0.5.11;


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