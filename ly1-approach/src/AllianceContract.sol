//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AllianceContract {
    struct Product {
        uint256 id;
        uint256 pricePerUnit;
    }

    struct Transaction {
        uint256 id;
        address sender;
        address receiver;
        uint256 productId;
        uint256 pricePerUnit;
        uint256 timestamp;
    }

    uint256[] private products;
    Transaction[] private transactions;

    address public owner;
    address[] private users;

    event ProductRegistration(uint256 productId, uint256 pricePerUnit);
    event UserRegistration(address _walletCompany);
    event TransactionRegistration(Transaction transaction);

    error CalculateAveragePricePerProductFailed(uint256 productId);
    error NotFoundProductWithId(uint256 id);
    error NotFoundTransactionWithId(uint256 id);
    error UserAlreadyRegistered(address user);
    error TransactionRegistrationFailed(Transaction transaction);
    error ProductRegistrationFailed(uint256 productId, uint256 pricePerUnit);

    mapping(uint256 => uint256) public pricePerProductById;
    mapping(address => bool) public isUser;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    modifier onlyUser() {
        require(isUser[msg.sender], "Not a user");
        _;
    }

    function userRegistration(
        address _newUser
    ) external onlyOwner returns (bool) {
        if (isUser[_newUser]) {
            revert UserAlreadyRegistered(_newUser);
        } else {
            isUser[_newUser] = true;
            users.push(_newUser);
            emit UserRegistration(_newUser);
            return true;
        }
    }

    function getAllUsers() external view returns (address[] memory) {
        return users;
    }

    function _isProductRegistered(uint256 _id) private view returns (bool) {
        for (uint256 i = 0; i < products.length; i++) {
            if (products[i] == _id) {
                return true;
            }
        }
        return false;
    }

    function productRegistration(
        uint256 _id,
        uint256 _pricePerUnit
    ) external onlyOwner returns (bool) {
        if (_isProductRegistered(_id)) {
            revert ProductRegistrationFailed(_id, _pricePerUnit);
        } else {
            products.push(_id);
            pricePerProductById[_id] = _pricePerUnit;
            emit ProductRegistration(_id, _pricePerUnit);
            return true;
        }
    }

    function getProductById(
        uint256 _id
    ) external view returns (Product memory) {
        for (uint256 i = 0; i < products.length; i++) {
            if (products[i] == _id) {
                return
                    Product({id: _id, pricePerUnit: pricePerProductById[_id]});
            }
        }
        revert NotFoundProductWithId(_id);
    }

    function _averagePricePerProductFromTransactions(
        uint256 _productId
    ) private view returns (uint256) {
        uint256 sum = 0;
        uint256 count = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].productId == _productId) {
                sum += transactions[i].pricePerUnit;
                count++;
            }
        }
        if (count == 0) {
            revert CalculateAveragePricePerProductFailed(_productId);
        } else {
            return sum / count;
        }
    }

    function transactionRegistration(
        uint256 _id,
        address _receiver,
        uint256 _productId,
        uint256 _pricePerUnit,
        uint256 _timestamp
    ) external onlyUser returns (bool) {
        if (
            !isUser[_receiver] &&
            msg.sender == _receiver &&
            !_isProductRegistered(_productId)
        ) {
            revert TransactionRegistrationFailed(
                Transaction({
                    id: _id,
                    sender: msg.sender,
                    receiver: _receiver,
                    productId: _productId,
                    pricePerUnit: _pricePerUnit,
                    timestamp: _timestamp
                })
            );
        } else {
            transactions.push(
                Transaction({
                    id: _id,
                    sender: msg.sender,
                    receiver: _receiver,
                    productId: _productId,
                    pricePerUnit: _pricePerUnit,
                    timestamp: _timestamp
                })
            );
            pricePerProductById[
                _productId
            ] = _averagePricePerProductFromTransactions(_productId);
            emit TransactionRegistration(
                Transaction({
                    id: _id,
                    sender: msg.sender,
                    receiver: _receiver,
                    productId: _productId,
                    pricePerUnit: _pricePerUnit,
                    timestamp: _timestamp
                })
            );
            return true;
        }
    }

    function getAllTransactions()
        external
        view
        onlyUser
        returns (Transaction[] memory)
    {
        return transactions;
    }

    function getTransactionById(
        uint256 _id
    ) external view returns (Transaction memory) {
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].id == _id) {
                return transactions[i];
            }
        }
        revert NotFoundTransactionWithId(_id);
    }
}
