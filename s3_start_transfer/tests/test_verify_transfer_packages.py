# -*- encoding: utf-8

import pathlib
import textwrap
import zipfile

import pytest

from log_handler import Logger
from verify_transfer_packages import (
    verify_package,
    verify_all_files_not_under_single_dir,
    verify_all_files_not_under_objects_dir,
    verify_has_a_metadata_csv,
    verify_only_metadata_csv_in_metadata_dir,
    verify_metadata_csv_has_dc_identifier,
    verify_metadata_csv_has_accession_fields,
    VerificationFailure,
)


def _get_zip_path(name):
    return pathlib.Path(__file__).parent / "files" / name


def _get_file_listing(name):
    zip_path = _get_zip_path(name)

    with zipfile.ZipFile(zip_path) as zf:
        return zf.namelist()


class TestVerifyPackage:
    verifications = [
        verify_all_files_not_under_single_dir,
        verify_all_files_not_under_objects_dir,
        verify_has_a_metadata_csv,
        verify_only_metadata_csv_in_metadata_dir,
        verify_metadata_csv_has_dc_identifier,
    ]

    def test_errors_if_no_metadata_in_zip(self):
        zip_path = _get_zip_path("no_metadata_csv.zip")

        logger = Logger()

        with zipfile.ZipFile(zip_path) as zf:
            verify_package(logger=logger, zip_file=zf, verifications=self.verifications)

    @pytest.mark.parametrize(
        "name",
        [
            "valid_transfer_package.zip",
            "valid_transfer_package_with_byte_order_mark.zip",
        ],
    )
    def test_handles_a_byte_order_mark_in_metadata_csv(self, name):
        zip_path = _get_zip_path(name)

        logger = Logger()
        with zipfile.ZipFile(zip_path) as zf:
            verify_package(logger=logger, zip_file=zf, verifications=self.verifications)


class TestVerifyAllFilesNotUnderSingleDir:
    def test_single_dir_is_exception(self):
        file_listing = _get_file_listing("single_dir_compressed.zip")

        with pytest.raises(VerificationFailure) as err:
            verify_all_files_not_under_single_dir(file_listing=file_listing)

        assert str(err.value).startswith(
            "All the files in your transfer package must be in the top level,"
        )

    @pytest.mark.parametrize(
        "name", ["valid_transfer_package.zip", "multi_top_level_dir.zip"]
    )
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

    @pytest.mark.parametrize(
        "name", ["valid_transfer_package.zip", "multi_top_level_dir.zip"]
    )
    def test_valid_transfer_package_is_okay(self, name):
        file_listing = _get_file_listing(name)
        verify_all_files_not_under_objects_dir(file_listing=file_listing)


class TestVerifyHasMetadataCsv:
    @pytest.mark.parametrize(
        "name", ["no_metadata_csv.zip", "metadata_at_top_level.zip"]
    )
    def test_no_metadata_csv_is_exception(self, name):
        file_listing = _get_file_listing(name)

        with pytest.raises(VerificationFailure) as err:
            verify_has_a_metadata_csv(file_listing=file_listing)

        assert str(err.value).startswith(
            "Your transfer package must have a file ``metadata/metadata.csv``\n"
            "that describes the objects in the bag."
        )

    @pytest.mark.parametrize(
        "name", ["valid_transfer_package.zip", "multi_top_level_dir.zip"]
    )
    def test_valid_transfer_package_is_okay(self, name):
        file_listing = _get_file_listing(name)
        verify_has_a_metadata_csv(file_listing=file_listing)


class TestVerifyOnlyMetadataCsvInMetadataDir:
    @pytest.mark.parametrize("name", ["extra_files_in_metadata_dir.zip"])
    def test_extra_files_in_metadata_dir_is_exception(self, name):
        file_listing = _get_file_listing(name)

        with pytest.raises(VerificationFailure) as err:
            verify_only_metadata_csv_in_metadata_dir(file_listing=file_listing)

        assert str(err.value).startswith(
            "Your transfer package has unexpected files in the ``metadata/`` folder.\n"
            "The only file in ``metadata/`` should be ``metadata/metadata.csv``."
        )

    @pytest.mark.parametrize(
        "name", ["valid_transfer_package.zip", "multi_top_level_dir.zip"]
    )
    def test_valid_transfer_package_is_okay(self, name):
        file_listing = _get_file_listing(name)
        verify_only_metadata_csv_in_metadata_dir(file_listing=file_listing)


