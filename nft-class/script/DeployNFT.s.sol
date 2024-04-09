// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC721Inteli} from "../src/token/ERC721/ERC721Inteli.sol";

contract DeployContracts is Script {
    function run() external {
        bytes32 _salt = bytes32(abi.encode(2024));
        vm.startBroadcast();
        ERC721Inteli erc721 = new ERC721Inteli{salt: _salt}();
        erc721.safeMint()
        vm.stopBroadcast();
        console.log(
            "ERC721Deroll address:",
            address(erc721),
            "at network:",
            block.chainid
        );
    }
}