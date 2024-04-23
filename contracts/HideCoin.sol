// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HideCoin is ERC20, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    bool public launched;

    uint256 public constant maxSupply = 1000_000_000 ether;

    uint256 private _currentSupply = 0;

    mapping(address => bool) private _isExcludedFromLimits;
    mapping(address => bool) private _isBot;

    event Launch(uint256 blockNumber, uint256 timestamp);
    event WithdrawStuckTokens(address token, uint256 amount);
    event ExcludeFromLimits(address indexed account, bool value);
    event SetBots(address indexed account, bool value);
    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    constructor(
        address initialOwner
    ) ERC20("Hide Coin", "HIDE") Ownable(initialOwner) {
        _excludeFromLimits(_msgSender(), true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0xdead), true);
    }

    receive() external payable {}

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
        emit Burn(_msgSender(), amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        uint256 supply = _currentSupply + amount;

        require(supply <= maxSupply, "HideCoin: Exceeds max supply");
        _mint(to, amount);
        _currentSupply += amount;
        emit Mint(to, amount);
    }

    function launch() public onlyOwner {
        require(!launched, "HideCoin: Already launched.");
        launched = true;
        emit Launch(block.number, block.timestamp);
    }

    function withdrawStuckTokens(address token) public onlyOwner {
        uint256 amount;
        if (token == address(0)) {
            bool success;
            amount = address(this).balance;
            (success, ) = address(_msgSender()).call{value: amount}("");
        } else {
            amount = IERC20(token).balanceOf(address(this));
            require(amount > 0, "HideCoin: No tokens");
            IERC20(token).safeTransfer(_msgSender(), amount);
        }
        emit WithdrawStuckTokens(token, amount);
    }

    function excludeFromLimits(
        address[] calldata accounts,
        bool value
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _excludeFromLimits(accounts[i], value);
        }
    }

    function setBots(address[] calldata accounts, bool value) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (
                (accounts[i] != address(this)) &&
                (!_isExcludedFromLimits[accounts[i]])
            ) _setBots(accounts[i], value);
        }
    }

    function isExcludedFromLimits(address account) public view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function isBot(address account) public view returns (bool) {
        return _isBot[account];
    }

    function currentSupply() public view returns (uint256) {
        return _currentSupply;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20) {
        if (_isExcludedFromLimits[from] || _isExcludedFromLimits[to]) {
            super._update(from, to, value);
            return;
        }

        require(!_isBot[from], "HideCoin: Bot detected");
        require(
            _msgSender() == from || !_isBot[_msgSender()],
            "HideCoin: Bot detected"
        );
        require(
            tx.origin == from ||
                tx.origin == _msgSender() ||
                !_isBot[tx.origin],
            "HideCoin: Bot detected"
        );

        address ownr = owner();

        require(
            launched || from == ownr || to == ownr || to == address(0xdead),
            "HideCoin: Not launched."
        );

        super._update(from, to, value);
    }

    function _excludeFromLimits(address account, bool value) internal virtual {
        _isExcludedFromLimits[account] = value;
        emit ExcludeFromLimits(account, value);
    }

    function _setBots(address account, bool value) internal virtual {
        _isBot[account] = value;
        emit SetBots(account, value);
    }
}
