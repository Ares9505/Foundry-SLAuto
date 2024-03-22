from testMarketFunctions import genericTransaction, writeMarketRecord, test_conexion, prepairRecordData, recordMarketCreateCustomSLA, readCreateCustomSLALogs
from web3 import Web3
import os
from dotenv import load_dotenv
import ipfsApi
import time
import json
from web3.middleware import geth_poa_middleware
from testAuctionFunctions import compilate_contract, deploy_contract, get_contract_interface_by_address

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

def deploy_custom_contract(contract_name, providerName, providerAddress, doc_hash , params, endpoint):
    contract_predeploy= compilate_contract(contract_name=contract_name)
    receipt, _ =deploy_contract(contract_predeploy, 0, current_chain_id, providerName, providerAddress, doc_hash , params, endpoint)
    print(receipt)
    return receipt     


if __name__ == '__main__':
    contract_name = "SLA"
    function_name = "requestVolumeData"
    # receipt = deploy_custom_contract(
    #     contract_name= contract_name,
    #     providerName= "etecsa",
    #     providerAddress = WALLET_ADDRESS_PROVIDER,
    #     doc_hash = 'hash_del_documento',
    #     params = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21],  # Ejemplo de parámetros
    #     endpoint = 'url_del_endpoint'
    #     )  
    # contract_address = receipt['contractAddress'] #0xe6CBdD42c6d3510EAe7C267338bA5738360EE5c6

    contract_address = "0xe6CBdD42c6d3510EAe7C267338bA5738360EE5c6"
    contract_interface = get_contract_interface_by_address(contract_name = contract_name, contract_address_function_test=contract_address)
    # receipt, rtt = genericTransaction(
    #     contract= contract_interface,
    #     function_name= function_name,
    #     value = 0,
    #     chain_id= current_chain_id
    # )
    # print("Recibo de ")
    logs_send_time = contract_interface.events.ChailinkRequestSendTime().get_logs(fromBlock=0, toBlock='latest')
    logs_send_request_id = contract_interface.events.ChainlinkRequested().get_logs(fromBlock=0, toBlock='latest')
    print("logs_send_request_id: ", logs_send_request_id[0]['args']['id'])
    print("logs_send_time: ", logs_send_time[0]['args']['sendTime'])
    while True:
        logs_receive = contract_interface.events.RequestVolume().get_logs(fromBlock=0, toBlock='latest')
        if logs_receive:
            print("logs_receive", logs_receive)
'''
    1 - Mesure time for chinlink call
            Deploy SLA and set active
            Set correct endPoint, Configure correctly api in aws
            Send link to the contract to operate
            Call funcion request volume
            Record
                event ChainlinkRequested(requestId) 
                event ChailinkRequestSendTime(uint256 sendTime);
                
                event RequestVolume(
                    bytes32 indexed requestId,
                    string volume,
                    uint256 recieveTime
                );
            Calculate diferences and save

'''



