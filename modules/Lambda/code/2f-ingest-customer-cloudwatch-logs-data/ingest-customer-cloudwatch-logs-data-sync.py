import json
import boto3
import os
from boto3.dynamodb.conditions import Key, Attr
import traceback
import sys
import datetime
import uuid
from dateutil.relativedelta import *

operationType = "CloudWatch"

def lambda_handler(event, context):
    message = 'Process has been completed.'
    statusCode = 200
    
    try:
        traverse_log_group_events(event)
    except Exception as e:
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        message = "Process has encountered an internal server exception."
        statusCode = 500
        print(e)
        
    return {
        'statusCode': statusCode,
        'message': message
    }
    
def traverse_log_group_events(event):

    ### This function will traverse all the events against a logGroup

    isLogEventDataPending = True
    additionalData = []
    logGroupData = json.loads(event['additionalData'])
    customerInfo = []

    cuid = event['cuid']
    client = boto3.resource('dynamodb')
    onBoardingTable = client.Table(os.environ['onBoardingTableName'])
    result = onBoardingTable.scan(
        FilterExpression=Attr("cuid").eq(cuid)
    )
    if result["Count"] > 0:
        customerInfo = result['Items'][0]

    cloudWatch_assumed_client = get_assumed_cloudWatch_client(event['accountId'], logGroupData['region'], customerInfo)
    
    ### Get all the logGroup Streams

    logGroupsStreams = get_logsGroups_streams(cloudWatch_assumed_client, logGroupData)
    logGroupOperationLog = get_logGroup_operationLog(logGroupData, event)
    logStreamStartTime = None
    
    ### If we are traversing logGroup first time, we'll fetch all the streams and its events.
    ### If we have already have record against this logGroup, we'll only fetch the given previous Days streams.

    if logGroupOperationLog is not None:
        maxPreviousDaysToCopy = int(os.environ['maxPreviousDaysToCopy'])
        logStreamStartTime = get_previous_epoch_dateTime(maxPreviousDaysToCopy)
    
    for logStream in logGroupsStreams:
        logStreamEvents = traverse_log_stream_if_necessary(cloudWatch_assumed_client, logStream, event, logGroupData, logStreamStartTime)
        if len(logStreamEvents) > 0:
            destinationBucket = event['destinationBucketName']
            destinationBucketPath = event['destinationBucketPath'] + "/" + logGroupData['logGroupName'].replace("/", "-").lstrip("-") + "/" + logStream['logStreamName'].replace("/","-")
            fileName = "data.json"
            data = { "events": logStreamEvents }
            jsonData = json.dumps(data)
            additionalData = { 
                "logGroup" : logGroupData['logGroupName'],
                "endTime" : logStream['lastEventTimestamp']
                }
            upload_to_s3_bucket(destinationBucket, destinationBucketPath, fileName, jsonData)
            add_an_entry_in_db(event, destinationBucket, destinationBucketPath, additionalData)

def traverse_log_stream_if_necessary(cloudWatch_assumed_client, logStream, event, logGroupData, startTime):
    
    ### Traverse all the events aginst a single logStream

    logStreamEvents = []
    isStreamEventsPending = True
    token = ""
    eventStartTime = startTime if startTime is not None else logGroupData['creationTime']
    result = cloudWatch_assumed_client.get_log_events(
                logGroupName=logGroupData['logGroupName'],
                logStreamName = logStream['logStreamName'],
                startTime = eventStartTime
                )

    while isStreamEventsPending:
        isStreamEventsPending = True if result['nextForwardToken'] !=  token else False
        
        if 'events' in result:
            logStreamEvents.extend(result['events'])
            
        if isStreamEventsPending:
            token = result['nextForwardToken']
            result = cloudWatch_assumed_client.get_log_events(
                        logGroupName=logGroupData['logGroupName'],
                        logStreamName = logStream['logStreamName'],
                        nextToken = token,
                        startTime = eventStartTime
                        )
    return logStreamEvents

def get_logsGroups_streams(cloudWatch_assumed_client, logGroupData):
    
    logGroupsStream = []
    isLogGroupStreamsPending = True
    
    result = cloudWatch_assumed_client.describe_log_streams(logGroupName= logGroupData['logGroupName'])
    
    while isLogGroupStreamsPending:
        isLogGroupStreamsPending = True if 'nextToken' in result else False
        
        if 'logStreams' in result:
            logGroupsStream.extend(result['logStreams'])
            
        if isLogGroupStreamsPending:
            result = cloudWatch_assumed_client.describe_log_streams(logGroupName= logGroupData['logGroupName'], nextToken=result['nextToken'])
    
    return logGroupsStream
    

def get_assumed_cloudWatch_client(accountId, region, item):

    ### Assume the role given in the environment variable `assumableRoleName`, 
    ### so that we can get information residing in the customer environment"

    sts_default_provider_chain = boto3.client('sts')
    role_to_assume_arn='arn:aws:iam::' + accountId + ':role/' + os.environ['assumableRoleName']
    role_session_name= accountId + 'assume_role_sesson'
    
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
    
    cloudWatch_assumed_client = boto3.client(
    'logs',
    aws_access_key_id=newsession_id,
    aws_secret_access_key=newsession_key,
    aws_session_token=newsession_token,
    region_name=region
    )
    
    return cloudWatch_assumed_client
    
def upload_to_s3_bucket(destination_bucket, destination_bucket_path, file_name, json_data):
    s3 = boto3.resource('s3')
    s3.Object(destination_bucket, destination_bucket_path + "/" + file_name).put(Body=json_data)
    
def add_an_entry_in_db(event, destinationBucketName, destinationBucketPath, additionalData):
    dynamodb_client = boto3.resource('dynamodb')
    record_id = str(uuid.uuid4())
    data_ingestion_table = dynamodb_client.Table(os.environ['lambdaOperationLogsTableName'])
    current_datetime = str(datetime.datetime.now())
    current_datetime_epoc = int(convert_datetime_to_epoch(datetime.datetime.now()))
    data_ingestion_table.put_item(
        Item={
            'id': record_id, 
            'cuid': event['cuid'], 
            'operationType': event['operationType'], 
            'sourceBucket': "NULL", 
            'sourceBucketPath': "NULL", 
            'destinationBucket': destinationBucketName, 
            'destinationBucketPath': destinationBucketPath,
            'createdDate': current_datetime,
            'createdDateEpoc': current_datetime_epoc,
            'additionalData': json.dumps(additionalData)
        })
        
def get_logGroup_operationLog(logGroupData, event):
    logGroupOperationLog = None
    client = boto3.resource('dynamodb')
    operationLogsTable = client.Table(os.environ['lambdaOperationLogsTableName'])
    result = operationLogsTable.scan(
                    FilterExpression=Attr("cuid").eq(event['cuid']) & 
                    Attr("operationType").eq(event['operationType']) &
                    Attr("destinationBucketPath").contains(logGroupData['logGroupName'].replace("/", "-").lstrip("-"))
                )
    if result['Count'] > 0:
        logGroupOperationLog = result['Items'][0]
        
    return logGroupOperationLog

def convert_datetime_to_epoch(dateTime):
    epoch = datetime.datetime.utcfromtimestamp(0)
    return int((dateTime - epoch).total_seconds() * 1000.0)
    
def get_previous_epoch_dateTime(maxPreviousDays):
    previousDay = datetime.date.today() + relativedelta(days=-maxPreviousDays)
    previousDay = datetime.datetime.strptime(previousDay.strftime('%Y-%m-%d'), '%Y-%m-%d')
    return convert_datetime_to_epoch(previousDay)