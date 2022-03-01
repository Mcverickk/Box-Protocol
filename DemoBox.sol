// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DemoBoxToken.sol";

contract DemoBox is DemoBoxToken {

    function addFundsToBox() payable public {
        uint value = msg.value;
        _mint(msg.sender, tokenAmountToMint(value));
    } 


    //decimals and division check to be done
    function boxTokenPrice() public returns(uint256){
        if(totalSupply() == 0) {
            return 1;
        }
        else { //not correct yet
            return (uint(totalBoxValue())/uint(totalSupply()));
        }
    }

    //decimals and division check to be done
    function totalBoxValue() public returns(uint256) { //have to use chainlink data feed

    }

    //decimals and division check to be done
    function tokenAmountToMint(uint _value) private returns(uint) {
        return _value/boxTokenPrice();
    }




}




