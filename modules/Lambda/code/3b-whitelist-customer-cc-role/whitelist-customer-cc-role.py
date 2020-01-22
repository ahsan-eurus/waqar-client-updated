import boto3
import os
import traceback
import logging
import sys
import json
from policy_helper_dir_level import PolicyHelperBucketDirLevel
from policy_helper_bucket_level import PolicyHelperBucketLevel
from awspolicy import BucketPolicy
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key, Attr

logger = logging.getLogger()
logger.setLevel(logging.INFO)
hasMinorException = False

def lambda_handler(event, context):
    message = 'Process completed successfully'
    statusCode = 200
    global hasMinorException
    hasMinorException = False
    
    try:
        cleanUpBucketPolicies()
        whitelist_customer_account(event['cuid'])
    except Exception as e:
        logger.error("Exception: {}".format(e), exc_info=sys.exc_info())
        message = "Process has encountered an internal server exception."
        statusCode = 500
        
    if hasMinorException:
        message = "Process has been completed with exception(s), some of the account ids(s) may not be successfully whitelisted"
        statusCode = 200
        
    return {
        'statusCode': statusCode,
        'message': message
    }
    
def whitelist_customer_account(cuid):
    global hasMinorException
    client = boto3.resource('dynamodb')
    onBoardingTable = client.Table(os.environ['onBoardingTableName'])
    customer_account_ids = []

    result = onBoardingTable.scan(
        FilterExpression=Attr("cuid").eq(cuid)
    )

    if result['Count'] > 0:
        customer_information = result['Items'][0]
        if customer_information['type'] == "Single":
            customer_account_ids.append(customer_information['accountId'])
        else:
            customer_account_ids = customer_information['accountIds'].replace(" ", "").split(",")

    for account_id in customer_account_ids:
        try:
            whitelist_customer_accountId(account_id, cuid)
        except Exception as e:
            hasMinorException = True
            logger.error("Exception: {}".format(e),  exc_info=sys.exc_info())
                        
def whitelist_customer_accountId(accountId, cuid):
    PolicyHelperBucketDirLevel.whitelist_customer_accountId(accountId, cuid)
    PolicyHelperBucketLevel.whitelist_customer_accountId(accountId, cuid)


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