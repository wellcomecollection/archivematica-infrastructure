# Upgrading to a new version of Archivematica

We've only upgraded Archivematica once, so we only have a loose sense of what this involves.

Roughly:

* Bump the version of the Archivematica upstream repos that we use to build our Docker images
* Deploy those new images. Run any database migrations required (see [bootstrapping instructions](bootstrapping.md#step\_4)).
* Run end-to-end tests using the test\_transfer Lambda.
