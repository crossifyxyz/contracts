// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {

    constructor () ERC20("Test token", "UPT") {}

    function mint(address _account, uint _amount) public {
        _mint(_account, _amount);
    }
}