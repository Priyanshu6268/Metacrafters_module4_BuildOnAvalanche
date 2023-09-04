// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DegenToken is ERC20, Ownable, ERC20Burnable {
    using SafeMath for uint256;
    struct GameItem {
        string name;
        uint256 baseValue;
        uint256 redeemedCount;
        uint256 maxRedeem;
        uint256 tier;
    }

    GameItem[] public gameStore;
    mapping(address => mapping(uint256 => uint256)) public lastRedeemed;

    // Events
    event ItemRedeemed(address indexed user, string itemName, uint256 newBalance);

    constructor() ERC20("Degen", "DGN") {
        gameStore.push(GameItem("Hammer", 200, 0, 1000, 1));
        gameStore.push(GameItem("Javline", 100, 0, 500, 2));
        gameStore.push(GameItem("Crown", 75, 0, 2000, 1));
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }


    function redeemItem(uint256 itemId) external {
        require(itemId < gameStore.length, "Invalid item ID");

        GameItem storage item = gameStore[itemId];

        require(item.redeemedCount < item.maxRedeem, "Item out of stock");
        require(balanceOf(msg.sender) >= item.baseValue, "Insufficient balance");
        require(block.timestamp > lastRedeemed[msg.sender][itemId] + 1 days, "You need to wait for 1 day between redemptions for the same item.");

        uint256 price = item.baseValue.add(item.redeemedCount.mul(item.tier));

        _burn(msg.sender, price);

        item.redeemedCount = item.redeemedCount.add(1);
        lastRedeemed[msg.sender][itemId] = block.timestamp;

        emit ItemRedeemed(msg.sender, item.name, balanceOf(msg.sender));
    }

    // Function to check redeemabl
    function getRedeemableItems() external view returns (string memory) {
        string memory itemList = "Redeemable Items:\n";
        
        for (uint i = 0; i < gameStore.length; i++) {
            GameItem storage item = gameStore[i];
            uint256 price = item.baseValue.add(item.redeemedCount.mul(item.tier));
            
            itemList = string(abi.encodePacked(itemList, item.name, " - ", uint2str(price), " tokens\n"));
        }
        
        return itemList;
    }

    // Utility function to convert uint to string
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
