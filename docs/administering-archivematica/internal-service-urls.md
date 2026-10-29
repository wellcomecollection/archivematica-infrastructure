# Internal URLs between Archivematica and Storage Service

Archivematica and its Storage Service should use their private AWS Cloud Map names for calls to each other.
This avoids routing internal API requests through the public load balancers, NAT gateways, and public source-IP allowlist.
Browser access still uses the [public HTTPS endpoints](network-access.md).

These URLs follow the current Terraform service names and nginx configuration.
The application database settings must be checked separately: this guide does not establish that the running applications already use them.

## Internal endpoints

| Environment | Dashboard base URL | Storage Service base URL |
| --- | --- | --- |
| Staging | `http://am-staging-dashboard.archivematica-staging/` | `http://am-staging-storage-service.archivematica-staging/` |
| Production | `http://am-prod-dashboard.archivematica-prod/` | `http://am-prod-storage-service.archivematica-prod/` |

Cloud Map resolves these names to private ECS task addresses inside the VPC.
Use HTTP on port 80, which reaches the task's nginx container and is forwarded to the application on port 9000.
TLS terminates at the public load balancer; these private nginx listeners do not provide HTTPS.
The tasks share an interservice security group that permits this traffic.
Use DNS names rather than task IPs, which change when tasks are replaced.

The names come from [the private namespace](../../terraform/modules/stack/service_discovery.tf) and [the nginx service module](../../terraform/modules/stack/nginx_service/main.tf).
The internal proxy configuration is in [archivematica.conf](../../archivematica-apps/archivematica-nginx/etc/nginx/conf.d/archivematica.conf).

## Application settings to change

| Direction | Configuration | Value |
| --- | --- | --- |
| AM dashboard and MCP jobs → SS | Dashboard **Administration → General → Storage Service URL** (`storage_service_url`) | The environment's internal Storage Service base URL |
| SS → AM dashboard API | Storage Service **Pipelines → edit the existing pipeline → Remote name** (`Pipeline.remote_name`) | The environment's internal dashboard base URL |

Use the base URLs above without `/api/` or `/api/v2/`; the API clients append those paths.
Preserve the existing API usernames and keys, pipeline UUID, and location associations.
These settings are stored in the application databases, so changing Terraform or redeploying containers alone does not migrate them.
The AM client reads `storage_service_url` from `DashboardSetting`; the SS client reads `remote_name` from its pipeline record.

The dashboard's **Site URL** is a separate setting and should retain its public HTTPS URL.
During initial registration, AM copies that value into the new SS pipeline's `remote_name`, so update **Remote name** after registration.
Saving the dashboard settings does not update an already registered SS pipeline's URL.
The pinned [AM registration code](https://github.com/artefactual/archivematica/blob/aa2fc87f50ffffde4cc26728cf45c9c58bdb5238/src/archivematica/dashboard/installer/steps.py) returns without modifying an existing pipeline; the [SS API client](https://github.com/artefactual/archivematica-storage-service/blob/0332eed8c25707ccf48b2b3dfc5fae68db39ba27/src/archivematica/storage_service/locations/models/pipeline.py) uses its stored `remote_name`.
Do not rerun the installer or create a replacement pipeline to change these URLs.

Terraform currently sets `WELLCOME_SS_URL` to a Cloud Map address on port 8000 and `WELLCOME_SITE_URL` to localhost in [services.tf](../../terraform/modules/stack/services.tf).
Neither variable is consumed by the pinned AM source (`aa2fc87f50ffffde4cc26728cf45c9c58bdb5238`), and port 8000 does not match this deployment's listeners.
Do not use those variables as evidence of the live connection settings or copy their values into the application settings.
Removing these obsolete variables is a separate configuration cleanup.

## Migration and verification

1. Start in staging and record the existing URL values and pipeline UUID so they can be restored.
   Arrange a quiet period for the change, avoiding active transfers and storage operations.
2. From the dashboard and MCP task network, resolve the internal SS hostname and check its `/login/` endpoint on port 80.
   From the SS task network, resolve the internal dashboard hostname and check `/administration/accounts/login/` on port 80.
   Use the [container-host access instructions](../debugging-archivematica/ssh-into-container-hosts.md) to run checks inside the relevant containers.
   A connection from a laptop is not a substitute for these checks, since the names are private.
3. Save the internal SS URL in the dashboard, then edit the matching existing pipeline in SS to use the internal dashboard URL as its **Remote name**.
   Confirm the pipeline UUID matches the dashboard's `dashboard_uuid` setting.
4. Verify authenticated API access in both directions, not just the login pages.
   Check that the dashboard can retrieve its pipeline and locations from SS and that SS can retrieve a processing configuration from the dashboard API.
   If the dashboard's separate application API allowlist (`api_whitelist`) is populated, verify the address Django sees through nginx rather than assuming it is the SS task IP.
   This application check uses `REMOTE_ADDR`, is independent of the public ALB allowlist, and matches individual IPs rather than CIDRs.
5. Run the [end-to-end transfer check](running-an-end-to-end-test.md) and check any download or reingest workflows used by operators.
   Confirm that browser navigation and Azure AD login still use the public HTTPS hostnames.
   Repeat the change and checks in production after staging succeeds.

If verification fails, restore the recorded URL values in both applications and investigate DNS, task connectivity, and API authentication before retrying.

## Connections that remain public

Keep public HTTPS URLs for browser bookmarks, Azure AD redirect URIs, and the dashboard **Site URL**.
The Wellcome Storage Service space's **Callback host** is also separate from `Pipeline.remote_name`: it tells the external Wellcome Archival Storage service how to call back into Archivematica's Storage Service.
Keep that callback public unless private connectivity and DNS resolution from the callback sender have been established, and ensure its source egress addresses are allowed.

The `s3_start_transfer` Lambda currently uses public dashboard and SS URLs and exits through the allowlisted VPC NAT gateways.
Changing the two application database settings does not change that Lambda configuration.
Keep the automatic NAT gateway allowlist entries while these public API callers remain; switching the Lambda to Cloud Map would also require checking its security-group access to the private tasks.
