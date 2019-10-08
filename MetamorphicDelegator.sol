pragma solidity 0.5.11;


/**s
 * @title MetamorphicDelegator
 * @author 0age
 * @notice A metamorphic deployment implementation that deploys a contract with
 * the target creation code in its runtime code, then retrieves the address of
 * that contract from the fallback function of the deployer during deployment of
 * the metamorphic contract and performs a DELEGATECALL into the contract. Note
 * that the "creation-code-in-runtime-code" contract does not need to be
 * deployed as part of this process - it can optionally be deployed ahead of
 * time and reused.
 * 
 * Arbitrary runtime prelude (used for "creation-code-in-runtime-code" contract)
 * 
 * 0x600b5981380380925939f3...
 * 
 * pc op name       [stack] + <memory> + *runtime!*
 * -- -- ---------- ----------------------------------------------
 * 00 60 PUSH1 0x0b [11 -> offset]
 * 02 59 MSIZE      [offset, 0]
 * 03 81 DUP2       [offset, 0, offset]
 * 04 38 CODESIZE   [offset, 0, offset, codesize]
 * 05 03 SUB        [offset, 0, codesize - offset => runtime_size]
 * 06 80 DUP1       [offset, 0, runtime_size, runtime_size]
 * 07 92 SWAP3      [runtime_size, 0, runtime_size, offset]
 * 08 59 MSIZE      [runtime_size, 0, runtime_size, offset, 0]
 * 09 39 CODECOPY   [runtime_size, 0] <arbitrary_runtime>
 * 10 f3 RETURN     [] *arbitrary_runtime*
 * ... arbitrary_runtime
 * 
 * 
 * 
 * Metamorphic Delegator
 * 
 * 0x58593d593d5960203d593d335afa15515af43d3d93833e601b57fd5bf3
 * 
 * pc op name           [stack] + <memory> + {return_buffer} + *runtime!*
 * -- -- -------------- -------------------------------------------------
 * 00 58 PC             [0]
 * 01 59 MSIZE          [0, 0]
 * 02 3d RETURNDATASIZE [0, 0, 0]
 * 03 59 MSIZE          [0, 0, 0, 0]
 * 04 3d RETURNDATASIZE [0, 0, 0, 0, 0]
 * 05 59 MSIZE          [0, 0, 0, 0, 0, 0]
 * 06 60 PUSH1 0x20     [0, 0, 0, 0, 0, 0, 32]
 * 08 3d RETURNDATASIZE [0, 0, 0, 0, 0, 0, 32, 0]
 * 09 59 MSIZE          [0, 0, 0, 0, 0, 0, 32, 0, 0]
 * 10 3d RETURNDATASIZE [0, 0, 0, 0, 0, 0, 32, 0, 0, 0]
 * 11 33 CALLER         [0, 0, 0, 0, 0, 0, 32, 0, 0, 0, caller]
 * 12 5a GAS            [0, 0, 0, 0, 0, 0, 32, 0, 0, 0, caller, gas]    
 * 13 fa STATICCALL     [0, 0, 0, 0, 0, 0, 1] <creation_in_runtime>
 * 14 15 ISZERO         [0, 0, 0, 0, 0, 0, 0]
 * 15 51 MLOAD          [0, 0, 0, 0, 0, 0, creation_in_runtime]
 * 16 5a GAS            [0, 0, 0, 0, 0, 0, creation_in_runtime, gas]
 * 17 f4 DELEGATECALL   [0, 0, 1 or 0] {runtime_code or revert_reason}
 * 18 3d RETURNDATASIZE [0, 0, 1 or 0, size]
 * 19 3d RETURNDATASIZE [0, 0, 1 or 0, size, size]
 * 20 93 SWAP4          [size, 0, 1 or 0, size, 0]
 * 21 83 DUP4           [size, 0, 1 or 0, size, 0, 0]
 * 22 3e RETURNDATACOPY [size, 0, 1 or 0] <runtime_code or revert_reason>
 * 23 60 PUSH1 0x1b     [size, 0, 1 or 0, 27]
 * 25 57 JUMPI          [size, 0]
 * 26 fd REVERT         [] *revert_reason*
 * 27 5b JUMPDEST       [size, 0]
 * 28 f3 RETURN         [] *runtime_code*
 */
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