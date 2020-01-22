import json
import boto3
import os
from boto3.dynamodb.conditions import Key, Attr
import traceback
import sys

def lambda_handler(event, context):
    hasMajorException = False
    hasMinorException = False
    message = 'Process has been completed.'
    statusCode = 200

    try:
        client = boto3.resource('dynamodb')
        onBoardingTable = client.Table(os.environ['onBoardingTableName'])
        ### Fetch only master customer information ###
        result = onBoardingTable.scan(
            FilterExpression=(Attr("type").eq('Master')) and (Attr("cuid").eq(event['cuid']))
        )
        ### Traverse all the data if its paginated.
        ### `LastEvaluatedKey` only exists if there is pending result that couldn't be fetched because of data size limitation.
        
        if result['Count'] > 0:
            item = result['Items'][0]

            organizations_assumed_client = get_assumed_organization_client(item)
            organizationsResponse = organizations_assumed_client.list_accounts()
            isOrganizationDataPending = True
            accountIds = []

            while isOrganizationDataPending:

                isOrganizationDataPending = True if 'NextToken' in organizationsResponse else False

                if organizationsResponse != None and len(organizationsResponse['Accounts']) > 0:
                    for account in organizationsResponse['Accounts']:
                        if account['Id'] not in accountIds:
                            accountIds.append(account['Id'])

                if isOrganizationDataPending:
                    organizationsResponse = organizations_assumed_client.list_accounts(NextToken=organizationsResponse['NextToken'])

            ### If there are accounts in the orgization, 
            ### make a comma separate string of them and update the DB against the given `cuid`

            if len(accountIds) > 0:
                response = onBoardingTable.get_item(Key={'cuid': item['cuid']})
                item = response['Item']
                item['accountIds'] = ", ".join(accountIds)
                onBoardingTable.put_item(Item=item)
                                                

    except Exception as e:
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        print(e)
        message = "Process has encountered an internal server exception."
        statusCode = 500
    
    return {
        'statusCode': statusCode,
        'message': message
    }

def get_assumed_organization_client(item):

    ### Assume the role given in the environment variable `assumableRoleName`, 
    ### so that we can get information residing in the customer environment"

    sts_default_provider_chain = boto3.client('sts')
                        
    role_to_assume_arn='arn:aws:iam::' + item['accountId'] + ':role/' + os.environ['assumableRoleName']
    role_session_name= item['accountId'] + 'assume_role_sesson'
    
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
    
    organizations_assumed_client = boto3.client(
    'organizations',
    aws_access_key_id=newsession_id,
    aws_secret_access_key=newsession_key,
    aws_session_token=newsession_token
    )

    return organizations_assumed_client