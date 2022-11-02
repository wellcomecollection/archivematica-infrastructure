# Microservices, tasks and jobs

There are three units of "work" in Archivematica, which you can see in the Archivematica dashboard:

![](../../images/microservices\_screenshot.png)

The top level unit is the _microservice_, for example `Create SIP from Transfer`.

Each microservice runs a number of _jobs_. Each job is doing a different action – for example, `Check transfer directory for objects` or `Load options to create SIPs`.

Each job may spawn one or more _tasks_, which are the Python scripts that run under the hood. You can see the tasks by clicking the gear icon. Often tasks run on a per-file basis: if there are 100 files in a transfer package and you need to perform an action on each file, there would be 100 tasks.

Microservices contain jobs, jobs spawn tasks:

![](../../images/microservices.svg)

Sometimes actions get stuck and need to be restarted; the only way I know how to do this is to restart the Archivematica containers (more on that below). Doing this may cause weird things to happen:

*   When the job is re-run, it gets scheduled twice, which might cause interesting things to happen downstream. Here's an example: this ingest had failed at the `Prepare AIP` step, I restarted the containers, and every job in and after Prepare AIP was run twice:

    ![](../../images/double\_scheduling\_task.png)
* Not all tasks tolerate being run twice, e.g. they try to create a directory and fail if the directory already exists (from a previous run of the task).

##
