resource "aws_lambda_function" "lambda_list_customer_accounts_function" {
  filename         = "${path.module}/code/zip/list-customer-accounts.zip"
  function_name    = "${var.RESOURCE_PREFIX}-list-customer-accounts"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "list-customer-accounts.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_list_customer_accounts_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
    }
  }
}

resource "aws_lambda_function" "lambda_update_customer_master_accounts_function" {
  filename         = "${path.module}/code/zip/update-customer-master-accounts.zip"
  function_name    = "${var.RESOURCE_PREFIX}-update-customer-master-accounts"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "update-customer-master-accounts.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_update_customer_master_accounts_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
    }
  }
}

resource "aws_lambda_function" "lambda_create_customer_account_function" {
  filename         = "${path.module}/code/zip/create-customer-account.zip"
  function_name    = "${var.RESOURCE_PREFIX}-create-customer-account"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "create-customer-account.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_create_customer_account_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      customerTableName = "${var.DYNAMO_DB_CUSTOMER_TABLE_NAME}"
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
    }
  }
}

resource "aws_lambda_function" "lambda_get_customer_by_id_function" {
  filename         = "${path.module}/code/zip/get-customer-by-id.zip"
  function_name    = "${var.RESOURCE_PREFIX}-get-customer-by-id"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "get-customer-by-id.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_get_customer_by_id_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
    }
  }
}

resource "aws_lambda_layer_version" "aws_cli_layer" {
  filename   = "${path.module}/layers/awscli.zip"
  layer_name = "aws_cli_layer"
  compatible_runtimes = ["python2.7"]
}

resource "aws_lambda_layer_version" "aws_policy_layer" {
  filename   = "${path.module}/layers/awspolicy.zip"
  layer_name = "aws_cli_layer"
  compatible_runtimes = ["python2.7", "python3.6", "python3.7", "python3.8"]
}

resource "aws_lambda_function" "lambda_ingest_customer_data_sync_function" {
  filename         = "${path.module}/code/zip/ingest-customer-data-sync.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-data-sync"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-data-sync.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_data_sync_archive.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
      customer_data_ingestion_tb = "${var.LAMBDA_OPERATION_LOG_TABLE_NAME}"
    }
  }
  layers = ["${aws_lambda_layer_version.aws_cli_layer.arn}"]
}

resource "aws_lambda_function" "lambda_ingest_customer_billing_data_function" {
  filename         = "${path.module}/code/zip/ingest-customer-billing-data.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-billing-data"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-billing-data.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_billing_data_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
      lambdaOperationLogsTableName = "${var.LAMBDA_OPERATION_LOG_TABLE_NAME}"
      lambdaSyncBucketFunctionName = "${aws_lambda_function.lambda_ingest_customer_data_sync_function.function_name}"
      maxPreviousMonthToCopy = "${var.BILLING_MAX_PREVIOUS_MONTH_TO_SYNC}"
      dataIngestionDestinationBucketName = "${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
    }
  }
  depends_on = ["aws_lambda_function.lambda_ingest_customer_data_sync_function"]
}


resource "aws_lambda_function" "lambda_ingest_customer_cloudtrail_data_function" {
  filename         = "${path.module}/code/zip/ingest-customer-cloudtrail-data.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-cloudtrail-data"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-cloudtrail-data.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_cloudtrail_data_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
      lambdaOperationLogsTableName = "${var.LAMBDA_OPERATION_LOG_TABLE_NAME}"
      lambdaSyncBucketFunctionName = "${aws_lambda_function.lambda_ingest_customer_data_sync_function.function_name}"
      maxPreviousDaysToCopy = "${var.CLOUDTRAIL_MAX_PREVIOUS_DAYS_TO_SYNC}"
      dataIngestionDestinationBucketName = "${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
    }
  }
  depends_on = ["aws_lambda_function.lambda_ingest_customer_data_sync_function"]
}

resource "aws_lambda_function" "lambda_ingest_customer_config_data_function" {
  filename         = "${path.module}/code/zip/ingest-customer-config-data.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-config-data"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-config-data.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_config_data_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
      lambdaOperationLogsTableName = "${var.LAMBDA_OPERATION_LOG_TABLE_NAME}"
      lambdaSyncBucketFunctionName = "${aws_lambda_function.lambda_ingest_customer_data_sync_function.function_name}"
      maxPreviousDaysToCopy = "${var.CONFIG_MAX_PREVIOUS_DAYS_TO_SYNC}"
      dataIngestionDestinationBucketName = "${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
    }
  }
  depends_on = ["aws_lambda_function.lambda_ingest_customer_data_sync_function"]
}

resource "aws_lambda_function" "lambda_ingest_customer_guardduty_data_function" {
  filename         = "${path.module}/code/zip/ingest-customer-guardduty-data.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-guardduty-data"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-guardduty-data.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_guardduty_data_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
      lambdaOperationLogsTableName = "${var.LAMBDA_OPERATION_LOG_TABLE_NAME}"
      lambdaSyncBucketFunctionName = "${aws_lambda_function.lambda_ingest_customer_data_sync_function.function_name}"
      maxPreviousDaysToCopy = "${var.GUARDDUTY_MAX_PREVIOUS_DAYS_TO_SYNC}"
      dataIngestionDestinationBucketName = "${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
    }
  }
  depends_on = ["aws_lambda_function.lambda_ingest_customer_data_sync_function"]
}

