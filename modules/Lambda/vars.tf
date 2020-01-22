variable "DYNAMO_DB_ONBOARDING_TABLE_NAME" {}
variable "DYNAMO_DB_CUSTOMER_TABLE_NAME" {}
variable "RESOURCE_PREFIX" {}
variable "ONBOARDING_BUCKET_NAME" {}

variable "IAM_ASSUMABLE_ROLE_NAME" {}
variable "LAMBDA_ROLE_ARN" {}
variable "LAMBDA_OPERATION_LOG_TABLE_NAME" {}
variable "AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME" {} 

variable "BILLING_MAX_PREVIOUS_MONTH_TO_SYNC" {}
variable "CLOUDTRAIL_MAX_PREVIOUS_DAYS_TO_SYNC" {}
variable "CONFIG_MAX_PREVIOUS_DAYS_TO_SYNC" {}
variable "GUARDDUTY_MAX_PREVIOUS_DAYS_TO_SYNC" {}
variable "CLOUDWATCH_LOGS_MAX_PREVIOUS_DAYS_TO_SYNC" {}

variable "ORGANIZATION_MAX_RESULTS_PER_REQUEST" {}
variable "SECURITYHUB_MAX_RESULTS_PER_REQUEST" {}