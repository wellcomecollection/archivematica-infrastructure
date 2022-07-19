import zipfile


def compare_zip_files(path1, path2):
    """Return True/False if ``path1`` and ``path2`` have the same contents.

    This ignores file metadata (e.g. creation time), and just looks at
    filenames and file contents.

    """
    with zipfile.ZipFile(path1) as zf1, zipfile.ZipFile(path2) as zf2:

        # If the zip files contain different files, they're obviously
        # different.
        if set(zf1.namelist()) != set(zf2.namelist()):
            return False

        for name in zf1.namelist():
            if zf1.read(name) != zf2.read(name):
                return False

    return True
