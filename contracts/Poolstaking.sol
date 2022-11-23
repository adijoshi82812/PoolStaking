// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PoolStaking {
    using SafeMath for uint256;

    ERC20 private immutable pool_token;
    address admin;
    mapping(address => bool) private users;
    struct Pools {
        uint id;
        string name;
        address owner;
        address[] investors;
        uint funds;
        bool is_filled;
    }
    Pools[] private pools;
    uint private pools_count = 0;
    mapping(string => bool) public unique_names;
    mapping(address => bool) private has_user_created_pool;
    address[] private temp_investors;
    mapping(uint => mapping(address => uint)) private user_index_in_pool;
    mapping(uint => mapping(address => bool)) private user_in_pool;
    mapping(uint => mapping(address => uint)) private user_specific_pool_stake;

    constructor() {
        require(msg.sender != address(0));

        pool_token = new ERC20("Coindelta Pool Token", "CPDT", address(this));
        admin = msg.sender;
    }

    receive() external payable {
        (bool success, ) = payable(admin).call{value: msg.value}("");
        require(success, "Donation not successful");
    }

    event Log(string message);

    function pool_filled(uint _id) internal {
        pools[_id].is_filled = true;
        emit Log("Pool full");
    }

    function token_address() external view returns(address) {
        return address(pool_token);
    }

    function contract_call() external {
        require(!users[msg.sender], "Already a user");
        users[msg.sender] = true;

        emit Log("User registered Successfully");
    }

    function create_pool(string memory _name) external payable {
        require(users[msg.sender], "Not a user");
        require(!unique_names[_name], "Name already exists");
        require(!has_user_created_pool[msg.sender], "You have already created a pool");
        require(payable(msg.sender).balance > 0.1 ether, "You don't have enough balance");
        require(msg.value > 0.01 ether, "Must invest at least 0.01 ether");
        require(msg.value <= 32 ether, "Overflow");

        temp_investors.push(msg.sender);
        Pools memory pool = Pools({
            id: pools_count,
            name: _name,
            owner: msg.sender,
            investors: temp_investors,
            funds: msg.value,
            is_filled: false
        });
        temp_investors.pop();

        pools.push(pool);
        unique_names[_name] = true;
        has_user_created_pool[msg.sender] = true;
        user_index_in_pool[pools_count][msg.sender] = SafeMath.sub(pools[pools_count].investors.length, 1);
        user_in_pool[pools_count][msg.sender] = true;
        user_specific_pool_stake[pools_count][msg.sender] = msg.value;
        pools_count = SafeMath.add(pools_count, 1);
        pool_token._mint(msg.sender, msg.value);

        emit Log("Pool created");
        if(msg.value > 32 ether) {
            pool_filled(pools_count - 1);
        }
    }

    function invest(uint _id) external payable {
        require(users[msg.sender], "Not a user");
        require(_id < pools_count, "Enter valid pool id");
        require(!pools[_id].is_filled, "Pool is already full");
        require(payable(msg.sender).balance > 0.01 ether, "You don't have enough balance");
        require(msg.value <= SafeMath.sub(32 ether, pools[_id].funds), "Overflow");

        if(!user_in_pool[_id][msg.sender]) {
            pools[_id].investors.push(msg.sender);
            user_index_in_pool[_id][msg.sender] = SafeMath.sub(pools[_id].investors.length, 1);
            user_in_pool[_id][msg.sender] = true;
        }

        pools[_id].funds = SafeMath.add(pools[_id].funds, msg.value);
        pool_token._mint(msg.sender, msg.value);

        if(pools[_id].funds >= 32 ether) {
            pool_filled(_id);
        }

        emit Log("Invested Successfully");
    }
}