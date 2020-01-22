variable "LAMBDA_CREATE_CUSTOMER_ACCOUNT_NAME" {}
variable "LAMBDA_LIST_CUSTOMER_ACCOUNTS_NAME" {}
variable "LAMBDA_GET_CUSTOMER_BY_ID_NAME" {}
variable "LAMBDA_WHITELIST_CUSTOMER_ACCOUNTS_NAME" {}
variable "LAMBDA_VERIFY_CUSTOMER_CC_ROLE_NAME" {}

variable "LAMBDA_LIST_CUSTOMER_ACCOUNTS_INVOKE_ARN" {}
variable "LAMBDA_CREATE_CUSTOMER_ACCOUNT_INVOKE_ARN" {}
variable "LAMBDA_GET_CUSTOMER_BY_ID_INVOKE_ARN" {}
variable "LAMBDA_WHITELIST_CUSTOMER_ACCOUNTS_INVOKE_ARN" {}
variable "LAMBDA_VERIFY_CUSTOMER_CC_ROLE_INVOKE_ARN" {}


variable "ENV" {}
variable "RESOURCE_PREFIX" {}


### For Option Method ###
variable "allow_headers" {
  description = "Allow headers"
  type        = "list"

  default = [
    "Authorization",
    "Content-Type",
    "X-Amz-Date",
    "X-Amz-Security-Token",
    "X-Api-Key",
    "X-Amz-User-Agent"
  ]
}

# var.allow_methods
variable "allow_methods" {
  description = "Allow methods"
  type        = "list"

  default = [
    "OPTIONS",
    "HEAD",
    "GET",
    "POST",
    "PUT",
    "PATCH",
    "DELETE",
  ]
}

# var.allow_origin
variable "allow_origin" {
  description = "Allow origin"
  type        = "string"
  default     = "*"
}

# var.allow_max_age
variable "allow_max_age" {
  description = "Allow response caching time"
  type        = "string"
  default     = "7200"
}

# var.allowed_credentials
variable "allow_credentials" {
  description = "Allow credentials"
  default     = true
}

##################