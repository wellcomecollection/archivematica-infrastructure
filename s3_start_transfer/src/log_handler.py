# -*- encoding: utf-8
"""
Although a Lambda function will write logs to CloudWatch, our users
(e.g. archivists) only interact with the S3 Console.

This class allows us to write a log file into S3, alongside the
zip package they've uploaded.  This gives some immediate feedback that
their upload was successful!

To use the context:

    with s3_logger(bucket="logging-bukkit", key="myfile.zip") as logger:
        logger.write("Something happened!")
        logger.write("Another thing happened!")

When the body of the ``with`` statement completes, a file will be written to
S3 of the form ``s3://logging-bukkit/myfile.zip.<timestamp>.log with the contents:

    @@ Logging starts at <timestamp> @@
    Something happened!
    Another thing happened!
    @@ Logging ends at <timestamp> @@

The logging style is deliberately simple -- this is intended for use by humans,
not machines.  Also, it should only be used in short-running functions, so log
messages aren't lost.

"""

import contextlib
import datetime as dt

import boto3


class Logger:
    def __init__(self):
        self._lines = [
            f"@@ Logging starts at {self._timestamp()} @@"
        ]

    def _timestamp(self):
        return dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def write(self, message):
        self._lines.append(message)

    def text(self):
        return "\n".join(self._lines + [f"@@ Logging ends at {self._timestamp()} @@"])


@contextlib.contextmanager
def s3_logger(bucket, prefix):
    logger = Logger()
    try:
        yield logger
    except Exception as exc:
        logger.write(f"!!! Something went wrong!")
        logger.write(f"!!! Please ask an AWS admin to check the CloudWatch logs.")
        logger.write(f"!!! Exception message: {exc}")
    finally:
        timestamp = dt.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        upload_key = prefix + "." + timestamp + ".log"
        print(f"Writing user log to s3://{bucket}/{upload_key}")

        boto3.client("s3").put_object(
            Bucket=bucket,
            Key=upload_key,
            Body=logger.text()
        )
