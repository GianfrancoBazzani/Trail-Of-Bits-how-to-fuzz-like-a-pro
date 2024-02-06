## Prerequisites
workshop repo: https://github.com/crytic/echidna-streaming-series
Echidna: https://github.com/crytic/echidna/releases
Solc: https://docs.soliditylang.org/en/latest/installing-solidity.html
# Part 1: Introduction to Fuzzing

## How to find bugs?
### Unit testing
Pros:
- Well understood by developers.
Cons:
* Mostly covers "happy paths".
* Might miss some edge cases.
Examples:
- HardHat + chai.
- Foundry tests.
> If you think for input space for any system as a line, an unit test will be only point in this line, will be only testing one concrete set of values. You can generate different concrete set of values but you will not be able to cover the entire input space. This fact usually leads to edge-cases that can not be found with unit testing alone. 

### Manual review
Pros:
* Any bug can be detected.
Cons:
- Time consuming.
- Require specific expertise.
- Time snapshot, does not track code changes.
Examples:
- Security audit.
- Bug Bounty.

### Fully automated analysis
Pros:
- Quick & easy to use
- Fully integrate in the security life-cycle pipeline.
Cons:
- High false positive rate.
- Only covers specific known bugs or bad practices.
Examples:
- Defender's Code Inspector.
- Slither.

### Semi Automated analysis
Pros:
- Great for logic-related bugs.
Cons:
- Require human research and development.
Examples:
- Medusa.
- Echidna.
- Foundry Fuzz & invariant.

## What is fuzzing?
1. Random input generation.
2. Execute test against system under test.
3. If test fails record inputs and stop else start over again.

