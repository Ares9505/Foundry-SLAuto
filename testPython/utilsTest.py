from web3 import Web3
import os
from dotenv import load_dotenv
import ipfsApi
import requests
import time
import datetime
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
SEPOLIA_CHAIN_ID = 11155111
POLYGON_CHAIN_ID = 137

   
w3 = Web3(Web3.HTTPProvider(ALCHEMY_API_KEY)) #Alchemy APi (nodeprovider)
ipfs_api = ipfsApi.Client(URL_IPFS_API, IPFS_PORT) #IPFS API

#Market ABI
with open('./out/Market.sol/Market.json') as file:
    contractMarketCompilation = json.load(file)

contract_market_ABI = contractMarketCompilation['abi']

#tomar el ultimo Market.sol desplegado
with open('./broadcast/DeployMarketSepolia.sol/11155111/run-latest.json') as f:
     contract_market_last_deployment = json.load(f)

contract_market_address = contract_market_last_deployment['transactions'][0]['contractAddress']
contract_market = w3.eth.contract(address=contract_market_address, abi=contract_market_ABI)


#Auction ABI
with open('./out/Auction.sol/Auction.json') as file:
    contractAuctionCompilation = json.load(file)

contract_Auction_ABI = contractAuctionCompilation['abi']

#tomar el ultimo Auction.sol desplegado
with open('./broadcast/DeployAuctionSepolia.s.sol/11155111/run-latest.json') as f:
     contract_Auction_last_deployment = json.load(f)

contract_Auction_address = contract_Auction_last_deployment['transactions'][0]['contractAddress']
contract_Auction = w3.eth.contract(address=contract_Auction_address, abi=contract_Auction_ABI)


#Upload doc to ipfs
def upload_to_ipfs() -> list[3]:    
    response = ipfs_api.add('Readme.md')
    return response

def retrieve_from_ipfs(hash):
    #response = ipfs_api.cat(hash)  #Library error
    response = requests.post(f'http://{URL_IPFS_API}:{IPFS_PORT}/api/v0/cat?arg={hash}')   
    return response.content #this response most be saved in a file


#Testing conection to sepolia
#this test give me RTT user-provider
def test_conexion():
    start = time.time()
    last_block = w3.eth.get_block('latest')
    end = time.time()
    call_duration = end - start
    print("The last block is: ", last_block)
    print("Call duration was: ", call_duration )


def testBCLatencyCreateSLA():
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
    'chainId': 11155111,  # Asegúrate de usar el ID de cadena correcto para tu red Sepolia
    'gas': 8000000,
    'gasPrice': w3.eth.gas_price, #w3.to_wei('50', 'gwei'),
    'nonce': nonce,
    })

    signed_transaction = w3.eth.account.sign_transaction(transaction, PRIVATE_KEY_PROVIDER)
    tx_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(receipt)


def testCreateSLA():#using generic transaction
    doc_hash = 'hash_del_documento'
    params = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]  # Ejemplo de parámetros
    endpoint = 'url_del_endpoint'
    bidding_time = 1000
    start_value = 50
    receipt, rtt = genericTransaction(contract_market , "createCustomSLA", 0, SEPOLIA_CHAIN_ID , doc_hash, params, endpoint, bidding_time, start_value)


def testAddProvider():
    providerName = "dummyName"
    providerAddress = "0xC9a7A5F8f2BDf39f602f2F5ab68c8790789Ca63f"
    receipt, rtt = genericTransaction(contract_market , "addProvider", 0, SEPOLIA_CHAIN_ID, providerName, providerAddress )
    print(receipt)

def testAddClient():
    clientName = "dummyClientName"
    clientAddress = "0xC9a7A5F8f2BDf39f602f2F3ab68c8790789Ca63f"
    receipt, rtt = genericTransaction(contract_market , "addClient", 0, SEPOLIA_CHAIN_ID, clientName, clientAddress )
    print(receipt)

def testBid():
    #the miniun configured in the contract is 10000000000000 wei = 0.00001 ether
    receipt, rtt = genericTransaction(contract_Auction, "bid", 100500000000000, SEPOLIA_CHAIN_ID)
    print(receipt)

