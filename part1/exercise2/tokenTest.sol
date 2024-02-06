pragma solidity ^0.8.0;

import {Token} from "./token.sol";

contract TokenTest is Token {

    // Setup
    constructor() {
        paused(); 
        owner = address(0);
    }

    // Test property
    function echidna_test_paused() public returns(bool){
        return is_paused;
    }

    // assertion testing
    function test_paused() public {
        assert(is_paused);  
    }
}