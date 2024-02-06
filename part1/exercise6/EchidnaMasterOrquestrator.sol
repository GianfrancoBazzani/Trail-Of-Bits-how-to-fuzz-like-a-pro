pragma solidity ^0.8.0;

import "./UnstoppableLender.sol";
import "./ReceiverUnstoppable.sol";
import "./DamnValuableToken.sol";

uint256 constant TOKENS_IN_POOL = 1000000 ether;
uint256 constant INITIAL_ATTACKER_TOKEN_BALANCE = 100 ether;

contract EchidnaMasterOrquestrator {
    DamnValuableToken token;
    UnstoppableLender pool;
    address echidna = msg.sender;

    // Setup
    constructor() payable {
        token = new DamnValuableToken();
        pool = new UnstoppableLender(address(token));

        token.approve(address(pool), TOKENS_IN_POOL);
        pool.depositTokens(TOKENS_IN_POOL);

        token.transfer(echidna, INITIAL_ATTACKER_TOKEN_BALANCE);
        assert(token.balanceOf(address(pool)) == TOKENS_IN_POOL);
        assert(
            token.balanceOf(address(echidna)) == INITIAL_ATTACKER_TOKEN_BALANCE
        );
    }

    // Are flashloans avaliable? 
    function test_flashloan(uint256 amount) public {
        require(amount <= pool.poolBalance());// bias
        require(amount > 0); // bias
        ReceiverUnstoppable flashLoanTaker = new ReceiverUnstoppable(
            address(pool)
        );
        (bool success, ) = address(flashLoanTaker).call(
            abi.encodeWithSignature("executeFlashLoan(uint256)", amount)
        );
        assert(success);
    }
}
