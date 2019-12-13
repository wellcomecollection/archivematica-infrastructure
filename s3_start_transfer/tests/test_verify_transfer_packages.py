# -*- encoding: utf-8

import pathlib
import textwrap
import zipfile

import pytest

from verify_transfer_packages import (
    verify_all_files_not_under_single_dir,
    verify_all_files_not_under_objects_dir,
    verify_has_a_metadata_csv,
    verify_only_metadata_csv_in_metadata_dir,
    verify_metadata_csv_is_correct_format,
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


class TestVerifyHasMetadataCsv:
    @pytest.mark.parametrize("name", [
        "no_metadata_csv.zip",
        "metadata_at_top_level.zip",
    ])
    def test_no_metadata_csv_is_exception(self, name):
        file_listing = _get_file_listing(name)

        with pytest.raises(VerificationFailure) as err:
            verify_has_a_metadata_csv(file_listing=file_listing)

        assert str(err.value).startswith(
            "Your transfer package must have a file ``metadata/metadata.csv``\n"
            "that describes the objects in the bag."
        )

    @pytest.mark.parametrize("name", [
        "valid_transfer_package.zip",
        "multi_top_level_dir.zip"
    ])
    def test_valid_transfer_package_is_okay(self, name):
        file_listing = _get_file_listing(name)
        verify_has_a_metadata_csv(file_listing=file_listing)



class TestVerifyOnlyMetadataCsvInMetadataDir:
    @pytest.mark.parametrize("name", [
        "extra_files_in_metadata_dir.zip",
    ])
    def test_extra_files_in_metadata_dir_is_exception(self, name):
        file_listing = _get_file_listing(name)

        with pytest.raises(VerificationFailure) as err:
            verify_only_metadata_csv_in_metadata_dir(file_listing=file_listing)

        assert str(err.value).startswith(
            "Your transfer package has unexpected files in the ``metadata/`` folder.\n"
            "The only file in ``metadata/`` should be ``metadata/metadata.csv``."
        )

    @pytest.mark.parametrize("name", [
        "valid_transfer_package.zip",
        "multi_top_level_dir.zip"
    ])
    def test_valid_transfer_package_is_okay(self, name):
        file_listing = _get_file_listing(name)
        verify_only_metadata_csv_in_metadata_dir(file_listing=file_listing)


class TestVerifyMetadataCsv:
    @pytest.mark.parametrize("metadata, row_count", [
        ("""
        filename,dc.identifier
        objects/lemon.png,LE/MON/1
        objects/lemon_curd.jpg,LE/MON/2
        """, 2),
        ("""filename,dc.identifier""", 0),
    ])
    def test_only_contains_one_row(self, metadata, row_count):
        metadata = textwrap.dedent(metadata).strip()

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_is_correct_format(metadata=metadata)

        assert str(err.value).startswith(
            f"Your metadata.csv should only contain a single row, but the\n"
            f"CSV in your transfer package contains {row_count} rows."
        )

    @pytest.mark.parametrize("metadata", [
        """
        filename,dc.title
        objects/,The Citrus Archives
        """,
        """
        dc.identifier,dc.title
        LE/MON/1,The Citrus Archives
        """,
        """
        dc.title
        The Citrus Archives
        """,
    ])
    def test_checks_for_mandatory_columns(self, metadata):
        metadata = textwrap.dedent(metadata).strip()

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_is_correct_format(metadata=metadata)

        assert str(err.value).startswith(
            "Your metadata.csv is missing one of the mandatory columns ('filename'\n"
            "and 'dc.identifier'.)  Please add these columns to your metadata.csv,"
        )

    @pytest.mark.parametrize("filename", ["objects", "objects/cat.jpg", "cat.jpg"])
    def test_checks_filename_is_correct(self, filename):
        metadata = f"""filename,dc.identifier\n{filename},LE/MON"""

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_is_correct_format(metadata=metadata)

        assert str(err.value).startswith(
            "Your metadata.csv has an incorrect value in the 'filename' column.\n"
            "The value in this column should be 'objects/'."
        )

    @pytest.mark.parametrize("metadata", [
        """
        filename,dc.identifier
        objects/,
        """,
        """
        filename,dc.identifier,dc.title
        objects/,,The Citrus Archives
        """,
    ])
    def test_checks_dc_identifier_is_non_empty(self, metadata):
        metadata = textwrap.dedent(metadata).strip()

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_is_correct_format(metadata=metadata)

        assert str(err.value).startswith(
            "You have supplied an empty value in the 'dc.identifier' field of\n"
            "your metadata.csv."
        )

    @pytest.mark.parametrize("metadata", [
        """
        filename,dc.identifier
        objects/,LE/MON/1
        """,
        """
        dc.identifier,filename
        LE/MON/1,objects/
        """,
        """
        dc.identifier,dc.title,filename
        LE/MON/1,The Citrus Archives,objects/
        """
    ])
    def test_valid_metadata_is_okay(self, metadata):
        metadata = textwrap.dedent(metadata).strip()

        verify_metadata_csv_is_correct_format(metadata=metadata)
