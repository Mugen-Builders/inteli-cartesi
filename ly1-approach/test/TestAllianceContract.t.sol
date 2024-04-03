//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {AllianceContract} from "../src/AllianceContract.sol";

contract TestAllianceContract is Test {
    address user = vm.addr(1);
    address user2 = vm.addr(2);
    address owner = vm.addr(3);

    AllianceContract allianceContract;

    function setUp() public {
        vm.prank(owner);
        allianceContract = new AllianceContract();
    }

    function testUserRegister() public {
        vm.prank(owner);
        assertTrue(allianceContract.userRegistration(user));
        assertTrue(allianceContract.isUser(user));
    }

    function testGetAllUsers() public {
        vm.prank(owner);
        assertTrue(allianceContract.getAllUsers().length == 0);
        vm.prank(owner);
        allianceContract.userRegistration(user);
        assertTrue(allianceContract.getAllUsers().length == 1);
    }

    function testProductResgistration() public {
        vm.prank(owner);
        allianceContract.userRegistration(user);
        vm.prank(owner);
        allianceContract.productRegistration(12345, 1500);
        assertEq(allianceContract.pricePerProductById(12345), 1500);
    }

    function testGetProductById() public {
        vm.prank(owner);
        allianceContract.userRegistration(user);
        vm.prank(owner);
        allianceContract.productRegistration(12345, 1500);
        AllianceContract.Product memory product = allianceContract
            .getProductById(12345);
        assertEq(product.id, 12345);
        assertEq(product.pricePerUnit, 1500);
    }

    function testTransactionRegistration() public {
        vm.prank(owner);
        bool res1 = allianceContract.userRegistration(user);
        vm.prank(owner);
        bool res2 = allianceContract.productRegistration(12345, 1500);
        vm.prank(user);
        bool res3 = allianceContract.transactionRegistration(
            12345,
            user2,
            12345,
            1500,
            12345
        );
        AllianceContract.Transaction memory transaction = allianceContract
            .getTransactionById(12345);
        assertTrue(res1);
        assertTrue(res2);
        assertTrue(res3);
        assertEq(transaction.id, 12345);
        assertEq(transaction.sender, user);
        assertEq(transaction.receiver, user2);
        assertEq(transaction.productId, 12345);
        assertEq(transaction.pricePerUnit, 1500);
        assertEq(transaction.timestamp, 12345);
    }
    function testGetAllTransactions() public {
        vm.prank(owner);
        allianceContract.userRegistration(user);
        vm.prank(user);
        assertTrue(allianceContract.getAllTransactions().length == 0);
        vm.prank(owner);
        allianceContract.productRegistration(12345, 1500);
        vm.prank(user);
        allianceContract.transactionRegistration(
            12345,
            user2,
            12345,
            1500,
            12345
        );
        vm.prank(user);
        uint256 length = allianceContract.getAllTransactions().length;
        assertTrue(length == 1);
    }

    function testGetTransactionById() public {
        vm.prank(owner);
        allianceContract.userRegistration(user);
        vm.prank(owner);
        allianceContract.productRegistration(12345, 1500);
        vm.prank(user);
        allianceContract.transactionRegistration(
            12345,
            user2,
            12345,
            1500,
            12345
        );
        AllianceContract.Transaction memory transaction = allianceContract
            .getTransactionById(12345);
        assertEq(transaction.id, 12345);
        assertEq(transaction.sender, user);
        assertEq(transaction.receiver, user2);
        assertEq(transaction.productId, 12345);
        assertEq(transaction.pricePerUnit, 1500);
        assertEq(transaction.timestamp, 12345);
    }
}
