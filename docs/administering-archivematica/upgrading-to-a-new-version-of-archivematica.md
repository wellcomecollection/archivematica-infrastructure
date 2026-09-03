# Upgrading to a new version of Archivematica

We build our Archivematica images from pinned upstream revisions with Wellcome overlay files applied on top.
The image tags selected for deployment are recorded in the `ecr_image_tags` values for the [staging](https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/stack_staging/locals.tf) and [production](https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/stack_prod/locals.tf) stacks.
These Terraform values describe the desired configuration, so verify the live ECS service task definitions before relying on them as a record of what is running.

An upgrade involves these stages:

* Select and pin the new upstream revisions in the Archivematica and Storage Service build scripts. Review the release-specific upgrade notes and identify the required migration, index, dependency, and processing-configuration changes.
* Refresh and review every upstream/Wellcome overlay pair and Wellcome-only addition using the [overlay update instructions](../service-architecture/how-is-our-deployment-unusual/archivematica-forks.md#updating-to-newer-versions-of-archivematica).
* Apply the overlays to clean checkouts of the pinned revisions and run the relevant application and migration tests. For the Storage Service, follow the [migration checks](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/archivematica-apps/archivematica-storage-service#django-migration-branches), including fresh-database and upgrade tests.
* Build and publish the images with Buildkite. The three core Archivematica images share one upstream-and-overlay tag, and the Storage Service has its own upstream-and-overlay tag.
* Before applying the staging stack, establish the version-specific deployment and migration order, pause new transfer intake, and confirm that no staging transfers or ingests are running.
* Update the staging Terraform values to the exact image tags. Apply the staging stack and run the required migrations in the established order.
* [Run an end-to-end test](running-an-end-to-end-test.md) and confirm that it reaches final storage, not merely that the test Lambda was invoked.
* Before changing production, confirm that no transfers or ingests are running, take recoverable backups of both application databases and any other state named by the version-specific guide, and establish the database and data restoration procedure.
* Promote the same tested image tags to production and repeat the required migrations and checks during an appropriate maintenance window.

Buildkite builds and publishes the application images, but it does not currently run the Archivematica or Storage Service application and migration test suites.
A successful image build is not evidence that an overlay or migration is compatible.

Keep the previous image tags and their matching database and data recovery point until the upgrade has been verified.
Do not restore older application images after forward database migrations unless their schema compatibility has been established; otherwise restore the matching database and data recovery point as part of the rollback.
