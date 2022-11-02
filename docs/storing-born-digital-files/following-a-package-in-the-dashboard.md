# Following a package in the dashboard

The Archivematica dashboard is a web app that allows you to monitor the progress of a transfer package. You can find it at one of these URLs:

* prod is [https://archivematica.wellcomecollection.org/](https://archivematica.wellcomecollection.org/)
* staging is [https://archivematica-stage.wellcomecollection.org/](https://archivematica-stage.wellcomecollection.org/)

This is what it looks like:

<figure><img src="../.gitbook/assets/Screenshot 2022-11-02 at 19.05.14.png" alt=""><figcaption></figcaption></figure>

A new transfer package will start in the **Transfer** tab, and go through various processing steps. If those steps succeed and it comples the **Create SIP from Transfer** task, then it moves to the **Ingest** tab.

In the Ingest tab, it goes through more processing steps, and eventually gets to **Store AIP**. This is the step where the package gets uploaded to the Wellcome storage service; if this step completes successfully, then the package has been correctly stored.

\[The terms SIP and AIP come from [the OAIS model](https://en.wikipedia.org/wiki/Open\_Archival\_Information\_System).]
