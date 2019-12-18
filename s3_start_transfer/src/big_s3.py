# -*- encoding: utf-8
"""
This is some code for treating objects in S3 as if they're file-like objects
in Python.  It's useful if you're working in an environment where you don't
want to download the entire object (e.g. a Lambda function).

This potentially makes many more GetObject calls than downloading a big
object from S3, so user beware -- this may be expensive.

For a detailed breakdown of this code, see
https://alexwlchan.net/2019/02/working-with-large-s3-objects/

"""

import io


class S3File(io.RawIOBase):
    def __init__(self, s3_object):
        self.s3_object = s3_object
        self.position = 0

    def __repr__(self):
        return f"<{type(self).__name__} s3_object={self.s3_object!r}>"

    @property
    def size(self):
        return self.s3_object.content_length

    def tell(self):
        return self.position

    def seek(self, offset, whence=io.SEEK_SET):
        if whence == io.SEEK_SET:
            self.position = offset
        elif whence == io.SEEK_CUR:
            self.position += offset
        elif whence == io.SEEK_END:
            self.position = self.size + offset
        else:
            raise ValueError(
                f"invalid whence ({whence!r}, "
                f"expected one of {io.SEEK_SET}, {io.SEEK_CUR}, {io.SEEK_END})"
            )

        return self.position

    def seekable(self):
        return True

    def read(self, size=-1):
        if size == -1:
            # Read to the end of the file
            range_header = f"bytes={self.position}-"
            self.seek(offset=0, whence=io.SEEK_END)
        else:
            new_position = self.position + size

            # If we're going to read beyond the end of the object, return
            # the entire object.
            if new_position >= self.size:
                return self.read()

            range_header = f"bytes={self.position}-{new_position - 1}"
            self.seek(offset=size, whence=io.SEEK_CUR)

        return self.s3_object.get(Range=range_header)["Body"].read()

    def readable(self):
        return True
