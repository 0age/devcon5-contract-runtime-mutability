pragma solidity 0.5.11;


contract MetamorphicDelegator {
  // We'll store the address where the target creation code is located (temporarily).
  address private _addressOfContractWithCreationCodeInRuntimeCode;
    
    // The fallback function will return this address when called.
    function () external {
      assembly {
        mstore(0, sload(0)) // Get the target address from storage slot 0.
        return(0, 32)       // Return the target address.
      }
    }

  function deployMetamorphicDelegator(
    bytes calldata creationCode
  ) external returns (address metamorphic) {
    // Construct creation code for the creation-in-runtime contract using the prelude.
    bytes memory targetCreationCode = abi.encodePacked(
      bytes11(0x600b5981380380925939f3), creationCode
    );

    assembly {
      // Deploy creation-in-runtime contract via `CREATE` and set the address in storage.
      sstore(0, create(0, add(32, targetCreationCode), mload(targetCreationCode)))
      
      // Deploy the contract with fixed, non-deterministic creation code.
      mstore(0, 0x58593d593d5960203d593d335afa15515af43d3d93833e601b57fd5bf3000000)
      metamorphic := create2(0, 0, 29, 0)
      if iszero(metamorphic) {  // "bubble up" any revert and pass along reason.
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
      
    // Clear out the storage slot once we're done.
    delete _addressOfContractWithCreationCodeInRuntimeCode;
  }
}