# Authentication with Azure AD

Our Archivematica instance relies on Azure AD for user authentication.

## How dashboard login looks for the user

Here's how the login flow works:

1.  A user goes to log in to Archivematica, and clicks the button that takes them to Azure AD:

    ![](../../images/sso\_login\_screen.png)

    (Note: this screen is one of the changes in our Archivematica fork. We deliberately emphasise SSO over the username/password login.)
2.  This sends the user to the standard Wellcome AD login screen:

    ![](../../images/wellcome\_ad\_login.png)

    The user logs in with their standard Wellcome username/password.
3. The user gets redirected back to Archivematica, where they're now able to access the Archivematica dashboard.

## How dashboard login works under the hood (roughly)

1. A user goes to log in to Archivematica, and clicks the button that takes them to Azure AD.
2. The user logs in to Azure AD with their standard username/password.
3.  If the login is successful, Azure AD sends a message to Archivematica telling it who this user is, e.g.

    > This user's `upn` is their Azure AD sign-in identity.

    Azure AD authenticates the identity, but the local Archivematica account controls access to the application.
    The dashboard is configured to prefer the access-token `upn` value as the user's email address and fall back to the ID-token `email` value when `upn` is absent.
4.  The dashboard looks for a user whose email address matches that value without regard to case. If it finds one, it allows them to access the application. If not, it rejects their login.

    This is how we control access to the dashboard -- only staff with a user configured in its user database will get past this step.

## How Storage Service login identifies a user

The Storage Service uses the `email` value in the Azure AD ID token and looks for a local user with a matching email address without regard to case.
It has a separate user database from the dashboard and does not create an account automatically.
