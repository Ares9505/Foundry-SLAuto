from web3 import Web3
import os
from dotenv import load_dotenv
import ipfsApi
import requests
import time
import datetime
import json
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from web3.middleware import geth_poa_middleware

#Loading enviromental variables
load_dotenv()

URL_IPFS_API = os.getenv("URL_IPFS_API")
IPFS_PORT = os.getenv("IPFS_PORT")
PRIVATE_KEY_PROVIDER= os.getenv("PRIVATE_KEY_PROVIDER")
ETHERSCAN_API_KEY= os.getenv("ETHERSCAN_API_KEY")
WALLET_ADDRESS_PROVIDER = os.getenv("WALLET_ADDRESS_PROVIDER")
SEPOLIA_CHAIN_ID = 11155111
SEPOLIA_RPC_URL= os.getenv("SEPOLIA_RPC_URL")
POLYGON_CHAIN_ID = 80001
POLYGON_RPC_URL= os.getenv("POLYGON_RPC_URL") #(Pendent)

#IPFS setup
ipfs_api = ipfsApi.Client(URL_IPFS_API, IPFS_PORT) #IPFS API

#Blockchain selection Setup
#-------------------------------------
CURRENT_CHAIN= "Sepolia" 

if CURRENT_CHAIN == "Sepolia":
    provider = SEPOLIA_RPC_URL
    current_chain_id = SEPOLIA_CHAIN_ID
    contract_address_market_function_test = "0x11C2AD05412900B94e113eD40A968eAe31fD28aD" 
elif CURRENT_CHAIN == "Polygon":
    provider = POLYGON_RPC_URL
    current_chain_id = POLYGON_CHAIN_ID
    contract_address_market_function_test = "0x8662B405dcE018300D2A8F5A8240014F1cd0420D"
else:
    print("Setup blockchain error. Invalidad chain name")

w3 = Web3(Web3.HTTPProvider(provider)) #Alchemy APi (nodeprovider) Sepolia URL RPC

if CURRENT_CHAIN == "Polygon":
    if geth_poa_middleware not in w3.middleware_onion:
        w3.middleware_onion.inject(geth_poa_middleware, layer=0)
#------------------------------------------


def test_conexion():
    start = time.time()
    last_block = w3.eth.get_block('latest')
    end = time.time()
    call_duration = end - start
    print("User-Provider Rtt: ", call_duration )
    return call_duration

