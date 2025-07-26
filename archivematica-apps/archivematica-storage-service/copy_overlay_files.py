#!/usr/bin/env python3

import collections
import filecmp
import os
import shutil
from collections.abc import Generator
from pathlib import Path
from typing import Optional


def get_file_paths_under(root: Path) -> Generator[Path, None, None]:
    """Generates the paths to every file under ``root``."""
    for dirpath, _, filenames in os.walk(root):
        for f in filenames:
            yield Path(dirpath, f)


if __name__ == "__main__":
    overlay_dir = Path(__file__).parent / "overlay"

    # Creates a list of (name) -> (file pair)
    #
    # e.g. src/archivematicaCommon/files.py -> {
    #        artefactual -> /path/to/repo/src/archivematicaCommon/files.artefactual.py
    #        wellcome -> /path/to/repo/src/archivematicaCommon/files.wellcome.py
    #      }
    file_pairs: dict[Path, dict[str, Optional[Path]]] = collections.defaultdict(
        lambda: {"artefactual": None, "wellcome": None}
    )

    for fp in sorted(get_file_paths_under(overlay_dir)):
        fp_str = str(fp)
        base_path = Path(fp_str.replace(".artefactual", "").replace(".wellcome", ""))

        if ".artefactual" in fp_str:
            file_pairs[base_path.relative_to(overlay_dir)]["artefactual"] = fp

        if ".wellcome" in fp_str:
            file_pairs[base_path.relative_to(overlay_dir)]["wellcome"] = fp

    # Now go through the file pairs.
    #
    # If the artefactual file doesn't match what's in Artefactual upstream, we need
    # to recheck our changes -- do they still apply?
    #
    # Otherwise we copy the artefactual file over the wellcome file.
    for name, pair in file_pairs.items():
        if None in pair.values() and str(name) not in {
            "storage_service/locations/migrations/0026_wellcome.py",
            "storage_service/locations/migrations/0027_add_wellcome_callback_fields.py",
            "storage_service/locations/migrations/0028_wellcome_blank_aws_auth.py",
            "storage_service/locations/migrations/0029_auto_20200122_0726.py",
            "storage_service/locations/migrations/0031_merge_20221017_0727.py",
            "storage_service/locations/migrations/0034_merge_20230720_0400.py",
            "storage_service/locations/migrations/0038_merge_20250527_1404.py",
            "storage_service/locations/models/wellcome.py",
            "tests/locations/fixtures/wellcome.json",
            "tests/locations/fixtures/small_compressed_bag.tar.gz",
            "tests/locations/test_wellcome.py",
        }:
            raise ValueError(f"Did not get a pair of overlayed files for {name}")

        if pair["artefactual"] and not filecmp.cmp(pair["artefactual"], name):
            raise ValueError(f"artefactual file for {name} doesn’t match upstream!")

        if pair["wellcome"]:
            print(f"Copying overlayed file {name}")
            shutil.copyfile(pair["wellcome"], name)
