This is a Lambda that allows us to do end-to-end testing of Archivematica.

When you run this Lambda, it creates a new transfer package and uploads it to the S3 bucket.
This simulates the behaviour of an archivist, so it should be picked up by our Archivematica workflow.

All packages created by this workflow are stored in a special `testing` space in the storage service, so they won't be confused with real content.

This Lambda is automatically deployed with the latest code when you run Terraform in `stack_staging` or `stack_prod`.
