# Authentication with Azure AD

Our Archivematica instance relies on Azure AD for user authentication.

## How login looks for the user

Here's how the login flow works:

1.  A user goes to log in to Archivematica, and clicks the button that takes them to Azure AD:

    ![](../../images/sso\_login\_screen.png)

    (Note: this screen is one of the changes in our Archivematica fork. We deliberately emphasise SSO over the username/password login.)
2.  This sends the user to the standard Wellcome AD login screen:

    ![](../../images/wellcome\_ad\_login.png)

    The user logs in with their standard Wellcome username/password.
3. The user gets redirected back to Archivematica, where they're now able to access the Archivematica dashboard.

## How login works under the hood (roughly)

1. A user goes to log in to Archivematica, and clicks the button that takes them to Azure AD.
2. The user logs in to Azure AD with their standard username/password.
3.  If the login is successful, Azure AD sends a message to Archivematica telling it who this user is, e.g.

    > This user is a.chan@wellcome.org.

    Azure AD will allow any user to "log in" to Archivematica this way. It doesn't enforce any permissions.
4.  Archivematica looks to see if it has a user with that email address. If so, it allows them to access the dashboard. If not, it rejects their login.

    This is how we control access to Archivematica -- only staff with a user configured in Archivematica will get past this step.
