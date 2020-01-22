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

### This Enum is being used for traversing the folder levels.

class TraverseLevels(Enum):
    base = 0
    accountId = 1
    service = 2
    region = 3
    year = 4
    month = 5
    day = 6

# Global variables

logger = logging.getLogger()
logger.setLevel(logging.INFO)

operationType = "CloudTrail"
finalLevel = TraverseLevels.day

def lambda_handler(event, context):
    message = 'Process completed successfully'
    statusCode = 200
    
    try:
        client = boto3.resource('dynamodb')
        onBoardingTable = client.Table(os.environ['onBoardingTableName'])

        ### Fetch only those customer's data, whose cloudTrail bucket information is not NULL

        result = onBoardingTable.scan(
            FilterExpression=Attr("cloudTrailBucketName").exists() & 
            Attr("cloudTrailBucketPath").exists()
        )
        isDbDataPending = True
        
        ### Traverse all the data if its paginated.
        ### `LastEvaluatedKey` only exists if there is pending result that couldn't be fetched because of data size limitation.
        
        while isDbDataPending:
            isDbDataPending = True if 'LastEvaluatedKey' in result else False
            
            if result['Count'] > 0:
                items = result['Items']
                for item in items:
                    try:
                        sync_buckets(item)
                    except Exception as e:
                        statusCode = 500
                        message = "An error occurred in traversing client s3 bucket"
                        logger.error("Exception: {}".format(e))
                        ex_type, ex, tb = sys.exc_info()
                        traceback.print_tb(tb)
                        
            if isDbDataPending:
                result = onBoardingTable.scan(FilterExpression=Attr("cloudTrailBucketName").exists() & 
                        Attr("cloudTrailBucketPath").exists(),
                        ExclusiveStartKey=result['LastEvaluatedKey'])
            

    except Exception as e:
        statusCode = 500
        message = "An error occurred in traversing client s3 bucket"
        logger.error("Exception: {}".format(e))
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
    
    return {
        'statusCode': statusCode,
        'message': message
    }

def sync_buckets(item):

    ### This function generate the destinaionBucketPath against each customer.
    ### Initiate the traversing logic of folders for each customer.
    ### And make sure if there is an operation logs for the given customer, apply the logic against it whether it needs to sync the data or not.

    operationLogsDateRanges = []
    operationLogs = []
    dynamodb_client = boto3.resource('dynamodb')
    
    operationLogsTable = dynamodb_client.Table(os.environ['lambdaOperationLogsTableName'])
    
    destinationBucketPath = item['cuid'] + ".cc-aws-data/" + item['cuid'] + ".cc-aws-data-cloudtrail/"
    
    logsTableResult = operationLogsTable.scan(
            FilterExpression=Attr("cuid").eq(item['cuid']) & Attr("operationType").eq(operationType)
        )
    
    if logsTableResult['Count'] > 0:
            operationLogs = logsTableResult['Items']
            for operationLog in operationLogs:
                operationLogsDateRanges.append(operationLog['sourceBucketPath'])
                
    
    s3_assumed_client = get_assumed_s3_client(item)
    
    sourceBucketName = item['cloudTrailBucketName']
    sourceBucketPath = "" if item['cloudTrailBucketPath'] == '/' else item['cloudTrailBucketPath']
    prefix = (sourceBucketPath + "/" if sourceBucketPath != "" else "") + "AWSLogs/"
    traverse_client_s3(operationLogsDateRanges, s3_assumed_client, item, prefix, TraverseLevels.base, finalLevel, sourceBucketName, sourceBucketPath, destinationBucketPath)
    

