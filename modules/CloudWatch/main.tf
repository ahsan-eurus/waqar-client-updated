## Ingest Customer Billing Data ###

resource "aws_cloudwatch_event_rule" "trigger_ingest_customer_billing_data" {
    name = "${var.RESOURCE_PREFIX}-ingest-customer-billing-data"
    description = "Fires ${var.RESOURCE_PREFIX}-ingest-customer-billing-data"
    schedule_expression = "${var.INGEST_CUSTOMER_BILLING_DATA_TRIGGER_FREQUENCY}"
}

resource "aws_cloudwatch_event_target" "target_ingest_customer_billing_data" {
    rule = "${aws_cloudwatch_event_rule.trigger_ingest_customer_billing_data.name}"
    target_id = "${var.LAMBDA_INGEST_CUSTOMER_BILLING_DATA_NAME}"
    arn = "${var.LAMBDA_INGEST_CUSTOMER_BILLING_DATA_ARN}"
}

resource "aws_lambda_permission" "ingest_customer_billing_data_permission" {
    statement_id = "ingest-customer-billing-data"
    action = "lambda:InvokeFunction"
    function_name = "${var.LAMBDA_INGEST_CUSTOMER_BILLING_DATA_NAME}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.trigger_ingest_customer_billing_data.arn}"
}

## Ingest Customer CloudTrail Data ###

resource "aws_cloudwatch_event_rule" "trigger_ingest_customer_cloudtrail_data" {
    name = "${var.RESOURCE_PREFIX}-ingest-customer-cloudtrail-data"
    description = "Fires ${var.RESOURCE_PREFIX}-ingest-customer-cloudtrail-data"
    schedule_expression = "${var.INGEST_CUSTOMER_CLOUDTRAIL_DATA_TRIGGER_FREQUENCY}"
}

resource "aws_cloudwatch_event_target" "target_ingest_customer_cloudtrail_data" {
    rule = "${aws_cloudwatch_event_rule.trigger_ingest_customer_cloudtrail_data.name}"
    target_id = "${var.LAMBDA_INGEST_CUSTOMER_CLOUDTRAIL_DATA_NAME}"
    arn = "${var.LAMBDA_INGEST_CUSTOMER_CLOUDTRAIL_DATA_ARN}"
}

resource "aws_lambda_permission" "ingest_customer_cloudtrail_data_permission" {
    statement_id = "ingest-customer-cloudtrail-data"
    action = "lambda:InvokeFunction"
    function_name = "${var.LAMBDA_INGEST_CUSTOMER_CLOUDTRAIL_DATA_NAME}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.trigger_ingest_customer_cloudtrail_data.arn}"
}

## Ingest Customer Config Data ###

resource "aws_cloudwatch_event_rule" "trigger_ingest_customer_config_data" {
    name = "${var.RESOURCE_PREFIX}-ingest-customer-config-data"
    description = "Fires ${var.RESOURCE_PREFIX}-ingest-customer-config-data"
    schedule_expression = "${var.INGEST_CUSTOMER_CONFIG_DATA_TRIGGER_FREQUENCY}"
}

resource "aws_cloudwatch_event_target" "target_ingest_customer_config_data" {
    rule = "${aws_cloudwatch_event_rule.trigger_ingest_customer_config_data.name}"
    target_id = "${var.LAMBDA_INGEST_CUSTOMER_CONFIG_DATA_NAME}"
    arn = "${var.LAMBDA_INGEST_CUSTOMER_CONFIG_DATA_ARN}"
}

resource "aws_lambda_permission" "ingest_customer_config_data_permission" {
    statement_id = "ingest-customer-config-data"
    action = "lambda:InvokeFunction"
    function_name = "${var.LAMBDA_INGEST_CUSTOMER_CONFIG_DATA_NAME}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.trigger_ingest_customer_config_data.arn}"
}

## Ingest Customer GuardDuty Data ###

resource "aws_cloudwatch_event_rule" "trigger_ingest_customer_guardduty_data" {
    name = "${var.RESOURCE_PREFIX}-ingest-customer-guardduty-data"
    description = "Fires ${var.RESOURCE_PREFIX}-ingest-customer-guardduty-data"
    schedule_expression = "${var.INGEST_CUSTOMER_GUARDDUTY_DATA_TRIGGER_FREQUENCY}"
}

