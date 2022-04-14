// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

//WETH9 token interface to swap WETH for native ETH
abstract contract WETH9interface {
    function deposit() public virtual payable;
    function withdraw(uint wad) public virtual;
}

//swapRouter address - 0xE592427A0AEce92De3Edee1F18E0157C05861564

//Swap contract
contract Swap is Ownable {
    // It should be noted that for the sake of these examples, we purposefully pass in the swap router instead of inherit the swap router for simplicity.
    // More advanced example contracts will detail how to inherit the swap router safely.

    ISwapRouter public immutable swapRouter;

    //creating a new object for WETH9interface
    WETH9interface wethtoken = WETH9interface(0xc778417E063141139Fce010982780140Aa0cD5Ab);

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    //mapping to store all the token addresses
    mapping(string => address) public tokenList;
    //_owner storing the address of the admin or owner
    address private _owner;

    //(ISwapRouter _swapRouter)
    constructor() {
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        _owner = msg.sender;

        tokenList["DAI"] = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
        tokenList["WETH9"] = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        tokenList["USDC"] = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
        tokenList["BAT"] = 0xbF7A7169562078c96f0eC1A8aFD6aE50f12e5A99;
    }

    //receive & fallback function to receive ETH in this contract address
    receive() external payable{}
    fallback() external payable{}

    //function to add token address to tokenList mapping
    function addToken(string memory tokenSymbol, address tokenAddress) onlyOwner public {
        tokenList[tokenSymbol] = tokenAddress;
    }

    //function to remove token address to tokenList mapping
    function deleteToken(string memory tokenSymbol) onlyOwner public {
        delete tokenList[tokenSymbol];
    }


    /*

    //function to swap exact ETH to any of the token in tokenList
    function swapExactETHForTokens(string memory tokenOut) payable public returns (uint256 amountOut) {
        require(msg.value > 0, "Not enough value.");
        wethtoken.deposit{value: msg.value}();
        amountOut = _swapExactInputSingle(msg.value, "WETH9", tokenOut);
    }

    //function to swap exact of any token to any of the token in tokenList
    function swapExactTokensForTokens(uint256 amountIn, string memory tokenIn, string memory tokenOut) external returns(uint256 amountOut) {
        TransferHelper.safeTransferFrom(tokenList[tokenIn], msg.sender, address(this), amountIn);
        amountOut = _swapExactInputSingle(amountIn, tokenIn, tokenOut);
    }

    //function to swap exact of any token in tokenList to ETH
    function swapExactTokensForETH(string memory tokenIn, uint256 amountIn) payable public returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(tokenList[tokenIn], msg.sender, address(this), amountIn);
        amountOut = _swapExactInputSingle(amountIn, tokenIn, "WETH9");
        wethtoken.withdraw(amountOut);
        (bool sent, bytes memory data) = msg.sender.call{value : amountOut}("");
    }

    */


    //using uniswap router to swap exact tokens for tokens
    function _swapExactInputSingle(uint256 amountIn, string memory tokenIn, string memory tokenOut) internal returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of DAI to this contract.
        //////TransferHelper.safeTransferFrom(tokenList[tokenIn], msg.sender, address(this), amountIn);

        // Approve the router to spend DAI.
        TransferHelper.safeApprove(tokenList[tokenIn], address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenList[tokenIn],
                tokenOut: tokenList[tokenOut],
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            
        amountOut = swapRouter.exactInputSingle(params);
    }


}
