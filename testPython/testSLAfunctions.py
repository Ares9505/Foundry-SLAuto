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

def deploy_custom_contract(contract_name, providerName, providerAddress, doc_hash , params, endpoint):
    contract_predeploy= compilate_contract(contract_name=contract_name)
    receipt, _ =deploy_contract(contract_predeploy, 0, current_chain_id, providerName, providerAddress, doc_hash , params, endpoint)
    print(receipt)
    return receipt     

def slaChainlinkCallMesuasure():
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
    
    #Set correct endpoint
    receipt, rtt = genericTransaction(
        contract_interface,
        "setAPIurl",
        0,
        current_chain_id,
        
    )

    # receipt, rtt = genericTransaction(
    #     contract= contract_interface,
    #     function_name= function_name,
    #     value = 0,
    #     chain_id= current_chain_id
    # )
    # print("Recibo de ")
    #set 

    logs_send_time = contract_interface.events.ChailinkRequestSendTime().get_logs(fromBlock=0, toBlock='latest')
    logs_send_request_id = contract_interface.events.ChainlinkRequested().get_logs(fromBlock=0, toBlock='latest')
    print("logs_send_request_id: ", logs_send_request_id[0]['args']['id'])
    print("logs_send_time: ", logs_send_time[0]['args']['sendTime'])
    while True:
        logs_receive = contract_interface.events.RequestVolume().get_logs(fromBlock=0, toBlock='latest')
        if logs_receive:
            print("logs_receive", logs_receive)

def APIConsumerChainlinkCallMesuasure():
    ''' No funciono el log del evento RequestVolume'''
    contract_address = "0x7f8C5655b45AE6D8CE843CC728325065df690047"
    contract_interface = get_contract_interface_by_address(contract_name= "APIConsumer", contract_address_function_test=contract_address)
    
    logs_send_time = contract_interface.events.ChailinkRequestSendTime().get_logs(fromBlock=0, toBlock='latest')
    logs_send_request_id = contract_interface.events.ChainlinkRequested().get_logs(fromBlock=0, toBlock='latest')
    print("logs_send_request_id: ", logs_send_request_id[0]['args']['id'])
    print("logs_send_time: ", logs_send_time[0]['args']['sendTime'])
    while True:
        logs_receive = contract_interface.events.RequestVolume().get_logs(fromBlock=0, toBlock='latest')
        print(logs_receive)
        if logs_receive:
            print("logs_receive", logs_receive)
            break



if __name__ == '__main__':
    contract_address = "0x300cDB89AfD313a23249Ca1893452E705D16C3aA"
    contract_interface = get_contract_interface_by_address(contract_name= "APIConsumerPolygon", contract_address_function_test=contract_address)
    #transferir tokens al contrato
    receipt = genericTransaction(
        contract = contract_interface,
        function_name = "requestVolumeData",
        value = 0,
        chain_id = current_chain_id,
        )
    print(receipt)
    #time.sleep(30)


'''
    1 - Mesure time for chinlink call
            Deploy SLA and set active X
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

    1- No sirvió lo anterior por alguna razon no me devolvia el evento de tiempo en fullfill, 
    por loque lo intente con APIConsumer.sol de forma manual. 
    Despues de varias pruebas con este contrato al revisar etherscan se pudo observar q para sepolia 
    el rtt_bc_chainlink(diferencia entre fecha de requestVolumeData y fecha de fulfillOracleRequest2) era igual al tiempo de bloque.
    Se puede apreciar en la sgte direccion de etherscan https://sepolia.etherscan.io/address/0x5038607C1BeC073e68838C3E8a0B7A5AF28C5ABd#events
     que el tiempo rtt de sepolia a chainlink es de 12 seg igual al tiempo de bloque de sepolia.

    2- Para probar en polygon no me dejo conectarme desde remix, supongo que problemas con el url rpc
    sin embargo lo intentare desde codigo python.
    Se puede apreciar en la sgte direccion de polygon scan https://mumbai.polygonscan.com/address/0xCBf668aC4A5523E8d8FA2B06093a894aCa314534#events
    que el tiempo rtt de polygon a chainlink es de 4 seg igual al tiempo de bloque de polygon.

'''



