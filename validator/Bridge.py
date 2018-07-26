from time import sleep
from web3 import Web3, HTTPProvider
from json import load, dump
from os import path

# initialize contracts
def initializeContractFactory(_w3, _path, _address):
    abi = getAbi(_path)
    contract = _w3.eth.contract(
        abi=abi,
        address=_address
    )
    return contract

# get private key from json file
def getPrivateKey():
    privateKeyPath = "/privateKey.json"
    if not path.exists(privateKeyPath):
        with open("./privateKey.json") as file:
            return load(file)["key"]
    else:
        print("Private key was not found")
        exit()

# get contract address from json file
def getContractAddress():
    with open("./contracts.json") as file:
        return load(file)

# get last processed block from json file
def getLastProcessedBlock(_key):
    if not path.exists(_key):
        writeDataBase({"blockNumber": 0}, _key)
        return 0
    with open(_key) as f:
        return load(f)['blockNumber']

# write _data in external _file
def writeDataBase(_data, _file):
    with open(_file, 'w') as out:
        dump(_data, out)

# get abi for contracts at specified path
def getAbi(_path):
    with open(_path) as _file:
         abi = load(_file)
    return abi

def main(_w3Home, _w3Foreign):
    homeBridge = initializeContractFactory(_w3Home, "../abi/bridge_abi.json",
                                           Web3.toChecksumAddress(getContractAddress()["HomeBridge"]))
    foreignBridge = initializeContractFactory(_w3Foreign, "../abi/bridge_abi.json",
                                              Web3.toChecksumAddress(getContractAddress()["ForeignBridge"]))

    acct = _w3Home.eth.account.privateKeyToAccount(getPrivateKey())

    # infinite loop which processes both networks in row
    while True:
        print([])
        filterHome = {
            "fromBlock": getLastProcessedBlock(lastProcessedHomeBlockPath),
            "toBlock": "latest",
            "address": homeBridge.address
        }
        logs = _w3Home.eth.getLogs(filterHome)
        for i in logs:
            receipt = _w3Home.eth.getTransactionReceipt(i['transactionHash'])
            events = homeBridge.events.UserRequestForSignature().processReceipt(receipt)
            for ev in events:
                nonce = _w3Foreign.eth.getTransactionCount(acct.address)
                tx_foreign = {
                    "gas": 7000000,
                    "gasPrice": gasPrice,
                    "nonce": nonce
                }
                tx = foreignBridge.functions.transferApproved(
                    ev.args['_from'],
                    ev.args['_tokenVIN'],
                    ev.args['_data'],
                    ev.transactionHash
                ).buildTransaction(tx_foreign)
                signed_tx = acct.signTransaction(tx)
                tx_hash = _w3Foreign.eth.sendRawTransaction(signed_tx.rawTransaction)
                _w3Foreign.eth.waitForTransactionReceipt(tx_hash)
                print(tx_hash.hex())
            writeDataBase({'blockNumber': receipt.blockNumber + 1}, lastProcessedHomeBlockPath)

        filterForeign = {
            "fromBlock": getLastProcessedBlock(lastProcessedForeignBlockPath),
            "toBlock": "latest",
            "address": foreignBridge.address
        }
        logs = _w3Foreign.eth.getLogs(filterForeign)
        for i in logs:
            receipt = _w3Foreign.eth.getTransactionReceipt(i['transactionHash'])
            events = foreignBridge.events.UserRequestForSignature().processReceipt(receipt)
            for ev in events:
                nonce = _w3Home.eth.getTransactionCount(acct.address)
                tx_home = {
                    "gas": 7000000,
                    "gasPrice": gasPrice,
                    "nonce": nonce
                }
                tx = homeBridge.functions.transferApproved(
                    ev.args['_from'],
                    ev.args['_tokenVIN'],
                    ev.args['_data'],
                    ev.transactionHash
                ).buildTransaction(tx_home)
                signed_tx = acct.signTransaction(tx)
                tx_hash = _w3Home.eth.sendRawTransaction(signed_tx.rawTransaction)
                _w3Home.eth.waitForTransactionReceipt(tx_hash)
                print(tx_hash.hex())
            writeDataBase({'blockNumber': receipt.blockNumber + 1}, lastProcessedForeignBlockPath)
        sleep(5)

w3Home = Web3(HTTPProvider("https://sokol.poa.network/"))
w3Foreign = Web3(HTTPProvider("https://kovan.infura.io/mew"))

lastProcessedHomeBlockPath = "../additional_data/homeLastProcessedBlock.json"
lastProcessedForeignBlockPath = "../additional_data/foreignLastProcessedBlock.json"

gasPrice = Web3.toWei(1, "gwei")

main(w3Home, w3Foreign)