def traverse_client_s3(operationLogsDateRanges, s3_assumed_client, item, base_prefix, currentLevel, finalLevel, sourceBucketName, sourceBucketBasePath, destinationBucketBasePath):
    
    ### This function make sure that the folder traversing is performing upto the given level,
    ### so that all the folders are properly traversed.
    
    if currentLevel == TraverseLevels.day:
        return
    else:
        currentLevel = TraverseLevels(currentLevel.value + 1)
                    
    isS3DataPending = True
    
    response = s3_assumed_client.list_objects_v2(
                Bucket = sourceBucketName,
                Prefix = base_prefix,
                Delimiter='/'
                )
                
    while isS3DataPending:
        
        isS3DataPending = True if 'NextContinuationToken' in response else False
        
        if response['KeyCount'] > 0:
            commonPrefixes = response['CommonPrefixes']
            for prefix in commonPrefixes:
                if currentLevel == TraverseLevels.day or currentLevel == finalLevel:
                    final_prefix = prefix['Prefix']
                    sourceBucketPath = final_prefix.rstrip('\/')
                    destinationBucketPath = destinationBucketBasePath + "AWSLogs" + final_prefix.split("AWSLogs",1)[1]
                    destinationBucketPath = destinationBucketPath.rstrip('\/')
                    date_string = re.search(r'\d{4}/\d{1,2}/\d{1,2}', final_prefix).group()
                    maxPreviousRange = generate_date_ranges(int(os.environ['maxPreviousDaysToCopy']))
                    
                    if sourceBucketPath not in operationLogsDateRanges or date_string in maxPreviousRange:
                        invoke_copy_lambda(item, sourceBucketName, sourceBucketPath, destinationBucketPath)
                else:
                    traverse_client_s3(operationLogsDateRanges, s3_assumed_client, item, prefix['Prefix'], currentLevel, finalLevel, sourceBucketName, sourceBucketBasePath, destinationBucketBasePath)
        
        if isS3DataPending:
            response = s3_assumed_client.list_objects_v2(
                        Bucket = sourceBucketName,
                        Prefix = base_prefix,
                        ContinuationToken = response['NextContinuationToken'],
                        Delimiter='/'
                        )
                        
    return


def get_assumed_s3_client(item):

    ### Assume the role given in the environment variable `assumableRoleName`, 
    ### so that we can get information residing in the customer environment"

    customer_account_id = get_account_id(item)
    sts_default_provider_chain = boto3.client('sts')
    role_to_assume_arn = 'arn:aws:iam::' + customer_account_id + ':role/' + os.environ['assumableRoleName']
    role_session_name = customer_account_id + 'assume_role_sesson'
    
    assumeRoleConf = {
        "RoleArn": role_to_assume_arn,
        "RoleSessionName": role_session_name
    }
    
    if "externalId" in item:
        assumeRoleConf['ExternalId'] = item['externalId']
    
    stsresponse = sts_default_provider_chain.assume_role(**assumeRoleConf)
    
    newsession_id = stsresponse["Credentials"]["AccessKeyId"]
    newsession_key = stsresponse["Credentials"]["SecretAccessKey"]
    newsession_token = stsresponse["Credentials"]["SessionToken"]
    
    s3_assumed_client = boto3.client(
    's3',
    aws_access_key_id=newsession_id,
    aws_secret_access_key=newsession_key,
    aws_session_token=newsession_token
    )
    
    return s3_assumed_client
    
def invoke_copy_lambda(item, sourceBucketName, sourceBucketPath, destinationBucketPath):

    ### This function invokes the lambda, that will sync the source bucket and destination bucket if needed. 
    
    lambda_client = boto3.client('lambda')
    
    msg = {"s3_source_bucket_name": sourceBucketName, "s3_source_bucket_path": sourceBucketPath, "s3_destination_bucket_name": os.environ['dataIngestionDestinationBucketName'], "s3_destination_bucket_path": destinationBucketPath , "account_id": get_account_id(item), "cuid": item['cuid'], "operation_type": operationType, "at": str(datetime.datetime.now())}
    invoke_response = lambda_client.invoke(FunctionName=os.environ['lambdaSyncBucketFunctionName'],
                       InvocationType='Event',
                       Payload=json.dumps(msg))
                       
    print(invoke_response)
    
    
def generate_date_ranges(prevDays):

    ### Generate the previous days ranges in format of cloud trail data.

    dateRange = []
    dateRange.append(datetime.date.today().strftime("%Y/%m/%d"))
    
    while prevDays > 0:
        prevDate = datetime.date.today()-datetime.timedelta(prevDays)
        dateRange.append(prevDate.strftime("%Y/%m/%d"))
        prevDays = prevDays - 1
    return dateRange

def get_account_id(item):
    accountId = ""
    if 'cloudTrailBucketAccountId' in item and item['cloudTrailBucketAccountId'] != "" and item['cloudTrailBucketAccountId'] != None:
        accountId = item['cloudTrailBucketAccountId']
    else:
        accountId = item['accountId']
    return accountId