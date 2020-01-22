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
import uuid

# enum for PolicyTypes
class PolicyTypes(Enum):
    SERVICE_CONTROL_POLICY = 1
    TAG_POLICY = 2
    def __str__(self):
        return self.name

# Global variables
logger = logging.getLogger()
logger.setLevel(logging.INFO)

assumed_client = None
max_results_per_request = 10

def lambda_handler(event, context):
    global max_results_per_request
    global assumed_client
    max_results_per_request = 10
    assumed_client = None
    message = 'Process completed successfully'
    statusCode = 200
    customerInfo = []
    

    try:    
        
        account_id = event['accountId']
        cuid = event['cuid']
        destination_bucket = os.environ['dataIngestionDestinationBucketName']
        destination_bucket_path = cuid + ".cc-aws-data/" + cuid + ".cc-aws-data-awsorgz"
        max_results_per_request = int(os.environ['maxResultsPerRequest'])
        
        filename = cuid + "-" + event['accountId'] + "-" + "orgz_data.json"

        client = boto3.resource('dynamodb')
        onBoardingTable = client.Table(os.environ['onBoardingTableName'])
        result = onBoardingTable.scan(
            FilterExpression=Attr("cuid").eq(cuid)
        )
        if result["Count"] > 0:
            customerInfo = result['Items'][0]
        
    except Exception as e:
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        logger.error("Exception: {}".format(e))
        statusCode = 500
        message += "Invalid input parameters \n"
        
    
    try:
        
        assumed_client = get_assumed_client(account_id, customerInfo)
        organization_json_data = traverse_organization()
        upload_organization_json_data(organization_json_data, destination_bucket, destination_bucket_path, filename)
        log_into_dynamodb(cuid, destination_bucket, destination_bucket_path)
        
    except Exception as e:
        statusCode = 500
        message = "An error occurred in traversing client organization data"
        logger.error("Exception: {}".format(e))
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        
    return {
        'statusCode': statusCode,
        'message': message
    }

def traverse_organization():
    ## Traversing the organization to fetch it's properties, attributes, service account policies, 
    ## root accounts, OUs

    response = assumed_client.describe_organization()
    
    if response is not None and response['Organization'] is not None:
        organization = {}
        organization['Organization'] = response['Organization']
        
        service_control_policies = traverse_policies(str(PolicyTypes.SERVICE_CONTROL_POLICY))
        if service_control_policies is not None and len(service_control_policies) > 0:
            organization['ServiceControlPolicies'] = service_control_policies
            
        tag_policies = traverse_policies(str(PolicyTypes.TAG_POLICY))
        if tag_policies is not None and len(tag_policies) > 0:
            organization['TagPolicies'] = tag_policies
        
        roots = traverse_roots()
        if roots is not None:
            organization['Roots'] = roots
            
        
        return json.dumps(organization)
    else:
        return None


def traverse_roots():
    ## traversing all root accounts available in an orgainzation

    isDataPending = True
    root_list = []
    
    response = assumed_client.list_roots(
                MaxResults = max_results_per_request
                )
                
    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        
        if len(response['Roots']) > 0:
            
            for root_account in response['Roots']:
                root_account_information = root_account
                
                ## traversing root account service control policies
                service_control_policies = traverse_target_policies(root_account_information['Id'], str(PolicyTypes.SERVICE_CONTROL_POLICY))
                if service_control_policies is not None and len(service_control_policies) > 0:
                    root_account_information['ServiceControlPolicies'] = service_control_policies
                    
                ## traversing root account tag policies
                tag_policies = traverse_target_policies(root_account_information['Id'], str(PolicyTypes.TAG_POLICY))
                if tag_policies is not None and len(tag_policies) > 0:
                    root_account_information['TagPolicies'] = tag_policies

                ## traversing root sub accounts
                accounts = traverse_accounts(root_account_information['Id'])
                if accounts is not None and len(accounts) > 0:
                    root_account_information['Accounts'] = accounts

                ## traversing root OUs    
                organization_units = traverse_organization_units(root_account_information['Id'])
                if organization_units is not None and len(organization_units) > 0:
                    root_account_information['OrganizationalUnits'] = organization_units
                    
                root_list.append(root_account_information)
        
        if isDataPending:
            response = assumed_client.list_roots(
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )
                        
    return root_list

