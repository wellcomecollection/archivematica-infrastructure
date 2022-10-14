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


if __name__ == '__main__':
    vendor_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vendor")
    print(vendor_dir)

    # Creates a list of (name) -> (file pair)
    #
    # e.g. src/archivematicaCommon/files.py -> {
    #        old -> /path/to/repo/src/archivematicaCommon/files.old.py
    #        new -> /path/to/repo/src/archivematicaCommon/files.new.py
    #      }
    file_pairs = collections.defaultdict(lambda: {'old': None, 'new': None})

    for fp in get_file_paths_under(vendor_dir):
        base_path = fp.replace('.old', '').replace('.new', '')

        if '.old' in fp:
            file_pairs[os.path.relpath(base_path, vendor_dir)]['old'] = fp

        if '.new' in fp:
            file_pairs[os.path.relpath(base_path, vendor_dir)]['new'] = fp

    # Now go through the file pairs.
    #
    # If the old file doesn't match what's in Artefactual upstream, we need
    # to recheck our changes -- do they still apply?
    #
    # Otherwise we copy the old file over the new file.
    for name, pair in file_pairs.items():
        if None in pair.values():
            raise ValueError(f'Did not get a pair of vendored files for {name}')

        if not filecmp.cmp(pair['old'], name):
            raise ValueError(f'Old file for {name} doesn’t match upstream!')

        print(f'Copying vendored file {name}')
        shutil.copyfile(pair['new'], name)
