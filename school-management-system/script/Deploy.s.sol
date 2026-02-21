// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "forge-std/Script.sol";
import "../src/ERC20Token.sol";
import "../src/SaveAsset.sol";
import "../src/SaveEther.sol";
import "../src/SchoolManagement.sol";
import "../src/ToDo.sol";

contract DeployScript is Script {
    ERC20Token public erc20Token;
    SaveAsset public saveAsset;
    SaveEther public saveEther;
    SchoolManagement public schoolManagement;
    ToDo public todo;

    uint8 decimals = 18;
    uint256 initialSupply = 100_000 * 10 ** uint256(decimals);

    function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        deployContracts();

        vm.stopBroadcast();
    }

    function deployContracts() internal {
        erc20Token = new ERC20Token("MyToken", "MTK", decimals, initialSupply);
        saveAsset = new SaveAsset(address(erc20Token));
        saveEther = new SaveEther();
        schoolManagement= new SchoolManagement(address(erc20Token), 200e18, 300e18, 400e18, 500e18);
        todo = new ToDo();
    }

}