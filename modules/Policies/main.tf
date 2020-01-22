resource "aws_iam_policy" "lambda_role_policy" {
  name = "${var.RESOURCE_PREFIX}-lambda"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:UpdateItem",
        "dynamodb:CreateTable",
        "dynamodb:UpdateTable",
        "dynamodb:GetRecords",
        "dynamodb:Scan"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:dynamodb:*:${var.CURRENT_ACCOUNT_ID}:table/${var.DYNAMO_DB_ONBOARDING_TABLE_NAME}",
        "arn:aws:dynamodb:*:${var.CURRENT_ACCOUNT_ID}:table/${var.DYNAMO_DB_CUSTOMER_TABLE_NAME}",
        "arn:aws:dynamodb:*:${var.CURRENT_ACCOUNT_ID}:table/${var.DYNAMO_DB_LAMBDA_OPERATION_LOGS_TABLE_NAME}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": [
        "arn:aws:lambda:*:${var.CURRENT_ACCOUNT_ID}:function:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": [
        "arn:aws:logs:*:${var.CURRENT_ACCOUNT_ID}:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole",
        "sts:GetFederationToken"
      ],
      "Resource": "arn:aws:iam::*:role/${var.IAM_ASSUMABLE_ROLE_NAME}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetSessionToken",
        "sts:DecodeAuthorizationMessage",
        "sts:GetAccessKeyInfo",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}",
        "arn:aws:s3:::${var.AWS_DATA_INGESTION_DESTINATION_BUCKET_NAME}/*",
        "arn:aws:s3:::${var.ONBOARDING_BUCKET_NAME}",
        "arn:aws:s3:::${var.ONBOARDING_BUCKET_NAME}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy-role-attachment" {
  role       = "${var.LAMBDA_ROLE_NAME}"
  policy_arn = "${aws_iam_policy.lambda_role_policy.arn}"
}