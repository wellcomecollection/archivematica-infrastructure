# transfer_monitor

This Lambda runs once a week and examines objects from the last 14 days in the "transfer source" S3 bucket.
It only considers objects which have the Transfer ID tag written by the [s3_start_transfer Lambda](../s3_start_transfer).
It does two things:

*   It posts a message to Slack telling us which tagged packages have or have not been matched to a stored METS file

*   It cleans up leftover files from successful transfers, so the transfer bucket doesn't fill up with files which are duplicated in the storage service

A package reported as failed has no matching stored METS file at the time of the check, but Archivematica may still be processing it.
Objects without a Transfer ID tag are not included in the report.



## Testing the Lambda locally

You can test the Lambda by running it locally with the `run_lambda.sh` script, for example:

```
bash run_lambda.sh prod
```



## Deployment

This Lambda is automatically deployed with the latest version whenever you apply Terraform in `stack_staging` or `stack_prod`.
