pragma solidity 0.5.11;


/**
 * @title MetamorphicCloner
 * @author 0age
 * @notice A metamorphic cloner implementation that retrieves the address to
 * clone from the fallback function of the deployer.
 * 
 * 0x5860203d593d335afa1551803b80928080933cf3
 * 
 * pc op name             [stack] + <memory> + *runtime!*
 * -- -- ---------------- --------------------------------
 * 00 58 PC               [0]
 * 00 60 PUSH1 0x20       [0, 32]
 * 02 3d RETURNDATASIZE   [0, 32, 0]
 * 03 59 MSIZE            [0, 32, 0, 0]
 * 04 3d RETURNDATASIZE   [0, 32, 0, 0, 0]
 * 05 33 CALLER           [0, 32, 0, 0, 0, caller]
 * 06 5a GAS              [0, 32, 0, 0, 0, caller, gas]    
 * 07 fa STATICCALL       [0, 1 (if successful)] <address>
 * 08 15 ISZERO           [0, 0]
 * 10 51 MLOAD            [0, address]                     
 * 11 80 DUP1             [0, address, address]
 * 12 3b EXTCODESIZE      [0, address, size]
 * 13 80 DUP1             [0, address, size, size]
 * 14 92 SWAP3            [size, address, size, 0]
 * 15 80 DUP1             [size, address, size, 0, 0]
 * 16 80 DUP1             [size, address, size, 0, 0, 0]
 * 17 93 SWAP4            [size, 0, size, 0, 0, address]    
 * 18 3c EXTCODECOPY      [size, 0] <code_to_clone>
 * 19 f3 RETURN           [] *code_to_clone*
 */
contract MetamorphicCloner { 
  // We'll store the address to clone (temporarily).
  address private _addressToCloneInStorageSlotZero; 

  // The fallback function will return this address when called.
  function () external { 
    assembly { 
      mstore(0, sload(0)) // Get the target address from storage slot 0.
      return(0, 32) // Return the target address. 
    }
  }

  function deployClone(address target) external returns (address clone) { 
    // Set the target to clone in storage slot zero.
    _addressToCloneInStorageSlotZero = target; 

    // Deploy the contract with fixed, non-deterministic creation code.
    assembly { 
      mstore(0, 0x5860203d593d335afa1551803b80928080933cf3000000000000000000000000)   
      clone := create2(0, 0, 20, 0) 
    }

    // Clear out the storage slot once we're done.
    delete _addressToCloneInStorageSlotZero;
  }
}
