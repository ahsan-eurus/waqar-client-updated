output "LAMBDA_CREATE_CUSTOMER_ACCOUNT_NAME" {
  value = "${aws_lambda_function.lambda_create_customer_account_function.function_name}"
}
output "LAMBDA_LIST_CUSTOMER_ACCOUNTS_NAME" {
  value = "${aws_lambda_function.lambda_list_customer_accounts_function.function_name}"
}
output "LAMBDA_UPDATE_CUSTOMER_MASTER_ACCOUNTS_NAME" {
  value = "${aws_lambda_function.lambda_update_customer_master_accounts_function.function_name}"
}
output "LAMBDA_GET_CUSTOMER_BY_ID_NAME" {
  value = "${aws_lambda_function.lambda_get_customer_by_id_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_BILLING_DATA_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_billing_data_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_DATA_SYNC_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_data_sync_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_CLOUDTRAIL_DATA_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_cloudtrail_data_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_GUARDDUTY_DATA_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_guardduty_data_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_CONFIG_DATA_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_config_data_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_cloudwatch_logs_data_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_SYNC_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_cloudwatch_logs_data_sync_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_ORGANIZATION_DATA_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_organization_data_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_ORGANIZATION_DATA_SYNC_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_organization_data_sync_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_SECURITYHUB_DATA_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_securityhub_data_function.function_name}"
}
output "LAMBDA_INGEST_CUSTOMER_SECURITYHUB_DATA_SYNC_NAME" {
  value = "${aws_lambda_function.lambda_ingest_customer_securityhub_data_sync_function.function_name}"
}
output "LAMBDA_WHITELIST_CUSTOMER_ACCOUNTS_NAME" {
  value = "${aws_lambda_function.lambda_whitelist_customer_accounts_function.function_name}"
}
output "LAMBDA_WHITELIST_CUSTOMER_CC_ROLE_NAME" {
  value = "${aws_lambda_function.lambda_whitelist_customer_cc_role_function.function_name}"
}

output "LAMBDA_VERIFY_CUSTOMER_CC_ROLE_NAME" {
  value = "${aws_lambda_function.lambda_verify_customer_cc_role_function.function_name}"
}


output "LAMBDA_UPDATE_CUSTOMER_MASTER_ACCOUNTS_ARN" {
  value = "${aws_lambda_function.lambda_update_customer_master_accounts_function.arn}"
}
output "LAMBDA_CREATE_CUSTOMER_ACCOUNT_INVOKE_ARN" {
  value = "${aws_lambda_function.lambda_create_customer_account_function.invoke_arn}"
}
output "LAMBDA_LIST_CUSTOMER_ACCOUNTS_INVOKE_ARN" {
  value = "${aws_lambda_function.lambda_list_customer_accounts_function.invoke_arn}"
}
output "LAMBDA_GET_CUSTOMER_BY_ID_INVOKE_ARN" {
  value = "${aws_lambda_function.lambda_get_customer_by_id_function.invoke_arn}"
}
output "LAMBDA_INGEST_CUSTOMER_BILLING_DATA_ARN" {
  value = "${aws_lambda_function.lambda_ingest_customer_billing_data_function.arn}"
}
output "LAMBDA_INGEST_CUSTOMER_CLOUDTRAIL_DATA_ARN" {
  value = "${aws_lambda_function.lambda_ingest_customer_cloudtrail_data_function.arn}"
}
output "LAMBDA_INGEST_CUSTOMER_CONFIG_DATA_ARN" {
  value = "${aws_lambda_function.lambda_ingest_customer_config_data_function.arn}"
}
output "LAMBDA_INGEST_CUSTOMER_GUARDDUTY_DATA_ARN" {
  value = "${aws_lambda_function.lambda_ingest_customer_guardduty_data_function.arn}"
}
output "LAMBDA_INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_ARN" {
  value = "${aws_lambda_function.lambda_ingest_customer_cloudwatch_logs_data_function.arn}"
}
output "LAMBDA_INGEST_CUSTOMER_ORGANIZATION_DATA_ARN" {
  value = "${aws_lambda_function.lambda_ingest_customer_organization_data_function.arn}"
}
output "LAMBDA_INGEST_CUSTOMER_SECURITYHUB_DATA_ARN" {
  value = "${aws_lambda_function.lambda_ingest_customer_securityhub_data_function.arn}"
}
output "LAMBDA_WHITELIST_CUSTOMER_ACCOUNTS_INVOKE_ARN" {
  value = "${aws_lambda_function.lambda_whitelist_customer_accounts_function.invoke_arn}"
}
output "LAMBDA_WHITELIST_CUSTOMER_CC_ROLE_INVOKE_ARN" {
  value = "${aws_lambda_function.lambda_whitelist_customer_cc_role_function.invoke_arn}"
}
output "LAMBDA_VERIFY_CUSTOMER_CC_ROLE_INVOKE_ARN" {
  value = "${aws_lambda_function.lambda_verify_customer_cc_role_function.invoke_arn}"
}