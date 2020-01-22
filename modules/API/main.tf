resource "aws_api_gateway_rest_api" "api-gateway" {
  name        = "${var.RESOURCE_PREFIX}"
  description = "API to create and list customer account(s) for boarding purposes."
}

resource "aws_api_gateway_deployment" "api-gateway-deployment" {
  depends_on = [
    "aws_api_gateway_method.create_customer_account_method",
    "aws_api_gateway_integration.create_customer_account_integration",
    "aws_api_gateway_method.list_customer_accounts_method",
    "aws_api_gateway_integration.list_customer_accounts_integration",
    "aws_api_gateway_method.get_customer_by_id_method",
    "aws_api_gateway_integration.get_customer_by_id_integration",
    "aws_api_gateway_method.options_root_method",
    "aws_api_gateway_integration.options_root_integration",
    "aws_api_gateway_method.options_cuid_method",
    "aws_api_gateway_integration.options_cuid_integration",
    "aws_api_gateway_method.options_verify_customer_cc_role_cuid_method",
    "aws_api_gateway_integration.options_verify_customer_cc_role_cuid_integration",
    "aws_api_gateway_method.verify_customer_cc_role_method",
    "aws_api_gateway_integration.verify_customer_cc_role_integration",
    "aws_api_gateway_method.options_whitelist_customer_accounts_cuid_method",
    "aws_api_gateway_integration.options_whitelist_customer_accounts_cuid_integration",
    "aws_api_gateway_method.whitelist_customer_accounts_method",
    "aws_api_gateway_integration.whitelist_customer_accounts_integration",
  ]
  rest_api_id       = "${aws_api_gateway_rest_api.api-gateway.id}"
  stage_name        = "${lower(var.ENV)}"
  stage_description = "1.0"
  description       = "1.0"
  
  variables = {
    "deployed_at" = "${timestamp()}"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_resource" "cuid_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  parent_id   = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  path_part   = "{cuid}"
}

resource "aws_api_gateway_resource" "whitelist_customer_accounts_cuid_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  parent_id   = "${aws_api_gateway_resource.cuid_resource.id}"
  path_part   = "whitelist-account"
}

resource "aws_api_gateway_resource" "verify_customer_cc_role_cuid_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  parent_id   = "${aws_api_gateway_resource.cuid_resource.id}"
  path_part   = "verify-cc-role"
}

resource "aws_api_gateway_base_path_mapping" "api-gateway-base-path-mapping" {
  api_id      = "${aws_api_gateway_rest_api.api-gateway.id}"
  stage_name  = "${aws_api_gateway_deployment.api-gateway-deployment.stage_name}"
  domain_name = "api.${lower(var.ENV)}.cecurecloud.com"
  base_path = "onboard-aws"
}

### Option Method For Root ###

resource "aws_api_gateway_method" "options_root_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id   = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_root_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id             = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method             = "${aws_api_gateway_method.options_root_method.http_method}"
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_method_response" "options_root_method_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method = "${aws_api_gateway_method.options_root_method.http_method}"
  status_code = "200"
  response_parameters = "${local.method_response_parameters}"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    "aws_api_gateway_method.options_root_method",
  ]
}

resource "aws_api_gateway_integration_response" "options_root_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method = "${aws_api_gateway_method_response.options_root_method_response_200.http_method}"
  status_code = "${aws_api_gateway_method_response.options_root_method_response_200.status_code}"

  response_parameters = "${local.integration_response_parameters}"

  depends_on = [
    "aws_api_gateway_integration.options_root_integration",
    "aws_api_gateway_method_response.options_root_method_response_200",
  ]
}

### Option Method For /{{CUID}} ###

resource "aws_api_gateway_method" "options_cuid_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.cuid_resource.id}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_cuid_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.cuid_resource.id}"
  http_method             = "${aws_api_gateway_method.options_cuid_method.http_method}"
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_method_response" "options_cuid_method_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.cuid_resource.id}"
  http_method = "${aws_api_gateway_method.options_cuid_method.http_method}"
  status_code = "200"
  response_parameters = "${local.method_response_parameters}"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    "aws_api_gateway_method.options_cuid_method",
  ]
}

resource "aws_api_gateway_integration_response" "options_cuid_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.cuid_resource.id}"
  http_method = "${aws_api_gateway_method_response.options_cuid_method_response_200.http_method}"
  status_code = "${aws_api_gateway_method_response.options_cuid_method_response_200.status_code}"

  response_parameters = "${local.integration_response_parameters}"

  depends_on = [
    "aws_api_gateway_integration.options_cuid_integration",
    "aws_api_gateway_method_response.options_cuid_method_response_200",
  ]
}

### Option Method For {{CUID}}/verify-cc-role ###

