# -*- encoding: utf-8
"""
Although a Lambda function will write logs to CloudWatch, our users
(e.g. archivists) only interact with the S3 Console.

This class allows us to write a log file into S3, alongside the
zip package they've uploaded.  This gives some immediate feedback that
their upload was successful!

The Logger accumulates the logs, and then at any time you can retrieve
what's been written to the log.  Log messages are mirrored to stdout.

    >>> from log_handler import Logger
    >>> logger = Logger()
    >>> logger.write("Something happened")
    Something happened
    >>> logger.write("Then another thing happened")
    Then another thing happened
    >>> logger.text()
    '@@ Logging starts at 2019-12-18 10:57:54 @@\nSomething happened\n'
    'Then another thing happened\n@@ Logging ends at 2019-12-18 10:58:08 @@'

"""

import datetime as dt


class Logger:
    def __init__(self):
        self._lines = [
            f"@@ Logging starts at {self._timestamp()} @@"
        ]

    def _timestamp(self):
        return dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def write(self, message):
        print(message)
        self._lines.append(message)

    def text(self):
        return "\n".join(self._lines + [f"@@ Logging ends at {self._timestamp()} @@"])
