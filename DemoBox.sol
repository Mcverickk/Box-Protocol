// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DemoBoxToken.sol";

contract DemoBox is DemoBoxToken {


    address public thisContract = address(this);
    // to check contracts eth balance ----not working
    uint public balance = address(this).balance;

    //function to add eth to this contract and get the DemoBoxToken
    function addFundsToBox() payable public {
        uint value = msg.value;
        _mint(msg.sender, tokenAmountToMint(value));
    }

    //function to withdraw eth for the DemoBoxToken
    function withdrawFunds(uint _tokenAmount) payable public {
        _burn(msg.sender, _tokenAmount);
        uint fundsToGive = _tokenAmount*boxTokenPrice();
        (bool sent,) = msg.sender.call{value : fundsToGive}("");
    }

    //***decimals and division check to be done
    function boxTokenPrice() private returns(uint){

        if(totalSupply() == 0) {
            return 1;                                          // 1token = 1 USD
        }
        else { //not correct yet
            return totalBoxValue()/totalSupply();
        }
    }

    //***decimals and division check to be done
    //-----incomplete
    function totalBoxValue() public returns(uint256) { //have to use chainlink data feed
        return 1000;
    }

    //decimals and division check to be done
    function tokenAmountToMint(uint _value) private returns(uint) {
        return _value/boxTokenPrice();
    }
}
