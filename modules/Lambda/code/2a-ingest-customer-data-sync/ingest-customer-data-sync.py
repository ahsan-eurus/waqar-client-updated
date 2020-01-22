import boto3
import os
import subprocess
import logging
import uuid
import 
import traceback
import sys
from boto3.dynamodb.conditions import Key, Attr

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    statusCode = 200
    message = ""

    role_name = os.environ['assumableRoleName']
    external_id = ""
    customerInfo = []
    
    try:    

        cuid = event['cuid']
        client = boto3.resource('dynamodb')
        onBoardingTable = client.Table(os.environ['onBoardingTableName'])
        result = onBoardingTable.scan(
            FilterExpression=Attr("cuid").eq(cuid)
        )
        if result["Count"] > 0:
            customerInfo = result['Items'][0]

        if 'externalId' in customerInfo:
            external_id = customerInfo['externalId']

        account_id = event['account_id']
        
        s3_source_bucket = event['s3_source_bucket_name']
        s3_source_prefix = event['s3_source_bucket_path']
        
        s3_destination_bucket = event['s3_destination_bucket_name']
        s3_destination_prefix = event['s3_destination_bucket_path']
        
        cuid = event['cuid']
        operation_type = event['operation_type']
        
    except Exception as e:
        logger.error("Exception: {}".format(e))
        statusCode = 500
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        message += "Invalid input parameters \n"
    
    
    buckets_synced_response = sync_buckets(account_id, role_name, external_id, s3_source_bucket, s3_source_prefix, s3_destination_bucket, s3_destination_prefix )
    
    if buckets_synced_response == "synced":
        message += "s3 buckets synced \n"
        record_inserted = log_into_dynamodb(cuid, s3_source_bucket, s3_source_prefix, s3_destination_bucket, s3_destination_prefix, operation_type)
        if record_inserted:
            statusCode = 200     
            message += "Record inserted in dynamodb table \n"
        else:
            statusCode = 500     
            message += "An error occurred in saving record in dynamodb \n"
    elif buckets_synced_response == "already_synced":
        statusCode = 200     
        message += "Buckets are already synced and upto date \n"
    else:
        statusCode = 500 
        message += "s3 buckets not synced due to an internal server error \n"
    
    return {
        'statusCode': statusCode,
        'message': message
    }
    
def log_into_dynamodb(cuid, s3_source_bucket, s3_source_prefix, s3_destination_bucket, s3_destination_prefix, operation_type):
    
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
                'sourceBucket': s3_source_bucket, 
                'sourceBucketPath': s3_source_prefix, 
                'destinationBucket': s3_destination_bucket, 
                'destinationBucketPath': s3_destination_prefix,
                'createdDate': current_datetime,
                'createdDateEpoc': current_datetime_epoc
            })
        
    except Exception as e:
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        logger.error("Exception: {}".format(e))
        return False
    return True
        
    
    
    
def sync_buckets(account_id, role_name, external_id, s3_source_bucket, s3_source_prefix, s3_destination_bucket, s3_destination_prefix):
    
    ### This function is using AWS Lambda - Layer feature.
    ### We have create an AWS CLI layer and attached it with the current lambda.
    ### So basically, this function is executing `the sync_bucket.sh` file,
    ### which is using AWS CLI to sync the two buckets w.r.t the given path.
    
    response = ""
    try:
        os.environ["PATH"] = os.environ["PATH"] + ":/opt/awscli"
        
        scriptPath = os.environ['LAMBDA_TASK_ROOT'] + "/sync_buckets.sh"
        
        os.system("cp " + scriptPath + " /tmp/sync_buckets.sh")
        os.system("chmod +x /tmp/sync_buckets.sh")
    
        sync_command = "cd /tmp && ./sync_buckets.sh " + account_id + " " + role_name + " " + s3_source_bucket + " " + s3_source_prefix + " " + s3_destination_bucket + " " + s3_destination_prefix + " " + external_id
        result = subprocess.check_output([sync_command], stderr=subprocess.STDOUT, shell=True)
        if result == "":
            logger.error("Buckets are already upto date")
            response = "already_synced"
        else:
            print(result)
            response = "synced"

    except subprocess.CalledProcessError as e:
        logger.error("Exception: {}".format(e))
        logger.error("Exception: {}".format(e.output))
        response = "error"
        
    except Exception as e:
        ex_type, ex, tb = sys.exc_info()
        traceback.print_tb(tb)
        logger.error("Exception: {}".format(e))
        response = "error"
        
    return response

def convert_datetime_to_epoch(dateTime):
    epoch = datetime.datetime.utcfromtimestamp(0)
    return int((dateTime - epoch).total_seconds() * 1000.0)