resource "aws_cloudwatch_event_target" "target_ingest_customer_guardduty_data" {
    rule = "${aws_cloudwatch_event_rule.trigger_ingest_customer_guardduty_data.name}"
    target_id = "${var.LAMBDA_INGEST_CUSTOMER_GUARDDUTY_DATA_NAME}"
    arn = "${var.LAMBDA_INGEST_CUSTOMER_GUARDDUTY_DATA_ARN}"
}

resource "aws_lambda_permission" "ingest_customer_guardduty_data_permission" {
    statement_id = "ingest-customer-guardduty-data"
    action = "lambda:InvokeFunction"
    function_name = "${var.LAMBDA_INGEST_CUSTOMER_GUARDDUTY_DATA_NAME}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.trigger_ingest_customer_guardduty_data.arn}"
}

## Ingest Customer CloudWatchLogs Data ###

resource "aws_cloudwatch_event_rule" "trigger_ingest_customer_cloudwatch_logs_data" {
    name = "${var.RESOURCE_PREFIX}-ingest-customer-cloudwatch-logs-data"
    description = "Fires ${var.RESOURCE_PREFIX}-ingest-customer-cloudwatch-logs-data"
    schedule_expression = "${var.INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_TRIGGER_FREQUENCY}"
}

resource "aws_cloudwatch_event_target" "target_ingest_customer_cloudwatch_logs_data" {
    rule = "${aws_cloudwatch_event_rule.trigger_ingest_customer_cloudwatch_logs_data.name}"
    target_id = "${var.LAMBDA_INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_NAME}"
    arn = "${var.LAMBDA_INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_ARN}"
}

resource "aws_lambda_permission" "ingest_customer_cloudwatch_logs_data_permission" {
    statement_id = "ingest-customer-cloudwatch-logs-data"
    action = "lambda:InvokeFunction"
    function_name = "${var.LAMBDA_INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_NAME}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.trigger_ingest_customer_cloudwatch_logs_data.arn}"
}

## Ingest Customer Organization Data ###

resource "aws_cloudwatch_event_rule" "trigger_ingest_customer_organization_data" {
    name = "${var.RESOURCE_PREFIX}-ingest-customer-organization-data"
    description = "Fires ${var.RESOURCE_PREFIX}-ingest-customer-organization-data"
    schedule_expression = "${var.INGEST_CUSTOMER_ORGANIZATION_DATA_TRIGGER_FREQUENCY}"
}

resource "aws_cloudwatch_event_target" "target_ingest_customer_organization_data" {
    rule = "${aws_cloudwatch_event_rule.trigger_ingest_customer_organization_data.name}"
    target_id = "${var.LAMBDA_INGEST_CUSTOMER_ORGANIZATION_DATA_NAME}"
    arn = "${var.LAMBDA_INGEST_CUSTOMER_ORGANIZATION_DATA_ARN}"
}

resource "aws_lambda_permission" "ingest_customer_organization_data_permission" {
    statement_id = "ingest-customer-organization-data"
    action = "lambda:InvokeFunction"
    function_name = "${var.LAMBDA_INGEST_CUSTOMER_ORGANIZATION_DATA_NAME}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.trigger_ingest_customer_organization_data.arn}"
}

## Ingest Customer Security Hub Data ###

resource "aws_cloudwatch_event_rule" "trigger_ingest_customer_securityhub_data" {
    name = "${var.RESOURCE_PREFIX}-ingest-customer-securityhub-data"
    description = "Fires ${var.RESOURCE_PREFIX}-ingest-customer-securityhub-data"
    schedule_expression = "${var.INGEST_CUSTOMER_SECURITYHUB_DATA_TRIGGER_FREQUENCY}"
}

resource "aws_cloudwatch_event_target" "target_ingest_customer_securityhub_data" {
    rule = "${aws_cloudwatch_event_rule.trigger_ingest_customer_securityhub_data.name}"
    target_id = "${var.LAMBDA_INGEST_CUSTOMER_SECURITYHUB_DATA_NAME}"
    arn = "${var.LAMBDA_INGEST_CUSTOMER_SECURITYHUB_DATA_ARN}"
}

resource "aws_lambda_permission" "ingest_customer_securityhub_data_permission" {
    statement_id = "ingest-customer-securityhub-data"
    action = "lambda:InvokeFunction"
    function_name = "${var.LAMBDA_INGEST_CUSTOMER_SECURITYHUB_DATA_NAME}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.trigger_ingest_customer_securityhub_data.arn}"
}