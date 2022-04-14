// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DemoBoxToken.sol";
import "./Swap.sol";

contract DemoBox is DemoBoxToken, Swap {

    //rinkeby
    /*
        tokenList["DAI"] = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
        tokenList["WETH9"] = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        tokenList["USDC"] = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
        tokenList["BAT"] = 0xbF7A7169562078c96f0eC1A8aFD6aE50f12e5A99;
    */

    //25% USDC 50%DAI 25%BAT

    mapping(string => uint256) public tokenBalance;

    constructor() {
        tokenBalance["BAT"] = 0;
        tokenBalance["DAI"] = 0;
        tokenBalance["USDC"] = 0;
        tokenBalance["ETH"] = address(this).balance;
        tokenBalance["WETH9"] = 0;
    }


    //function to add eth to this contract and get the DemoBoxToken
    function addFundsToBox() payable public {
        require(msg.value > 0, "Not enough value.");
        tokenBalance["ETH"] = msg.value;
        uint256 valueETH = msg.value;
        swapExactETHForWETH9();

        buyTokensFromWETH(tokenBalance["WETH9"]);
        _mint(msg.sender, tokenAmountToMint(valueETH));
    }

    function buyTokensFromWETH(uint _amountWETH) internal {
        uint buyingAmountOfBAT = _amountWETH/4;
        uint buyingAmountOfUSDC = _amountWETH/4;
        uint buyingAmountOfDAI = _amountWETH/2;

        tokenBalance["BAT"] += _swapExactInputSingle(buyingAmountOfBAT, "WETH9", "BAT");
        tokenBalance["WETH9"] -= buyingAmountOfBAT;
        tokenBalance["USDC"] += _swapExactInputSingle(buyingAmountOfUSDC, "WETH9", "USDC");
        tokenBalance["WETH9"] -= buyingAmountOfUSDC;
        tokenBalance["DAI"] += _swapExactInputSingle(buyingAmountOfDAI, "WETH9", "DAI");
        tokenBalance["WETH9"] -= buyingAmountOfDAI;
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


    //function to swap exact ETH to WETH9
    function swapExactETHForWETH9() payable public {
        require(msg.value > 0, "Not enough value.");
        wethtoken.deposit{value: msg.value}();
        tokenBalance["WETH9"] = msg.value;
        tokenBalance["ETH"] -= msg.value;
    }
}




