# How to check a transfer package is stored

Go to <reporting.wellcomecollection.org>, and select "Login with your Wellcome account".
Log in with your usual Active Directory credentials.

![Web browser window "Welcome to Elastic" with three login options. The first is named "Login with your Wellcome account".](reporting.png)

Select the "Storage Service" space:

![Web browser window titled "Select your space" with a grid of six cards. In the lower-right is a card titled "Storage service" with a yellow box icon.](reporting_spaces.png)

Search for a bag with the same identifier (either catalogue reference or accession number) as your transfer package.
You may need to extend the time range with the calendar picker in the top right.

![A Kibana search dashboard for the query "PPMDM/A/3/1a"](reporting_search_result.png)

If you find a result with:

*   a matching `info.externalIdentifier` matches
*   a `createdDate` from after you uploaded your transfer package to S3

then your transfer package has been stored successfully.

If your transfer package doesn't appear within a day, then ask a developer to look at the Archivematica logs in the `#wc-preservation-feedback` channel in Slack.
