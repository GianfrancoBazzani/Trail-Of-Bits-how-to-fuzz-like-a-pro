pragma solidity ^0.8.0;

import {Token} from "./token.sol";

contract TestToken is Token {
    event balance(string, address, uint256);

    // address echidna = msg.sender;

    // Setup
    // constructor() {
    //     balances[echidna] = 1000 ether;
    // }

    function test_transfer_after_balance(uint256 amount, uint256 mintAmount, address to) public {
        balances[msg.sender] += mintAmount;
        uint256 initialBalanceEchidna = balances[msg.sender];
        require(amount <= initialBalanceEchidna);
        require(msg.sender != to);
        uint256 initialBalanceTo = balances[to];
        emit balance("Initial echidna", msg.sender, initialBalanceEchidna);
        emit balance("Initial to", to, initialBalanceTo);
        transfer(to, amount);
        emit balance("Final echidna", msg.sender, balances[msg.sender]);
        emit balance("Final to", to, balances[to]);
        assert(balances[msg.sender] == initialBalanceEchidna - amount);
        assert(balances[to] == initialBalanceTo + amount);
    }
}