def traverse_organization_units(parent_id):
    # travsering organization units to fetch properties, attributes, 
    # service control policies, tag policies, sub accounts, sub OUs

    isDataPending = True
    organization_unit_list = []
    
    response = assumed_client.list_organizational_units_for_parent(
                ParentId = parent_id,
                MaxResults = max_results_per_request
                )
                
    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        
        if len(response['OrganizationalUnits']) > 0:
            
            for ou in response['OrganizationalUnits']:
                org_unit_information = ou
                
                service_control_policies = traverse_target_policies(ou['Id'], str(PolicyTypes.SERVICE_CONTROL_POLICY))
                if service_control_policies is not None and len(service_control_policies) > 0:
                    org_unit_information['ServiceControlPolicies'] = service_control_policies
                    
                tag_policies = traverse_target_policies(ou['Id'], str(PolicyTypes.TAG_POLICY))
                if tag_policies is not None and len(tag_policies) > 0:
                    org_unit_information['TagPolicies'] = tag_policies
                    
                accounts = traverse_accounts(ou['Id'])
                if accounts is not None and len(accounts) > 0:
                    org_unit_information['Accounts'] = accounts
                
                nested_ous = traverse_organization_units(ou['Id'])
                if nested_ous is not None and len(nested_ous) > 0:
                    org_unit_information['OrganizationalUnits'] = nested_ous
                
                organization_unit_list.append(org_unit_information)
                
        if isDataPending:
            response = assumed_client.list_organizational_units_for_parent(
                ParentId = parent_id,
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )
                        
    return organization_unit_list
    

def traverse_accounts(parent_id):
    # traversing sub accounts for parent account (root, sub OUs)
    isDataPending = True
    account_list = []
    
    response = assumed_client.list_accounts_for_parent(
                ParentId = parent_id,
                MaxResults = max_results_per_request
                )
                
    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        
        if len(response['Accounts']) > 0:
            for account in response['Accounts']:
                
                account_information = account
                
                if 'JoinedTimestamp' in account_information:
                    account_information['JoinedTimestamp'] = str(account['JoinedTimestamp'])
                    
                account_tags = traverse_account_tags(account['Id'])
                if account_tags is not None and len(account_tags) > 0:
                    account_information['Tags'] = account_tags
                
                service_control_policies = traverse_target_policies(account['Id'], str(PolicyTypes.SERVICE_CONTROL_POLICY))
                if service_control_policies is not None and len(service_control_policies) > 0:
                    account_information['ServiceControlPolicies'] = service_control_policies
                    
                tag_policies = traverse_target_policies(account['Id'], str(PolicyTypes.TAG_POLICY))
                if tag_policies is not None and len(tag_policies) > 0:
                    account_information['TagPolicies'] = tag_policies
                
                account_list.append(account_information)
                
        if isDataPending:
            response = assumed_client.list_accounts_for_parent(
                ParentId = parent_id,
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )
                        
    return account_list


def traverse_account_tags(account_id):
    # get all tags associated with an account

    isDataPending = True
    account_tag_list = []
    
    response = assumed_client.list_tags_for_resource(
                ResourceId=account_id
                )
                
    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        
        if len(response['Tags']) > 0:
            for tag in response['Tags']:
                account_tag_list.append(tag)

        if isDataPending:
            response = assumed_client.list_tags_for_resource(
                ResourceId=account_id,
                NextToken = response['NextToken']
                )
                        
    return account_tag_list
    
def traverse_target_policies(target_id, policy_type):
    # fetch all targets associated with policy

    isDataPending = True
    policy_list = []
    
    response = assumed_client.list_policies_for_target(
                TargetId = target_id,
                Filter = policy_type,
                MaxResults = max_results_per_request
                )
                
    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        
        if len(response['Policies']) > 0:
            for policy in response['Policies']:
                policy_list.append(policy)
        
        if isDataPending:
            response = assumed_client.list_policies_for_target(
                TargetId = target_id,
                Filter = policy_type,
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )
                
    return policy_list