resource "aws_lambda_function" "lambda_ingest_customer_cloudwatch_logs_data_sync_function" {
  filename         = "${path.module}/code/zip/ingest-customer-cloudwatch-logs-data-sync.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-cloudwatch-logs-data-sync"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-cloudwatch-logs-data-sync.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_cloudwatch_logs_data_sync_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
      lambdaOperationLogsTableName = "${var.LAMBDA_OPERATION_LOG_TABLE_NAME}"
      maxPreviousDaysToCopy = "${var.CLOUDWATCH_LOGS_MAX_PREVIOUS_DAYS_TO_SYNC}"
      }
  }
}

resource "aws_lambda_function" "lambda_ingest_customer_cloudwatch_logs_data_function" {
  filename         = "${path.module}/code/zip/ingest-customer-cloudwatch-logs-data.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-cloudwatch-logs-data"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-cloudwatch-logs-data.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_cloudwatch_logs_data_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
      destinationBucketName = "${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      lambdaCopyDataFunctionName = "${aws_lambda_function.lambda_ingest_customer_cloudwatch_logs_data_sync_function.function_name}"
    }
  }
  depends_on = ["aws_lambda_function.lambda_ingest_customer_cloudwatch_logs_data_sync_function"]
}

resource "aws_lambda_function" "lambda_ingest_customer_organization_data_sync_function" {
  filename         = "${path.module}/code/zip/ingest-customer-organization-data-sync.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-organization-data-sync"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-organization-data-sync.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_organization_data_sync_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
      dataIngestionDestinationBucketName = "${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
      maxResultsPerRequest = "${var.ORGANIZATION_MAX_RESULTS_PER_REQUEST}"
      customer_data_ingestion_tb = "${var.LAMBDA_OPERATION_LOG_TABLE_NAME}"
    }
  }
}

resource "aws_lambda_function" "lambda_ingest_customer_organization_data_function" {
  filename         = "${path.module}/code/zip/ingest-customer-organization-data.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-organization-data"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-organization-data.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_organization_data_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      lambdaCustomerOrganizationDataIngestionFunctionName = "${aws_lambda_function.lambda_ingest_customer_organization_data_sync_function.function_name}"
    }
  }
  depends_on = ["aws_lambda_function.lambda_ingest_customer_organization_data_sync_function"]
}

resource "aws_lambda_function" "lambda_ingest_customer_securityhub_data_sync_function" {
  filename         = "${path.module}/code/zip/ingest-customer-securityhub-data-sync.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-securityhub-data-sync"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-securityhub-data-sync.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_securityhub_data_sync_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
      dataIngestionDestinationBucketName = "${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
      maxResultsPerRequest = "${var.SECURITYHUB_MAX_RESULTS_PER_REQUEST}"
      customer_data_ingestion_tb = "${var.LAMBDA_OPERATION_LOG_TABLE_NAME}"
    }
  }
}

resource "aws_lambda_function" "lambda_ingest_customer_securityhub_data_function" {
  filename         = "${path.module}/code/zip/ingest-customer-securityhub-data.zip"
  function_name    = "${var.RESOURCE_PREFIX}-ingest-customer-securityhub-data"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "ingest-customer-securityhub-data.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_ingest_customer_securityhub_data_archive.output_base64sha256}"
  runtime          = "python3.8"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      lambdaCopyDataFunctionName = "${aws_lambda_function.lambda_ingest_customer_securityhub_data_sync_function.function_name}"
    }
  }
  depends_on = ["aws_lambda_function.lambda_ingest_customer_securityhub_data_sync_function"]
}

resource "aws_lambda_function" "lambda_whitelist_customer_accounts_function" {
  filename         = "${path.module}/code/zip/whitelist-customer-accounts.zip"
  function_name    = "${var.RESOURCE_PREFIX}-whitelist-customer-accounts"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "whitelist-customer-accounts.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_whitelist_customer_accounts_archive.output_base64sha256}"
  runtime          = "python3.7"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      bucketName = "${var.ONBOARDING_BUCKET_NAME}"
      updateCustomerMasterAccountLambda = "${aws_lambda_function.lambda_update_customer_master_accounts_function.function_name}"
      ingestionBucketName = "${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
    }
  }
  layers = ["${aws_lambda_layer_version.aws_policy_layer.arn}"]
}

resource "aws_lambda_function" "lambda_whitelist_customer_cc_role_function" {
  filename         = "${path.module}/code/zip/whitelist-customer-cc-role.zip"
  function_name    = "${var.RESOURCE_PREFIX}-whitelist-customer-cc-role"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "whitelist-customer-cc-role.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_whitelist_customer_cc_role_archive.output_base64sha256}"
  runtime          = "python3.7"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      bucketName = "${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
    }
  }
  layers = ["${aws_lambda_layer_version.aws_policy_layer.arn}"]
}

resource "aws_lambda_function" "lambda_verify_customer_cc_role_function" {
  filename         = "${path.module}/code/zip/verify-customer-cc-role.zip"
  function_name    = "${var.RESOURCE_PREFIX}-verify-customer-cc-role"
  role             = "${var.LAMBDA_ROLE_ARN}"
  handler          = "verify-customer-cc-role.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_verify_customer_cc_role_archive.output_base64sha256}"
  runtime          = "python3.7"
  timeout          = "900" 
  environment {
    variables = {
      onBoardingTableName = "${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}"
      assumableRoleName = "${var.IAM_ASSUMABLE_ROLE_NAME}"
      whitelistCustomerCCRoleLambda = "${aws_lambda_function.lambda_whitelist_customer_cc_role_function.function_name}"
    }
  }
}