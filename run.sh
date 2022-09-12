#!/bin/sh -v

# -----------------------------------------------------------------
# Configure the AWS CLI to let it communicate with your account
# -----------------------------------------------------------------
aws configure set aws_access_key_id $ACCESS_KEY_ID
aws configure set aws_secret_access_key $SECRET_ACCESS_KEY
aws configure set region us-east-1

# -----------------------------------------------------------------
# Create a unique S3 Bucket. The name of S3 bucket is derived from the access key. So it has to be unique
# -----------------------------------------------------------------
bucket=`echo $ACCESS_KEY_ID | tr '[:upper:]' '[:lower:]'`
aws s3 mb s3://educative.${bucket} --region us-east-1


# -----------------------------------------------------------------
# Delete any old deployments
# -----------------------------------------------------------------
# 1. Trigger CloudFormation stack delete
# 2. Wait for the stack to be deleted 
aws cloudformation delete-stack --stack-name  EducativeCourseApiGateway
aws cloudformation wait stack-delete-complete --stack-name EducativeCourseApiGateway


# -----------------------------------------------------------------
# External API, no Lambda function. Initiate the CloudFormation deployment.
# -----------------------------------------------------------------
aws cloudformation deploy \
    --template-file template.yml \
    --stack-name EducativeCourseApiGateway \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides DeployId="$RAND" SourceCodeBucket="educative.${bucket}" \
    --region us-east-1

# -----------------------------------------------------------------
# Get the API ID of the Rest API we just created.
# -----------------------------------------------------------------
apiId=`aws cloudformation list-stack-resources --stack-name EducativeCourseApiGateway | jq -r ".StackResourceSummaries[2].PhysicalResourceId"`
echo "API ID: $apiId"

# -----------------------------------------------------------------
# This is the URL for the API we just created
# -----------------------------------------------------------------
url="https://${apiId}.execute-api.us-east-1.amazonaws.com/v1/educative.${bucket}/test.txt"
echo $url

# -----------------------------------------------------------------
# Invoke the URL to test the response
# -----------------------------------------------------------------

# 1. Save text content to the S3 Bucket 
curl --location --request PUT $url --data-raw 'Hello World'

# 2. Retrieve the text from S3 Bucket
curl --location --request GET $url 


