# 401 Unauthorized when the s3\_start\_transfer Lambda tries to run

We have an s3\_start\_transfer Lambda which is meant to notice uploads to the transfer source bucket, and trigger a new transfer process in Archivematica. If that's not working, you may see this in the CloudWatch logs:

> urllib.error.HTTPError: HTTP Error 401: Unauthorized

This may mean that the Lambda has a bad username or API key for the Archivematica dashboard or Storage Service.
The failing URL identifies which application rejected the request.
The credentials are kept in Parameter Store, then injected into the Lambda by Terraform (see [lambda_s3_start_transfer.tf](https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/modules/stack/lambda_s3_start_transfer.tf)).

Verify the relevant credentials, or create and store a new API key as necessary.
