// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CoinDeltaPoolToken is ERC20 {
    using SafeMath for uint256;

    address public owner;
    mapping(address => bool) private users;
    struct Pools {
        uint id;
        string name;
        address admin;
        uint pool_funds;
        bool is_filled;
        address[] investors;
    }
    Pools[] private pools;
    uint private pools_count = 0;
    mapping(string => bool) public unique_names;
    mapping(address => bool) public has_user_created_pool;
    mapping(uint => mapping(address => uint)) private user_specific_pool_investment;
    mapping(uint => mapping(address => bool)) public investor_in_pool;
    address[] private temp_investors;

    constructor() ERC20("CoinDeltaPoolToken", "CDPT") {
        owner = msg.sender;
    }

    event pool_filled(uint _id, string name);

    function contract_call() external {
        require(!users[msg.sender], "Already a user");
        users[msg.sender] = true;
    }

    function check_user(address _user) external view returns(bool) {
        bool result = users[_user];
        return result;
    }

    function create_pool(string memory _name) external payable {
        require(users[msg.sender], "Not a user");
        require(!has_user_created_pool[msg.sender], "You have already created a pool");
        require(!unique_names[_name], "Name not unique");
        require(msg.value >= 0.01 ether, "You must send atleast 0.01 ether");
        require(msg.value <= 32 ether, "Overflow");

        temp_investors.push(msg.sender);
        Pools memory pool = Pools({
            id: pools_count,
            name: _name,
            admin: msg.sender,
            pool_funds: msg.value,
            is_filled: false,
            investors: temp_investors
        });
        temp_investors.pop();
        pools.push(pool);

        unique_names[_name] = true;
        has_user_created_pool[msg.sender] = true;
        user_specific_pool_investment[pools_count][msg.sender] = msg.value;
        investor_in_pool[pools_count][msg.sender] = true;
        pools_count = SafeMath.add(pools_count, 1);
        _mint(msg.sender, msg.value);

        if(pools[pools_count - 1].pool_funds >= 32 ether) {
            pools[pools_count - 1].is_filled = true;
            emit pool_filled(pools[pools_count - 1].id, "Pool filled");
        }
    }

    function invest(uint _id) external payable {
        require(users[msg.sender], "Not a user");
        require(!pools[_id].is_filled, "Pool is full");
        require(_id < pools_count, "Enter a valid pool id");
        require(msg.value >= 0.01 ether, "You must send atleast 0.01 ether");
        require(msg.value <= 32 ether - pools[_id].pool_funds, "Overflow");

        pools[_id].pool_funds = SafeMath.add(pools[_id].pool_funds, msg.value);
        pools[_id].investors.push(msg.sender);
        if(!investor_in_pool[_id][msg.sender]) {
            user_specific_pool_investment[_id][msg.sender] = SafeMath.add(user_specific_pool_investment[_id][msg.sender], msg.value);
            investor_in_pool[_id][msg.sender] = true;
        }
        _mint(msg.sender, msg.value);

        if(pools[pools_count - 1].pool_funds >= 32 ether) {
            pools[pools_count - 1].is_filled = true;
            emit pool_filled(pools[pools_count - 1].id, "Pool filled");
        }
    }
}
