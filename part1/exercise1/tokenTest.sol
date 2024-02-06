pragma solidity ^0.7.0;

import "./token.sol";

// define target: TestToken
// inheritance: we get all functions from token  + state
contract TokenTest is Token {
    // Setup
    // `echidna_caller` cannot have more than an initial balance of 10000.
    address echidna_caller = msg.sender;

    constructor(){
        balances[echidna_caller] = 10_000;
    }

    // Property
    function echidna_test_balance() public returns (bool) {
        return balances[echidna_caller] <= 10_000;
    } 
}
