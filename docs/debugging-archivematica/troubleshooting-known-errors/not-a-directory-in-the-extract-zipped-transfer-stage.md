# NotADirectoryError in the Extract zipped transfer stage

If you have to retry a transfer, you may see a "not a directory" error in the "Extract zipped transfer stage", for example:

```
[Errno 20] Not a directory: '/var/archivematica/sharedDirectory/currentlyProcessing/WT_C_6_2_9_3.zip'Traceback (most recent call last):
  File "/src/src/MCPClient/lib/job.py", line 103, in JobContext
    yield
  File "/src/src/MCPClient/lib/clientScripts/failed_transfer_cleanup.py", line 70, in call
    main(job, args.fail_type, args.transfer_uuid, args.transfer_path)
  File "/src/src/MCPClient/lib/clientScripts/failed_transfer_cleanup.py", line 33, in main
    for item in os.listdir(mets_dir):
NotADirectoryError: [Errno 20] Not a directory: '/var/archivematica/sharedDirectory/currentlyProcessing/WT_C_6_2_9_3.zip'
```

This error can occur after extraction fails while the transfer path still points to the zip file.
The failed zip may already have moved to `failed`, while a partially extracted directory with the same name remains in `currentlyProcessing`.
Before changing any files, confirm that you are connected to the intended environment, record the transfer name and UUID, and check that no active transfer is using the path.

Connect to the Archivematica container host and inspect matching paths under `/ebs/pipeline-data`.
Only move the matching entry from `currentlyProcessing`; the other results may be logs or evidence which is useful for understanding the failure.

For example, to fix `WT_C_6_2_9_3.zip`:

```
[root@ip-10-50-3-25 /]# cd /ebs
[root@ip-10-50-3-25 ebs]# find ./pipeline-data -name '*WT_C_6_2_9_3*'
./pipeline-data/failed/WT_C_6_2_9_3.zip
./pipeline-data/tmp/tmpvrw7hglu/WT_C_6_2_9_3.zip.success.2023-07-24_11-14-51.log
./pipeline-data/tmp/tmpia_x8g31/WT_C_6_2_9_3.zip.success.2023-07-25_10-52-26.log
./pipeline-data/tmp/tmpia_x8g31/WT_C_6_2_9_3.zip.success.2023-07-25_11-31-34.log
./pipeline-data/tmp/tmpia_x8g31/WT_C_6_2_9_3.zip.success.2023-07-25_10-28-52.log
./pipeline-data/tmp/tmpia_x8g31/WT_C_6_2_9_3.zip.success.2023-07-24_11-14-51.log
./pipeline-data/tmp/tmpuv33syk2/WT_C_6_2_9_3.zip.success.2023-07-25_10-28-52.log
./pipeline-data/tmp/tmpuv33syk2/WT_C_6_2_9_3.zip.success.2023-07-24_11-14-51.log
./pipeline-data/tmp/tmpihlcvk6l/WT_C_6_2_9_3.zip.success.2023-07-25_10-52-26.log
./pipeline-data/tmp/tmpihlcvk6l/WT_C_6_2_9_3.zip.success.2023-07-25_10-28-52.log
./pipeline-data/tmp/tmpihlcvk6l/WT_C_6_2_9_3.zip.success.2023-07-24_11-14-51.log
./pipeline-data/currentlyProcessing/WT_C_6_2_9_3
[root@ip-10-50-3-25 ebs]# sudo install -d -m 0700 ./quarantine/WT_C_6_2_9_3-2023-07-25T120000Z
[root@ip-10-50-3-25 ebs]# sudo mv --no-clobber -- ./pipeline-data/currentlyProcessing/WT_C_6_2_9_3 ./quarantine/WT_C_6_2_9_3-2023-07-25T120000Z/
[root@ip-10-50-3-25 ebs]# sudo test ! -e ./pipeline-data/currentlyProcessing/WT_C_6_2_9_3
[root@ip-10-50-3-25 ebs]# sudo test -e ./quarantine/WT_C_6_2_9_3-2023-07-25T120000Z/WT_C_6_2_9_3
```

Use a unique directory named with the transfer and the incident time so an earlier quarantine cannot be overwritten.
Retry the transfer and confirm that it progresses beyond the failed stage.
Keep the quarantined directory until the transfer succeeds and you are confident it is no longer needed.
