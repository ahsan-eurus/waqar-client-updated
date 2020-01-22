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
from botocore.exceptions import ClientError

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
    regions = []
    customerInfo = []

    try:    

        account_id = event['accountId']
        cuid = event['cuid']
        regions_raw = event['regions']
        destination_bucket = os.environ['dataIngestionDestinationBucketName']
        destination_bucket_path = cuid + ".cc-aws-data/" + cuid + ".cc-aws-data-securityhub"
        max_results_per_request = int(os.environ['maxResultsPerRequest'])
        client = boto3.resource('dynamodb')
        onBoardingTable = client.Table(os.environ['onBoardingTableName'])

        filename = cuid + "-" + event['accountId'] + "-" + "securityhub_data.json"

        regions = regions_raw.split(',')
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

        for region in regions:
            region = region.replace(" ", "")
            assumed_client = get_assumed_client(account_id, region, customerInfo)
            securityhub_json_data = traverse_securityhub()
            destination_bucket_path_with_region = destination_bucket_path + "/" + region
            if securityhub_json_data is None:
                message += "Security Hub service not found in region [" + region + "] \n"
            else:
                upload_securityhub_json_data(securityhub_json_data, destination_bucket, destination_bucket_path_with_region, filename)
                log_into_dynamodb(cuid, destination_bucket, destination_bucket_path_with_region)

    except Exception as e:
        statusCode = 500
        message = "An error occurred in traversing client security hub information"
        logger.error("Exception: {}".format(e))
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)

    return {
        'statusCode': statusCode,
        'message': message
    }

# method to traverse customer security hub
def traverse_securityhub():

    try:
        response = assumed_client.describe_hub()
    except ClientError as e:
        # logger.error("Exception: {}".format(e))
        print(e)
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        return None

    if response is not None:
        securityhub = {}
        if 'HubArn' in response:
            securityhub['HubArn'] = response['HubArn']
        if 'SubscribedAt' in response:
            securityhub['SubscribedAt'] = response['SubscribedAt']

        invitation_counts = get_invitations_count()
        if invitation_counts is not None:
            securityhub['InvitationsCount'] = invitation_counts

        invitations = traverse_invitations()
        if invitations is not None and len(invitations) > 0:
            securityhub['Invitations'] = invitations

        master_account = get_master_account()
        if master_account is not None:
            securityhub['Master'] = master_account

        member_accounts = traverse_member_accounts()
        if member_accounts is not None and len(member_accounts) > 0:
            securityhub['Members'] = member_accounts

        products = traverse_products()
        if products is not None and len(products) > 0:
            securityhub['ProductSubscriptions'] = products

        standards = traverse_standards()
        if standards is not None and len(standards) > 0:
            securityhub['EnabledStandards'] = standards

        insights = traverse_insights()
        if insights is not None and len(insights) > 0:
            securityhub['Insights'] = insights

        findings = traverse_findings({}, [])
        if findings is not None and len(findings) > 0:
            securityhub['Findings'] = findings

        return json.dumps(securityhub)
    else:
        return None


# method to traverse products subscribed in security hub
def traverse_products():
    isDataPending = True
    product_list = []

    response = assumed_client.list_enabled_products_for_import(
                MaxResults = max_results_per_request
                )

    while isDataPending:
        isDataPending = True if 'NextToken' in response else False

        if 'ProductSubscriptions' in response and response['ProductSubscriptions'] is not None and len(response['ProductSubscriptions']) > 0:
            for product in response['ProductSubscriptions']:
                product_list.append(product)

        if isDataPending:
            response = assumed_client.list_enabled_products_for_import(
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )

    return product_list


# method to traverse standards enabled in security hub    
def traverse_standards():
    isDataPending = True
    standards_list = []

    response = assumed_client.get_enabled_standards(
                MaxResults = max_results_per_request
                )

    while isDataPending:
        isDataPending = True if 'NextToken' in response else False

        if 'StandardsSubscriptions' in response and response['StandardsSubscriptions'] is not None and len(response['StandardsSubscriptions']) > 0:
            for standards in response['StandardsSubscriptions']:
                standards_list.append(standards)

        if isDataPending:
            response = assumed_client.get_enabled_standards(
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )

    return standards_list