def deployContract(contract, value: int, chain_id: int,  *parameters):
    #save transactionCount
    nonce = w3.eth.get_transaction_count(WALLET_ADDRESS_PROVIDER)
    print("chain_id : ", chain_id)
    print("nonce : " , nonce)
    provider = parameters[0]
    transaction = contract.constructor(provider).build_transaction({
    'chainId': chain_id ,  # Asegúrate de usar el ID de cadena correcto para tu red Sepolia
    'gas': 8000000,#80000
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
        #TX_ SAMPLE
        # AttributeDict({'blockHash': HexBytes('0xc1bb3216e5271adc7fa185c06a9c683456fd22056f38c16da883cc975e4e3f7f'),
        # 'blockNumber': 5493561, 'contractAddress': '0x78Aa177C0c6eBDCD46bBab5d21aAF4dcBc8F9548', 
        # 'gasUsed': 3662225, 'effectiveGasPrice': 2287629178, 'from': '0x1789897bC6C2674667967C84Aca9C8f9efb62590',
        # 'gasUsed': 3662225, 'logs': [], 'logsBloom': HexBytes('0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'),
        # 'status': 1, 'to': None, 'transactionHash': HexBytes('0xd475f94079b50907ff474ff529d5fddd445fff63114a249f50f19dca8adb50bf'),
        # 'transactionIndex': 0, 'type': 0})
    end = time.time()
    rtt = end - start
    return receipt, rtt

#Market ABI
def compilate_market():
    with open('./out/Market.sol/Market.json') as file:
        contractMarketCompilation = json.load(file)

    contract_market_ABI = contractMarketCompilation['abi']
    contract_market_bytecode = contractMarketCompilation['bytecode']['object']

    #Desplegar market.sol y obtener direccion, tiempo y costo
    contract_market_predeploy = w3.eth.contract(bytecode = contract_market_bytecode, abi=contract_market_ABI)

#DEPOY MARKET
    provider_name = "dummy_name"
    rtt_user_provider = test_conexion()
    receipt, rtt_user_bc = deployContract(contract_market_predeploy, 0, current_chain_id , provider_name)
    print(receipt)
    rtt = rtt_user_bc - rtt_user_provider
    gas_used = receipt['gasUsed']
    gas_price = receipt['effectiveGasPrice']
    contract_name = "Market"
    function_name = "constructor"
    address = receipt['contractAddress']
    #rtt
    tx_fee = (gas_used * gas_price) / 10**18
    if receipt['status'] == 1:
        return [contract_name, function_name, rtt, address, gas_used, gas_price, tx_fee]
    else:
        print("Transacction failed")

def testAddProvider(contract_market, contract_address):
    providerName = "dummyName"
    providerAddress = "0xC9a7A5F8f2BDf39f602f2F5ab68c8790789Ca63f" #dummy
    rtt_user_provider = test_conexion()
    receipt, rtt_user_bc = genericTransaction(contract_market , "addProvider", 0, current_chain_id, providerName, providerAddress )
    print(receipt)

    #Extract receipt data
    contract_name = "Market"
    function_name = "addProvider"
    rtt = rtt_user_bc - rtt_user_provider
    address = contract_address
    gas_used = receipt['gasUsed']
    gas_price = receipt['effectiveGasPrice']
    tx_fee = (gas_used * gas_price) / 10**18

    if receipt['status'] == 1:
        return [contract_name, function_name, rtt, address, gas_used, gas_price, tx_fee]
    else:
        print("Transacction failed")

def testCreateSLA(contract_market, contract_address):#using generic transaction
    doc_hash = 'hash_del_documento'
    params = [200, 100, 250, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]  # Ejemplo de parámetros
    endpoint = 'url_del_endpoint'
    bidding_time = 5*60 #
    start_value = 1
    function_name = "createCustomSLA"
    rtt_user_provider = test_conexion()
    receipt, rtt_user_bc = genericTransaction(contract_market , function_name, 0, current_chain_id, doc_hash, params, endpoint, bidding_time, start_value)
    print(receipt)
    return prepairRecordData(rtt_user_bc, rtt_user_provider,receipt,  function_name, contract_address )

def prepairRecordData(rtt_user_bc, rtt_user_provider, receipt,function_name, contract_address):
        #Extract receipt data
    contract_name = "Market"
    function_name = function_name
    rtt = rtt_user_bc - rtt_user_provider
    address = contract_address
    gas_used = receipt['gasUsed']
    gas_price = receipt['effectiveGasPrice']
    tx_fee = (gas_used * gas_price) / 10**18

    if receipt['status'] == 1:
        return [contract_name, function_name, rtt, address, gas_used, gas_price, tx_fee]
    else:
        print("Transacction failed")

#incializar un dataframe para un deployment de market
def initializeContractRecord(contract_name,function_name, rtt, address, gas_used, gas_price, tx_fee):
    columnas = ['Contract_Name', 'Function', 'Address', 'RTT', 'Gas_Used', 'Gas_Price', 'Transacction_Fee', 'Date']
    df = pd.DataFrame(columns=columnas)

    record = {
        'Contract_Name': contract_name,
        'Function': function_name,
        'Address': address,
        'RTT': rtt,
        'Gas_Used': gas_used,
        'Gas_Price': gas_price,
        'Transacction_Fee': tx_fee,
        'Date':  datetime.datetime.now()
    }

    df = df.append(record, ignore_index=True)

    # Abrir el archivo CSV en modo append y escribir los nuevos datos
    with open(f'./testPython/{CURRENT_CHAIN}Records.csv', 'a') as f:
        df.to_csv(f'./testPython/{CURRENT_CHAIN}Records.csv', index=False, sep=',')

def writeMarketRecord(contract_name,function_name, rtt, address, gas_used, gas_price, tx_fee):
    columnas = ['Contract_Name', 'Function', 'Address', 'RTT', 'Gas_Used', 'Gas_Price', 'Transacction_Fee', 'Date']
    df = pd.DataFrame(columns=columnas)
    record = {
        'Contract_Name': contract_name,
        'Function': function_name,
        'Address': address,
        'RTT': rtt,
        'Gas_Used': gas_used,
        'Gas_Price': gas_price,
        'Transacction_Fee': tx_fee,
        'Date':  datetime.datetime.now()
    }

    df = df.append(record, ignore_index=True)
    with open(f'./testPython/{CURRENT_CHAIN}Records.csv', 'a') as f:
        df.to_csv(f'./testPython/{CURRENT_CHAIN}Records.csv', mode = 'a', header = False, index=False, sep=',')



#TX RECORDS for Market Deployment
#------------------ 
def recordMarketDeploymentTx():
    # record = compilate_market()
    # if record:
    #     initializeContractRecord(*record)      
        #writeMarketRecord(*record)

    for i in range(1,20):   
        record = compilate_market()
        if record:
            #initializeContractRecord(*record)
            writeMarketRecord(*record)
            time.sleep(15) #tome la muestra cada 15 seg
 #---------------------
            
#TX RECORDS for Market addProvider function
        #take deployed contract
def recordMarketAddProviderFunction():
    with open('./out/Market.sol/Market.json') as file:
        contractMarketCompilation = json.load(file)

    contract_market_ABI = contractMarketCompilation['abi']
    contract_market = w3.eth.contract(address=contract_address_market_function_test, abi=contract_market_ABI)
    

    for i in range(1,20):   
        record = testAddProvider(contract_market, contract_address_market_function_test)
        print(record)
        if record:
            #initializeContractRecord(*record)
            writeMarketRecord(*record)
            time.sleep(15) #tome la muestra cada 15 seg


#TX RECORDS for Market addClient  function
            #Innecesaria pq sigue la misma logica q addProvider


#TX RECORDS for Market CreateCustomSLA function
def recordMarketCreateCustomSLA(number_of_records):
    with open('./out/Market.sol/Market.json') as file:
        contractMarketCompilation = json.load(file)

    contract_market_ABI = contractMarketCompilation['abi']
    contract_market = w3.eth.contract(address=contract_address_market_function_test, abi=contract_market_ABI)
    

    for i in range(0,number_of_records):   
        record = testCreateSLA(contract_market, contract_address_market_function_test)
        print(record)
        if record:
            #initializeContractRecord(*record)
            writeMarketRecord(*record)
            time.sleep(15) #tome la muestra cada 15 seg


#rename number
def readCreateCustomSLALogs():
    with open('./out/Market.sol/Market.json') as file:
        contractMarketCompilation = json.load(file)

    contract_market_ABI = contractMarketCompilation['abi']
    contract_market = w3.eth.contract(address=contract_address_market_function_test, abi=contract_market_ABI)
    
    list_available_sla = []
    logs = contract_market.events.e_createSLA().get_logs(fromBlock=0, toBlock='latest')
    print("Logs from createCustomSLA function: ")
    cont_active_contract =0
    for log in logs:    
        sla_date = log['args']['endDate']
        if datetime.datetime.fromtimestamp(sla_date) > datetime.datetime.now():
            cont_active_contract += 1
            active_sla = log['args']
            # Example log['args']:  AttributeDict({'docHash': 'hash_del_documento', 'newSLAAddress': '0x473888866344680a9b43d7cd1483959c9bC0143C', 'newAuctionAddress': '0x42D3dDC52cbC08eA4c4C38dBAD60d3699109b7DA', 'endDate': 1742330772, 'params': [200, 100, 250, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]})
            print(f'Active contract {cont_active_contract}: {active_sla}')                   
            list_available_sla.append(active_sla)
    return list_available_sla

if __name__ == '__main__':
    #recordMarketDeploymentTx()
    #recordMarketAddProviderFunction()
    #recordMarketCreateCustomSLA(1)
    readCreateCustomSLALogs()
    # block = w3.eth.get_block('latest')
    # print(block['timestamp'])

"""
Latency test:

user   ==>  node provider ==> Blockchain
0- RTT de despliegue de Market desde python para medir tiempo de subida X


1- RTT (user-nodeprovider) Function test conection X
     tiempo que toma llegar al primer nodo y tener una respuesta
     

2- RTT llamada a la funcion create SLA de SC Market
    Verificar contrato Market
        >>forge verify-contract <address> SomeContract --watch
        >>forge verify-contract --etherscan-api-key $ETHERSCAN_API_KEY --chain 11155111 0x232A4De01083FdC87Edd04e6D3A46e5CF2018538 ./src/Market.sol:Market --watch


    Añadir evento al contrato de creacion de SLA y Subasta X
    Subscribirse al evento X
    Guardar logs del evento con python 
    Filtrar logs para sla activos (pendiente)

2.1- Añadir eventos a los contratos X

3- Registro de cliente  X
4- RTT oferta de cliente X
5- Medir descubrimiento de proveedores (prueba pendiente)
6- Medición de llamada a chainlink

7- Medir tiempo de transferencia SLA 
7.1 - Medir tiempo de withdraw function 

8- Repetir pruebas para otra blockchain
8- Estimar limite de SLAs
9- Estimar limite de llamadas por segundo usando una API

10- Graficos de mediciones de tiempo y costos.
        Como guardar los datos?


10- Elementos a considerar en el diseño de un sistema que involucre smart contract para monitorear slas
11- Si da tiempo guardar logs en una dB
"""


            
            





