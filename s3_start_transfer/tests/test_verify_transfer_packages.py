# -*- encoding: utf-8

import pathlib
import zipfile

import pytest

from verify_transfer_packages import (
    verify_all_files_not_under_single_dir,
    verify_all_files_not_under_objects_dir,
    VerificationFailure
)


def _get_file_listing(name):
    zip_path = pathlib.Path(__file__).parent / "files" / name

    with zipfile.ZipFile(zip_path) as zf:
        return zf.namelist()


class TestVerifyAllFilesNotUnderSingleDir:
    def test_single_dir_is_exception(self):
        file_listing = _get_file_listing("single_dir_compressed.zip")

        with pytest.raises(VerificationFailure) as err:
            verify_all_files_not_under_single_dir(file_listing=file_listing)

        assert str(err.value).startswith(
            "All the files in your transfer package must be in the top level,"
        )

    @pytest.mark.parametrize("name", [
        "valid_transfer_package.zip",
        "multi_top_level_dir.zip",
    ])
    def test_valid_transfer_package_is_okay(self, name):
        file_listing = _get_file_listing(name)
        verify_all_files_not_under_single_dir(file_listing=file_listing)


class TestVerifyAllFilesNotUnderObjectsDir:
    def test_everything_under_objects_is_exception(self):
        file_listing = _get_file_listing("everything_under_objects.zip")

        with pytest.raises(VerificationFailure) as err:
            verify_all_files_not_under_objects_dir(file_listing=file_listing)

        assert str(err.value).startswith(
            "You do not need to place the files in your transfer package under\n"
            "``objects/`` (even though that's the prefix in ``metadata.csv``)."
        )

    @pytest.mark.parametrize("name", [
        "valid_transfer_package.zip",
        "multi_top_level_dir.zip"
    ])
    def test_valid_transfer_package_is_okay(self, name):
        file_listing = _get_file_listing(name)
        verify_all_files_not_under_objects_dir(file_listing=file_listing)
