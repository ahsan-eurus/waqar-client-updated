# AWS IAM Role - CloudFormation
This stack deployes the IAM Role with some given resources(Organizations, SecurityHub, GuardDuty, Billing, CloudTrail, CloudWatch, Config, S3 policies, Trusted Account relationship and ExternalID association.

### Following are the parameters that are required to complete the process:
- Origin Account ID
- Email Address
- External ID
- Role Access Type

If any bucket name is provided, access of that bucket will be granted using policy.

- Billing Bucket
- CloudTrail Bucket
- Config Bucket
- GuardDuty Bucket

IAM role will be tagged with the `key: managedby` and `value: ${Email Address}` provided in the parameter and AssumeRolePolicy will be created against `External ID`