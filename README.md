# archivematica-infrastructure

[![Build status](https://badge.buildkite.com/110c72015ef5319e8fbec009b7f3e477ccc7ccab1a732e5194.svg)](https://buildkite.com/wellcomecollection/archivematica-infrastructure)

**We use Archivematica to process and store our born-digital archives.**

This processing includes:

* Analysing files in the archive, like virus scanning, file format identification, and fixity checking
* Creating a metadata description of the archive that can be read by downstream applications
8 Uploading the archive to our permanent cloud storage

It's an open-source application created by [Artefactual], and we run a lightly modified fork.

You can read more about our Archivematica deployment in [our documentation][docs].

[Artefactual]: https://www.artefactual.com/
[docs]: https://docs.wellcomecollection.org/archivematica



## Repo layout

*   [`archivematica-apps`](./archivematica-apps) – our [forked versions](./docs/developers/archivematica-forks.md) of the core Archivematica apps.
*   [`azure_ad_login`](./azure_ad_login) – instructions for configuring SSO for Archivematica.
*   [`born_digital_listener`](./born_digital_listener) – a Lambda that sends notifications of newly-stored born digital material to iiif-builder, so it can build IIIF Presentation manifests.
*   [`docs`](./docs) – documentation and instructions, which are published using GitBook
*   [`lambdas`](./lambdas) – a couple of glue functions that provide additional functionality beyond the core Archivematica apps.
*   [`terraform`](./terraform) – Terraform configurations for our two deployments of Archivematica in AWS, including databases and services.



## License

This repository includes some code from the Archivematica repository, which is licensed from Artefactual under AGPL v3.0.
There are separate LICENSE files in the root of trees that contain AGPL code.

The remainder of the repository is released under the MIT license.
