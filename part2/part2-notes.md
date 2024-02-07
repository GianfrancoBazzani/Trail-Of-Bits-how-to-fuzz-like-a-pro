## ABDKMath Library: ABDKMath Library
- Implements fixed-point integers for rational numbers.
- Has basic operations like add()/sub() and more complex operations like inv()/log2().
- 64.64 integer is represented in an int128 variable.
- Treat a 64.64 integer as a fraction.
	- Numerator is an int128, variable.
	- Denominator is 2^64 constant
- 64 bits represents the integer and 64 bits represents the fractional part
- | --sign bit-- | -----63 bits integer part---- | -----64 bits fractional part---- |

### Function level properties of ABDKMath
#### Properties of addition and subtraction
* Associative property of addition: (x + y) + z = x + (y + z)
* Commutative property of addition: x + y = y + x
* Addition and and subtraction are inverse operations: (x + y) - y = x
* Non commutative property of the subtraction: x - y != y -x
 >- This properties are tested in assertion mode since invariant properties (`function echidna_*() public returns(bool)`) of property mode  can't take arguments. Instead, assertion mode properties can take fuzzed arguments as parameters.
> - The human in the loop has to be creative when creating invariants, the example shows how invariant testing the addition operation isolated where not highlighting the bug while a combined test with subtraction operation was catching it.
> - Do not test arithmetic operations by re-doing the operations.

### Defining precision loss
- Precision loss occurs when the value of an operation cannot be represented in the underlying data type.
- Addition and subtraction are vulnerable to overflows.
- Multiplication/division/sqrt can all have variable amounts of precision loss.

## How to debug Echidna tests
- I want to know what is actually happening under the hood.
- Echidna executions can be debuged using debug events.
- With events we can get information form all intermediate states.
## Pre-conditions vs Post-conditions
-  We can bias (bound the input space) our echidna invariant with `require` syntax, called **pre-conditions**.
- Nonetheless, cover all edgecases with **Post-conditions** without hardly bound the input is recommended instead of bound  the input space through using **Pre-conditions** with `require` syntax. E.g:
- Pre-conditions:
``` solidity
// Test that division is not commutative
// (x / y) != (y / x)
function div_test_not_commutative(int128 x, int128 y) public {
	// Pre-conditions (bounding the input space) 
	require(abs(x) != abs(y));
	int128 x_y = div(x, y);
	int128 y_x = div(y, x);
	assert(x_y != y_x);
}
```
- Post-conditions:
```solidity
// Test that division is not commutative
// (x / y) != (y / x)
function div_test_not_commutative(int128 x, int128 y) public {
	int128 x_y = div(x, y);
	int128 y_x = div(y, x);
	// Post-conditions (asserting edge cases)
	if (abs(x) == abs(y)){
		assert(x_y == y_x);
	} else {
		assert(x_y != y_x);
	}
}
```

### Function-level invariant structure
* **Pre-conditions**,  `require` syntax biases the fuzzer by bounding the input space.
* **Action**, What you are testing.
* **Post-condition** checks assertions, bust cover happy and not-so-happy paths.

### Echidna performance optimization
* Goal: Maximize the value of each transaction sequence that Echidna runs
* Solution: Bound your inputs or apply arithmetic manipulations to avoid waste computation in undesired inputs.
* We want to Echinda to break assertions or properties, we don't want to echidna to waste computation in reverting runs.
* If i know that a transaction is going to revert that is a waste of computation.

Example of optimization by arithmetic manipulation:
Non optimized:
```solidity
// Test that division is not commutative
// (x / y) != (y / x)
function div_test_not_commutative(int128 x, int128 y) public {
	// Pre-conditions (bounding the input space) 
	require(abs(x) != abs(y)); //Reverts here!
	int128 x_y = div(x, y);
	int128 y_x = div(y, x);
	assert(x_y != y_x);
}
```
Optimized:
```solidity
// Test that division is not commutative
// (x / y) != (y / x)
function div_test_not_commutative(int128 x, int128 y) public {
	// Pre-conditions (bounding the input space)
	if(abs(x) == abs(y)){
		y = x + 1; // Only revers when overflow, less likely than before
	}
	require(abs(x) != abs(y)); //Reverts here!
	int128 x_y = div(x, y);
	int128 y_x = div(y, x);
	assert(x_y != y_x);
}
```

Example of optimization using modulo to bound the input space:
```solidity
function testStake(uint256 _amount) public {
	// Pre-condition
	require(tokenToStake.balanceOf(address(this)) > 0);
	// Optimization: amount is now bounded between [1, balanceOf(address(this))]
	uint256 amount = 1 + (_amount % (tokenToStake.balanceOf(address(this))));
	...
	}
}
```
## External testing vs internal testing
### Internal testing
- uses inheritance to test the target contract.
- Pros:
	- Easy to set up.
	- Get the state and all public/external function of the inherited contracts.
	- msg.sender is preserved, Echidna si an EOA and the target contract is directly the contract under test.
* Cons:
	* Not good for complex systems.
	* Mostly viable for single-entrypoint systems.
### External testing 
* Uses external calls to the target system.
* Pros:
	* Good for complex systems with complex initialization.
	* Good for multi-entrypoint systems.
	* Mostly used in practice.
* Cons:
	* Difficult to set up.
	* msg.sender is not preserved.

## Debugging with coverage reports
- Coverage is the tracking of what code was touched by the fuzzer.
- The report is a .txt file will all the target source code.
- Coverage report legent:
	- * :  Execution ended with a STOP.
	- r : Execution ended with a REVERT.
	- o : Out-of-gas error.
	- e : Execution ended with any other error.
	- none : Code not touched.
- **It is a cucial debugging tool that will improve your testing efforts.**
- **Provides a guarantee that your tests ran as expected.**
- Config file: 
	- `corpusDir`
	- `coverage: true`

## Compiling external dependencies (Hardhat or Foundry projects)
>To allow Echinda to compile files that contains remapped imports we have to use the char "." as target file to specify that we want to compile the entire project.

## Try catch
Try catch expressions will help us to test the not-so-happy paths that occurs when the **actions** revert.

``` solidity
function testStake(uint256 _amount) public {
	// Pre-condition
	require(tokenToStake.balanceOf(address(this)) > 0);
	// Optimization: amount is now bounded between [1,balanceOf(address(this))]
	uint256 amount = 1 + (_amount % (tokenToStake.balanceOf(address(this))));
	// State before the "action"
	uint256 preStakedBalance = stakerContract.stakedBalances(address(this));
	// Action
	tokenToStake.approve(address(stakerContract), amount);
	try stakerContract.stake(amount) returns(uint256 stakedAmount) {
		assert(stakerContract.stakedBalances(address(this)) == preStakedBalance + stakedAmount);
	} catch (bytes memory err){
		assert(false);
	}
}
```

 Homework
- Continue writing properties for [ABDKMath64x64.sol](https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol)
	- Associative property of product: (x * y) * z = x * (y * z)
	- Distributive property of the product: x * (y + z) = z * y + x * z
	- Product inverse of quotient: (x * y)/y = x
	- Multiplication of inverses: inv(x * y) = inv(x) * inv(y)
	- Square roots: sqrt(x) * sqrt(x) = x
	- Logarithms: Log2(x * y)= log2(x) * log2(y)
	- gavg(), pow(), ln(), exp()...
