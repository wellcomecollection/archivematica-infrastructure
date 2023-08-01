# transfer_monitor

This Lambda monitors the "transfer source" S3 bucket, and does two things:

*   It posts a message to Slack telling us about transfers, including both successes and failures

*   It cleans up leftover files from successful transfers, so the transfer bucket doesn't fill up with files which are duplicated in the storage service

It's triggered on a schedule.

It uses the tags written by the [s3_start_transfer Lambda](../s3_start_transfer) to match package in the transfer bucket to bags in the storage service.



## Testing the Lambda locally

You can test the Lambda by running it locally with the `run_lambda.sh` script, for example:

```
bash run_lambda.sh prod
```



## Deployment

This Lambda is automatically deployed with the latest version whenever you apply Terraform in `stack_staging` or `stack_prod`.
