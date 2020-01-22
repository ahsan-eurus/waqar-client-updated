resource "aws_dynamodb_table" "dynamo-table" {
  name           = "${var.RESOURCE_PREFIX}-customerid"
  billing_mode   = "PAY_PER_REQUEST"
  read_capacity  = 0
  write_capacity = 0
  hash_key       = "cuid"

  attribute {
    name = "cuid"
    type = "S"
  }
}

resource "aws_dynamodb_table" "lambda-operation-logs-table" {
  name           = "${var.DYNAMO_DB_LAMBDA_OPERATION_LOGS_TABLE_NAME}"
  billing_mode   = "PAY_PER_REQUEST"
  read_capacity  = 0
  write_capacity = 0
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}