// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract DegenToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private isAdmin;
    mapping(address => uint256) private rewards;

    struct GameItem {
        string name;
        uint256 baseValue;
        uint256 redeemedCount;
        uint256 maxRedeem;
        uint256 tier;
    }

    GameItem[] public gameStore;
    mapping(address => mapping(uint256 => uint256)) public lastRedeemed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event RewardAdded(address indexed admin, uint256 amount);
    event RewardClaimed(address indexed player, uint256 amount);
    event ItemRedeemed(address indexed user, string itemName, uint256 newBalance);

    constructor() {
        name = "Degen Token";
        symbol = "DGN";
        decimals = 18;
        totalSupply = 0;
        owner = msg.sender;
        gameStore.push(GameItem("Sword", 300, 0, 800, 2));
        gameStore.push(GameItem("Shield", 150, 0, 400, 1));
        gameStore.push(GameItem("Helmet", 100, 0, 1000, 2));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");

        balances[account] += amount;
        totalSupply += amount;

        emit Transfer(address(0), account, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Invalid address");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(sender != address(0), "Invalid address");
        require(recipient != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function burn(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
        function claimReward() external returns (uint256) {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "No rewards to claim");

        rewards[msg.sender] = 0;
        emit RewardClaimed(msg.sender, amount);

        return amount;
    }

    function redeemItem(uint256 itemId) external {
        require(itemId < gameStore.length, "Invalid item ID");

        GameItem storage item = gameStore[itemId];

        require(item.redeemedCount < item.maxRedeem, "Item out of stock");
        require(balances[msg.sender] >= item.baseValue, "Insufficient balance");
        require(block.timestamp > lastRedeemed[msg.sender][itemId] + 1 days, "You need to wait for 1 day between redemptions for the same item.");

        // uint256 price = item.baseValue.add(item.redeemedCount.mul(item.tier));

        // balances[msg.sender] -= price;

        // item.redeemedCount = item.redeemedCount.add(1);
        lastRedeemed[msg.sender][itemId] = block.timestamp;

        emit ItemRedeemed(msg.sender, item.name, balances[msg.sender]);
    }

    function getRedeemableItems() external view returns (string memory) {
        string memory itemList = "Available Items:\n";
        
        for (uint i = 0; i < gameStore.length; i++) {
            GameItem storage item = gameStore[i];
            // uint256 price = item.baseValue.add(item.redeemedCount.mul(item.tier));
            
            itemList = string(abi.encodePacked(itemList, item.name, " - ", " tokens\n"));
        }
        
        return itemList;
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }
}
