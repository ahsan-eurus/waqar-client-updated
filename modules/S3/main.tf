resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.RESOURCE_PREFIX}"
  acl    = "private"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "WhiteListedCustomersAccountIds",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${var.CURRENT_ACCOUNT_ID}"
        ]
      },
      "Action": [
        "s3:List*",
        "s3:GetObject"
       ],
      "Resource": [
        "arn:aws:s3:::${var.RESOURCE_PREFIX}/aws-iam-role-cfn",
        "arn:aws:s3:::${var.RESOURCE_PREFIX}/aws-iam-role-cfn/*"
      ]
    }
  ]
}
EOF
}

resource "aws_s3_bucket_object" "aws-iam-role-cfn" {
  for_each = "${fileset("${path.module}/s3-content/aws-iam-role-cfn", "*")}"

  bucket = "${aws_s3_bucket.s3_bucket.bucket}"
  key    = "aws-iam-role-cfn/${each.value}"
  source = "${path.module}/s3-content/aws-iam-role-cfn/${each.value}"
  etag    = "${path.module}/s3-content/aws-iam-role-cfn/${each.value}"
}