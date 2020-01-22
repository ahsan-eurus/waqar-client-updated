import json
import boto3
import os
from boto3.dynamodb.conditions import Key, Attr
import traceback
import sys

def lambda_handler(event, context):
    message = 'Process has been completed.'
    statusCode = 200
    item = None
    cuid = ""

    try:
        cuid = event['cuid']
        client = boto3.resource('dynamodb')
        onBoardingTable = client.Table(os.environ['onBoardingTableName'])
        result = onBoardingTable.scan(
            FilterExpression=Attr("cuid").eq(cuid)
        )
        if result["Count"] > 0:
            item = result['Items'][0]

    except Exception as e:
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        print(e)

        message = "Process has encountered an internal server exception."
        statusCode = 500        
    
    return {
        'statusCode': statusCode,
        'data' : item,
        'message': message
    }