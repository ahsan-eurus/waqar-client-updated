import boto3
import os
import traceback
import logging
import time
import subprocess
import sys
from awspolicy import BucketPolicy
from boto3.dynamodb.conditions import Key, Attr
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)
hasMinorException = False

def lambda_handler(event, context):
    message = 'Process completed successfully'
    statusCode = 200
    global hasMinorException
    hasMinorException = False
    launch_cc_role_cfn_url = ""
    customer_information = None

    try:
        customer_information = get_customer_information(event['cuid'])
        if customer_information == None:
            return {
                'statusCode': 500,
                'message': "Customer not found."
            }

        if customer_information['type'] == "Master":
            triggeredFuncResponse = invoke_lambda(os.environ['updateCustomerMasterAccountLambda'], {"cuid": event['cuid']})
            json_response = json.loads(triggeredFuncResponse['Payload'].read().decode("utf-8"))
            if json_response['statusCode'] != 200:
                return {
                    'statusCode': json_response['statusCode'],
                    'message': json_response['message']
                }

        cleanUpBucketPolicies()
        whitelist_customer_account(customer_information)
        launch_cc_role_cfn_url = get_cc_role_launch_url(customer_information)
        
    except Exception as e:
        logger.error("Exception: {}".format(e), exc_info=sys.exc_info())
        message = "Process has encountered an internal server exception."
        statusCode = 500
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)

    if hasMinorException:
        message = "Process has been completed with exception(s)"
        statusCode = 500

    print(launch_cc_role_cfn_url)
    return {
        'statusCode': statusCode,
        'message': message,
        'launch_cc_role_cfn_url': launch_cc_role_cfn_url
    }

def get_cc_role_launch_url(customer_information):
    return ("https://console.aws.amazon.com/cloudformation/home?#/stacks/create/review?"
            "stackName=CecureCloud-IAM-Role-CFN&"
            "templateURL=https://{onBoardingBucketName}.s3-us-west-2.amazonaws.com/aws-iam-role-cfn/aws-iam-role.yml&"
            "param_OriginAccountId=&"
            "param_ExternalId={externalId}&"
            "param_IntegrationType=RO&"
            "param_CecureCloudDataBucket={ingestionBucketName}&"
            "param_BillingBucketName={billingBucketName}&"
            "param_CloudTrailBucketName={cloudTrailBucketName}&"
            "param_ConfigBucketName={configBucketName}&"
            "param_GuardDutyBucketName={guardDutyBucketName}"
            ).format(onBoardingBucketName=os.environ['bucketName'], 
                    externalId = customer_information['externalId'] if 'externalId' in customer_information else "",
                    ingestionBucketName = os.environ['ingestionBucketName'],
                    billingBucketName = customer_information['billingBucketName'] if 'billingBucketName' in customer_information else "",
                    cloudTrailBucketName = customer_information['cloudTrailBucketName'] if 'cloudTrailBucketName' in customer_information else "",
                    configBucketName = customer_information['configBucketName'] if 'configBucketName' in customer_information else "",
                    guardDutyBucketName = customer_information['guardDutyBucketName'] if 'guardDutyBucketName' in customer_information else ""
                    )

def get_customer_information(cuid):
    customer_information = None
    client = boto3.resource('dynamodb')
    onBoardingTable = client.Table(os.environ['onBoardingTableName'])
    
    result = onBoardingTable.scan(
        FilterExpression=Attr("cuid").eq(cuid)
    )   
    if result['Count'] > 0:
        customer_information = result['Items'][0]

    return customer_information

def whitelist_customer_account(customer_information):
    global hasMinorException
    customer_account_ids = []
    if customer_information['type'] == "Single":
        customer_account_ids.append(customer_information['accountId'])
    else:
        customer_account_ids = customer_information['accountIds'].replace(" ", "").split(",")

    for account_id in customer_account_ids:
        try:
            whitelist_customer_accountId(account_id)
        except Exception as e:
            hasMinorException = True
            logger.error("Exception: {}".format(e),  exc_info=sys.exc_info())

def whitelist_customer_accountId(accountId):
    s3_client = boto3.client('s3')

    # Load the bucket policy as an object
    bucket_policy = BucketPolicy(serviceModule=s3_client, resourceIdentifer=os.environ['bucketName'])

    # Select the statement that will be modified
    statement_to_modify = bucket_policy.select_statement('WhiteListedCustomersAccountIds')

    if not is_accountId_already_exists(statement_to_modify, accountId):

        if type(statement_to_modify.Principal['AWS']) is str:
            accountIds = []
            accountIds.append(statement_to_modify.Principal['AWS'])
            accountIds.append(accountId)
            statement_to_modify.Principal['AWS'] = accountIds
        else:
            statement_to_modify.Principal['AWS'].append(accountId)

        # Save change of the statement
        statement_to_modify.save()
        statement_to_modify.source_policy.save()

def is_accountId_already_exists(statement_to_modify, accountId):
    return accountId in statement_to_modify.Principal['AWS']

def cleanUpBucketPolicies():
    try:
        
        s3 = boto3.client('s3')
        result = s3.get_bucket_policy(Bucket=os.environ['bucketName'])
        policy = json.loads(result['Policy'])
        updatePolicyStatement = []
        for statement in policy['Statement']:
            if ('AWS' in statement['Principal']):
                if type(statement['Principal']['AWS']) is str and not len(statement['Principal']['AWS']) == 21:
                    updatePolicyStatement.append(statement)
                elif type(statement['Principal']['AWS']) is str and len(statement['Principal']['AWS']) == 21:
                    pass
                else:
                    arns = [acc for acc in statement['Principal']['AWS'] if not len(acc) == 21 ]
                    if len(arns) > 0:
                        statement['Principal']['AWS'] = arns
                        updatePolicyStatement.append(statement)
            else:
                updatePolicyStatement.append(statement)
                
        if len(updatePolicyStatement) > 0:
            policy['Statement'] = updatePolicyStatement
            bucket_policy = json.dumps(policy)
            s3.put_bucket_policy(Bucket=os.environ['bucketName'], Policy=bucket_policy)
        else:
            s3.delete_bucket_policy(Bucket=os.environ['bucketName'])
            
    except Exception as e:
        logger.error("Exception: {}".format(e), exc_info=sys.exc_info())

def invoke_lambda(function_name, data):
    lambda_client = boto3.client('lambda')
    response = lambda_client.invoke(
        FunctionName=function_name,
        InvocationType='RequestResponse',
        Payload=json.dumps(data)
    )
    return response