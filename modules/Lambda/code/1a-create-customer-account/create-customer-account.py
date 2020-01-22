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
    clientInformation = None
    try:
        client = boto3.resource('dynamodb')
        onBoardingTable = client.Table(os.environ['onBoardingTableName'])
        customerTable = client.Table(os.environ['customerTableName'])
        
        customerResult = onBoardingTable.scan(
            FilterExpression=Attr("cuid").eq(event['cuid'])
        )
        if customerResult["Count"] > 0:
            clientInformation = customerResult['Items'][0]
            
            if 'type' in event and event['type'] != None and event['type'] != "":
                clientInformation['type'] = event['type']
            if 'accountId' in event and event['accountId'] != None and event['accountId'] != "":
                clientInformation['accountId'] = event['accountId']
        else:
            clientInformation = { 
                'cuid': event['cuid'],
                'type': event['type'], 
                'accountId': event['accountId']
                }

        cid = "NULL"
        clientInformation = fill_information(clientInformation, event)

        try:
            result =  customerTable.query(
                KeyConditionExpression=Key('cuid').eq(event['cuid'])
            )
            print(result)
            if result["Count"] > 0:
                items = result['Items']
                cid = items[0]["cid"]
                
        except Exception as e:
            ex_type, ex, tb = sys.exc_info()
            traceback.print_tb(tb)
            print(e)

        clientInformation['cid'] = cid
            
        onBoardingTable.put_item(Item=clientInformation)

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
        'message': message
    }

def fill_information(clientInformation, event):

    if 'billingBucketName' in event and event['billingBucketName'] != None and event['billingBucketName'] != "":
        clientInformation['billingBucketName'] = event['billingBucketName']
    if 'billingBucketPath' in event and event['billingBucketPath'] != None and event['billingBucketPath'] != "":
        clientInformation['billingBucketPath'] = event['billingBucketPath']
    if 'billingBucketAccountId' in event and event['billingBucketAccountId'] != None and event['billingBucketAccountId'] != "":
        clientInformation['billingBucketAccountId'] = event['billingBucketAccountId']

    if 'cloudTrailBucketName' in event and event['cloudTrailBucketName'] != None and event['cloudTrailBucketName'] != "":
        clientInformation['cloudTrailBucketName'] = event['cloudTrailBucketName']
    if 'cloudTrailBucketPath' in event and event['cloudTrailBucketPath'] != None and event['cloudTrailBucketPath'] != "":
        clientInformation['cloudTrailBucketPath'] = event['cloudTrailBucketPath']
    if 'cloudTrailBucketAccountId' in event and event['cloudTrailBucketAccountId'] != None and event['cloudTrailBucketAccountId'] != "":
        clientInformation['cloudTrailBucketAccountId'] = event['cloudTrailBucketAccountId']

    if 'configBucketName' in event and event['configBucketName'] != None and event['configBucketName'] != "":
        clientInformation['configBucketName'] = event['configBucketName']
    if 'configBucketPath' in event and event['configBucketPath'] != None and event['configBucketPath'] != "":
        clientInformation['configBucketPath'] = event['configBucketPath']
    if 'configBucketAccountId' in event and event['configBucketAccountId'] != None and event['configBucketAccountId'] != "":
        clientInformation['configBucketAccountId'] = event['configBucketAccountId']

    if 'guardDutyBucketName' in event and event['guardDutyBucketName'] != None and event['guardDutyBucketName'] != "":
        clientInformation['guardDutyBucketName'] = event['guardDutyBucketName']
    if 'guardDutyBucketPath' in event and event['guardDutyBucketPath'] != None and event['guardDutyBucketPath'] != "":
        clientInformation['guardDutyBucketPath'] = event['guardDutyBucketPath']
    if 'guardDutyBucketAccountId' in event and event['guardDutyBucketAccountId'] != None and event['guardDutyBucketAccountId'] != "":
        clientInformation['guardDutyBucketAccountId'] = event['guardDutyBucketAccountId']
    
    if 'cloudWatchRegions' in event and event['cloudWatchRegions'] != None and event['cloudWatchRegions'] != "":
        clientInformation['cloudWatchRegions'] = event['cloudWatchRegions']

    if 'securityHubRegions' in event and event['securityHubRegions'] != None and event['securityHubRegions'] != "":
        clientInformation['securityHubRegions'] = event['securityHubRegions']
    if 'securityHubAccountId' in event and event['securityHubAccountId'] != None and event['securityHubAccountId'] != "":
        clientInformation['securityHubAccountId'] = event['securityHubAccountId']

    if 'externalId' in event and event['externalId'] != None and event['externalId'] != "":
        clientInformation['externalId'] = event['externalId']

    return clientInformation