pragma solidity ^0.8.0;

import {MintableToken} from "./mintable.sol";

int256 constant MAX_MINT_LIMIT_INT = 10000;
uint256 constant MAX_MINT_LIMIT_UINT = 10000;
contract TestTokenMintable is MintableToken {
    address echidna = msg.sender;

   // Setup
   constructor() MintableToken(MAX_MINT_LIMIT_INT) {
    owner = echidna;
   }

   // Property
    function echidna_maxMintLimit() public returns (bool) {
        return balances[msg.sender] <= MAX_MINT_LIMIT_UINT;
    }
}