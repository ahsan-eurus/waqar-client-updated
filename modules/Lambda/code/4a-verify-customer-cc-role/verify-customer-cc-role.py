import boto3
import os
import traceback
import logging
import time
import subprocess
import sys
import json
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    message = 'Process completed successfully'
    statusCode = 200
    permissions = {}
    
    try:
        triggeredFuncResponse = invoke_lambda(os.environ['whitelistCustomerCCRoleLambda'], {"cuid": event['cuid']})
        json_response = json.loads(triggeredFuncResponse['Payload'].read().decode("utf-8"))
        if json_response['statusCode'] != 200:
            return {
                'statusCode': json_response['statusCode'],
                'message': json_response['message']
            }
            
        permissions = verifyPermissions(event['cuid'])
    except Exception as e:
        logger.error("Exception: {}".format(e), exc_info=sys.exc_info())
        message = "Process has encountered an internal server exception."
        statusCode = 500
        
    return {
        'statusCode': statusCode,
        'message': message,
        'permissions': permissions
    }
    
def verifyPermissions(cuid):
    customer_information = None
    client = boto3.resource('dynamodb')
    onBoardingTable = client.Table(os.environ['onBoardingTableName'])

    result = onBoardingTable.scan(
        FilterExpression=Attr("cuid").eq(cuid)
    )
    
    if result['Count'] > 0:
        customer_information = result['Items'][0]
    
    return get_permissions(customer_information)
    
    
def get_permissions(customer_information):
    permission_information = {}
    bucket_permission_information = {}
    
    bucket_permission_information = get_buckets_permissions(customer_information)
    permission_information['BucketPermissions'] = bucket_permission_information
    
    return permission_information
    
def get_buckets_permissions(customer_information):
    bucket_permission_information = {}
    
    if 'billingBucketName' in customer_information:
        bucket_permission_information["billingBucket"] = get_specific_bucket_permission(customer_information, 'billingBucket')
        
    if 'cloudTrailBucketName' in customer_information:
        bucket_permission_information["cloudTrailBucket"] = get_specific_bucket_permission(customer_information, 'cloudTrailBucket')
        
    if 'configBucketName' in customer_information:
        bucket_permission_information["configBucket"] = get_specific_bucket_permission(customer_information, 'configBucket')
        
    if 'guardDutyBucketName' in customer_information:
        bucket_permission_information["guardDutyBucket"] = get_specific_bucket_permission(customer_information, 'guardDutyBucket')

    return bucket_permission_information
    
def get_specific_bucket_permission(customer_information, bucket_service_param):
    bucket_name = customer_information[bucket_service_param + 'Name']
    bucket_path = customer_information[bucket_service_param + 'Path']
    bucket_account_id_param = bucket_service_param + 'accountId' 
    
    perm = {
            "bucketName" : bucket_name,
            "bucketPath" : bucket_path,
            "hasPermission": check_bucket_permission(customer_information, bucket_name, bucket_path, bucket_account_id_param)
        }
    return perm
    
def check_bucket_permission(customer_information, bucketName, bucket_path, bucket_account_id_param):
    hasPermission = True
    try:
        s3_assumed_client = get_assumed_s3_client(customer_information, get_account_id(customer_information, bucket_account_id_param))
        
        response = s3_assumed_client.list_objects_v2(
                    Bucket = bucketName,
                    Prefix = bucket_path,
                    Delimiter='/'
                    )
    except Exception as e:
        logger.error("Exception: {}".format(e), exc_info=sys.exc_info())
        hasPermission = false
    return hasPermission
    
def get_assumed_s3_client(item, selected_account_id):

    ### Assume the role given in the environment variable `assumableRoleName`, 
    ### so that we can get information residing in the customer environment"

    sts_default_provider_chain = boto3.client('sts')
    role_to_assume_arn ='arn:aws:iam::' + selected_account_id + ':role/' + os.environ['assumableRoleName']
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
    
    s3_assumed_client = boto3.client(
    's3',
    aws_access_key_id=newsession_id,
    aws_secret_access_key=newsession_key,
    aws_session_token=newsession_token
    )
    
    return s3_assumed_client
    
def get_account_id(item, account_id_param):
    accountId = ""
    if account_id_param in item and item[account_id_param] != "" and item[account_id_param] != None:
        accountId = item[account_id_param]
    else:
        accountId = item['accountId']
    return accountId
    
def invoke_lambda(function_name, data):
    lambda_client = boto3.client('lambda')
    response = lambda_client.invoke(
        FunctionName=function_name,
        InvocationType='RequestResponse',
        Payload=json.dumps(data)
    )
    return response