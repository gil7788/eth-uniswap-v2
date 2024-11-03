// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "src/LPToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Pair is Ownable, ReentrancyGuard {
    LPToken _lpToken;
    ERC20 _token0;
    ERC20 _token1;
    string _name;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        ERC20 token0,
        ERC20 token1
    ) Ownable(msg.sender) {
        _lpToken = new LPToken(tokenName, tokenSymbol, 0);
        _token0 = token0;
        _token1 = token1;
        string memory token0Symbol = token0.symbol();
        string memory token1Symbol = token1.symbol();
        _name = string(
            abi.encodePacked("uniswap-", token0Symbol, "/", token1Symbol)
        );
    }

    function provideInitLiqudity(
        uint256 token1Amount,
        uint256 token2Amount
    ) public onlyOwner nonReentrant {
        _addLiquidity(token1Amount, token2Amount);
    }

    // Swap functionality
    function swap(
        address from,
        address to,
        uint256 amount
    ) public nonReentrant {
        address tokenAAddress = address(_token0);
        address tokenBAddress = address(_token1);
        address owner = _msgSender();
        require(
            (from == tokenAAddress && to == tokenBAddress) ||
                (from == tokenBAddress && to == tokenAAddress),
            "Invalid token pair"
        );

        ERC20 fromToken = ERC20(from);
        ERC20 toToken = ERC20(to);
        require(fromToken.balanceOf(owner) >= amount, "Insufficient Amount");

        uint256 price = getTokenPrice(from, to, amount);
        fromToken.transferFrom(owner, address(this), amount);
        toToken.transfer(owner, price);
    }

    function getTokenPrice(
        address from,
        address to,
        uint256 amount
    ) internal view returns (uint256) {
        ERC20 erc20From = ERC20(from);
        ERC20 erc20To = ERC20(to);
        uint256 balanceFrom = erc20From.balanceOf(address(this));
        uint256 balanceTo = erc20To.balanceOf(address(this));

        uint256 price = (ceilDiv(balanceFrom, balanceFrom + amount) - 1) *
            balanceTo;
        return price;
    }

    function addLiquidity(address token, uint256 amount) public nonReentrant {
        require(
            token == address(_token0) || token == address(_token1),
            "Invalid token"
        );

        ERC20 erc20Token = ERC20(token);
        uint256 balanceFrom = erc20Token.balanceOf(address(this));

        if (token == address(_token0)) {
            uint256 balanceTo = _token1.balanceOf(address(this));
            uint256 amountTo = ceilDiv(amount * balanceTo, balanceFrom);
            _addLiquidity(amount, amountTo);
        } else if (token == address(_token1)) {
            uint256 balanceTo = _token0.balanceOf(address(this));
            uint256 amountTo = ceilDiv(amount * balanceTo, balanceFrom);
            _addLiquidity(amount, amountTo);
        }
    }

    function _addLiquidity(uint256 amountA, uint256 amountB) internal {
        address owner = _msgSender();
        approve(address(_token0), amountA);
        _token0.transferFrom(owner, address(this), amountA);
        approve(address(_token1), amountB);
        _token1.transferFrom(owner, address(this), amountB);
    }

    function approve(address token, uint256 amount) public {
        require(
            token == address(_token0) || token == address(_token1),
            "Invalid Token"
        );
        ERC20 erc20Token = ERC20(token);
        erc20Token.approve(address(this), amount);
    }

    function ceilDiv(uint256 x, uint256 y) public pure returns (uint256) {
        require(y != 0, "Invalid division by 0");
        if (x == 0) {
            return 0;
        }
        uint256 result = 1 + (x - 1) / y;
        return result;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _lpToken.symbol();
    }
}
