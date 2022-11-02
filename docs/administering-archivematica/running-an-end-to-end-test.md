# Running an end-to-end test

You can send a test transfer package to Archivematica using the test\_transfer Lambda package.

1. Log in to the AWS console
2. Select the workflow-developer role (account ID `299497370133`, role name `workflow-developer`)
3. Go to the list of functions in the Lambda console
4. Find the **start\_test\_transfer** function. If you want to test staging, look for **archivematica-start\_test\_transfer-staging**. If you want to test prod, look for **archivematica-start\_test\_transfer-prod**.
5. Open the right function, then select the **Test** tab. Click the **Test** button to run the Lambda.

This should upload a new package called **test\_package** to the Archivematica transfer source bucket, triggering a new transfer that you can follow in the Archivematica dashboard.
