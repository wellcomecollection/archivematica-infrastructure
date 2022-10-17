#!/usr/bin/env python3

import collections
import filecmp
import os
import shutil


def get_file_paths_under(root):
    """Generates the paths to every file under ``root``."""
    for dirpath, _, filenames in os.walk(root):
        for f in filenames:
            yield os.path.join(dirpath, f)


if __name__ == "__main__":
    overlay_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "overlay")

    # Creates a list of (name) -> (file pair)
    #
    # e.g. src/archivematicaCommon/files.py -> {
    #        artefactual -> /path/to/repo/src/archivematicaCommon/files.artefactual.py
    #        wellcome -> /path/to/repo/src/archivematicaCommon/files.wellcome.py
    #      }
    file_pairs = collections.defaultdict(
        lambda: {"artefactual": None, "wellcome": None}
    )

    for fp in get_file_paths_under(overlay_dir):
        base_path = fp.replace(".artefactual", "").replace(".wellcome", "")

        if ".artefactual" in fp:
            file_pairs[os.path.relpath(base_path, overlay_dir)]["artefactual"] = fp

        if ".wellcome" in fp:
            file_pairs[os.path.relpath(base_path, overlay_dir)]["wellcome"] = fp

    # Now go through the file pairs.
    #
    # If the artefactual file doesn't match what's in Artefactual upstream, we need
    # to recheck our changes -- do they still apply?
    #
    # Otherwise we copy the artefactual file over the wellcome file.
    for name, pair in file_pairs.items():
        if None in pair.values() and name not in {
            "storage_service/locations/fixtures/wellcome.json",
            "storage_service/locations/migrations/0026_wellcome.py",
            "storage_service/locations/migrations/0027_add_wellcome_callback_fields.py",
            "storage_service/locations/migrations/0028_wellcome_blank_aws_auth.py",
            "storage_service/locations/migrations/0029_auto_20200122_0726.py",
            "storage_service/locations/models/wellcome.py",
            "storage_service/locations/tests/test_wellcome.py",
        }:
            raise ValueError(f"Did not get a pair of overlayed files for {name}")

        if pair["artefactual"] and not filecmp.cmp(pair["artefactual"], name):
            raise ValueError(f"artefactual file for {name} doesn’t match upstream!")

        print(f"Copying overlayed file {name}")
        shutil.copyfile(pair["wellcome"], name)
