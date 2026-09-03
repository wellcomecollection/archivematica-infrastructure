# Azure Active Directory login

Users can authenticate to Archivematica using Single Sign-On with their Wellcome accounts.

## How it works

We have an application in the Azure Wellcome Cloud (["Wellcome Collection Archivematica"](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/8dccdaeb-e67e-417f-bebc-7aab4abade28/isMSAApp/)).

When a user tries to log in to Archivematica, they are redirected to an Azure Active Directory login screen.
This screen says something like _"Do you want to log in to Wellcome Collection Archivematica?_ and asks for their AD username/password.
Once they're logged in, they get redirected back to Archivematica.



## Creating cross-account secrets

Archivematica needs three values to use Azure AD for login:

*   The **tenant ID** is a UUID that identifies our instance of Active Directory.

*   The **client ID** identifies the application inside Active Directory.

*   The **client secret** identifies the application *to* Active Directory.
    This is how Azure knows to show the _"Do you want to log in to Wellcome Collection Archivematica?_ screen.

The tenant ID and client ID are fixed; the client secret can be changed.

To create a new secret:

1.  Confirm that you are an owner of the Azure AD app.
    If you are not an owner, ask one of the current application owners to grant access or run the rotation.

2.  Install the Azure CLI and the boto3 Python library.
    Obtain AWS credentials which can assume `arn:aws:iam::299497370133:role/workflow-developer`; the script sends all AWS requests to `eu-west-1`.

3.  Run the script in this folder:

    ```console
    $ aws sso login --profile weco
    $ env AWS_PROFILE=weco python3 create_azure_client_secret.py
    ```

    Use a different AWS profile if that is how your access to the workflow account is configured.

    This will:

    *   Prompt you to log in to Azure through the browser
    *   Create separate staging and production client secrets in Azure which expire in a year's time
    *   Save both secrets in Secrets Manager in the workflow account
    *   Redeploy the dashboard and Storage Service in both environments, so they pick up the newest secret

    Record the rotation ID and credential display name printed for each environment.
    The script includes the unique rotation ID in each credential's display name before creating it, so the credential can still be identified if a later operation fails.

    The script always changes both staging and production.
    Do not run it if you only intend to change one environment.
    It stops at the first failed Azure, Secrets Manager, or ECS operation and does not roll back steps which have already completed.
    It verifies that it can assume the workflow AWS role before it creates either Azure credential.
    If it fails later, use the last completed status message to identify the affected environment, resolve the error, and run the script again.
    Running it again may append another Azure credential, but the previous credentials remain valid until they are removed explicitly.
    Azure does not reveal an existing client secret value, so do not try to recover or copy the value from the portal.

4.  Use the Azure portal to verify that the new `weco/staging/ROTATION_ID` and `weco/prod/ROTATION_ID` credentials have the expected expiry dates.
    Match their display names to the script output and record their key IDs for later cleanup.
    This confirms the credential metadata, but it does not confirm that Azure and Secrets Manager contain matching secret values.

5.  Wait for the dashboard and Storage Service deployments triggered by the final successful script run to complete in both environments.
    Confirm in ECS that each service has its expected task count from the new deployment and that all tasks from previous deployments have stopped.
    Then use a fresh browser session to verify Azure AD login to both applications in staging and production.
    Keep the previous Azure credentials until both environments have been checked successfully.

6.  After these deployment and login checks have succeeded for both applications in both environments, remove the credentials superseded by this rotation from the Azure application.
    Delete superseded credentials by key ID, and retain the staging and production credentials whose display names match the final successful script run.
    If the script was retried, use each run's unique display names to find the extra credentials from failed runs, then remove them by key ID only after the final credentials have been verified.

We do **not** use Terraform for managing the client secret because the secret would be stored unencrypted in the Terraform state.
Using the script, the unencrypted secret is created inside the script, written directly to the secret stores, then discarded.
