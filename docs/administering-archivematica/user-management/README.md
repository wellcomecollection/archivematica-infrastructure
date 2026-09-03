# User management

We use OpenID Connect with Azure AD to authenticate users in Archivematica. Access and roles are managed with local application accounts.

Terraform configures OpenID Connect login for both the Archivematica dashboard and the Archivematica Storage Service.
The applications have separate user databases and automatic account creation is disabled, so a matching account is needed in each application and environment the person uses.

See [How to add or remove users](add-or-remove-users.md) for account management and [Authentication with Azure AD](authentication.md) for an explanation of the login flow.
