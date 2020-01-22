data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  DYNAMO_DB_CUSTOMER_TABLE_NAME = "${lower(var.ENV)}-customerid"
  RESOURCE_PREFIX = "${lower(var.ENV)}-cc-onboard-aws"
  AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME = "${lower(var.ENV)}-cc-customer-aws-data"
  DYNAMO_DB_LAMBDA_OPERATION_LOGS_TABLE_NAME = "${lower(var.ENV)}-cc-onboard-aws-customer-data-ingestion-operation-logs"
}


module "S3" {
  source = "./modules/S3"

  CURRENT_ACCOUNT_ID = "${data.aws_caller_identity.current.account_id}"
  RESOURCE_PREFIX = "${local.RESOURCE_PREFIX}"
}

module "DynamoDB" {
  source = "./modules/DynamoDB"
  
  DYNAMO_DB_LAMBDA_OPERATION_LOGS_TABLE_NAME = "${local.DYNAMO_DB_LAMBDA_OPERATION_LOGS_TABLE_NAME}"
  RESOURCE_PREFIX = "${local.RESOURCE_PREFIX}"
}

module "Role" {
  source = "./modules/Role"

  RESOURCE_PREFIX = "${local.RESOURCE_PREFIX}"
}

module "Lambda" {
  source = "./modules/Lambda"
  
  DYNAMO_DB_ONBOARDING_TABLE_NAME = "${module.DynamoDB.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
  DYNAMO_DB_CUSTOMER_TABLE_NAME = "${local.DYNAMO_DB_CUSTOMER_TABLE_NAME}"
  ONBOARDING_BUCKET_NAME = "${module.S3.ONBOARDING_BUCKET_NAME}"

  LAMBDA_ROLE_ARN = "${module.Role.LAMBDA_ROLE_ARN}"
  RESOURCE_PREFIX = "${local.RESOURCE_PREFIX}"
  IAM_ASSUMABLE_ROLE_NAME = "${var.IAM_ASSUMABLE_ROLE_NAME}"
  LAMBDA_OPERATION_LOG_TABLE_NAME = "${local.DYNAMO_DB_LAMBDA_OPERATION_LOGS_TABLE_NAME}"
  AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME = "${local.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
  
  BILLING_MAX_PREVIOUS_MONTH_TO_SYNC = "${var.BILLING_MAX_PREVIOUS_MONTH_TO_SYNC}"
  CLOUDTRAIL_MAX_PREVIOUS_DAYS_TO_SYNC = "${var.CLOUDTRAIL_MAX_PREVIOUS_DAYS_TO_SYNC}"
  CONFIG_MAX_PREVIOUS_DAYS_TO_SYNC = "${var.CONFIG_MAX_PREVIOUS_DAYS_TO_SYNC}"
  GUARDDUTY_MAX_PREVIOUS_DAYS_TO_SYNC = "${var.GUARDDUTY_MAX_PREVIOUS_DAYS_TO_SYNC}"
  CLOUDWATCH_LOGS_MAX_PREVIOUS_DAYS_TO_SYNC = "${var.CLOUDWATCH_LOGS_MAX_PREVIOUS_DAYS_TO_SYNC}"
  
  ORGANIZATION_MAX_RESULTS_PER_REQUEST = "${var.ORGANIZATION_MAX_RESULTS_PER_REQUEST}"
  SECURITYHUB_MAX_RESULTS_PER_REQUEST = "${var.SECURITYHUB_MAX_RESULTS_PER_REQUEST}"
}

module "CloudWatch" {
  source = "./modules/CloudWatch"
  
