from testMarketFunctions import genericTransaction, writeMarketRecord, test_conexion, prepairRecordData, recordMarketCreateCustomSLA, readCreateCustomSLALogs
from web3 import Web3
import os
from dotenv import load_dotenv
import ipfsApi
import time
import json
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
CURRENT_CHAIN = os.getenv("CURRENT_CHAIN")

#IPFS setup
ipfs_api = ipfsApi.Client(URL_IPFS_API, IPFS_PORT) #IPFS API

#Blockchain selection Setup
#-------------------------------------

if CURRENT_CHAIN == "Sepolia":
    provider = SEPOLIA_RPC_URL
    current_chain_id = SEPOLIA_CHAIN_ID
    #extracted from csv previous records
    contract_address_market_function_test = "0x11C2AD05412900B94e113eD40A968eAe31fD28aD"  
    contract_address_auction_function_test = "0x7ab47B582b50e32646e6D26911Cf2B2c50e8c406" 

elif CURRENT_CHAIN == "Polygon":
    provider = POLYGON_RPC_URL
    current_chain_id = POLYGON_CHAIN_ID
    #extracted from csv previous records
    contract_address_market_function_test = "0x8662B405dcE018300D2A8F5A8240014F1cd0420D"
    contract_address_auction_function_test = "pendent"
else:
    print("Setup blockchain error. Invalidad chain name")

w3 = Web3(Web3.HTTPProvider(provider)) #Alchemy APi (nodeprovider) Sepolia URL RPC

if CURRENT_CHAIN == "Polygon":
    if geth_poa_middleware not in w3.middleware_onion:
        w3.middleware_onion.inject(geth_poa_middleware, layer=0)
#------------------------------------------
        
def compilate_contract(contract_name):
    with open(f'./out/{contract_name}.sol/{contract_name}.json') as file:
        contractCompilation = json.load(file)

    contract_ABI = contractCompilation['abi']
    contract_bytecode = contractCompilation['bytecode']['object']

    #Desplegar.sol y obtener direccion, tiempo y costo
    contract_predeploy = w3.eth.contract(bytecode = contract_bytecode, abi=contract_ABI)
    return contract_predeploy

def deploy_contract(contract, value: int, chain_id: int,  *parameters):
    #save transactionCount
    nonce = w3.eth.get_transaction_count(WALLET_ADDRESS_PROVIDER)
    print(parameters)
    transaction = contract.constructor(*parameters).build_transaction({
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

def prepair_record_data( _contract_name, rtt_user_bc, rtt_user_provider, receipt, _function_name, contract_address):
        #Extract receipt data
    contract_name = _contract_name
    function_name = _function_name
    rtt = rtt_user_bc - rtt_user_provider
    address = contract_address
    gas_used = receipt['gasUsed']
    gas_price = receipt['effectiveGasPrice']
    tx_fee = (gas_used * gas_price) / 10**18

    if receipt['status'] == 1:
        return [contract_name, function_name, rtt, address, gas_used, gas_price, tx_fee]
    else:
        print("Transacction failed")

def get_contract_interface_by_address(contract_name, contract_address_function_test):
    with open(f'./out/{contract_name}.sol/{contract_name}.json') as file:
        contractCompilation = json.load(file)

    contract_ABI = contractCompilation['abi']
    contract_interface = w3.eth.contract(address=contract_address_function_test, abi=contract_ABI)
    return contract_interface


#  for i in range(1,20):   
#         record = testAddProvider(contract_market, contract_address_market_function_test)
#         print(record)
#         time.sleep(15) #tome la muestra cada 15 seg
#         if record:
#             #initializeContractRecord(*record)
#             writeMarketRecord(*record)
   
    
def recordContractFunction(number_of_records, contract_name, _function_name, value, contract_address_function_test ):
    contract_interface = get_contract_interface_by_address(contract_name=contract_name, contract_address_function_test= contract_address_function_test)
    for i in range(0,number_of_records): 
        rtt_user_provider = test_conexion()
        receipt, rtt_user_bc = genericTransaction(contract_interface, _function_name , value, current_chain_id)
        print(receipt)
        record = prepair_record_data(contract_name,rtt_user_bc,rtt_user_provider,receipt,_function_name,contract_address_function_test) 
        if record:
            #initializeContractRecord(*record)
            writeMarketRecord(*record)
            time.sleep(15) #tome la muestra cada 15 seg
        value += 1 #increment bid value to be higher than before

def deploy_custom_contract(contract_name, bidding_time, beneficiary, sla_address, start_value):
    contract_predeploy= compilate_contract(contract_name=contract_name)
    receipt, _ =deploy_contract(contract_predeploy, 0, current_chain_id, bidding_time, beneficiary, sla_address, start_value)
    print(receipt)
    return receipt


def deploy_auction_for_auctionEnd_function_test():
    ''' Deploy custom auction contract to test auctionEnd function
    fixed bidding time to 10 min to be capable to end contract and 
    mesure auctionEnd function'''
    contract_name= "Auction"
    receipt = deploy_custom_contract(
        contract_name= contract_name, 
        bidding_time= 3*60,#10 min de tiempo de subasta
        beneficiary= WALLET_ADDRESS_PROVIDER, 
        sla_address= "0x473888866344680a9b43d7cd1483959c9bC0143C", #extracted using readCreateCustomSLALogs function
        start_value=1
        )
    contract_auction_address = receipt['contractAddress'] #0x01a6464d06f9c53182d803c4D57B4Af14A9DD253
    print(contract_auction_address)
    return  contract_auction_address

def record_auction_function_auctionEnd():
    #Create Custom SLA and save sla_contract_address y auction sla contract
    for i in range(0,1):
        recordMarketCreateCustomSLA(1)
        list_available_sla = readCreateCustomSLALogs()
        address_auction_contract = list_available_sla[-1]['newAuctionAddress']

        #Subnit one bid and wait untill bidding time end
        bidding_time = 5*60 # debe ser igual al bidding time de testCreateSLA en testMarketFunction.py
        contract_name = "Auction"
        function_name = "bid"
        recordContractFunction(
            number_of_records = 1,
            contract_name = contract_name,
            _function_name = function_name, 
            value=2, # debe ser mayor al bidding time de testCreateSLA en testMarketFunction.py
            contract_address_function_test= address_auction_contract
            )
        time.sleep(bidding_time) 

        #Terminar contrato y medir 
        function_name = "auctionEnd"
        recordContractFunction(
            number_of_records=1,
            contract_name= contract_name,
            _function_name = function_name,
            value = 0,
            contract_address_function_test= address_auction_contract
        )

if __name__ == '__main__':
    #Todeploy a new contract
    #contract_auction_predeploy = compilate_contract("Auction")
    #receipt = deploy_contract(contract_auction_predeploy)

    #recordContractFunction(number_of_records = 2 ,contract_name = "Auction" , _function_name = "bid", value=75, contract_address_function_test= contract_address_auction_function_test ) 
    
    #Deploy contract Auction
    #contract_auction_address = deploy_auction_for_auctionEnd_function_test()

    #Record tx for bid function
    #Este sirve para grabar createCustomSLA, bid y action end faltaria solo grabar addProvider
    record_auction_function_auctionEnd()
  



