// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyBank{
    mapping(address => uint256) balances;
    function balanceOf() public view returns(uint balance){
        return balances[msg.sender];
    }
    function deposit(uint256 amount) public returns(bool){
        balances[msg.sender] = balances[msg.sender] + amount;
        return true;
    }
    function withdraw(uint256 amount) public returns(bool){
        require(balances[msg.sender]>=amount, "Balance is not enought");
        balances[msg.sender] -= amount;
        return true;
    }
}