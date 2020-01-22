import json
import boto3
import os
from boto3.dynamodb.conditions import Key, Attr
import traceback
import sys
import datetime

operationType = "CloudWatchLogs"

def lambda_handler(event, context):
    hasMajorException = False
    message = 'Process has been completed.'
    statusCode = 200
    
    try:
        hasMinorException = traverse_customers()
    except Exception as e:
        hasMajorException = True
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        print(e)
    
    if hasMinorException:
        message = "Process has been completed with exception(s)."
    if hasMajorException:
        message = "Process has encountered an internal server exception."
        statusCode = 500
        
    return {
        'statusCode': statusCode,
        'message': message
    }
    
def traverse_customers():
    hasMinorException = False
    
    client = boto3.resource('dynamodb')
    onBoardingTable = client.Table(os.environ['onBoardingTableName'])
    isCustomerDataPending = True
    
    ### Fetch only the customer(s) whose cloudWatchRegions are defined

    result = onBoardingTable.scan(
        FilterExpression=Attr("cloudWatchRegions").exists()
        )

    ### Traverse all the data if its paginated.
    ### `LastEvaluatedKey` only exists if there is pending result that couldn't be fetched because of data size limitation.
    
    while isCustomerDataPending:
        isCustomerDataPending = True if 'LastEvaluatedKey' in result else False
        
        if result['Count'] > 0:
            items = result['Items']
            for item in items:
                try:
                    traverse_customer_associated_accounts(item)
                except Exception as e:
                    hasMinorException = True
                    ex_type, ex, tb = sys.exc_info()
                    traceback.print_tb(tb)
                    print(e)
                    
        if isCustomerDataPending:
            result = onBoardingTable.scan(
                FilterExpression=Attr("cloudWatchRegions").exists(),
                ExclusiveStartKey=result['LastEvaluatedKey']
                )
                
    return hasMinorException

def traverse_customer_associated_accounts(item):
    customer_account_ids = []
    if item['type'] == 'Single':
        customer_account_ids.append(item['accountId'])
    else:
        customer_account_ids = item['accountIds'].replace(" ", "").split(",")

    for accountId in customer_account_ids:
        traverse_customer_per_regions(item, accountId)
        
def traverse_customer_per_regions(item, selected_account_id):

    ### Traverse the cloudwatchGroups in all the regions provided by the customer

    regions = item['cloudWatchRegions'].replace(" ", "").split(",")
    for region in regions:
        cloudWatch_assumed_client = get_assumed_cloudWatch_client(item, region, selected_account_id)
        traverse_customer_cloudWatch_groups(cloudWatch_assumed_client, item, region, selected_account_id)
        
def traverse_customer_cloudWatch_groups(cloudWatch_assumed_client, item, region, selected_account_id):
    isLogGroupsDataPending = True
    result = cloudWatch_assumed_client.describe_log_groups()
    
    while isLogGroupsDataPending:
        isLogGroupsDataPending = True if 'nextToken' in result else False
        
        if 'logGroups' in result:
            logGroups = result['logGroups']
            for logGroup in logGroups:
                invoke_copy_lambda_if_necessary(cloudWatch_assumed_client, item, logGroup, region, selected_account_id)
                    
        if isLogGroupsDataPending:
            result = cloudWatch_assumed_client.describe_log_groups(nextToken=result['nextToken'])
            
def invoke_copy_lambda_if_necessary(cloudWatch_assumed_client, item, logGroup, region, selected_account_id):
    hasEvents = False

    ### Check whether the logGroups is empty or not,
    ### If its empty we'll not query for events against it

    logGroupEvents = cloudWatch_assumed_client.filter_log_events(
                    logGroupName = logGroup['logGroupName'],
                    limit = 1
                    )
                    
    if 'events' in logGroupEvents and len(logGroupEvents['events']) > 0:
        hasEvents = True
    
    if hasEvents:
        destinationBucketPath = item['cuid'] + ".cc-aws-data/" + item['cuid'] + ".cc-aws-data-cloudwatch" + "/logs" + "/" + region
        logData = {
             "logGroupName": logGroup['logGroupName'], 
             "creationTime": logGroup['creationTime'], 
             "region": region
            }
        lambda_client = boto3.client('lambda')
        msg = {
                "destinationBucketName": os.environ['destinationBucketName'], 
                "destinationBucketPath": destinationBucketPath,
                "additionalData": json.dumps(logData),
                "accountId": selected_account_id, 
                "cuid": item['cuid'], 
                "operationType": operationType, 
                "at": str(datetime.datetime.now())
              }
        invoke_response = lambda_client.invoke(FunctionName=os.environ['lambdaCopyDataFunctionName'],
                           InvocationType='Event',
                           Payload= json.dumps(msg))
    

def get_assumed_cloudWatch_client(item, region, selected_account_id):

    ### Assume the role given in the environment variable `assumableRoleName`, 
    ### so that we can get information residing in the customer environment"

    sts_default_provider_chain = boto3.client('sts')
    role_to_assume_arn = 'arn:aws:iam::' + selected_account_id + ':role/' + os.environ['assumableRoleName']
    role_session_name = selected_account_id + 'assume_role_sesson'
    
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
    