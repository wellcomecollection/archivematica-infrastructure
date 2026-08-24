# archivematica

This folder creates the following images:

*   dashboard
*   MCPClient
*   MCPServer

We only diverge slightly from Archivematica upstream, so rather than maintaining a whole separate fork, we have a series of overlays.

## How to build images

Run `build_and_publish_image.sh` with `dashboard`, `mcp-client`, or `mcp-server` as its argument.

You can get a newer version of the code from Artefactual upstream by changing the `UPSTREAM_COMMIT` variable in `build_and_publish_image.sh`.

## How the overlay works

The overlay is designed to balance a few competing concerns:

*   We want to diverge from the upstream Artefactual code in a handful of places, with changes that are unlikely to be accepted upstream
*   We don't want to maintain a completely separate Archivematica fork
*   We want to be able to upgrade to new versions of Archivematica

For example:

```text
overlay/src/archivematica/archivematicaCommon/
├── storageService.artefactual.py
└── storageService.wellcome.py
```

This represents a Wellcome-specific version of the file `src/archivematica/archivematicaCommon/storageService.py` in the core Archivematica repo.
When we build the Docker image, these files replace the upstream versions.

We keep both the upstream and Wellcome-specific copy in the tree so that we can easily see how we've diverged.
This also allows us to maintain the divergence if the upstream code changes, because we can see what our changes from the original were.

The `.artefactual.py` file is the upstream version and the `.wellcome.py` file is its complete Wellcome replacement.

## Current overlays

Keep this inventory up to date when adding or removing an overlay pair. It records the behavior we own, why it differs from upstream, and when the divergence can be removed.

| Concept | Overlay pairs | Purpose and removal condition |
| --- | --- | --- |
| Transfer-wide rights imports | `src/archivematica/MCPClient/clientScripts/rights_from_csv.{artefactual,wellcome}.py` | Treats `objects/` in `rights.csv` as a transfer-scoped target for [issue #114](https://github.com/wellcomecollection/archivematica-infrastructure/issues/114). This is a temporary bridge that can be removed when `UPSTREAM_COMMIT` includes [artefactual/archivematica#2376](https://github.com/artefactual/archivematica/pull/2376). |
| Asynchronous Storage Service operations | `src/archivematica/archivematicaCommon/storageService.{artefactual,wellcome}.py` and `tests/archivematicaCommon/test_storage_service.{artefactual,wellcome}.py` | Restores asynchronous Storage Service operations with bounded polling and explicit unknown-outcome errors for long-running Wellcome storage work. Revisit this overlay when a durable, idempotent asynchronous workflow replaces it; see [issue #176](https://github.com/wellcomecollection/archivematica-infrastructure/issues/176). |
| Azure OIDC UPN behavior | `tests/dashboard/test_oidc.{artefactual,wellcome}.py` | Adds Wellcome-specific regression coverage for mapping the Azure access-token `upn` claim to an Archivematica email. This is a test-only overlay; retain it while the deployed authentication configuration depends on that behavior. |
