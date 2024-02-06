pragma solidity ^0.8.0;

import {NaiveReceiverLenderPool} from "./NaiveReceiverLenderPool.sol";
import {FlashLoanReceiver} from "./FlashLoanReceiver.sol";

uint256 constant ETHER_IN_POOL = 1000 ether;
uint256 constant ETHER_IN_RECEIVER = 10 ether;

contract EchidnaMasterOrquestrator {
    event Log(string message, uint256 val);
    event LogAddress(string message, address val);

    NaiveReceiverLenderPool lenderPool;
    FlashLoanReceiver flashLoanReceiver;

    // System setup
    constructor() payable {
        lenderPool = new NaiveReceiverLenderPool();
        payable(address(lenderPool)).transfer(ETHER_IN_POOL);
        assert(address(lenderPool).balance == ETHER_IN_POOL);
        assert(lenderPool.fixedFee() == 1 ether);

        flashLoanReceiver = new FlashLoanReceiver(payable(address(lenderPool)));
        payable(address(flashLoanReceiver)).transfer(ETHER_IN_RECEIVER);
        assert(address(flashLoanReceiver).balance == ETHER_IN_RECEIVER);
    }

    // Echidna all assets has ben drained from the receiver
    function echidna_drain_receiver() public returns (bool) {
        return address(flashLoanReceiver).balance >= ETHER_IN_RECEIVER;
    }
}
