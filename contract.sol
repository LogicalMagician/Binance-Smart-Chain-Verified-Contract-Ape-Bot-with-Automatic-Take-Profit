// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";

contract AutoTokenBuyer {
    
    address public owner;
    uint256 public minBuyAmount;
    uint256 public minSellAmount;
    uint256 public buyFee;
    uint256 public sellFee;
    uint256 public slippage;
    address[] public blacklistedTokens;
    mapping(address => bool) public isBlacklisted;
    
    constructor(uint256 _minBuyAmount, uint256 _minSellAmount, uint256 _buyFee, uint256 _sellFee, uint256 _slippage, address[] memory _blacklistedTokens) {
        owner = msg.sender;
        minBuyAmount = _minBuyAmount;
        minSellAmount = _minSellAmount;
        buyFee = _buyFee;
        sellFee = _sellFee;
        slippage = _slippage;
        blacklistedTokens = _blacklistedTokens;
        for (uint256 i = 0; i < _blacklistedTokens.length; i++) {
            isBlacklisted[_blacklistedTokens[i]] = true;
        }
    }
    
    function deposit() external payable {
        require(msg.sender == owner, "Only the contract owner can deposit.");
    }
    
    function buyTokens(address _token) external {
        require(msg.sender == owner, "Only the contract owner can buy tokens.");
        require(!isBlacklisted[_token], "Token is blacklisted.");
        IPancakeFactory factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73); // PancakeSwap factory address on Binance Smart Chain
        address pairAddress = factory.getPair(_token, factory.WETH());
        require(pairAddress != address(0), "Pair does not exist.");
        IPancakePair pair = IPancakePair(pairAddress);
        uint256 amountOut = pair.token1() == _token ? getAmountOut(pairAddress, msg.value, pair.token0(), pair.token1()) : getAmountOut(pairAddress, msg.value, pair.token1(), pair.token0());
        require(amountOut >= minBuyAmount, "Buy amount too low.");
        require(IBEP20(_token).transfer(address(this), amountOut), "Token transfer failed.");
        uint256 buyFeeAmount = amountOut * buyFee / 100;
        IBEP20(_token).transfer(owner, buyFeeAmount);
        IBEP20(_token).approve(address(factory), amountOut - buyFeeAmount);
        (uint256 amountA, uint256 amountB) = factory.swapExactTokensForTokens(amountOut - buyFeeAmount, 0, getPathForTokenToToken(pair.token1(), pair.token0()), address(this), block.timestamp + 60);
        require(amountA > 0 && amountB > 0, "Token swap failed.");
    }
    
    function sellTokens(address _token) external {
        require(msg.sender == owner, "Only the contract owner can sell tokens.");
        require(!isBlacklisted[_token], "Token is blacklisted.");
        IPancakeFactory factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73); // PancakeSwap factory address on Binance Smart Chain
        address pairAddress = factory.getPair(_token, factory.WETH());
        require(pairAddress != address(0), "Pair does not exist.");
        IPancakePair pair= IPancakePair(pairAddress);
        uint256 amount = IERC20(_token).balanceOf(address(this));
        pair.approve(address(pancakeRouter), amount);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        address token1 = pair.token1();

        uint256 amountOut;
        if (_token == pair.token0()) {
            amountOut = getAmountOut(amount, reserve0, reserve1);
            pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amountOut, 0, getPathForTokenToToken(_token), address(this), block.timestamp + 360);
        } else {
            amountOut = getAmountOut(amount, reserve1, reserve0);
            pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amountOut, 0, getPathForTokenToToken(_token), address(this), block.timestamp + 360);
        }

        uint256 initialBalance = address(this).balance;
        uint256 tokensToSell = IERC20(_token).balanceOf(address(this)) / 3;
        pair.approve(address(pancakeRouter), tokensToSell);

        if (_token == pair.token0()) {
            pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokensToSell, 0, getPathForTokenToToken(_token), address(this), block.timestamp + 360);
        } else {
            pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokensToSell, 0, getPathForTokenToToken(_token), address(this), block.timestamp + 360);
        }

        uint256 soldBalance = address(this).balance - initialBalance;
        uint256 sellAmount = (soldBalance * 33) / 100;
        (bool success, ) = msg.sender.call{value: sellAmount}("");
        require(success, "Failed to send BNB to owner.");
    }

    function withdraw(address _token, uint256 _amount) external {
        require(msg.sender == owner, "Only the contract owner can withdraw funds.");
        if (_token == address(0)) {
            uint256 balance = address(this).balance;
            require(balance >= _amount, "Insufficient balance.");
            (bool success, ) = msg.sender.call{value: _amount}("");
            require(success, "Failed to send BNB to owner.");
        } else {
            uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
            require(tokenBalance >= _amount, "Insufficient balance.");
            IERC20(_token).transfer(msg.sender, _amount);
        }
    }
}
