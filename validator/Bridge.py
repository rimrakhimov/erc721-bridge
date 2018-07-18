import time

from web3 import Web3, HTTPProvider
# from web3.utils.events import get_event_data
from json import load, dump
import os

def initializeContractFactory(_w3, _key, _address):
    with open(abiDict[_key]) as _file:
         abi = load(_file)
    contract = _w3.eth.contract(
        abi=abi,
        address=_address
    )
    return contract

def getPrivateKey():
    with open("./privateKeyExample.json") as file:
        return load(file)["key"]

def getContractAddress():
    with open("./contracts.json") as file:
        return load(file)

def getLastProcessedBlock(_key):
    if not os.path.exists(f"{_key}.json"):
        writeDataBase({"blockNumber": 0}, f"{_key}.json")
        return 0
    with open(f"{_key}.json") as f:
        return load(f)['blockNumber']

def writeDataBase(_data, _file):
    with open(_file, 'w') as out:
        dump(_data, out)

def getEventAbi():
    with open(abiDict['request']) as _file:
         abi = load(_file)
    return abi

def main():
    print("hello")

# contract files
abiDict = {'token': '../abi/ERC721Abi.json',
       'homeBridge': '../abi/HomeBridgeAbi.json',
       'foreignBridge': '../abi/ForeignBridgeAbi.json',
       'request': '../abi/UserRequestForSignatureAbi.json'}

# w3Kovan = Web3(HTTPProvider("https://kovan.infura.io/2gCvo0mqwJtdyCThCLmC"))
w3Kovan = Web3(HTTPProvider("https://kovan.infura.io/mew"))
# w3Kovan = Web3(WebsocketProvider("wss://mainnet.infura.io/ws"))
w3Sokol = Web3(HTTPProvider("https://sokol.poa.network/"))

kovanERC721 = initializeContractFactory(w3Kovan, 'token', Web3.toChecksumAddress(getContractAddress()["ERC721Home"]))
kovanBridge = initializeContractFactory(w3Kovan, 'homeBridge', Web3.toChecksumAddress(getContractAddress()["HomeBridge"]))
sokolERC721 = initializeContractFactory(w3Sokol, 'token', Web3.toChecksumAddress(getContractAddress()["ERC721Foreign"]))
sokolBridge = initializeContractFactory(w3Sokol, 'foreignBridge', Web3.toChecksumAddress(getContractAddress()["ForeignBridge"]))

abi = getEventAbi()

logs = w3Kovan.eth.getLogs(
        {"fromBlock": 0, "toBlock": 'latest', "address": "0xc2E9A7D509d8623486e14cBc6Cd81c80243a58b7",
         'topics': ['0x0831de4e17a15d5b767132e3a83ab45377a7327cf889e873bae8e6b772b50c61']})

print(w3Sokol.eth.account.privateKeyToAccount(getPrivateKey()).address)
print(w3Sokol.eth.getTransactionCount(w3Sokol.eth.account.privateKeyToAccount(getPrivateKey()).address))

while True:
    # userHomeRequestForSignature_filter = kovanBridge.eventFilter('UserRequestForSignature')
    logs = w3Kovan.eth.getLogs(
        {"fromBlock": getLastProcessedBlock("homeLastProcessedBlock"), "toBlock": 'latest',
         "address": Web3.toChecksumAddress(getContractAddress()['HomeBridge']),
         'topics': ['0x0831de4e17a15d5b767132e3a83ab45377a7327cf889e873bae8e6b772b50c61']})
    for i in logs:
        receipt = w3Kovan.eth.getTransactionReceipt(i['transactionHash'])
        request = kovanBridge.events.UserRequestForSignature().processReceipt(receipt)[0]
        nonce = w3Sokol.eth.getTransactionCount(w3Sokol.eth.account.privateKeyToAccount(getPrivateKey()).address)
        tx = sokolBridge.functions.transferApproved(request['args']['_from'], request['args']['_tokenVIN'], request['args']['_data'], request['transactionHash']).buildTransaction({
            'gas': 7000000,
            'gasPrice': w3Sokol.toWei(1, 'gwei'),
            'nonce': nonce
        })
        signed_txn = w3Sokol.eth.account.signTransaction(tx, private_key=getPrivateKey())
        txHash = w3Sokol.eth.sendRawTransaction(signed_txn.rawTransaction)
        print(w3Sokol.eth.waitForTransactionReceipt(txHash))
        print(request)
        writeDataBase({'blockNumber': request['blockNumber']+1}, "./homeLastProcessedBlock.json")

    userForeignRequestForSignature_filter = sokolBridge.events.UserRequestForSignature.createFilter(
        fromBlock=getLastProcessedBlock("foreignLastProcessedBlock"), toBlock='latest'
    )
    logs = userForeignRequestForSignature_filter.get_all_entries()
    print(logs)
    for request in logs:
        nonce = w3Kovan.eth.getTransactionCount(w3Kovan.eth.account.privateKeyToAccount(getPrivateKey()).address)
        tx = kovanBridge.functions.transferApproved(request['args']['_from'], request['args']['_tokenVIN'],
                                                    request['args']['_data'],
                                                    request['transactionHash']).buildTransaction({
            'gas': 7000000,
            'gasPrice': w3Sokol.toWei(1, 'gwei'),
            'nonce': nonce
        })
        signed_txn = w3Kovan.eth.account.signTransaction(tx, private_key=getPrivateKey())
        w3Kovan.eth.sendRawTransaction(signed_txn.rawTransaction)
        txHash = w3Kovan.eth.sendRawTransaction(signed_txn.rawTransaction)
        print(w3Kovan.eth.waitForTransactionReceipt(txHash))
        print(request)
        writeDataBase({'blockNumber': request['blockNumber']+1}, "./foreignLastProcessedBlock.json")
    time.sleep(5)