### Traditional fuzzing (Break the system) vs smart contracts fuzzing (Validate properties)
- In traditional systems, the goal of fuzzing testing is to stress the program with random inputs to find edge cases that crashes the system.
- Smart contracts don't (really) have crashes, transactions may fail but a failing transaction doesn't mean a failing smart contract.
- In Smart Contracts we combine fuzzing with property based testing, when we say property based testing what we do is to define some system properties (something that always must be true).
- In Smart Contracts the fuzzer will try to validate whether the properties of the system are hold or not, which is equivalent to say that check if the system can reach incorrect states.
## Echidna
### What Echidna is?
Echida is a smart contract fuzzer that will generate random inputs and will test the system properties (Invariants) that has been defined by the human in the loop. 
https://github.com/crytic/echidna
### What does Echidna needs?
- Target Smart Contracts.
- Property Invariants.
### Who does Echidna works?
- Echidna will act as an externally-owned account (EOA)
- Then Echidna will call a sequence of functions with random inputs in the target and inherited contracts.
- Check whether the property holds. Ultimately properties will evaluate to a boolean value.
### Exercise 1
[Link](https://github.com/crytic/echidna-streaming-series/blob/main/part1/exercise1/README.md)
What I learnt form exercise 1?
>- To test a contract with Echinda we define a test contract that will inherit from tested one, in that way we get all functions (non private) + state of the contract under test. 
>- We can Setup contract under test from the token test that inherits it.
>- Echidna property invariant has following  format: `function echidna_*() public returns(bool)`
>- [solc-select](https://github.com/crytic/solc-select) python package is useful to rapidly switch among solidity versions.
>- In real audits we check if someone can steal funds(extract value) the toy example in the exercise simulates a EOA that has x amount of funds and checks if more value can be extracted.

Q&A.
- **Can Echidna test raw bytecode or raw solidity?** Echinda needs an ABI, you will need the ABI in addition to the bytecode.
- **Is the contract state reset after a sequence of calls?** Yes it is, except of the things that we do in the constructor.
### Exercise 2
[Link](https://github.com/crytic/echidna-streaming-series/tree/main/part1/exercise2)
What I learnt form exercise 2? 
> - Echidna can find a sequence of calls to the contract that leads to a state that breaks the invariant.
> - Property mode is the default test mode in Echidna.
> - Echidna can be ran in assertion mode with the option `--test-mode assertion`. 
> - Assertions are invariants expressed as public functions in our test that contain Solidity `assert` expression. Fuzzer will stop if any assertion reverts.
> - Assertions unlike regular invariant properties can take fuzzed arguments as parameters.
> - Echidna can fuzz block timestamp and block number.

Q&A.
- **How is Echidna compared to Foundry?** I guess there's a few different points to this. Echidna is more mature when it comes to its features, Echidna does not have cheatcodes like Foundry. Echidna focus first on provide power to the end user while Foundry is more developer friendly. 
- **How does the fuzzer retain a test to mutate it further?** Echidna tracks coverage, Imagine that your bytecode length is 100 bytes, the coverage map (initially an array of zeros) will be 100 bytes long and if in a specific run the execution flow touches a specific byte that has not being touched before, that byte will be marked as 1 in the coverage map, if it founds new coverage the transaction will be stored in a different data structure called the **Corpus**. The Corpus is a set of the inputs that has been marked as interesting by Echinda, the interest criteria is evaluated based on the coverage increase. Data from the corpus is mutated to generate further random inputs. Think of it as educated randomness. 

## How to define good invariants
### Steps
1. Define the invariant in English
2. Translate that  invariant to Solidity
3. Run Echidna
### Invariants categorization
- **Function-level invariant:** Testing a single function, may not always have to relay n much of the system or could be stateless. Can be tested in an isolated fashion Example:``
```solidity
contract TestMath is Math {
	function test_commutative(uint a, uint b) public {
		assert(add(a,b) == add(b,a));
	}
}
```
- **System-level invariant:** You need to deploy the whole system to test the things that matter at system level. Usually are stateful, and usually require some kind of setup. Example:
```solidity
contract TestToken is Token {
	constructor() public {
		balances[echidna_caller] = 10000;
	}
	function test_balance() public {
		assert(balances[echidna_caller] <= 10000);
	}
}
```

## Homework
- complete exercises 3-6 in [building-secure-contracts](https://github.com/crytic/building-secure-contracts/tree/master/program-analysis/echidna/exercises)
- Review [ABDKMath64x64.sol](https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol)
What I learnt form exercises 3-4?
> - It is not needed to call contract functions with random values in assertion mode properties, Echinda will call that functions anyway.
> Eg NOK:
```solidity
function test_maxMintLimit(uint256 value) public {
	mint(value);
	assert(balances[msg.sender] <= MAX_MINT_LIMIT_UINT);
}
```
>Eg OK:
```solidity
function test_maxMintLimit() public {
	assert(balances[msg.sender] <= MAX_MINT_LIMIT_UINT);
}
```

> - test function can be biased with require statements.
> Eg:
```solidity
function test_transfer_after_balance(uint256 amount, uint256 mintAmount, address to) public {
	balances[msg.sender] += 1000 ether;
	uint256 initialBalanceEchidna = balances[msg.sender];
	require(amount <= initialBalanceEchidna); // Bias
	require(msg.sender != to); // Bias
}
```

What I learnt form exercise 5?
> - A test contract can be used as System setup oquestrator to deploy the system under test.
> - Echidna can be configured through a config file and specifying it with `--config` option. [config options](https://github.com/crytic/echidna/wiki/Config#parameters-in-the-configuration-file)
> - The orquestrator contract must have target functions in the abi or `multi-abi: true` or `allContracts: true` can be used in echidna config file to automatically fuzz all contracts whose ABI is known at runtime.
> - The orquestator contract can be funded with an arbitrary amount of ether by using `balanceContract:` option in config file. `constructor()` must be payable to accept the funds.

What I learnt form exercise 6?
> - When using orquestrator contracts we can clearly differentiate two entities, the echidna's EOA and the orquestrator(Master) contract. Following config options are related to this entities:
```yml
#contractAddr is the address of the contract itself
contractAddr: "0x00a329c0648769a73afac7f9381e08fb43dbea72"
#deployer is address of the contract deployer (who often is privileged owner,etc.)
deployer: "0x30000"
#sender is set of addresses transactions may originate from
sender: ["0x10000", "0x20000", "0x30000"]
#balanceAddr is default balance for addresses
balanceAddr: 0xffffffff
#balanceContract overrides balanceAddr for the contract address
balanceContract: 0
```

