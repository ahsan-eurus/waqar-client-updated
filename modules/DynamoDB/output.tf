output "DYNAMO_DB_ONBOARDING_TABLE_NAME" {
  value = "${aws_dynamodb_table.dynamo-table.name}"
}