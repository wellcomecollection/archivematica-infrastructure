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

If this is the case, it means there's an old version of the transfer package lying around somewhere on the Archivematica disk.
The way to fix this is to SSH into the Archivematica container host, and remove any versions of the transfer package from the `currentlyProcessing` folder.

For example, to fix `WT_C_6_2_9_3.zip`:

```
[root@ip-10-50-3-25 /]# cd /ebs
[root@ip-10-50-3-25 ebs]# find . -name '*WT_C_6_2_9_3*'
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
[root@ip-10-50-3-25 ebs]# rm -rf ./pipeline-data/currentlyProcessing/WT_C_6_2_9_3
```
