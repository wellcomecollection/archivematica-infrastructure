# 401 Unauthorized when the s3\_start\_transfer Lambda tries to run

## 401 Unauthorized when the s3\_start\_transfer Lambda tries to run <a href="#401_lambda" id="401_lambda"></a>

We have an s3\_start\_transfer Lambda which is meant to notice uploads to the transfer source bucket, and trigger a new transfer process in Archivematica. If that's not working, and you see this in the CloudWatch logs:

> Response: \<Response \[401]>

it might be a sign that the Lambda has bad credentials for the Archivematica API. These are kept in Parameter Store, then injected into the Lambda by Terraform (see `transfer_lambda.tf`).

Verify the credentials are correct, or create and store new API keys as necessary.
