// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// This implements the ERC20 library for the staking token we will use 
// This token will be used for both depositing and rewards
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
// This library will be used for math operations
import "https://github.com/OpenZeppelin/openzeppelin-contracts-08/contracts/math/SafeMath.sol";

contract staking is ERC20, SafeMath {

// A struct which defines all the parameters, regarding what/who a staker is w/in the contract
struct Staker{
    // This states that a 'Staker', needs to have an address
    address staker;
    // This returns a T/F if staker has a balance w/in the contract
    bool isStaker; 
    // This returns a uint which defines the amount of the tokens staked 
    uint256 amounttStaked; 
    }

    // This mapping, pairs addresses which stake tokens within the smart contract and the amt of those tokens as well
    mapping(address => uint256) public stakedTokens;
    // This mapping indicates whether the mapping key is or is not inserted into the array of 'stakedAddresses'
    mapping(address => bool) public inserted;
    // This is an array which we will use to iterate through all the addresses which have staked tokens in this smart contract
    // This is so we can calculate the address amount of stake 
    // So we can give them a congruent amount of rewards depending on the share in their pool
    address[] public stakedAddresses;
    // Same mapping as before, for receipt tokens
    mapping(address => uint256) receiptTokens;
    // Same bool mapping
    mapping(address => bool) public inputed;
    // array for the receiptAddresses, as we will need to iterate through this too
    address[] public receiptAddresses; 
    
    // This gets the size of the array, which is the size of the stakedTokens mapping
    function getSize() external view returns (uint) {
        return inserted.length;
    }

    // This gets the size of the array, which is the size of the receiptTokens mapping 
    function getAmt() external view returns (uint) {
        return inputed.length;
    }

    uint totalsupply; 

// This struct defines 'TokenBalances' of accounts using the staking contract
// Will be used for the retrieve fxs 
struct TokenBalances{
    uint staked;
    uint receipt;
}
    // maps address to amount of rewards they receive
    // this will be dependent on how long they have been in the staking contract for 
    mapping(address => uint) public rewards;

constructor() ERC20("StakingToken", "ST"){
    // This sets the one who calls the constructor as the owner of the contract
    owner = msg.sender;
    // Assigns totalSupply to _totalSupply
    totalSupply = _totalSupply;
    // Assigns balances to _balances
    balances = _balances; 
    // This will mint the total supply and send it to the staking contract
    // Function is marked as internal so only functions w/in this contract can call this function
    // This sets the total supply of the staking tokens
    _mint(this, 10000 * (10**18));
    // Guard check to ensure that the address the tokens are being minted towards
    // Are not being sent to a 'null address'
    require(this != 0);
    // Guard to check that the one calling the mint function is the owner
    require(msg.sender == owner);
    // State var which adds the amount of the tokens minted to the total supply
    _totalSupply = _totalSupply.add(amount);
    // State var which adds the 'balance' of the token being created/minted to 'this'
    // 'this', means that the tokens minted to 'totalSupply' will be sent to the smart contract itself deploying the token
    // it will add to the current balance of the smart contract
    _balances[this] = add(_balances[this], (amount));
    // 1st argument, smart contract address will transfer tokens
    // 2nd argument, tokens will be transfered to an account, which is the smart contract itself
    // 3rd argument, is the value/amount of tokens transfered  
    emit Transfer(address(this), this, amount);
}

// This function is the 'stake' function, where users will be allowed to deposit the amount of tokens they have 
// The EoAs MUST have a token balance greater than 0 to stake their token/s in the contract to begin accruing rewards
function stake() public returns(uint256){
    // This will throw an error "No balance" if the EoA attempts to stake tokens but has none in their wallet 
    // we do amount here, rather than 0 
    // want to ensure that the caller also is not staking more tokens than they own
    require(balanceOf[msg.sender] > _amount, "Not Enough Tokens");
    // Transfers tokens from Eoa to 'this' smart contract and amount of tokens
    emit transfer(msg.sender, this, amount); 
    // Subtracts 'StakingToken' balance from caller
    balanceOf[msg.sender] = sub(balanceOf[msg.sender], (_amount));
    // Adds stakedtoken balance to caller wallet
    stakedTokens[msg.sender] = add(stakedTokens[msg.sender], (_amount)); 
    stakedTokensTS[msg.sender] = block.timestamp;
    // Adds equal amount of receiptTokens, as tokens staked in the contract
    receiptTokens[msg.sender] = amount;
    // get and retrieve are inner functions which are called, when the stake function is triggered
    call.get();
    call.retrieve();
    } 
    function get (uint _i) external view returns (uint) {
        return stakedTokens[inserted[_i]];
    }
    // This will return the balance of 'msg.sender' (EoA) after they have deposited the amount of tokens they have
    // This function allows the msg.sender to send 'x' amount of tokens, does not need to be their entire balance
    // They can deposit a portion of their tokens in to the staked contract 
    function retrieve(address _addr) public view returns(TokenBalances){
        // memory is used here because the struct data is not preserved in storage
        TokenBalances memory result; 
        // Allows smart contract to return the balance of both staked & receipt tokens simultaneously 
        reuslt.staked = stakedTokens[_addr];
        result.receipt = receiptTokens[_addr];
        return result;
    }

function unstake() public returns(uint256){
    // This looks at the msg.sender to see if they have tokens staked w/in the contract
    require(stakedTokens[msg.sender] > 0, "No tokens staked" );
    // Transfers tokens from Smart contract to EoA and amount of tokens
    emit transfer(this, msg.sender, amount); 
    // Incremenets 'StakingToken' balance from caller
    StakingToken[msg.sender] = add(StakingToken[msg.sender], (_amount));
    // Subtracts the amount tokens requested to be unstaked from the msg.sender
    stakedTokens[msg.sender] = sub(stakedTokens[msg.sender], (_amount));
    // Removes the same amount of receiptTokens
    receiptTokens[msg.sender] = amount;
    // removeBalance and retrieve2 are inner functions, which will be called when the unstake function is triggered
    call.removeBalance();
    call.retrieve2();
}
    // This function analyzes the msg.sender balance to see if they unstaked all their tokens to a balance of 0
    // If the address passed through has no tokens staked, it's value of 'stakedTokens' will be set to 0 
    function removeBalance (address stakedAddresses) external  returns (uint) {
        // needs amount of staked tokens to be 0 for fx to continue 
        require(stakedTokens[stakedAddresses] == 0, "Tokens are still staked");
        // assigns staked to stakedTokens in array 'stakeAddresses' which is an array of the mapping of addy > token
        uint staked = stakedTokens[stakedAddresses];
        // sets amount of stakedTokens within the array of the caller to 0
        // defines value of respective key to 0 
        stakedTokens[stakedAddresses] = 0;
        // returns amount of tokens staked 
        return staked;
        }
    // This will return the balance of 'msg.sender' (EoA) after they have withdrawn the amount of tokens they have
    // Also returns balance of receiptTokens, which represents tokens staked in smart contract
    function retrieve2(address _addr) public view returns(TokenBalances){
        // memory is used here because the struct data is not preserved in storage
        TokenBalances memory result; 
        // Allows smart contract to return the balance of both staked & receipt tokens simultaneously 
        reuslt.staked = stakedTokens[_addr];
        result.receipt = receiptTokens[_addr];
        return result;
    }

// This sets the value of total tokens stake to 0
uint totalStaked = 0;
// The for loop iterated through the stakedTokens mapping 
function totalStake() public pure returns (uint){
// This will parse through the array 'stakedAddresses' which has implemented the stakedTokens mapping
for (uint i = 0; i < stakedAddresses[i].length; i++) {
    // This will subtract addresses which return a value of 0 in the mapping
    // Meaning they do not stake any tokens
   if (_stakedTokens[_stakedAddresses[i]]  == 0) {
       sub(numberofStakers, (_amount));
    // This will add addreses to the mapping if it returns a value
    // Meaning they do have tokens staked
   }
   if (stakedTokens[_stakedAddresses[i]] == _value)  {
       add(numberofStakers, (_amount));
   }
    return totalStaked; 
}

// Defines amount of seconds tokens were staked for 
uint timePassed;
// Amount of rewards that can be claimed
uint claimable;
// This function allows the user to see the amount of rewards they can claim via their receipt token
function viewRewards() external pure returns(uint) {
    // Require fx indicating that user has to have tokens staked to view their rewards claimable
    require(receiptTokens[msg.sender] >0, "User needs to have tokens staked");
    // Calcs to find time passed and amount of rewards to be claimable
    timePassed = sub(block.timestamp, stakedTokensTS[msg.sender]);
    viewReward = div(mul(mul(receiptTokens[msg.sender]totalReward), timePassed), totalStaked[msg.sender]);
    return claimable; 
}
function claimRewards(address claimer, uint rewards) external returns (string) {
    // Require statements callers must pass prior to getting rewards
    require(stakedTokens[msg.sender] > 0, "Claimer needs tokens staked"); 
    require(claimer != address(0), "Claimer cannot be a null address"); 
    require(rewards != 0,"Claimer cannot claim 0 rewards");
    // This subtracts the current block timestamp from the timestamp when the caller staked their tokens
    timePassed = sub(block.timestamp, stakedTokensTS[msg.sender]);
    rewards = div(mul(mul(stakedTokens[msg.sender]totalReward), timePassed), totalStaked[msg.sender]);
    // This will transfer rewards to claimer
    emit transfer(this, claimer, rewards);
    // Indicates rewards have been sucessfully claimed
    return "Rewards have been claimed"; 
    }
}

