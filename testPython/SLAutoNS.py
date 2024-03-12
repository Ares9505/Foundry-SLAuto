from web3 import Web3
import os
from dotenv import load_dotenv
import ipfsApi
import requests
import time
import json

#Loading enviromental variables
load_dotenv()
ALCHEMY_API_KEY = os.getenv("ALCHEMY_API_KEY")
URL_IPFS_API = os.getenv("URL_IPFS_API")
IPFS_PORT = os.getenv("IPFS_PORT")
SEPOLIA_RPC_URL= os.getenv("SEPOLIA_RPC_URL")
PRIVATE_KEY_PROVIDER= os.getenv("PRIVATE_KEY_PROVIDER")
ETHERSCAN_API_KEY= os.getenv("ETHERSCAN_API_KEY")
WALLET_ADDRESS_PROVIDER = os.getenv("WALLET_ADDRESS_PROVIDER")

    
w3 = Web3(Web3.HTTPProvider(ALCHEMY_API_KEY)) #Alchemy APi (nodeprovider)
ipfs_api = ipfsApi.Client(URL_IPFS_API, IPFS_PORT) #IPFS API

#Market ABI
with open('./out/Market.sol/Market.json') as file:
    contractMarketCompilation = json.load(file)

contract_market_ABI = contractMarketCompilation['abi']

#tomar el ultimo Market.sol desplegado
with open('./broadcast/DeployMarketSepolia.sol/11155111/run-latest.json') as f:
     contract_market_last_deployment = json.load(f)

contract_market_address = contract_market_last_deployment['transactions'][1]['contractAddress']



#Testing conection to ethereum
def test_conexion():
    start = time.time()
    last_block = w3.eth.get_block('latest')
    end = time.time()
    call_duration = end - start
    print("The last block is: ", last_block)
    print("Call duration was: ", call_duration )

#Upload doc to ipfs
def upload_to_ipfs() -> list[3]:    
    response = ipfs_api.add('Readme.md')
    return response


def testBCLatencyCreateSLA():
    contract_market = w3.eth.contract(address=contract_market_address, abi=contract_market_ABI)
    #resultado = contract_market.functions.getOwner().call()
    #print(resultado)
    
    
    doc_hash = 'hash_del_documento'
    params = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]  # Ejemplo de parámetros
    endpoint = 'url_del_endpoint'
    bidding_time = 1000
    start_value = 50

    nonce = w3.eth.get_transaction_count(WALLET_ADDRESS_PROVIDER)
    transaction = contract_market.functions.createCustomSLA(
    doc_hash,
    params,
    endpoint,
    bidding_time,
    start_value
    ).build_transaction({
    'chainId': 11155111,  # Asegúrate de usar el ID de cadena correcto para tu red
    'gas': 2000000,
    'gasPrice': w3.to_wei('50', 'gwei'),
    'nonce': nonce,
    })

    signed_transaction = w3.eth.account.sign_transaction(transaction, PRIVATE_KEY_PROVIDER)
    tx_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(receipt)

def retrieve_from_ipfs(hash):
    #response = ipfs_api.cat(hash)  #Library error
    response = requests.post(f'http://{URL_IPFS_API}:{IPFS_PORT}/api/v0/cat?arg={hash}')   
    return response.content #this response most be saved in a file

#Test retrieve from ipfs
#print(retrieve_from_ipfs('QmYJ9FvMcRKDRquKUHwiAMnAdN2cjDznNdKFn3M3z4nPi8'))

#Test RTT user-provider
#test_conexion()

testBCLatencyCreateSLA()

""" Pendents:
Latency test:

user   ==>  node provider ==> Blockchain
1- RTT (user-nodeprovider) Function test conection X
     tiempo que toma llegar al primer nodo y tener una respuesta
2- RTT llamada a la funcion create SLA de SC Market
3- Registro de cliente
4- RTT oferta de cliente
5- Medición de llamada a chainlink
6- Medir descubrimiento de proveedores
7- Medir tiempo de transferencia



"""