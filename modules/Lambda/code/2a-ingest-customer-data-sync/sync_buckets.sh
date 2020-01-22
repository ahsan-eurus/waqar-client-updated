#!/bin/bash

ACCOUNT_ID="${1}"
ROLE_NAME="${2}"
SOURCE_BUCKET="${3}"
SOURCE_BUCKET_PREFIX="${4}"
DESTINATION_BUCKET="${5}"
DESTINATION_BUCKET_PREFIX="${6}"
EXTERNAL_ID="${7}"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

CMD="aws sts assume-role --role-arn '$ROLE_ARN' --role-session-name 'AWSCLI-Session' --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text"

if [ ! -z "$EXTERNAL_ID" ]
then
    CMD="${CMD} --external-id '$EXTERNAL_ID'"
fi

sts=( $( eval $CMD) )

AWS_ACCESS_KEY_ID=${sts[0]}
AWS_SECRET_ACCESS_KEY=${sts[1]}
AWS_SESSION_TOKEN=${sts[2]}

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN

unset AWS_SECURITY_TOKEN

aws s3 sync s3://${SOURCE_BUCKET}/${SOURCE_BUCKET_PREFIX} s3://${DESTINATION_BUCKET}/${DESTINATION_BUCKET_PREFIX} --acl bucket-owner-full-control