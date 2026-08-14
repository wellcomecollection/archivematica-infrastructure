# -*- encoding: utf-8

import io
import pathlib
import zipfile

import pytest

from log_handler import Logger
from verify_transfer_packages import (
    VerificationFailure,
    verify_all_files_not_under_objects_dir,
    verify_all_files_not_under_single_dir,
    verify_has_a_metadata_csv,
    verify_metadata_csv_has_dc_identifier,
    verify_only_metadata_and_rights_csv_in_metadata_dir,
    verify_package,
    verify_rights_csv_is_valid,
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
        verify_only_metadata_and_rights_csv_in_metadata_dir,
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

    @pytest.mark.parametrize("path", ["metadata/metadata.csv", "metadata/rights.csv"])
    def test_invalid_csv_encoding_is_logged_as_a_verification_failure(self, path):
        contents = io.BytesIO()
        with zipfile.ZipFile(contents, "w") as zf:
            metadata = b"filename,dc.identifier\nobjects/,LEMON\n"
            if path == "metadata/metadata.csv":
                metadata = b"filename,dc.identifier\nobjects/,\xff\n"
            zf.writestr("metadata/metadata.csv", metadata)

            if path == "metadata/rights.csv":
                zf.writestr(path, b"file,basis\nobjects/report.txt,pol\xffcy\n")

        contents.seek(0)
        logger = Logger()
        with zipfile.ZipFile(contents) as zf:
            assert not verify_package(logger=logger, zip_file=zf, verifications=[])

        assert f"The ``{path}`` file" in logger.text()
        assert "Save the CSV using UTF-8 encoding" in logger.text()

    def test_rights_csv_byte_order_mark_is_logged_as_a_failure(self):
        contents = io.BytesIO()
        with zipfile.ZipFile(contents, "w") as zf:
            zf.writestr(
                "metadata/metadata.csv",
                b"filename,dc.identifier\nobjects/,LEMON\n",
            )
            zf.writestr(
                "metadata/rights.csv",
                b"\xef\xbb\xbffile,basis\nobjects/report.txt,policy\n",
            )

        contents.seek(0)
        logger = Logger()
        with zipfile.ZipFile(contents) as zf:
            assert not verify_package(logger=logger, zip_file=zf, verifications=[])

        assert "byte-order mark (BOM)" in logger.text()
        assert "Save the CSV using UTF-8 without a BOM" in logger.text()

    def test_rights_csv_accepts_byte_order_mark_character_in_a_value(self):
        contents = io.BytesIO()
        with zipfile.ZipFile(contents, "w") as zf:
            zf.writestr(
                "metadata/rights.csv",
                "file,basis,note\nobjects/report.txt,policy,\ufeff\n",
            )
            zf.writestr("report.txt", b"")

        contents.seek(0)
        with zipfile.ZipFile(contents) as zf:
            assert verify_package(
                logger=Logger(),
                zip_file=zf,
                verifications=[verify_rights_csv_is_valid],
            )


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
            "that describes the objects in the package."
        )

    @pytest.mark.parametrize(
        "name", ["valid_transfer_package.zip", "multi_top_level_dir.zip"]
    )
    def test_valid_transfer_package_is_okay(self, name):
        file_listing = _get_file_listing(name)
        verify_has_a_metadata_csv(file_listing=file_listing)


class TestVerifyOnlyMetadataAndRightsCsvInMetadataDir:
    @pytest.mark.parametrize("name", ["extra_files_in_metadata_dir.zip"])
    def test_extra_files_in_metadata_dir_is_exception(self, name):
        file_listing = _get_file_listing(name)

        with pytest.raises(VerificationFailure) as err:
            verify_only_metadata_and_rights_csv_in_metadata_dir(
                file_listing=file_listing
            )

        assert str(err.value).startswith(
            "Your transfer package has unexpected files in the ``metadata/`` folder.\n"
            "The only files allowed in ``metadata/`` are ``metadata/metadata.csv``\n"
            "and the optional ``metadata/rights.csv``."
        )

    @pytest.mark.parametrize(
        "name", ["valid_transfer_package.zip", "multi_top_level_dir.zip"]
    )
    def test_valid_transfer_package_is_okay(self, name):
        file_listing = _get_file_listing(name)
        verify_only_metadata_and_rights_csv_in_metadata_dir(file_listing=file_listing)

    def test_rights_csv_is_okay(self):
        file_listing = [
            "metadata/",
            "metadata/metadata.csv",
            "metadata/rights.csv",
        ]
        verify_only_metadata_and_rights_csv_in_metadata_dir(file_listing=file_listing)