  LAMBDA_INGEST_CUSTOMER_CLOUDTRAIL_DATA_NAME = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_CLOUDTRAIL_DATA_NAME}"
  LAMBDA_INGEST_CUSTOMER_BILLING_DATA_NAME = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_BILLING_DATA_NAME}"
  LAMBDA_INGEST_CUSTOMER_CONFIG_DATA_NAME = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_CONFIG_DATA_NAME}"
  LAMBDA_INGEST_CUSTOMER_GUARDDUTY_DATA_NAME = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_GUARDDUTY_DATA_NAME}"
  LAMBDA_INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_NAME = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_NAME}"
  LAMBDA_INGEST_CUSTOMER_ORGANIZATION_DATA_NAME = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_ORGANIZATION_DATA_NAME}"
  LAMBDA_INGEST_CUSTOMER_SECURITYHUB_DATA_NAME = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_SECURITYHUB_DATA_NAME}"

  INGEST_CUSTOMER_BILLING_DATA_TRIGGER_FREQUENCY = "${var.INGEST_CUSTOMER_BILLING_DATA_TRIGGER_FREQUENCY}"
  INGEST_CUSTOMER_CLOUDTRAIL_DATA_TRIGGER_FREQUENCY = "${var.INGEST_CUSTOMER_CLOUDTRAIL_DATA_TRIGGER_FREQUENCY}"
  INGEST_CUSTOMER_GUARDDUTY_DATA_TRIGGER_FREQUENCY = "${var.INGEST_CUSTOMER_GUARDDUTY_DATA_TRIGGER_FREQUENCY}"
  INGEST_CUSTOMER_CONFIG_DATA_TRIGGER_FREQUENCY = "${var.INGEST_CUSTOMER_CONFIG_DATA_TRIGGER_FREQUENCY}"  
  INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_TRIGGER_FREQUENCY = "${var.INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_TRIGGER_FREQUENCY}"
  INGEST_CUSTOMER_ORGANIZATION_DATA_TRIGGER_FREQUENCY = "${var.INGEST_CUSTOMER_ORGANIZATION_DATA_TRIGGER_FREQUENCY}"
  INGEST_CUSTOMER_SECURITYHUB_DATA_TRIGGER_FREQUENCY = "${var.INGEST_CUSTOMER_SECURITYHUB_DATA_TRIGGER_FREQUENCY}"

  LAMBDA_INGEST_CUSTOMER_BILLING_DATA_ARN = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_BILLING_DATA_ARN}"
  LAMBDA_INGEST_CUSTOMER_CLOUDTRAIL_DATA_ARN = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_CLOUDTRAIL_DATA_ARN}"
  LAMBDA_INGEST_CUSTOMER_CONFIG_DATA_ARN = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_CONFIG_DATA_ARN}"
  LAMBDA_INGEST_CUSTOMER_GUARDDUTY_DATA_ARN = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_GUARDDUTY_DATA_ARN}"
  LAMBDA_INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_ARN = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_ARN}"
  LAMBDA_INGEST_CUSTOMER_ORGANIZATION_DATA_ARN = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_ORGANIZATION_DATA_ARN}"
  LAMBDA_INGEST_CUSTOMER_SECURITYHUB_DATA_ARN = "${module.Lambda.LAMBDA_INGEST_CUSTOMER_SECURITYHUB_DATA_ARN}"

  RESOURCE_PREFIX = "${local.RESOURCE_PREFIX}"
}


# module "Policies" {
#   source = "./modules/Policies"
  
#   DYNAMO_DB_ONBOARDING_TABLE_NAME = "${module.DynamoDB.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
#   DYNAMO_DB_CUSTOMER_TABLE_NAME = "${local.DYNAMO_DB_CUSTOMER_TABLE_NAME}"
#   DYNAMO_DB_LAMBDA_OPERATION_LOGS_TABLE_NAME = "${local.DYNAMO_DB_LAMBDA_OPERATION_LOGS_TABLE_NAME}"
#   AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME ="${local.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
#   ONBOARDING_BUCKET_NAME = "${module.S3.ONBOARDING_BUCKET_NAME}"

#   RESOURCE_PREFIX = "${local.RESOURCE_PREFIX}"
#   LAMBDA_ROLE_NAME = "${module.Role.LAMBDA_ROLE_NAME}"
#   CURRENT_ACCOUNT_ID = "${data.aws_caller_identity.current.account_id}"
#   IAM_ASSUMABLE_ROLE_NAME = "${var.IAM_ASSUMABLE_ROLE_NAME}"
  
#   }

# module "API" {
#   source = "./modules/API"
  
#   LAMBDA_LIST_CUSTOMER_ACCOUNTS_NAME = "${module.Lambda.LAMBDA_LIST_CUSTOMER_ACCOUNTS_NAME}"
#   LAMBDA_LIST_CUSTOMER_ACCOUNTS_INVOKE_ARN = "${module.Lambda.LAMBDA_LIST_CUSTOMER_ACCOUNTS_INVOKE_ARN}"

#   LAMBDA_CREATE_CUSTOMER_ACCOUNT_NAME = "${module.Lambda.LAMBDA_CREATE_CUSTOMER_ACCOUNT_NAME}"
#   LAMBDA_CREATE_CUSTOMER_ACCOUNT_INVOKE_ARN = "${module.Lambda.LAMBDA_CREATE_CUSTOMER_ACCOUNT_INVOKE_ARN}"

#   LAMBDA_GET_CUSTOMER_BY_ID_NAME = "${module.Lambda.LAMBDA_GET_CUSTOMER_BY_ID_NAME}"
#   LAMBDA_GET_CUSTOMER_BY_ID_INVOKE_ARN = "${module.Lambda.LAMBDA_GET_CUSTOMER_BY_ID_INVOKE_ARN}"

#   LAMBDA_VERIFY_CUSTOMER_CC_ROLE_NAME = "${module.Lambda.LAMBDA_VERIFY_CUSTOMER_CC_ROLE_NAME}"
#   LAMBDA_VERIFY_CUSTOMER_CC_ROLE_INVOKE_ARN = "${module.Lambda.LAMBDA_VERIFY_CUSTOMER_CC_ROLE_INVOKE_ARN}"

#   LAMBDA_WHITELIST_CUSTOMER_ACCOUNTS_NAME = "${module.Lambda.LAMBDA_WHITELIST_CUSTOMER_ACCOUNTS_NAME}"
#   LAMBDA_WHITELIST_CUSTOMER_ACCOUNTS_INVOKE_ARN = "${module.Lambda.LAMBDA_WHITELIST_CUSTOMER_ACCOUNTS_INVOKE_ARN}"


#   RESOURCE_PREFIX = "${local.RESOURCE_PREFIX}"
#   ENV = "${var.ENV}"
# }

