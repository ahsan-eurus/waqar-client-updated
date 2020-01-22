import json
import boto3
import os
from boto3.dynamodb.conditions import Key, Attr
import traceback
import sys

def lambda_handler(event, context):
    hasException = False
    message = 'Process has been completed.'
    statusCode = 200
    items = []

    try:
        client = boto3.resource('dynamodb')
        onBoardingTable = client.Table(os.environ['onBoardingTableName'])
        result = onBoardingTable.scan()
        items = result['Items']

    except Exception as e:
        hasException = True
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        print(e)

    if hasException:
        message = "Process has encountered an internal server exception."
        statusCode = 500
    
    return {
        'statusCode': statusCode,
        'items' : items,
        'message': message
    }