def traverse_policies(policy_type):
    # traverse all policies using policy type parameter

    isDataPending = True
    policy_list = []
    
    response = assumed_client.list_policies(
                Filter = policy_type,
                MaxResults = max_results_per_request
                )
                
    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        
        if len(response['Policies']) > 0:
            for policy in response['Policies']:
                
                policy_information = describe_policy(policy['Id'])
                
                if 'Content' in policy_information:
                    policy_information['Content'] = json.loads(policy_information['Content'])
                
                policy_targets = traverse_policy_targets(policy['Id'])
                if policy_targets is not None and len(policy_targets) > 0:
                    policy_information['PolicyTargets'] = policy_targets
                
                policy_list.append(policy_information)
        
        if isDataPending:
            response = assumed_client.list_policies(
                Filter = policy_type,
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )
                        
    return policy_list
    
def describe_policy(policy_id):
    # get properties of policy

    response = assumed_client.describe_policy(
        PolicyId=policy_id
    )
    if response is not None and response['Policy'] is not None:
        return response['Policy']
    else:
        return None
    
def traverse_policy_targets(policy_id):
    # traver policy targets for specifi policy using policy id

    isDataPending = True
    policy_target_list = []
    
    response = assumed_client.list_targets_for_policy(
                PolicyId = policy_id,
                MaxResults = max_results_per_request
                )
                
    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        
        if len(response['Targets']) > 0:
            for target in response['Targets']:
                policy_target_list.append(target)
                
        if isDataPending:
            response = assumed_client.list_targets_for_policy(
                PolicyId = policy_id,
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )
                        
    return policy_target_list

def get_assumed_client(account_id, item):

    ### Assume the role given in the environment variable `assumableRoleName`, 
    ### so that we can get information residing in the customer environment"

    sts_default_provider_chain =    boto3.client('sts')
    role_to_assume_arn='arn:aws:iam::' + account_id + ':role/' + os.environ['assumableRoleName']
    role_session_name= account_id + 'assume_role_sesson'
    
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
    
    assumed_client = boto3.client(
    'organizations',
    aws_access_key_id=newsession_id,
    aws_secret_access_key=newsession_key,
    aws_session_token=newsession_token
    )
    
    return assumed_client
    

def upload_organization_json_data(json_data, destination_bucket, destination_bucket_path, file_name):
    ## uploading the organization json data to s3 bucket

    s3 = boto3.resource('s3')
    s3.Object(destination_bucket, destination_bucket_path + "/" + file_name ).put(Body=json_data)


def log_into_dynamodb(cuid, s3_destination_bucket, s3_destination_path):
    operation_type = "ORGZ"
    ### Logging the operation in DB,
    ### so that we can keep track of which source's path synced to which destination's path.

    try:
        dynamodb_client = boto3.resource('dynamodb')
        record_id = str(uuid.uuid4())
        data_ingestion_table = dynamodb_client.Table(os.environ['customer_data_ingestion_tb'])
        current_datetime = str(datetime.datetime.now())
        current_datetime_epoc = int(convert_datetime_to_epoch(datetime.datetime.now()))
        data_ingestion_table.put_item(
            Item={
                'id': record_id, 
                'cuid': cuid, 
                'operationType': operation_type, 
                'sourceBucket': 'NULL', 
                'sourceBucketPath': 'NULL', 
                'destinationBucket': s3_destination_bucket, 
                'destinationBucketPath': s3_destination_path,
                'createdDate': current_datetime,
                'createdDateEpoc': current_datetime_epoc
            })
        
    except Exception as e:
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        logger.error("Exception: {}".format(e))
        return False
    return True


def convert_datetime_to_epoch(dateTime):
    epoch = datetime.datetime.utcfromtimestamp(0)
    return int((dateTime - epoch).total_seconds() * 1000.0)