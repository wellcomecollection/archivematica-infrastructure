# Azure Active Directory login

Users can authenticate to Archivematica using Single Sign-On with their Wellcome accounts.

## How it works

We have an application in the Azure Wellcome Cloud (["Wellcome Collection Archivematica"](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/8dccdaeb-e67e-417f-bebc-7aab4abade28/isMSAApp/)).

When a user tries to log in to Archivematica, they are redirected to a Azure Active Directory login screen.
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

1.  Become an owner on the Azure AD app.
    (As of 15 October 2020, @alexwlchan and @kenoir are both owners.)

2.  Install the Azure CLI and the boto3 Python library.

3.  Run the script in this folder:

    ```console
    $ python3 create_azure_client_secret.py
    ```

    This will:

    *   Prompt you to log in to Azure through the browser
    *   Create a new client secret in Azure which expires in a year's time
    *   Save that secret in Secrets Manager
    *   Redeploy our ECS services, so they pick up the newest secret

4.  Verify your secrets were created correctly using the Azure portal.

    ![](azure_portal.png)

We do **not** use Terraform for managing the client secret because the secret would be stored unencrypted in the Terraform state.
Using the script, the unencrypted secret is created inside the script, written directly to the secret stores, then discarded.
