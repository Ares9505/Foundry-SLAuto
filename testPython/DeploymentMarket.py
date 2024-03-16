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


CURRENT_CHAIN= "Polygon" #"Sepolia" 
#Para pruebas en otra blockchain

if CURRENT_CHAIN == "Sepolia":
    provider = SEPOLIA_RPC_URL
    current_chain_id = SEPOLIA_CHAIN_ID
elif CURRENT_CHAIN == "Polygon":
    provider = POLYGON_RPC_URL
    current_chain_id = POLYGON_CHAIN_ID

w3 = Web3(Web3.HTTPProvider(provider)) #Alchemy APi (nodeprovider) Sepolia URL RPC
ipfs_api = ipfsApi.Client(URL_IPFS_API, IPFS_PORT) #IPFS API



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
    end = time.time()
    rtt = end - start
    return receipt, rtt

def testAddProvider():
    providerName = "dummyName"
    providerAddress = "0xC9a7A5F8f2BDf39f602f2F5ab68c8790789Ca63f"
    receipt, rtt = genericTransaction(contract_market , "addProvider", 0, SEPOLIA_CHAIN_ID, providerName, providerAddress )
    print(receipt)


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
    receipt, rtt = deployContract(contract_market_predeploy, 0,current_chain_id , provider_name)
    print(receipt)
    gas_used = receipt['cumulativeGasUsed']
    gas_price = receipt['effectiveGasPrice']
    contract_name = "Market"
    address = receipt['contractAddress']
    #rtt
    tx_fee = (gas_used * gas_price) / 10**18
    print(type(receipt['status']))
    if receipt['status'] == 1:
        return [contract_name,rtt, address, gas_used, gas_price, tx_fee]
    else:
        print("Transacction failed")

#incializar un dataframe para un deployment de market
def initializeContractRecord(contract_name, rtt, address, gas_used, gas_price, tx_fee):
    columnas = ['Contract_Name', 'Function', 'Address', 'RTT', 'Gas_Used', 'Gas_Price', 'Transacction_Fee', 'Date']
    df = pd.DataFrame(columns=columnas)

    record = {
        'Contract_Name': contract_name,
        'Function': 'constructor',
        'Address': address,
        'RTT': rtt,
        'Gas_Used': gas_used,
        'Gas_Price': gas_price,
        'Transacction_Fee': tx_fee,
        'Date':  datetime.datetime.now()
    }

    df = df.append(record, ignore_index=True)

    # Abrir el archivo CSV en modo append y escribir los nuevos datos
    with open(f'./testPython/{CURRENT_CHAIN}MarketRecords.csv', 'a') as f:
        df.to_csv(f'./testPython/{CURRENT_CHAIN}MarketRecords.csv', index=False, sep=',')

def writeMarketRecord(contract_name, rtt, address, gas_used, gas_price, tx_fee):
    columnas = ['Contract_Name', 'Function', 'Address', 'RTT', 'Gas_Used', 'Gas_Price', 'Transacction_Fee', 'Date']
    df = pd.DataFrame(columns=columnas)
    record = {
        'Contract_Name': contract_name,
        'Function': 'constructor',
        'Address': address,
        'RTT': rtt,
        'Gas_Used': gas_used,
        'Gas_Price': gas_price,
        'Transacction_Fee': tx_fee,
        'Date':  datetime.datetime.now()
    }

    df = df.append(record, ignore_index=True)
    with open(f'./testPython/{CURRENT_CHAIN}MarketRecords.csv', 'a') as f:
        df.to_csv(f'./testPython/{CURRENT_CHAIN}MarketRecords.csv', mode = 'a', header = False, index=False, sep=',')


def boxplot():
# Datos de ejemplo
    datos = [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35]

    # Crear el gráfico de cajas y bigotes
    sns.boxplot(x=datos)

    # Mostrar el gráfico
    sns.plt.show()

    # # Mostrar las primeras filas del DataFrame
    # print(df.head())


# AttributeDict({'blockHash': HexBytes('0xc1bb3216e5271adc7fa185c06a9c683456fd22056f38c16da883cc975e4e3f7f'),
# 'blockNumber': 5493561, 'contractAddress': '0x78Aa177C0c6eBDCD46bBab5d21aAF4dcBc8F9548', 
# 'cumulativeGasUsed': 3662225, 'effectiveGasPrice': 2287629178, 'from': '0x1789897bC6C2674667967C84Aca9C8f9efb62590',
# 'gasUsed': 3662225, 'logs': [], 'logsBloom': HexBytes('0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'),
# 'status': 1, 'to': None, 'transactionHash': HexBytes('0xd475f94079b50907ff474ff529d5fddd445fff63114a249f50f19dca8adb50bf'),
# 'transactionIndex': 0, 'type': 0})


# contract_market = w3.eth.contract(address="0x78Aa177C0c6eBDCD46bBab5d21aAF4dcBc8F9548", abi=contract_market_ABI)
# testAddProvider()
        

#contract_name, rtt, address, gas_used, gas_price, tx_fee
#initializeContractRecord("market", 10, "0x32323", 43, 32,32)

#TX RECORDS      
record = compilate_market()
if record:
    initializeContractRecord(*record)
#writeMarketRecord(*record)

# df = pd.read_csv('./testPython/MarketRecords.csv')

# # Mostrar las primeras filas del DataFrame
# print(df.head())

# e1dc84c5737c153605eb3b7ba85dd47de25ab8f92ae3c87ed4dbbd1a4c3c73b0