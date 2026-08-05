# Why we forked Archivematica

We fork Archivematica to add support for our storage service. We've considered adding support to the upstream code (and deleting our forks), but this is non-trivial:

* It means adding a new dependency to Archivematica (our storage service client library), which Artefactual are understandably reluctant to do.
*   Archivematica is designed to work with a variety of storage backends (e.g. S3, DuraCloud, Fedora), and our storage service is a bit of an "odd one out".

    Most of the storage backends can store packages very quickly, whereas our storage service is asynchronous and can sometimes take multiple hours to successfully store a package.
    We've had to change some of the code around timeouts and waiting for the storage backend.

## How our forks work / how overlays work

Previously we maintained two completely separate copies of the Archivematica repositories (artefactual/archivematica and archivematica-storage-service), but because we only modify a handful of files we've replaced them with "overlays" that live in this repository.

The overlay works as follows:

1. Clone the upstream Artefactual repository
2. Copy our "overlay" files into the clone
3. Run the `docker build` command inside the clone-plus-overlay

The overlay is designed to balance a few competing concerns:

* We only want to diverge from the upstream Artefactual code in a handful of places
* We don't want the overhead of a separate Archivematica fork
* We want to be able to update to new versions of Archivematica

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

## Updating to newer versions of Archivematica

Because we only fork in a handful of places, we should be able to update to newer Archivematica versions relatively easily.

Bumping the version of the Artefactual repo is only the first step; every artefactual/wellcome pair must also be refreshed and reviewed.

When you bump the version, you may get errors from the `copy_overlay_files.py` script warning that there's a mismatch between upstream.
This means that there have been changes in Archivematica that need to be mirrored to our repo.

To fix these errors:

1.  Diff the artefactual/wellcome copies of the file, to determine what changes we've made.
2.  Copy the latest file from the artefactual repo into our codebase, replacing both the artefactual/wellcome copies of the file.
3.  Reapply any changes from the wellcome copy which you saw in step 1.
