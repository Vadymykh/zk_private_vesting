// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TestERC20 is ERC20Permit{
    uint8 private immutable _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 mintAmount
    )
    ERC20(name, symbol)
    ERC20Permit(name)
    {
        _mint(msg.sender, mintAmount);
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}