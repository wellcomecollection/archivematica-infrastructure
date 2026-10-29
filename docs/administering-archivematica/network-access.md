# Network access to Archivematica

The dashboard and Storage Service have public HTTPS endpoints, but their load balancers only forward application requests from allowed source IP addresses.
This applies to browsers and API clients in both environments.
Users still need the appropriate [application accounts] and authentication after passing the network allowlist.

| Environment | Service         | Hostname                                                     |
| ----------- | --------------- | ------------------------------------------------------------ |
| Staging     | Dashboard       | `archivematica-stage.wellcomecollection.org`                 |
| Staging     | Storage Service | `archivematica-storage-service-stage.wellcomecollection.org` |
| Production  | Dashboard       | `archivematica.wellcomecollection.org`                       |
| Production  | Storage Service | `archivematica-storage-service.wellcomecollection.org`       |

## Requesting access

Prefer a shared, managed VPN or a bastion/proxy with a stable public egress IP over individual home or mobile connection addresses.
The browser or API traffic must actually pass through that connection.
A bastion only helps if requests originate there or are proxied through it; connecting to a split-tunnel VPN may still send these requests through the user's normal internet connection.

Ask the infrastructure maintainers to add the connection's public egress IPv4 address or CIDR range.
Include the connection's owner, purpose, all possible egress addresses (including failover), and whether access is temporary.
For a single address, use a `/32` CIDR.
Do not supply a laptop's private address or the destination addresses returned by `dig` for Archivematica.

The allowlist is shared by staging and production.
Adding an address permits network access to all four endpoints; application permissions remain separate.

Calls between Archivematica and its Storage Service should use [private Cloud Map URLs](internal-service-urls.md).
Their application settings must be updated separately from this public allowlist.

## Updating the allowlist

Both stacks read the comma-separated CIDR list in AWS Systems Manager Parameter Store in the workflow account (`299497370133`), region `eu-west-1`, at `/archivematica/config/prod/alb_source_ips`.
The `prod` segment is intentional: [staging configuration] and [production configuration] use the same parameter.

1. Confirm the public egress addresses with the network administrator.
   Preserve existing entries and use the smallest ranges needed for the connection.
2. Update the parameter, using comma-separated CIDRs without spaces.
   Do not add `0.0.0.0/0`, which would allow application requests from any IPv4 address.
3. Plan and apply the Terraform change in `terraform/stack_staging`, then in `terraform/stack_prod`.
   Review each plan for unrelated changes.
   Editing the parameter alone does not update the running load balancers.
4. Check the normal HTTPS application URLs through the intended connection in both environments.
   Confirm an application response or login redirect, then check that a connection outside the allowlist still receives the load balancer's default 404 response.

Remove temporary or retired entries using the same process.
Terraform also [adds the VPC NAT gateway addresses] automatically so services calling the public hostnames from inside the VPC can reach them.
Those addresses do not need to be duplicated in the parameter.

## Troubleshooting and VPN routes

The restriction is an HTTPS listener rule, not a connection-level firewall block.
A disallowed source can resolve DNS and establish TLS but receives a default `404 Not Found` instead of reaching the application.
HTTP redirects to HTTPS even for a disallowed source, so that redirect alone does not prove access.

If a normal application URL returns 404 before login, check the actual egress address, VPN/proxy routing, and whether both Terraform stacks have been applied.
An application can also return 404, so the status alone is not conclusive.
Always use the listed hostname: forwarding requires both a matching hostname and an allowed source address.
`/metrics` and `/metrics/*` deliberately return 404 through these public endpoints, even from allowed addresses.

Each hostname points to an AWS Application Load Balancer.
Its public destination IPs can change as AWS updates the load balancer; see [AWS DNS routing].
Do not treat a one-time DNS lookup as a permanent list of VPN routes.
Ask the network administrator for routing that follows DNS changes or another managed way to send these requests through the allowed egress connection.
The stable source IPs in the allowlist and the changing destination IPs are different things.

[adds the vpc nat gateway addresses]: ../../terraform/modules/stack/alb_source_ips.tf
[application accounts]: user-management/README.md
[aws dns routing]: https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#request-routing
[production configuration]: ../../terraform/stack_prod/config.tf
[staging configuration]: ../../terraform/stack_staging/config.tf
