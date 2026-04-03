// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function initializeERC20(string memory _name, string memory _symbol, uint256 _initialSupply) external;
    function nameERC20() external view returns (string memory);
    function symbolERC20() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOfERC20(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approveERC20(address spender, uint256 amount) external returns (bool);
    function transferFromERC20(address sender, address recipient, uint256 amount) external returns (bool);
}
