import boto3
import os
import traceback
import logging
import sys
import json
from awspolicy import BucketPolicy
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key, Attr

logger = logging.getLogger()
logger.setLevel(logging.INFO)

class PolicyHelperBucketDirLevel():
    
    @staticmethod
    def is_accountId_already_exists(statement_to_modify, accountId):
        return accountId in statement_to_modify.Principal['AWS']
    
    
    @staticmethod
    def whitelist_customer_accountId(accountId, cuid):
        statement_to_modify = PolicyHelperBucketDirLevel.get_bucket_policy_statement(cuid)
    
        if statement_to_modify == None:
            statement_to_modify = PolicyHelperBucketDirLevel.generate_initial_statement(accountId, cuid)
        
        if not PolicyHelperBucketDirLevel.is_accountId_already_exists(statement_to_modify, accountId):
            
            if type(statement_to_modify.Principal['AWS']) is str:
                accountIds = []
                accountIds.append(statement_to_modify.Principal['AWS'])
                accountIds.append(PolicyHelperBucketDirLevel.get_customer_role_arn(accountId))
                
                statement_to_modify.Principal['AWS'] = accountIds
            else:
                statement_to_modify.Principal['AWS'].append(PolicyHelperBucketDirLevel.get_customer_role_arn(accountId))
            
            # Save change of the statement
            statement_to_modify.save()
            statement_to_modify.source_policy.save()
    
    @staticmethod
    def get_customer_role_arn(accountId):
        return "arn:aws:iam::{accountId}:role/{assumableRoleName}".format(accountId=accountId, assumableRoleName=os.environ['assumableRoleName'])
    
    @staticmethod
    def get_customer_bucket_policy_statementId(cuid):
        return 'WhiteListingCCRoleForCustomerBucketDirLevel-{cuid}'.format(cuid=cuid)
        
    @staticmethod
    def get_customer_bucket_path(bucket_name, bucket_path):
        return [
            'arn:aws:s3:::{bucketName}/{bucketPath}'.format(bucketName=bucket_name, bucketPath=bucket_path),
            'arn:aws:s3:::{bucketName}/{bucketPath}/*'.format(bucketName=bucket_name, bucketPath=bucket_path)
            ]
            
    @staticmethod   
    def get_customer_bucket_actions():
        return [
                "s3:ReplicateObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:GetObject",
                "s3:RestoreObject"
            ]
            
    @staticmethod
    def get_bucket_policy_statement(cuid):
        try:
            s3_client = boto3.client('s3')
            
            # Load the bucket policy as an object
            bucket_policy = BucketPolicy(serviceModule=s3_client, resourceIdentifer=os.environ['bucketName'])
            
            # Select the statement that will be modified
            statement_to_modify = bucket_policy.select_statement(PolicyHelperBucketDirLevel.get_customer_bucket_policy_statementId(cuid))
        except ClientError as e:
            if e.response['Error']['Code'] == "NoSuchBucketPolicy":
                statement_to_modify = None
            else:
                raise
        
        return statement_to_modify
        
        
    @staticmethod
    def generate_initial_statement(accountId, cuid):
        bucket_policy = ""
        bucket_name = os.environ['bucketName']
        bucket_path = "{cuid}.cc-aws-data".format(cuid=cuid)
        isBucketPolicyAlreadyExists = False
        
        try:
            s3 = boto3.client('s3')
            result = s3.get_bucket_policy(Bucket=os.environ['bucketName'])
            isBucketPolicyAlreadyExists = True
            bucket_policy = json.loads(result['Policy'])
        except ClientError as e:
            if e.response['Error']['Code'] == "NoSuchBucketPolicy":
                bucket_policy = {
                                'Version': '2012-10-17',
                                'Statement': [{
                                    'Sid': PolicyHelperBucketDirLevel.get_customer_bucket_policy_statementId(cuid),
                                    'Effect': 'Allow',
                                    "Principal": {
                                        "AWS": PolicyHelperBucketDirLevel.get_customer_role_arn(accountId)
                                    },
                                    'Action': PolicyHelperBucketDirLevel.get_customer_bucket_actions(),
                                    'Resource': PolicyHelperBucketDirLevel.get_customer_bucket_path(bucket_name, bucket_path)
                                }]
                            }
            else:
                raise
            
        if isBucketPolicyAlreadyExists:
            bucket_policy["Statement"].append({
                'Sid': PolicyHelperBucketDirLevel.get_customer_bucket_policy_statementId(cuid),
                'Effect': 'Allow',
                "Principal": {
                    "AWS": PolicyHelperBucketDirLevel.get_customer_role_arn(accountId)
                },
                'Action': PolicyHelperBucketDirLevel.get_customer_bucket_actions(),
                'Resource': PolicyHelperBucketDirLevel.get_customer_bucket_path(bucket_name, bucket_path)
            })
        
        # Convert the policy from JSON dict to string
        bucket_policy = json.dumps(bucket_policy)
    
        # Set the new policy
        s3.put_bucket_policy(Bucket=bucket_name, Policy=bucket_policy)
        return PolicyHelperBucketDirLevel.get_bucket_policy_statement(cuid)
