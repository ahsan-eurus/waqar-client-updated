locals {
  common_tags = {
    environment     = "${lower(var.ENV)}"
    project         = "cc-012-onboard-core - cecurecloud-onboard-aws"
    managedby       = "westmyra-cc-aws-mgmt@westmyra.com"
  }
}