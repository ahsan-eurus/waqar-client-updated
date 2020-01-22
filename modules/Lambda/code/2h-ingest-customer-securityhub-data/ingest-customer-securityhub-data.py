import json
import boto3
import os
from boto3.dynamodb.conditions import Key, Attr
from enum import Enum
import traceback
import sys
from dateutil.relativedelta import *
import datetime
import logging
import re


# Global variables
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    global organization_page_size
    message = 'Process completed successfully'
    statusCode = 200
    
    try:
        client = boto3.resource('dynamodb')
        onBoardingTable = client.Table(os.environ['onBoardingTableName'])

        # Fetch customer's data from database that are configured with securityHubRegions configuration        
        result = onBoardingTable.scan(
        FilterExpression=Attr("securityHubRegions").exists() & Attr("securityHubRegions").ne('NULL')
        )
        isDbDataPending = True
        
        while isDbDataPending:
            isDbDataPending = True if 'LastEvaluatedKey' in result else False
            
            if result['Count'] > 0:
                items = result['Items']
                for item in items:
                    try:
                        # Initiating the process of data ingestion for customer
                        initiate_process(item)
                    except Exception as e:
                        statusCode = 500
                        message = "An error occurred in traversing client data for security hub"
                        logger.error("Exception: {}".format(e))
                        ex_type, ex, tb = sys.exc_info()
                        traceback.print_tb(tb)
                        
            if isDbDataPending:
                result = onBoardingTable.scan(ExclusiveStartKey=result['LastEvaluatedKey'])
            

    except Exception as e:
        statusCode = 500
        message = "An error occurred in traversing client data"
        logger.error("Exception: {}".format(e))
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
    
    return {
        'statusCode': statusCode,
        'message': message
    }

def initiate_process(item):
    # Initiating the process of data ingestion for customer by calling security hub data ingestion lambda

    lambda_client = boto3.client('lambda')
    
    function_name = os.environ['lambdaCopyDataFunctionName']
    
    msg = {"regions": item['securityHubRegions'], "accountId": get_account_id(item), "cuid": item['cuid'], "at": str(datetime.datetime.now())}
    invoke_response = lambda_client.invoke(FunctionName=function_name,
                       InvocationType='Event',
                       Payload=json.dumps(msg))
                       
    print(invoke_response)

def get_account_id(item):
    accountId = ""
    if 'securityHubAccountId' in item and item['securityHubAccountId'] != "" and item['securityHubAccountId'] != None:
        accountId = item['securityHubAccountId']
    else:
        accountId = item['accountId']
    return accountId