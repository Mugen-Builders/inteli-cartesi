from os import environ
import logging
import requests
import numpy as np
import json

logging.basicConfig(level="INFO")
logger = logging.getLogger(__name__)

rollup_server = environ["ROLLUP_HTTP_SERVER_URL"]
logger.info(f"HTTP rollup_server url is {rollup_server}")

prices = []

# Funções auxiliares

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

def handle_advance(data):
    logger.info(f"Receiving price os transaction {hex2str(data['payload'])} and adding it to the list of transaction prices")
    logger.info("Adding notice")
    binary = hex2str(data['payload'])
    json_data = json.loads(binary)
    prices.append(json_data['price'])
    notice_payload = f'Receiving price os transaction {data["payload"]} and adding it to the list of transaction prices'
    notice = {"payload": str2hex(notice_payload)}
    response = requests.post(rollup_server + "/notice", json=notice)
    logger.info(f"Received notice status {response.status_code} body {response.content}")
    return "accept"

def handle_inspect(data):
    logger.info(f"Received inspect request data {data}")
    logger.info("Adding report")
    mean_price = np.mean(prices)
    report_payload = {"mean": mean_price}
    report = {"payload": str2hex(json.dumps(report_payload))}
    response = requests.post(rollup_server + "/report", json=report)
    logger.info(f"Received report status {response.status_code}")
    return "accept"

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