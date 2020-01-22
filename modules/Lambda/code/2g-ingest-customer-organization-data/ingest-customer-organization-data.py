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
    message = 'Process completed successfully'
    statusCode = 200
    
    try:
        client = boto3.resource('dynamodb')
        onBoardingTable = client.Table(os.environ['onBoardingTableName'])
        
        # Fetch customer's data from database that are configured as master account
        # Only master accounts will have organization information
        result = onBoardingTable.scan(FilterExpression=Attr("type").eq('Master'))
        isDbDataPending = True
        

        # Traversing all customers
        while isDbDataPending:
            isDbDataPending = True if 'LastEvaluatedKey' in result else False
            
            if result['Count'] > 0:
                items = result['Items']
                for item in items:
                    try:
                        # Initiating the process of data ingestion for curstomer
                        initiate_process(item)
                    except Exception as e:
                        statusCode = 500
                        message = "An error occurred in traversing client organization data"
                        logger.error("Exception: {}".format(e))
                        ex_type, ex, tb = sys.exc_info()
                        traceback.print_tb(tb)
                        
            if isDbDataPending:
                result = onBoardingTable.scan(ExclusiveStartKey=result['LastEvaluatedKey'])
            

    except Exception as e:
        statusCode = 500
        message = "An error occurred in traversing client organization data"
        logger.error("Exception: {}".format(e))
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
    
    return {
        'statusCode': statusCode,
        'message': message
    }

def initiate_process(item):
    # Initiating the process of data ingestion for curstomer by calling organization data ingestion lambda

    lambda_client = boto3.client('lambda')
    
    function_name = os.environ['lambdaCustomerOrganizationDataIngestionFunctionName']
    
    msg = {"accountId": item['accountId'], "cuid": item['cuid'], "at": str(datetime.datetime.now())}
    invoke_response = lambda_client.invoke(FunctionName=function_name,
                       InvocationType='Event',
                       Payload=json.dumps(msg))
                       
    print(invoke_response)