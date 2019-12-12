# -*- encoding: utf-8
"""
The Archivematica transfer format is a bit fiddly, and there are ways to get
it wrong that are non-obvious.

This runs some checks over the package before sending it to Archivematica.

It needs two things from the package:
*   The list of all files in the package (from zipfile.namelist())
*   The contents of ``metadata/metadata.csv`` (if present in the package)

"""

import os
import textwrap


class VerificationFailure(Exception):
    def __init__(self, message):
        super().__init__(textwrap.dedent(message).strip())
    pass


def verify_all_files_not_under_single_dir(file_listing):
    common_path = os.path.commonpath(file_listing)
    if common_path:
        raise VerificationFailure(
            f"""
            All the files in your transfer package must be in the top level,
            not under a single folder.

            All the files in your package are under the single folder {common_path}.

            Recompress your transfer package with all the files at the top level,
            then upload it again.

            WRONG:

                transfer_package.zip
                  └─ LE/MON/
                       ├── recipe.txt
                       └── metadata/
                             └── metadata.csv
            RIGHT:

                transfer_package.zip
                  ├── recipe.txt
                  └── metadata/
                        └── metadata.csv

            """
        )


def verify_all_files_not_under_objects_dir(file_listing):
    if all([f.startswith(("objects/", "metadata/")) for f in file_listing]):
        raise VerificationFailure(
            """
            You do not need to place the files in your transfer package under
            ``objects/`` (even though that's the prefix in ``metadata.csv``).

            Move your files up a level (out of ``objects``), recompress your
            transfer package, then upload it again.

            WRONG:

                transfer_package.zip
                  ├── objects/
                  │     ├── documents/
                  │     │     └── report.pdf
                  │     └── pictures/
                  │           ├── cat.jpg
                  │           └── dog.png
                  └── metadata/
                        └── metadata.csv

            RIGHT:

                transfer_package.zip
                  ├── documents/
                  │     └── report.pdf
                  ├── pictures/
                  │     ├── cat.jpg
                  │     └── dog.png
                  └── metadata/
                        └── metadata.csv

            """
        )