# method to traverse standards custom insights created in security hub        
def traverse_insights():
    isDataPending = True
    insight_list = []

    response = assumed_client.get_insights(
                MaxResults = max_results_per_request
                )

    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        if 'Insights' in response and response['Insights'] is not None and len(response['Insights']) > 0:
            for insight in response['Insights']:
                insight_information = insight
                if 'InsightArn' in insight_information:
                    insight_results = get_insight_result(insight_information['InsightArn'])
                    if insight_results is not None:
                        insight_information['Results'] = insight_results
                insight_list.append(insight_information)

        if isDataPending:
            response = assumed_client.get_insights(
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )

    return insight_list


# method to get insight results for particular insight     
def get_insight_result(insight_arn):
    insight_results = {}

    response = assumed_client.get_insight_results(
                InsightArn = insight_arn
                )

    if 'InsightResults' in response and response['InsightResults'] is not None:
        insight_results = response['InsightResults']

    return insight_results


# method to traverse all findings in security hub
def traverse_findings(filters, sort_cireteria):
    isDataPending = True
    findings_list = []

    response = assumed_client.get_findings(
                Filters = filters,
                SortCriteria = sort_cireteria,
                MaxResults = max_results_per_request
                )

    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        if 'Findings' in response and response['Findings'] is not None and len(response['Findings']) > 0:
            for finding in response['Findings']:
                findings_list.append(finding)

        if isDataPending:
            response = assumed_client.get_findings(
                Filters = filters,
                SortCriteria = sort_cireteria,
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )

    return findings_list


# method to get invitations count
def get_invitations_count():
    result = {}

    response = assumed_client.get_invitations_count()

    if 'InvitationsCount' in response and response['InvitationsCount'] is not None:
        result = response['InvitationsCount']

    return result

# method to traverse all invitations
def traverse_invitations():
    isDataPending = True
    invitation_list = []

    response = assumed_client.list_invitations(
                MaxResults = max_results_per_request
                )

    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        if 'Invitations' in response and response['Invitations'] is not None and len(response['Invitations']) > 0:
            for invitation in response['Invitations']:

                if 'InvitedAt' in invitation and invitation['InvitedAt'] is not None:
                    invitation['InvitedAt'] = str(invitation['InvitedAt'])
                    
                invitation_list.append(invitation)

        if isDataPending:
            response = assumed_client.list_invitations(
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )

    return invitation_list  

# method to get master account
def get_master_account():
    master_account = {}

    response = assumed_client.get_master_account()
    if 'Master' in response and response['Master'] is not None:
        master_account = response['Master']
        if 'InvitedAt' in master_account and master_account['InvitedAt'] is not None:
            master_account['InvitedAt'] = str(master_account['InvitedAt'])

    return master_account


# method to traverse all member accounts
def traverse_member_accounts():
    isDataPending = True
    member_list = []

    response = assumed_client.list_members(
                MaxResults = max_results_per_request
                )

    while isDataPending:
        isDataPending = True if 'NextToken' in response else False
        if 'Members' in response and response['Members'] is not None and len(response['Members']) > 0:
            for member in response['Members']:
                if 'UpdatedAt' in member and member['UpdatedAt'] is not None:
                    member['UpdatedAt'] = str(member['UpdatedAt'])
                if 'InvitedAt' in member and member['InvitedAt'] is not None:
                    member['InvitedAt'] = str(member['InvitedAt'])
                member_list.append(member)

        if isDataPending:
            response = assumed_client.list_members(
                MaxResults = max_results_per_request,
                NextToken = response['NextToken']
                )

    return member_list    


# method to get the assumed role
def get_assumed_client(account_id, region, item):

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
    'securityhub',
    aws_access_key_id=newsession_id,
    aws_secret_access_key=newsession_key,
    aws_session_token=newsession_token,
    region_name=region
    )

    return assumed_client


# method to upload the json data extracted from customer security hub into s3
def upload_securityhub_json_data(json_data, destination_bucket, destination_bucket_path, file_name):
    s3 = boto3.resource('s3')
    s3.Object(destination_bucket, destination_bucket_path + "/" + file_name ).put(Body=json_data)


# method to add log entry in database
def log_into_dynamodb(cuid, s3_destination_bucket, s3_destination_path):
    operation_type = "SecurityHub"
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