// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CoinDeltaPoolToken is ERC20 {
    address public owner;
    mapping(address => bool) private users;
    struct Pools {
        string name;
        address admin;
        uint pool_funds;
        bool is_filled;
        address[] investors;
    }
    Pools[] private pools;
    mapping(string => bool) public unique_names;
    mapping(address => bool) public has_user_created_pool;
    mapping(uint => mapping(address => uint)) private user_specific_pool_investment;
    address[] private temp_investors;

    constructor() ERC20("CoinDeltaPoolToken", "CDPT") {
        owner = msg.sender;
    }

    function contract_call() external {
        require(!users[msg.sender], "Already a user");
        users[msg.sender] = true;
    }

    function check_user(address _user) external view returns(bool) {
        if(users[_user]) {
            return true;
        } else {
            return false;
        }
    }

    function create_pool(string memory _name) external payable {
        require(users[msg.sender], "Not a user");
        require(!unique_names[_name], "Not not unique");
        require(!has_user_created_pool[msg.sender], "You have already created a pool");
        require(msg.value > 0.01 ether, "You must send atleast 0.01 ether");
        require(msg.value < 32 ether, "Overflow");

        temp_investors.push(msg.sender);
        Pools memory pool = Pools({
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
        uint length = pools.length - 1;
        user_specific_pool_investment[length][msg.sender] = msg.value;
        _mint(msg.sender, msg.value);

        if(pools[length].pool_funds >= 32 ether) {
            pools[length].is_filled = true; 
        }
    }
}
