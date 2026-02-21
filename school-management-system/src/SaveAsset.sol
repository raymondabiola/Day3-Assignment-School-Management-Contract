// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {ERC20Token} from "../src/ERC20Token.sol";

contract SaveAsset{
ERC20Token public erc20Token;
mapping(address => uint) balancesEther;
mapping(address => uint) balancesMTK;

event DepositedEther(address indexed sender, uint256 indexed amount);
event DepositedMTK(address indexed sender, uint256 indexed amount);

    event WithdrewEther(address indexed receiver, uint256 indexed amount);
     event WithdrewMTK(address indexed receiver, uint256 indexed amount);

constructor(address _erc20TokenAddress){
    erc20Token = ERC20Token(_erc20TokenAddress);
}

function depositEther()external payable {
        // require(msg.sender != address(0), "Address zero detected");
        require(msg.value > 0, "Can't deposit zero value");

        balancesEther[msg.sender] = balancesEther[msg.sender] + msg.value;

        emit DepositedEther(msg.sender, msg.value);
    }

function depositMTK( uint256 _amount)external{
    erc20Token.transferFrom(msg.sender, address(this), _amount);
        balancesMTK[msg.sender] += _amount;
        emit DepositedMTK(msg.sender, _amount);
}

function withdrawEther(uint256 _amount) external {
        require(msg.sender != address(0), "Address zero detected");

        require(balancesEther[msg.sender] > 0, "Insufficient funds");

        balancesEther[msg.sender] = balancesEther[msg.sender] - _amount;

        (bool result,) = payable(msg.sender).call{value: _amount}("");

        require(result, "transfer failed");

        emit WithdrewEther(msg.sender, _amount);
    }

    function withdrawMTK(
        uint256 _amount
    ) external{
         require(msg.sender != address(0), "Address zero detected");
    require(_amount > 0, "Invalid Amount");
    require(_amount <= balancesMTK[msg.sender], "Insufficient balance");
        erc20Token.transfer(msg.sender, _amount);
        emit WithdrewMTK(msg.sender, _amount);
    }

    function getMyEtherBalance()external view returns(uint){
        return balancesEther[msg.sender];
    }

    function getMyMTKBalance()external view returns(uint){
        return balancesMTK[msg.sender];
    }

    function getContractEtherBalance()external view returns(uint){
        return address(this).balance;
    }

    function getContractMTKBalance()external view returns(uint){
        return erc20Token.balanceOf(address(this));
    }
}