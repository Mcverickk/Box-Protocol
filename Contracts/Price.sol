// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * THIS EXAMPLE USES UN-AUDITED CODE.
 * Network: Rinkeby
 * Decimals: 8
 * ETH/USD : 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
 * USDC/USD : 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB
 */

contract Price {

    function getPrice(address _dataFeedAddress) public view returns(int256) {
        ( , int256 latestPrice, , , ) = AggregatorV3Interface(_dataFeedAddress).latestRoundData();
        return latestPrice;
    }

    function getDerivedPrice(address _base, address _quote, uint8 _decimals) public view returns (int256) {

        require(_decimals > uint8(0) && _decimals <= uint8(18), "Invalid _decimals");

        int256 decimals = int256(10 ** uint256(_decimals));

        ( , int256 basePrice, , , ) = AggregatorV3Interface(_base).latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        ( , int256 quotePrice, , , ) = AggregatorV3Interface(_quote).latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return basePrice * decimals / quotePrice;
    }

    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals)
        internal
        pure
        returns (int256)
    {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

}