resource "aws_api_gateway_method" "options_verify_customer_cc_role_cuid_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.verify_customer_cc_role_cuid_resource.id}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_verify_customer_cc_role_cuid_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.verify_customer_cc_role_cuid_resource.id}"
  http_method             = "${aws_api_gateway_method.options_verify_customer_cc_role_cuid_method.http_method}"
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_method_response" "options_verify_customer_cc_role_cuid_method_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.verify_customer_cc_role_cuid_resource.id}"
  http_method = "${aws_api_gateway_method.options_verify_customer_cc_role_cuid_method.http_method}"
  status_code = "200"
  response_parameters = "${local.method_response_parameters}"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    "aws_api_gateway_method.options_verify_customer_cc_role_cuid_method",
  ]
}

resource "aws_api_gateway_integration_response" "options_verify_customer_cc_role_cuid_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.verify_customer_cc_role_cuid_resource.id}"
  http_method = "${aws_api_gateway_method_response.options_verify_customer_cc_role_cuid_method_response_200.http_method}"
  status_code = "${aws_api_gateway_method_response.options_verify_customer_cc_role_cuid_method_response_200.status_code}"

  response_parameters = "${local.integration_response_parameters}"

  depends_on = [
    "aws_api_gateway_integration.options_verify_customer_cc_role_cuid_integration",
    "aws_api_gateway_method_response.options_verify_customer_cc_role_cuid_method_response_200",
  ]
}

### Option Method For {{CUID}}/whitelist-account ###

resource "aws_api_gateway_method" "options_whitelist_customer_accounts_cuid_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.whitelist_customer_accounts_cuid_resource.id}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_whitelist_customer_accounts_cuid_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.whitelist_customer_accounts_cuid_resource.id}"
  http_method             = "${aws_api_gateway_method.options_whitelist_customer_accounts_cuid_method.http_method}"
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_method_response" "options_whitelist_customer_accounts_cuid_method_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.whitelist_customer_accounts_cuid_resource.id}"
  http_method = "${aws_api_gateway_method.options_whitelist_customer_accounts_cuid_method.http_method}"
  status_code = "200"
  response_parameters = "${local.method_response_parameters}"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    "aws_api_gateway_method.options_whitelist_customer_accounts_cuid_method",
  ]
}

resource "aws_api_gateway_integration_response" "options_whitelist_customer_accounts_cuid_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.whitelist_customer_accounts_cuid_resource.id}"
  http_method = "${aws_api_gateway_method_response.options_whitelist_customer_accounts_cuid_method_response_200.http_method}"
  status_code = "${aws_api_gateway_method_response.options_whitelist_customer_accounts_cuid_method_response_200.status_code}"

  response_parameters = "${local.integration_response_parameters}"

  depends_on = [
    "aws_api_gateway_integration.options_whitelist_customer_accounts_cuid_integration",
    "aws_api_gateway_method_response.options_whitelist_customer_accounts_cuid_method_response_200",
  ]
}

## Create Customer Account Method ###

resource "aws_api_gateway_method" "create_customer_account_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id   = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_customer_account_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id             = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method             = "${aws_api_gateway_method.create_customer_account_method.http_method}"
  type                    = "AWS"
  uri                     = "${var.LAMBDA_CREATE_CUSTOMER_ACCOUNT_INVOKE_ARN}"
  integration_http_method = "POST"
}

resource "aws_api_gateway_method_response" "create_customer_account_method_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method = "${aws_api_gateway_method.create_customer_account_method.http_method}"
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_lambda_permission" "create_customer_account_permission" {
  function_name = "${var.LAMBDA_CREATE_CUSTOMER_ACCOUNT_NAME}"
  statement_id  = "create-customer-account"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api-gateway.execution_arn}/*/*"
}

resource "aws_api_gateway_integration_response" "create_customer_account_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method = "${aws_api_gateway_method_response.create_customer_account_method_response_200.http_method}"
  status_code = "${aws_api_gateway_method_response.create_customer_account_method_response_200.status_code}"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = ["aws_api_gateway_integration.create_customer_account_integration"]
}

### List Customer Accounts Method ###

resource "aws_api_gateway_method" "list_customer_accounts_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id   = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "list_customer_accounts_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id             = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method             = "${aws_api_gateway_method.list_customer_accounts_method.http_method}"
  type                    = "AWS"
  uri                     = "${var.LAMBDA_LIST_CUSTOMER_ACCOUNTS_INVOKE_ARN}"
  integration_http_method = "POST"
}

resource "aws_api_gateway_method_response" "list_customer_accounts_method_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method = "${aws_api_gateway_method.list_customer_accounts_method.http_method}"
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_lambda_permission" "list_customer_accounts_permission" {
  function_name = "${var.LAMBDA_LIST_CUSTOMER_ACCOUNTS_NAME}"
  statement_id  = "list-customer-accounts"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api-gateway.execution_arn}/*/*"
}

resource "aws_api_gateway_integration_response" "list_customer_accounts_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_rest_api.api-gateway.root_resource_id}"
  http_method = "${aws_api_gateway_method_response.list_customer_accounts_method_response_200.http_method}"
  status_code = "${aws_api_gateway_method_response.list_customer_accounts_method_response_200.status_code}"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = ["aws_api_gateway_integration.list_customer_accounts_integration"]
}


### Get Customer By CUID Method ###

