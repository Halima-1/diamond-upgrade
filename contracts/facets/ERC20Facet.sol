// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibAppStorage, AppStorage} from "../libraries/LibAppStorage.sol";

contract ERC20Facet {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    error AlreadyInitialized();
    error TransferFromZeroAddress();
    error TransferToZeroAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error ApproveFromZeroAddress();
    error ApproveToZeroAddress();

    function initializeERC20(string memory _name, string memory _symbol, uint256 _initialSupply) external {
        AppStorage storage s = LibAppStorage.appStorage();
        if (bytes(s.tokenName).length != 0) revert AlreadyInitialized();

        s.tokenName = _name;
        s.tokenSymbol = _symbol;
        s.tokenTotalSupply = _initialSupply;
        s.tokenBalances[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function nameERC20() external view returns (string memory) {
        return LibAppStorage.appStorage().tokenName;
    }

    function symbolERC20() external view returns (string memory) {
        return LibAppStorage.appStorage().tokenSymbol;
    }

    function totalSupply() external view returns (uint256) {
        return LibAppStorage.appStorage().tokenTotalSupply;
    }

    function balanceOfERC20(address account) external view returns (uint256) {
        return LibAppStorage.appStorage().tokenBalances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return LibAppStorage.appStorage().tokenAllowances[owner][spender];
    }

    function approveERC20(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFromERC20(address sender, address recipient, uint256 amount) external returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 currentAllowance = s.tokenAllowances[sender][msg.sender];

        if (currentAllowance < amount) revert InsufficientAllowance();

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        if (sender == address(0)) revert TransferFromZeroAddress();
        if (recipient == address(0)) revert TransferToZeroAddress();
        if (s.tokenBalances[sender] < amount) revert InsufficientBalance();

        s.tokenBalances[sender] -= amount;
        s.tokenBalances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        if (owner == address(0)) revert ApproveFromZeroAddress();
        if (spender == address(0)) revert ApproveToZeroAddress();

        s.tokenAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}