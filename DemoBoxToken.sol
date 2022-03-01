// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DemoBoxToken is ERC20 {
    constructor() ERC20("Demo Box Token", "DemoBT") {}  
    
}