resource "aws_api_gateway_method" "get_customer_by_id_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id   = "${aws_api_gateway_resource.cuid_resource.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_customer_by_id_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id             = "${aws_api_gateway_resource.cuid_resource.id}"
  http_method             = "${aws_api_gateway_method.get_customer_by_id_method.http_method}"
  type                    = "AWS"
  uri                     = "${var.LAMBDA_GET_CUSTOMER_BY_ID_INVOKE_ARN}"
  integration_http_method = "POST"
  request_templates = {
    "application/json" = <<EOF
{
"cuid": "$input.params('cuid')"
}
  EOF
  }
}

resource "aws_api_gateway_method_response" "get_customer_by_id_method_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.cuid_resource.id}"
  http_method = "${aws_api_gateway_method.get_customer_by_id_method.http_method}"
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_lambda_permission" "get_customer_by_id_permission" {
  function_name = "${var.LAMBDA_GET_CUSTOMER_BY_ID_NAME}"
  statement_id  = "get-customer-by-id"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api-gateway.execution_arn}/*/*"
}

resource "aws_api_gateway_integration_response" "get_customer_by_id_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.cuid_resource.id}"
  http_method = "${aws_api_gateway_method_response.get_customer_by_id_method_response_200.http_method}"
  status_code = "${aws_api_gateway_method_response.get_customer_by_id_method_response_200.status_code}"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {  
    "application/json" = ""
  }

  depends_on = ["aws_api_gateway_integration.get_customer_by_id_integration"]
}


### Verify Customer CC Role ###

resource "aws_api_gateway_method" "verify_customer_cc_role_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id   = "${aws_api_gateway_resource.verify_customer_cc_role_cuid_resource.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "verify_customer_cc_role_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id             = "${aws_api_gateway_resource.verify_customer_cc_role_cuid_resource.id}"
  http_method             = "${aws_api_gateway_method.verify_customer_cc_role_method.http_method}"
  type                    = "AWS"
  uri                     = "${var.LAMBDA_VERIFY_CUSTOMER_CC_ROLE_INVOKE_ARN}"
  integration_http_method = "POST"
  request_templates = {
    "application/json" = <<EOF
{
"cuid": "$input.params('cuid')"
}
  EOF
  }
}

resource "aws_api_gateway_method_response" "verify_customer_cc_role_method_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.verify_customer_cc_role_cuid_resource.id}"
  http_method = "${aws_api_gateway_method.verify_customer_cc_role_method.http_method}"
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_lambda_permission" "verify_customer_cc_role_permission" {
  function_name = "${var.LAMBDA_VERIFY_CUSTOMER_CC_ROLE_NAME}"
  statement_id  = "verify-customer-cc-role"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api-gateway.execution_arn}/*/*"
}

resource "aws_api_gateway_integration_response" "verify_customer_cc_role_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.verify_customer_cc_role_cuid_resource.id}"
  http_method = "${aws_api_gateway_method_response.verify_customer_cc_role_method_response_200.http_method}"
  status_code = "${aws_api_gateway_method_response.verify_customer_cc_role_method_response_200.status_code}"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {  
    "application/json" = ""
  }

  depends_on = ["aws_api_gateway_integration.verify_customer_cc_role_integration"]
}

### Whitelist Customer Account ###

resource "aws_api_gateway_method" "whitelist_customer_accounts_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id   = "${aws_api_gateway_resource.whitelist_customer_accounts_cuid_resource.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "whitelist_customer_accounts_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id             = "${aws_api_gateway_resource.whitelist_customer_accounts_cuid_resource.id}"
  http_method             = "${aws_api_gateway_method.whitelist_customer_accounts_method.http_method}"
  type                    = "AWS"
  uri                     = "${var.LAMBDA_WHITELIST_CUSTOMER_ACCOUNTS_INVOKE_ARN}"
  integration_http_method = "POST"
  request_templates = {
    "application/json" = <<EOF
{
"cuid": "$input.params('cuid')"
}
  EOF
  }
}

resource "aws_api_gateway_method_response" "whitelist_customer_accounts_method_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.whitelist_customer_accounts_cuid_resource.id}"
  http_method = "${aws_api_gateway_method.whitelist_customer_accounts_method.http_method}"
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_lambda_permission" "whitelist_customer_accounts_permission" {
  function_name = "${var.LAMBDA_WHITELIST_CUSTOMER_ACCOUNTS_NAME}"
  statement_id  = "whitelist-customer-accounts"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api-gateway.execution_arn}/*/*"
}

resource "aws_api_gateway_integration_response" "whitelist_customer_accounts_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway.id}"
  resource_id = "${aws_api_gateway_resource.whitelist_customer_accounts_cuid_resource.id}"
  http_method = "${aws_api_gateway_method_response.whitelist_customer_accounts_method_response_200.http_method}"
  status_code = "${aws_api_gateway_method_response.whitelist_customer_accounts_method_response_200.status_code}"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {  
    "application/json" = ""
  }

  depends_on = ["aws_api_gateway_integration.whitelist_customer_accounts_integration"]
}