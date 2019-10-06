pragma solidity 0.5.11;


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
