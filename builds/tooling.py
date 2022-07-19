import subprocess


def compare_zip_files(zf1, zf2):
    """Return True/False if ``zf1`` and ``zf2`` have the same contents.

    This ignores file metadata (e.g. creation time), and just looks at
    filenames and CRC-32 checksums.

    This requires zipcmp to be available.
    """
    try:
        subprocess.check_call(['zipcmp', '-q', zf1, zf2])
    except subprocess.CalledProcessError:
        return False
    else:
        return True
