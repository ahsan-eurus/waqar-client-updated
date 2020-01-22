data "archive_file" "lambda_create_customer_account_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/1a-create-customer-account"
  output_path = "${path.module}/code/zip/create-customer-account.zip"
}

data "archive_file" "lambda_list_customer_accounts_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/1b-list-customer-accounts"
  output_path = "${path.module}/code/zip/list-customer-accounts.zip"
}

data "archive_file" "lambda_update_customer_master_accounts_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/1c-update-customer-master-accounts"
  output_path = "${path.module}/code/zip/update-customer-master-accounts.zip"
}

data "archive_file" "lambda_get_customer_by_id_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/1d-get-customer-by-id"
  output_path = "${path.module}/code/zip/get-customer-by-id.zip"
}

data "archive_file" "lambda_ingest_customer_data_sync_archive" {
  type        = "zip"
  source_dir  = "${path.module}/code/2a-ingest-customer-data-sync"
  output_path = "${path.module}/code/zip/ingest-customer-data-sync.zip"
}

data "archive_file" "lambda_ingest_customer_billing_data_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/2b-ingest-customer-billing-data"
  output_path = "${path.module}/code/zip/ingest-customer-billing-data.zip"
}

data "archive_file" "lambda_ingest_customer_cloudtrail_data_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/2c-ingest-customer-cloudtrail-data"
  output_path = "${path.module}/code/zip/ingest-customer-cloudtrail-data.zip"
}

data "archive_file" "lambda_ingest_customer_config_data_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/2d-ingest-customer-config-data"
  output_path = "${path.module}/code/zip/ingest-customer-config-data.zip"
}

data "archive_file" "lambda_ingest_customer_guardduty_data_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/2e-ingest-customer-guardduty-data"
  output_path = "${path.module}/code/zip/ingest-customer-guardduty-data.zip"
}

data "archive_file" "lambda_ingest_customer_cloudwatch_logs_data_archive" {
  type        = "zip"
  source_file = "${path.module}/code/2f-ingest-customer-cloudwatch-logs-data/ingest-customer-cloudwatch-logs-data.py"
  output_path = "${path.module}/code/zip/ingest-customer-cloudwatch-logs-data.zip"
}

data "archive_file" "lambda_ingest_customer_cloudwatch_logs_data_sync_archive" {
  type        = "zip"
  source_file = "${path.module}/code/2f-ingest-customer-cloudwatch-logs-data/ingest-customer-cloudwatch-logs-data-sync.py"
  output_path = "${path.module}/code/zip/ingest-customer-cloudwatch-logs-data-sync.zip"
}

data "archive_file" "lambda_ingest_customer_organization_data_archive" {
  type        = "zip"
  source_file = "${path.module}/code/2g-ingest-customer-organization-data/ingest-customer-organization-data.py"
  output_path = "${path.module}/code/zip/ingest-customer-organization-data.zip"
}

data "archive_file" "lambda_ingest_customer_organization_data_sync_archive" {
  type        = "zip"
  source_file = "${path.module}/code/2g-ingest-customer-organization-data/ingest-customer-organization-data-sync.py"
  output_path = "${path.module}/code/zip/ingest-customer-organization-data-sync.zip"
}

data "archive_file" "lambda_ingest_customer_securityhub_data_archive" {
  type        = "zip"
  source_file = "${path.module}/code/2h-ingest-customer-securityhub-data/ingest-customer-securityhub-data.py"
  output_path = "${path.module}/code/zip/ingest-customer-securityhub-data.zip"
}

data "archive_file" "lambda_ingest_customer_securityhub_data_sync_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/2h-ingest-customer-securityhub-data"
  output_path = "${path.module}/code/zip/ingest-customer-securityhub-data-sync.zip"
}

data "archive_file" "lambda_whitelist_customer_accounts_archive" {
  type        = "zip"
  source_file = "${path.module}/code/3a-whitelist-customer-accounts/whitelist-customer-accounts.py"
  output_path = "${path.module}/code/zip/whitelist-customer-accounts.zip"
}

data "archive_file" "lambda_whitelist_customer_cc_role_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/3b-whitelist-customer-cc-role"
  output_path = "${path.module}/code/zip/whitelist-customer-cc-role.zip"
}

data "archive_file" "lambda_verify_customer_cc_role_archive" {
  type        = "zip"
  source_dir = "${path.module}/code/4a-verify-customer-cc-role"
  output_path = "${path.module}/code/zip/verify-customer-cc-role.zip"
}