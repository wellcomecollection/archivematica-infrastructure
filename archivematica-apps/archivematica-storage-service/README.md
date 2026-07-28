# archivematica

This folder creates the following images:

*   storage-service

We only diverge slightly from Archivematica upstream, so rather than maintaining a whole separate fork, we have a series of overlays.

Note: this is the *Archivematica* storage service, which is an orchestrator for different storage backends (e.g. S3, DuraCloud).
It's different from the Wellcome storage service.

## How to build images

Run the `build_and_publish_image.sh` script.

You can get a newer version of the code from Artefactual upstream by changing the `ARCHIVEMATICA_TAG` variable.

## How the overlay works

The overlay is designed to balance a few competing concerns:

*   We want to diverge from the upstream Artefactual code in a handful of places, with changes that are unlikely to be accepted upstream
*   We don't want to maintain a completely separate Archivematica fork
*   We want to be able to upgrade to new versions of Archivematica

For example, the dependency overlay contains `.artefactual` and `.wellcome` copies of `pyproject.toml` and `uv.lock`.
When we build the Docker image, these files replace the upstream versions.

We keep both the upstream and Wellcome-specific copy in the tree so that we can easily see how we've diverged.
This also allows us to maintain the divergence if the upstream code changes, because we can see what our changes from the original were.

Some files have only a Wellcome copy because they are additions rather than replacements for upstream files.

The dependency overlay pairs both `pyproject.toml` and the generated `uv.lock`.
After changing `pyproject.wellcome.toml`, apply it to a clean upstream checkout and run `uv lock`.
Copy the result to `uv.wellcome.lock`; do not edit the generated lock file by hand.

## Django migration branches

The Wellcome storage-space model has its own migration branch.
Its files have no `.artefactual` partner because they add to upstream rather than replace it.
`copy_overlay_files.py` explicitly allows them and copies them into the upstream migrations package.

Django orders migrations by their full names and declared dependencies, not just by the numeric prefixes.
It is therefore valid for upstream and Wellcome to both have migrations beginning with `0026`, for example.

The current branch joins upstream at three points:

| Wellcome migration | Dependencies | Purpose |
| --- | --- | --- |
| `0026_wellcome` through `0029_auto_20200122_0726` | Upstream `0025`, then the preceding Wellcome migration | Add and evolve the Wellcome storage-space model |
| `0031_merge_20221017_0727` | Wellcome `0029` and upstream `0030` | Join the first two branches |
| `0034_merge_20230720_0400` | Wellcome merge `0031` and upstream `0033` | Include later upstream migrations |
| `0038_merge_20250527_1404` | Wellcome merge `0034` and upstream `0037` | Produce one combined migration leaf |
| `0039_alter_space_access_protocol` | Wellcome merge `0038` | Record the final upstream choices plus `WELLCOME` |
| `0040_add_wellcome_manager_permissions` | Wellcome `0039` | Add direct Wellcome model permissions to the upstream Managers group |

The merge migrations have no operations.
They only require both parent branches to have been applied.
They do not combine model state or replay data migrations.
When both branches change the same model state, add a normal migration after the merge to record the intended result, as `0039` does for `Space.access_protocol`.

Upstream `0030_user_groups` creates the Managers group before the parallel Wellcome branch creates `WellcomeStorageService`.
Because a merge does not replay that data migration, `0040` explicitly adds the Wellcome model permissions after the branches join.

Treat migration names, dependencies, and operations as deployed history.
Do not renumber or delete an existing Wellcome migration, or change its dependencies or operations.
When updating the upstream base:

1. Copy the existing Wellcome migrations into the new upstream package without changing their dependencies or operations.
2. Add an empty merge migration if upstream and Wellcome now have separate leaf migrations.
3. Update `test_wellcome_migrations.py` with the new upstream leaf, Wellcome migrations, and dependencies.
4. Run `makemigrations --check --dry-run`.
   If Django detects a model-state difference, create a normal migration after the merge.
5. Test both a fresh disposable database and an upgrade from the migration state currently deployed to staging.

Run these checks from a clean checkout of the pinned upstream revision after applying the overlay.
`showmigrations locations --plan` displays the dependency order, while `sqlmigrate locations <migration>` shows whether a migration changes the database or only Django's recorded model state.
