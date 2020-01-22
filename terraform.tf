# terraform {  
#   backend "s3" {  
#     encrypt        = true  
#     bucket         = "westmyra-terraform-remote-state-centralised"  
#     dynamodb_table = "westmyra-terraform-locks-centralised"  
#     region         = "us-east-1"  
#     key            = "westmyra-onboard-aws/{{ENV}}/terraform.tfstate"  
#     kms_key_id     = "arn:aws:kms:us-east-1:596648398627:key/f7227aad-3138-47ea-8e67-f4d688fac960"  
#   }  
# }