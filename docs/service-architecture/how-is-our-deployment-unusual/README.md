# How is our deployment unusual?

The conventional approach to Archivematica is to get a big VM and install all the Archivematica apps directly on the host (e.g. with rpms or dpkgs).

Archivematica predates a lot of technologies and techniques we now take for granted, e.g. managed cloud services, containers as a way to run services. But we want to run it as similar as possible to the rest of our services.

This means our Archivematica deployment:

* doesn't look the same as Archivematica in a lot of other institutions
* doesn't look the same as our other services, in particular those we wrote ourselves