class TestVerifyMetadataCsvHasDcIdentifier:
    @pytest.mark.parametrize(
        "metadata, row_count",
        [
            (
                """
        filename,dc.identifier
        objects/lemon.png,LE/MON/1
        objects/lemon_curd.jpg,LE/MON/2
        """,
                2,
            ),
            ("""filename,dc.identifier""", 0),
        ],
    )
    def test_only_contains_one_row(self, metadata, row_count):
        metadata = textwrap.dedent(metadata).strip()

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_has_dc_identifier(metadata=metadata)

        assert str(err.value).startswith(
            f"Your metadata.csv should only contain a single row, but the\n"
            f"CSV in your transfer package contains {row_count} rows."
        )

    @pytest.mark.parametrize(
        "metadata",
        [
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
        ],
    )
    def test_checks_for_mandatory_columns(self, metadata):
        metadata = textwrap.dedent(metadata).strip()

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_has_dc_identifier(metadata=metadata)

        assert str(err.value).startswith(
            "Your metadata.csv is missing one of the mandatory columns ('filename'\n"
            "and 'dc.identifier'.)  Please add these columns to your metadata.csv,"
        )

    @pytest.mark.parametrize("filename", ["objects", "objects/cat.jpg", "cat.jpg"])
    def test_checks_filename_is_correct(self, filename):
        metadata = f"""filename,dc.identifier\n{filename},LE/MON"""

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_has_dc_identifier(metadata=metadata)

        assert str(err.value).startswith(
            "Your metadata.csv has an incorrect value in the 'filename' column.\n"
            "The value in this column should be 'objects/'."
        )

    @pytest.mark.parametrize(
        "metadata",
        [
            """
        filename,dc.identifier
        objects/,
        """,
            """
        filename,dc.identifier,dc.title
        objects/,,The Citrus Archives
        """,
        ],
    )
    def test_checks_dc_identifier_is_non_empty(self, metadata):
        metadata = textwrap.dedent(metadata).strip()

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_has_dc_identifier(metadata=metadata)

        assert str(err.value).startswith(
            "You have supplied an empty value in the 'dc.identifier' field of\n"
            "your metadata.csv."
        )

    @pytest.mark.parametrize(
        "metadata",
        [
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
        """,
        ],
    )
    def test_valid_metadata_is_okay(self, metadata):
        metadata = textwrap.dedent(metadata).strip()

        verify_metadata_csv_has_dc_identifier(metadata=metadata)


class TestVerifyMetadataCsvHasAccessionFields:
    @pytest.mark.parametrize(
        "metadata, row_count",
        [
            (
                """
        filename,dc.identifier
        objects/lemon.png,LE/MON/1
        objects/lemon_curd.jpg,LE/MON/2
        """,
                2,
            ),
            ("""filename,dc.identifier""", 0),
        ],
    )
    def test_only_contains_one_row(self, metadata, row_count):
        metadata = textwrap.dedent(metadata).strip()

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_has_accession_fields(metadata=metadata)

        assert str(err.value).startswith(
            f"Your metadata.csv should only contain a single row, but the\n"
            f"CSV in your transfer package contains {row_count} rows."
        )

    @pytest.mark.parametrize(
        "metadata",
        [
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
        ],
    )
    def test_checks_for_mandatory_columns(self, metadata):
        metadata = textwrap.dedent(metadata).strip()

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_has_accession_fields(metadata=metadata)

        assert str(err.value).startswith(
            "Your metadata.csv is missing one of the mandatory columns ('filename'\n"
            "'collection_reference', and 'accession_number'.)  Please add these"
        )

    @pytest.mark.parametrize("filename", ["objects", "objects/cat.jpg", "cat.jpg"])
    def test_checks_filename_is_correct(self, filename):
        metadata = (
            "filename,collection_reference,accession_number\n" f"{filename},LEMON,1234"
        )

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_has_accession_fields(metadata=metadata)

        assert str(err.value).startswith(
            "Your metadata.csv has an incorrect value in the 'filename' column.\n"
            "The value in this column should be 'objects/'."
        )

    @pytest.mark.parametrize(
        "metadata",
        [
            """
        filename,accession_number,collection_reference
        objects/,1234,
        """,
            """
        filename,accession_number,collection_reference
        objects/,,LEMON
        """,
            """
        filename,accession_number,collection_reference
        objects/,,
        """,
        ],
    )
    def test_checks_accession_fields_is_non_empty(self, metadata):
        metadata = textwrap.dedent(metadata).strip()

        with pytest.raises(VerificationFailure) as err:
            verify_metadata_csv_has_accession_fields(metadata=metadata)

        assert str(err.value).startswith(
            "You have supplied an empty value in the 'accession_number' or\n"
            "'collection_reference' fields of your metadata.csv."
        )

    @pytest.mark.parametrize(
        "metadata",
        [
            """
        filename,accession_number,collection_reference
        objects/,1,LEMON
        """,
            """
        filename,collection_reference,accession_number
        objects/,LEMON,1
        """,
            """
        filename,collection_reference,accession_number,dc.title
        objects/,LEMON,1,The Citrus Archives
        """,
        ],
    )
    def test_valid_metadata_is_okay(self, metadata):
        metadata = textwrap.dedent(metadata).strip()

        verify_metadata_csv_has_accession_fields(metadata=metadata)
