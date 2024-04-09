from os import environ
import logging
import requests
import numpy as np
import json
import traceback


class Transaction:
    def __init__(self, _id: str, sender: str, receiver: str, product_id: str, price: int, quantity: int, timestamp: int):
        self.id = _id
        self.sender = sender
        self.receiver = receiver
        self.product_id = product_id
        self.price = price
        self.price_per_unit = price / quantity
        self.quantity = quantity
        self.timestamp = timestamp

    def to_dict(self):
        return {
            "id": self.id,
            "sender": self.sender,
            "receiver": self.receiver,
            "product_id": self.product_id,
            "price": self.price,
            "price_per_unit": self.price_per_unit,
            "quantity": self.quantity,
            "timestamp": self.timestamp
        }


owner = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
confirmed_transactions = []
not_confirmed_transactions = []
users = []

logging.basicConfig(level="INFO")
logger = logging.getLogger(__name__)
rollup_server = environ.get(
    "ROLLUP_HTTP_SERVER_URL", "http://127.0.0.1:8080/rollup")
logger.info(f"HTTP rollup_server url is {rollup_server}")


def str2hex(string):
    return binary2hex(str2binary(string))


def str2binary(string):
    return string.encode("utf-8")


def binary2hex(binary):
    return "0x" + binary.hex()


def hex2binary(hexstr):
    return bytes.fromhex(hexstr[2:])


def hex2str(hexstr):
    return hex2binary(hexstr).decode("utf-8")
# HTTP API functions


def send_notice(notice: str) -> None:
    send_post("notice", notice)


def send_report(report: str) -> None:
    send_post("report", report)


def send_post(endpoint, json_data) -> None:
    response = requests.post(rollup_server + f"/{endpoint}", json=json_data)
    logger.info(
        f"/{endpoint}: Received response status {response.status_code} body {response.content}")


def handle_advance(data):
    logger.info(
        f"Receiving advance request with data {hex2str(data['payload'])} from {data['metadata']['msg_sender']}")
    binary = hex2str(data['payload'])
    json_data = json.loads(binary)
    logger.info(f"Received json data {json_data}")
    try:
        if json_data["method"] == "addNewUser" and data["metadata"]["msg_sender"] == owner.lower():
            users.append(json_data["data"])
            notice_payload = {"payload": str2hex(
                f'Add new user {data["payload"]} to the list of users')}
            send_notice(notice_payload)
            return "accept"
        elif json_data["method"] == "deleteUser" and data["metadata"]["msg_sender"] == owner.lower():
            users.remove(json_data["data"])
            notice_payload = {"payload": str2hex(
                f'Delete user {data["payload"]} from the list of users')}
            send_notice(notice_payload)
            return "accept"
        elif json_data["method"] == "addNewTransaction":
            tx = Transaction(
                _id=json_data["data"]["id"],
                sender=data["metadata"]["msg_sender"],
                receiver=json_data["data"]["receiver"].lower(),
                product_id=json_data["data"]["product_id"],
                price=json_data["data"]["price"],
                quantity=json_data["data"]["quantity"],
                timestamp=json_data["data"]["timestamp"]
            )
            not_confirmed_transactions.append(tx)
            notice_payload = {"payload": str2hex(
                f'Add new transaction {data["payload"]} to the list of not confirmed transactions')}
            send_notice(notice_payload)
            return "accept"
        elif json_data['method'] == "validateTransaction":
            for transaction in not_confirmed_transactions:
                if str(transaction.id) == str(json_data["data"]):
                    if str(transaction.receiver) == str(data["metadata"]["msg_sender"]):
                        not_confirmed_transactions.remove(transaction)
                        confirmed_transactions.append(transaction)
                        notice_payload = {"payload": str2hex(
                            f'Transaction {data["payload"]} confirmed')}
                        send_notice(notice_payload)
            return "accept"
    except Exception as e:
        msg = f"Error {e} processing data {data}"
        logger.error(f"{msg}\n{traceback.format_exc()}")
        send_report({"payload": str2hex(msg)})
        return "reject"


def handle_inspect(data):
    logger.info(f"Received inspect request data {data}")
    binary = hex2str(data['payload'])
    try:
        if binary == "users":
            users_data = ",".join(users)
            report_payload = {"all_users": f"{users_data}"}
            send_report({"payload": str2hex(f'{report_payload}')})
            return "accept"
        if binary == "transactions/confirmed":
            confirmed_transactions_data = [
                transaction.to_dict() for transaction in confirmed_transactions]
            report_payload = {
                "confirmed_transactions": f"{confirmed_transactions_data}"}
            send_report({"payload": str2hex(f'{report_payload}')})
            return "accept"
        if binary == "transactions/not_confirmed":
            not_confirmed_transactions_data = [
                transaction.to_dict() for transaction in not_confirmed_transactions]
            report_payload = {
                "not_confirmed_transactions": f"{not_confirmed_transactions_data}"}
            send_report({"payload": str2hex(f'{report_payload}')})
            return "accept"
        if binary.split('/')[0] == 'mean':
            product_id = binary.split('/')[1]
            transaction_by_product_id = [transaction.to_dict(
            ) for transaction in confirmed_transactions if transaction.product_id == product_id]
            prices_by_id = [entry['price_per_unit']
                            for entry in transaction_by_product_id]
            mean_price_by_product_id = np.mean(prices_by_id)
            report_payload = {"product_id": f"{product_id}",
                              "mean_price": f"{mean_price_by_product_id}"}
            send_report({"payload": str2hex(str(report_payload))})
            return "accept"
    except Exception as e:
        msg = f"Error {e} processing data {data}"
        logger.error(f"{msg}\n{traceback.format_exc()}")
        send_report({"payload": str2hex(msg)})
        return "reject"


handlers = {
    "advance_state": handle_advance,
    "inspect_state": handle_inspect,
}

finish = {"status": "accept"}

while True:
    logger.info("Sending finish")
    response = requests.post(rollup_server + "/finish", json=finish)
    logger.info(f"Received finish status {response.status_code}")
    if response.status_code == 202:
        logger.info("No pending rollup request, trying again")
    else:
        rollup_request = response.json()
        data = rollup_request["data"]
        handler = handlers[rollup_request["request_type"]]
        finish["status"] = handler(rollup_request["data"])
