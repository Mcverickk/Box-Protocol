// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DemoBoxToken.sol";
import "./Swap.sol";
import "./Price.sol";

contract DemoBox is DemoBoxToken, Swap, Price {

    //Made for Rinkeby Testnet
    /*
        tokenList["DAI"] = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
        tokenList["WETH9"] = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        tokenList["USDC"] = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
        tokenList["BAT"] = 0xbF7A7169562078c96f0eC1A8aFD6aE50f12e5A99;
    */

    //25% USDC 50%DAI 25%BAT in this Demo Box

    //each token Balance that the box should hold
    //******look if this needs to be made internal or private********
    mapping(string => uint256) public tokenBalance;
    uint public tempBoxValue = 0;

//constructor setting the initial token balances as 0
    constructor() {
        tokenBalance["BAT"] = 0;
        tokenBalance["DAI"] = 0;
        tokenBalance["USDC"] = 0;
        tokenBalance["ETH"] = address(this).balance;
        tokenBalance["WETH9"] = 0;
    }


    //function to add ETH to this contract and get the DemoBoxToken
    function addFundsToBox() payable public {
        require(msg.value > 0, "Not enough value.");
        //updating the contract's ETH balance
        tokenBalance["ETH"] += msg.value;
        //storing msg.value locally for further use
        uint256 valueETH = msg.value;
        //swapping ETH for WETH9(ERC-20)...will be helpfull in further token swaps
        //using WETH9 contract for this
        swapExactETHForWETH9();
        //using Uniswap to swap WETH9 for 25,25,50% for BAT,USDC and DAI respectively.
        buyTokensFromWETH(valueETH);
        //minting new Demo Box Tokens according to the value added in Box
        _mint(msg.sender, tokenAmountToMint(valueETH));
    }


    //function to buy box conprising tokens in exchange for WETH9
    function buyTokensFromWETH(uint _amountWETH) internal {
        //storing the buying amount of respective tokens in WETH
        uint buyingAmountOfBAT = _amountWETH/4;
        uint buyingAmountOfUSDC = _amountWETH/4;
        uint buyingAmountOfDAI = _amountWETH/2;
        //swaping tokens and updating contract's token balances
        tokenBalance["BAT"] += _swapExactInputSingle(buyingAmountOfBAT, "WETH9", "BAT");
        tokenBalance["WETH9"] -= buyingAmountOfBAT;
        tokenBalance["USDC"] += _swapExactInputSingle(buyingAmountOfUSDC, "WETH9", "USDC");
        tokenBalance["WETH9"] -= buyingAmountOfUSDC;
        tokenBalance["DAI"] += _swapExactInputSingle(buyingAmountOfDAI, "WETH9", "DAI");
        tokenBalance["WETH9"] -= buyingAmountOfDAI;
    }

    function approxWithdrawalAmount(uint _tokenAmount) public view returns(uint256) {
        uint tempPercentageOfBoxValue = _tokenAmount*(10**18)/totalSupply();
        uint valueInETH = tempBoxValue*percentageOfBoxValue*uint(getPrice(0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf))/(10**36);
        return valueInETH;
    }


    //function to withdraw eth for the DemoBoxToken
    //*************to we worked on*************
    function withdrawFunds(uint _tokenAmount) payable public {
        require(balanceOf(msg.sender)>= _tokenAmount, "Box Token amount exceeding.");
        uint percentageOfBoxValue = _tokenAmount*(10**18)/totalSupply();
        _burn(msg.sender, _tokenAmount);
        tempBoxValue -= tempBoxValue*percentageOfBoxValue/(10**18);
        uint ETHToGive = sellTokensForWETH(percentageOfBoxValue);
        swapExactWETH9ForETH(ETHToGive);
        (bool sent, bytes memory data) = msg.sender.call{value : ETHToGive}("");
    }


    function sellTokensForWETH(uint _percentageBoxValue) internal returns(uint256) {
        //storing the selling amount of respective tokens
        uint sellingAmountOfBAT = tokenBalance["BAT"]*_percentageBoxValue/(10**18);
        uint sellingAmountOfUSDC = tokenBalance["USDC"]*_percentageBoxValue/(10**18);
        uint sellingAmountOfDAI = tokenBalance["DAI"]*_percentageBoxValue/(10**18);
        //storing the initial value of WETH9 to calculate WETH9 from the sell of the tokens
        uint initialWETH9amount = tokenBalance["WETH9"];
        //swaping tokens and updating contract's token balances
        tokenBalance["WETH9"] += _swapExactInputSingle(sellingAmountOfBAT, "BAT", "WETH9");
        tokenBalance["BAT"] -= sellingAmountOfBAT;
        tokenBalance["WETH9"] += _swapExactInputSingle(sellingAmountOfUSDC, "USDC", "WETH9");
        tokenBalance["USDC"] -= sellingAmountOfUSDC;
        tokenBalance["WETH9"] += _swapExactInputSingle(sellingAmountOfDAI, "DAI", "WETH9");
        tokenBalance["DAI"] -= sellingAmountOfDAI;
        //returning the WETH9 deposited to contract from the sellings
        return (tokenBalance["WETH9"] - initialWETH9amount);
    }






    //function to get the amount of Box tokens to be minted
    function tokenAmountToMint(uint _value) private returns(uint) {
        //calculating the added ETH value in USD with 18 decimals
        uint valueInUSD =  _value*uint256(getPrice(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e))/uint256(10**8);
        //getting the price of Box Token in USD with 18 decimals
        uint boxTokenPrice = getBoxTokenPrice(); 
        //calulating temporary Box Value for simulations
        tempBoxValue += valueInUSD;
        //returning the amount of box tokens to be minted in 18 decimals
        return (valueInUSD*(10**18)/boxTokenPrice);
    }

    //function to get the price of each Box Token
    function getBoxTokenPrice() private returns(uint){
        //if it is the 1st deposit...Box token price = 1 USD 
        if(totalSupply() == 0) {
            // returing 1 USD in 18 decimals
            return uint(10**18);                                          
        }
        //calculating Box Token price if it is not the 1st deposit
        else { 
            //getting total Box value and dividing it by total supply to get price in 18 decimals
            return getTotalBoxValue()*(10**18)/totalSupply(); 
        }
    }


    //********************get price in USD and 18 decimals*************************
    //************Have to use Chainlink prices to calculate total value*************
    function getTotalBoxValue() public returns(uint256) { 
        //returning 1000USD in 18 decimals as total Box Value
        return tempBoxValue;
    }

    


    //function to swap exact ETH to WETH9
    function swapExactETHForWETH9() payable public {
        require(msg.value > 0, "Not enough value.");
        //calling the deposit function in WETH9 contract to wrap ETH
        wethtoken.deposit{value: msg.value}();
        //updating contract's token balance
        tokenBalance["ETH"] -= msg.value;
        tokenBalance["WETH9"] += msg.value;    
    }

    //function to swap exact WETH9 to ETH
    function swapExactWETH9ForETH(uint _amount) payable public {
        //calling the withdraw function in WETH9 contract to unwrap WETH9
        wethtoken.withdraw(_amount);
        //updating contract's token balance
        tokenBalance["WETH9"] -= _amount; 
        tokenBalance["ETH"] += _amount;
    }
}
