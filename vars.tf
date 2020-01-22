variable "IAM_ASSUMABLE_ROLE_NAME" {
    default = "cecurecloud-ro"
}
variable "ENV" {
    default = "ah"
}
variable "DEPLOY_ROLE" {}
variable "BILLING_MAX_PREVIOUS_MONTH_TO_SYNC" {
    default = "6" 
}
variable "INGEST_CUSTOMER_BILLING_DATA_TRIGGER_FREQUENCY" {
  default = "rate(12 hours)"
}
variable "CLOUDTRAIL_MAX_PREVIOUS_DAYS_TO_SYNC" {
  default= "2"
}
variable "INGEST_CUSTOMER_CLOUDTRAIL_DATA_TRIGGER_FREQUENCY" {
  default = "rate(12 hours)"
}
variable "CONFIG_MAX_PREVIOUS_DAYS_TO_SYNC" {
  default= "2"
}
variable "INGEST_CUSTOMER_CONFIG_DATA_TRIGGER_FREQUENCY" {
  default = "rate(12 hours)"
}
variable "GUARDDUTY_MAX_PREVIOUS_DAYS_TO_SYNC" {
  default= "2"
}
variable "INGEST_CUSTOMER_GUARDDUTY_DATA_TRIGGER_FREQUENCY" {
  default = "rate(12 hours)"
}
variable "CLOUDWATCH_LOGS_MAX_PREVIOUS_DAYS_TO_SYNC" {
  default = "2"
}
variable "INGEST_CUSTOMER_CLOUDWATCH_LOGS_DATA_TRIGGER_FREQUENCY" {
  default = "rate(1 hour)"
}
variable "ORGANIZATION_MAX_RESULTS_PER_REQUEST" {
  default = "20"
}
variable "INGEST_CUSTOMER_ORGANIZATION_DATA_TRIGGER_FREQUENCY" {
  default = "rate(12 hours)"
}
variable "INGEST_CUSTOMER_SECURITYHUB_DATA_TRIGGER_FREQUENCY" {
  default = "rate(12 hours)"
}
variable "SECURITYHUB_MAX_RESULTS_PER_REQUEST" {
  default = "20"
}