def genericTransaction(contract, function_name: str, value: int, chain_id: int,  *parameters):
    #save transactionCount
    nonce = w3.eth.get_transaction_count(WALLET_ADDRESS_PROVIDER)

    executable_function = getattr(contract.functions,function_name )
    transaction = executable_function(*parameters).build_transaction({
    'chainId': chain_id ,  # Asegúrate de usar el ID de cadena correcto para tu red Sepolia
    'gas': 8000000,
    'gasPrice':w3.eth.gas_price, #w3.to_wei('50', 'gwei'),
    'nonce': nonce,
    'value' : value
    })
    signed_transaction = w3.eth.account.sign_transaction(transaction, PRIVATE_KEY_PROVIDER)
    tx_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
    start = time.time()
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    end = time.time()
    rtt = end - start
    return receipt, rtt


def check_events() -> dict:
    logs = contract_market.events.e_createSLA().get_logs(fromBlock=0, toBlock='latest')
    for log in logs:
        print(log)
    return logs

def filterAvailableSLA(logs: dict):
    utc_now = datetime.datetime.utcnow()
    # Convertir a timestamp en Unix (segundos desde epoch)
    actual_time = int(time.mktime(utc_now.timetuple()))
    for log in logs:
        endDate = int(log['args']['endDate'])
        if endDate > actual_time:
            #save to database in case of dApp
            print(log)



def getMethodSelectorByFunction(contract_method_name: str) -> str:
    #Posible inputs                                                    outputs
    # "createCustomSLA(string,uint256[22],string,uint256,uint256)"     0x7606b37a
    # "addProvider(string,address)"                                    0x1e6e256d
    # "addClient(string,address)"                                      0x7545657e
    # "bid()"                                                          0x1998aeef

    # Calculate hash Keccak-256 de la firma
    keccak_hash = Web3.keccak(text=contract_method_name)
    # Obtein hash's  first  4 bytes 
    method_selector = keccak_hash.hex()[:10]
    return method_selector


print(getMethodSelectorByFunction("bid()"))
#Test retrieve from ipfs
#print(retrieve_from_ipfs('QmYJ9FvMcRKDRquKUHwiAMnAdN2cjDznNdKFn3M3z4nPi8'))

#Test RTT user-provider
#test_conexion()

#Test RTT create SLA 
# testBCLatencyCreateSLA()
# logs = check_events()

#Test discovery sla available (pendent)
# filterActiveContracts(logs)
            
#Generic payable function call
#genericTransaction()
            
# testAddProvider()
# testBid()

# print(contract_market_ABI)
# print("")
# print(contract_market_    address)

""" Pendents:
Latency test:

user   ==>  node provider ==> Blockchain
0- RTT de despliegue de Market desde python para medir tiempo de subida


1- RTT (user-nodeprovider) Function test conection X
     tiempo que toma llegar al primer nodo y tener una respuesta
     

2- RTT llamada a la funcion create SLA de SC Market
    Verificar contrato Market
        >>forge verify-contract <address> SomeContract --watch
        >>forge verify-contract --etherscan-api-key $ETHERSCAN_API_KEY --chain 11155111 0x232A4De01083FdC87Edd04e6D3A46e5CF2018538 ./src/Market.sol:Market --watch


    Añadir evento al contrato de creacion de SLA y Subasta X
    Subscribirse al evento X
    Guardar logs del evento con python X
    Filtrar logs para sla activos X

2.1- Añadir eventos a los contratos X

3- Registro de cliente  X
4- RTT oferta de cliente X
4.1- RTT bid y auctionEnd functions X
5- Medir descubrimiento de proveedores X

6- Medición de llamada a chainlink 
7- Medir tiempo de transferencia SLA 

7.1 - Medir tiempo de withdraw function 

8- Repetir pruebas para otra blockchain

8- Estimar limite de SLAs
9- Estimar limite de llamadas por segundo usando una API

10- Graficos de mediciones de tiempo y costos.
        Como guardar los datos?


11- Elementos a considerar en el diseño de un sistema que involucre smart contract para monitorear slas



"""