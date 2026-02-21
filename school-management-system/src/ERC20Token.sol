// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ERC20Token {
string private _name;
string private _symbol;
uint8 private immutable _decimals;
uint private _totalSupply;

mapping(address => uint) balances;
mapping(address => mapping(address => uint)) allowances;

event Transfer(address indexed _from, address indexed _to, uint indexed _value);
event Approval(address indexed _owner, address indexed _spender, uint indexed _value);

error InvalidAddress();
error InvalidAmount();
error InsufficientAllowance();

constructor(string memory name_, string memory symbol_, uint8 decimals_, uint _initialSupply) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        balances[msg.sender] = _initialSupply;
        _totalSupply += _initialSupply;

    }

function name() public view returns(string memory){
return _name;
}

function symbol() public view returns(string memory){
    return _symbol;
}

function decimals() public view returns(uint8){
    return _decimals;
}

function totalSupply() public view returns(uint){
    return _totalSupply;
}

function mint(address _address, uint _value)public{
    require(_address != address(0), InvalidAddress());
    require(_value > 0, InvalidAmount());
    _totalSupply += _value;
    balances[_address] += _value;
    emit Transfer(address(0), _address, _value);
}

function burn(uint _value)public{
    require(_value > 0, InvalidAmount());
    balances[msg.sender] -= _value;
    _totalSupply -= _value;
    emit Transfer(msg.sender, address(0), _value);
}

function balanceOf(address _address) public view returns(uint){
    return balances[_address];
}


function approve(address _spender, uint _amount) public returns(bool success){
allowances[msg.sender][_spender] = _amount;
emit Approval(msg.sender, _spender, _amount);
return true;
}

function allowance(address _owner, address _spender) public view returns(uint){
   return allowances[_owner][_spender];
}

function transfer(address _to, uint _value) public returns(bool success){
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
}
function transferFrom(address _from, address _to, uint _value) public returns(bool success){
 require(_value > 0, InvalidAmount());
 require(allowances[_from][msg.sender] >= _value, InsufficientAllowance());
 allowances[_from][msg.sender] -= _value;
 balances[_from] -= _value;
 balances[_to] += _value;
 emit Transfer(_from, _to, _value);
 return true;
}

function burnFrom(address _from, uint _value) public returns(bool success){
    require(_value > 0, InvalidAmount());
 require(allowances[_from][msg.sender] >= _value, InsufficientAllowance());
 allowances[_from][msg.sender] -= _value;
 balances[_from] -= _value;
 _totalSupply -= _value;
 emit Transfer(_from, address(0), _value);
 return true;
}

}
