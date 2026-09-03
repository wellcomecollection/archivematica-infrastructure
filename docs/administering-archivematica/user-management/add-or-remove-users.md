# How to add or remove users

We use Azure Active Directory (OpenID Connect) for authentication. When somebody tries to log in to Archivematica, they are sent to an Active Directory login page first. Once you're logged in with AD, you have access to Archivematica if and only if you have been authorised by an Archivematica admin.

The Archivematica dashboard and the Archivematica Storage Service have separate user databases, and accounts are not synchronised between them.
Staging and production also have separate databases, so provision and remove accounts independently in every application and environment the person needs to use.

## Dashboard accounts

To give somebody access to the Archivematica dashboard:

1. Log in to the dashboard as an admin.
2. Select **Administration** from the top menu bar.
3. In the sidebar, click **Users**.
4.  Click **Add New**.

    This screenshot shows the dashboard user-management screen:

    ![Screenshot of the Archivematica user management screen, with green arrows highlighting key areas](../../howto/user\_management.png)
5.  Fill in the new user form. Two fields need particular care:

    * The email address must match the person's Azure AD sign-in identity. The dashboard prefers the access-token `upn` value and compares email addresses without regard to case, so confirm the sign-in identity rather than assuming which Wellcome email domain it uses. The username is local and is not used for the OIDC lookup.
    *   Set a long random password because the local username/password login remains available, even though the person will normally use Azure AD. If you want to generate a password and you're comfortable on the command line, try running:

        ```
        python3 -c 'import secrets; print("Aa1!" + secrets.token_hex(28))'
        ```

    Click **Create** when you're done.

To remove dashboard access, delete the matching account from the dashboard in each environment the person can use.

## Storage Service accounts

When OIDC is enabled, the Storage Service disables user editing and does not show the **Add New** or delete actions in its administration interface.
The application includes management commands for creating users, but this repository does not define the approved role, API key, provisioning, or offboarding procedure for routine human accounts.
Ask a developer to provision or remove the account using an agreed management procedure rather than trying to follow the dashboard steps.
The Storage Service matches the email from the Azure AD ID token without regard to case, so that value must match the local account.
