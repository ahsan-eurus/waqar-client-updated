# Customer Data Ingestion - Billing (Lambda) 
`<env>-cc-onboard-aws-ingest-customer-billing-data` performs the data ingestion of billing to `<env>-cc-data-tenants`. 
 
This lambda performs the following steps: 
 
- Fetch the customer's information from the `<env>-cc-onboard-aws-customerid` dynamoDB table 
- Ingest the customer's billing information based on *billingBucketName* and *billingBucketPath* (provided on adding the account) 
- After successfuly ingesting the data from customer's bucket, a log is added to the `<env>-cc-onboard-aws-customer-data-ingestion-operation-logs`

# Customer Data Ingestion - CloudTrail (Lambda) 
`<env>-cc-onboard-aws-ingest-customer-cloudtrail-data` performs the data ingestion of cloudtrail to `<env>-cc-data-tenants`. 
 
This lambda performs the following steps: 
 
- Fetch the customer's information from the `<env>-cc-onboard-aws-customerid` dynamoDB table 
- Ingest the customer's cloud trail information based on *cloudTrailBucketName* and *cloudTrailBucketPath* (provided on adding the account) 
- After successfuly ingesting the data from customer's bucket, a log is added to the `<env>-cc-onboard-aws-customer-data-ingestion-operation-logs`

# Customer Data Ingestion - Config (Lambda) 
`<env>-cc-onboard-aws-ingest-customer-config-data` performs the data ingestion of config to `<env>-cc-data-tenants`. 
 
This lambda performs the following steps: 
 
- Fetch the customer's information from the `<env>-cc-onboard-aws-customerid` dynamoDB table 
- Ingest the customer's config information based on *configBucketName* and *configBucketPath* (provided on adding the account) 
- After successfuly ingesting the data from customer's bucket, a log is added to the `<env>-cc-onboard-aws-customer-data-ingestion-operation-logs`

# Customer Data Ingestion - GuardDuty (Lambda) 
`<env>-cc-onboard-aws-ingest-customer-guardduty-data` performs the data ingestion of GuardDuty to `<env>-cc-data-tenants`. 
 
This lambda performs the following steps: 
 
- Fetch the customer's information from the `<env>-cc-onboard-aws-customerid` dynamoDB table 
- Ingest the customer's GuardDuty information based on *guardDutyBucketName* and *guardDutyBucketPath* (provided on adding the account) 
- After successfuly ingesting the data from customer's bucket, a log is added to the `<env>-cc-onboard-aws-customer-data-ingestion-operation-logs`

Note: If the GuardDuty data's is encrypted on the customer's bucket, make sure that the assumableRole (in the customer environment) must have permission for the `KMS', by which the GuardDuty is encrypting the data.

# Customer Data Ingestion - CloudWatch-Logs (Lambda) 
`<env>-cc-onboard-aws-ingest-customer-cloudwatch-logs-data` performs the data ingestion of CloudWatch-Logs to `<env>-cc-data-tenants`. 
 
This lambda performs the following steps: 
 
- Fetch the customer's information cloudwatch's regions from the `<env>-cc-onboard-aws-customerid` dynamoDB table 
- Ingest the customer's CloudWatch logs based on *cloudWatchRegions*
- After successfuly ingesting the data from customer's cloudwatchLogs, a log is added to the `<env>-cc-onboard-aws-customer-data-ingestion-operation-logs`

# Customer Data Ingestion - Organization (Lambda) 
`<env>-cc-onboard-aws-ingest-customer-organization-data` performs the data ingestion of Organization Information to `<env>-cc-data-tenants`. 

This lambda performs the following steps: 

- Fetch the customer's information from the `<env>-cc-onboard-aws-customerid` dynamoDB table 
- Fetch the customer's organization information using API
- Upload the customer's organization information in json format to s3
- After successfuly ingesting the data from customer's organization, a log is added to the `<env>-cc-onboard-aws-customer-data-ingestion-operation-logs`

# Customer Data Ingestion - SecurityHub Information (Lambda) 
`<env>-cc-onboard-aws-ingest-customer-securityhub-data` performs the data ingestion of security hub information to `<env>-cc-data-tenants`. 

This lambda performs the following steps: 

- Fetch the customer's information from the `<env>-cc-onboard-aws-customerid` dynamoDB table 
- Fetch the customer's security hub information using API
- Upload the customer's security hub information in json format to s3
- After successfuly ingesting the data from customer's security hub, a log is added to the `<env>-cc-onboard-aws-customer-data-ingestion-operation-logs`