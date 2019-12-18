# -*- encoding: utf-8

import datetime as dt
import re

from log_handler import Logger


class TestLogger:
    def test_can_write(self):
        logger = Logger()
        logger.write("Hello!")
        logger.write("My favourite colour is red")

        assert re.match(
            r"@@ Logging starts at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@\n"
            r"Hello!\n"
            r"My favourite colour is red\n"
            r"@@ Logging ends at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@",
            logger.text()
        )

        logger.write("I will write some more text")
        assert re.match(
            r"@@ Logging starts at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@\n"
            r"Hello!\n"
            r"My favourite colour is red\n"
            r"I will write some more text\n"
            r"@@ Logging ends at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@",
            logger.text()
        )

    def test_timestamp_is_recent(self):
        logger = Logger()
        logger.write("Hello!")

        text = logger.text()
        timestamp, *_ = text.splitlines()
        parsed_datetime = dt.datetime.strptime(
            timestamp, "@@ Logging starts at %Y-%m-%d %H:%M:%S @@"
        )
        assert (dt.datetime.now() - parsed_datetime).seconds < 5
