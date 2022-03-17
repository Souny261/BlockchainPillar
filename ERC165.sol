//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHello{
    function hello() external;
    function world() external;
}

contract Hello{
    function getInterfaeId() public pure returns(bytes4){
        return type(IHello).interfaceId;
    }

    function getSelector() public pure returns(bytes4){
        return IHello.hello.selector;
    }
}