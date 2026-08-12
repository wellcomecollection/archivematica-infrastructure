# -*- encoding: utf-8

import csv
import io
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
    verify_only_metadata_and_rights_csv_in_metadata_dir,
    verify_rights_csv_is_valid,
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


def _make_rights_csv(*rows, lineterminator="\n"):
    fieldnames = list(dict.fromkeys(key for row in rows for key in row))
    contents = io.StringIO(newline="")
    writer = csv.DictWriter(
        contents,
        fieldnames=fieldnames,
        lineterminator=lineterminator,
    )
    writer.writeheader()
    writer.writerows(rows)
    return contents.getvalue()


_RIGHTS_BASIS_FIELD_VALUES = {
    "status": "copyrighted",
    "determination_date": "2026-01-01",
    "start_date": "2026-01-01",
    "end_date": "2026-12-31",
    "jurisdiction": "GB",
    "terms": "Example licence terms",
    "citation": "Example Act 2026",
    "note": "Example rights note",
}
_RIGHTS_PERSISTED_FIELDS_BY_BASIS = {
    "copyright": (
        "status",
        "determination_date",
        "start_date",
        "end_date",
        "jurisdiction",
        "note",
    ),
    "donor": ("start_date", "end_date", "note"),
    "license": ("start_date", "end_date", "terms", "note"),
    "other": ("start_date", "end_date", "note"),
    "policy": ("start_date", "end_date", "note"),
    "statute": (
        "determination_date",
        "start_date",
        "end_date",
        "jurisdiction",
        "citation",
        "note",
    ),
}
_RIGHTS_REQUIRED_FIELDS_BY_BASIS = {
    "copyright": {"status": "copyrighted", "jurisdiction": "GB"},
    "statute": {"citation": "Example Act 2026", "jurisdiction": "GB"},
}


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

    @pytest.mark.parametrize(
        "rights_metadata",
        [
            pytest.param(
                b"\xef\xbb\xbffile,basis\nobjects/report.txt,policy\n",
                id="leading-bom",
            ),
            pytest.param(
                b"file,basis,note\nobjects/report.txt,policy,\xef\xbb\xbf\n",
                id="embedded-bom",
            ),
        ],
    )
    def test_rights_csv_byte_order_mark_is_logged_as_a_failure(self, rights_metadata):
        contents = io.BytesIO()
        with zipfile.ZipFile(contents, "w") as zf:
            zf.writestr(
                "metadata/metadata.csv",
                b"filename,dc.identifier\nobjects/,LEMON\n",
            )
            zf.writestr("metadata/rights.csv", rights_metadata)

        contents.seek(0)
        logger = Logger()
        with zipfile.ZipFile(contents) as zf:
            assert not verify_package(logger=logger, zip_file=zf, verifications=[])

        assert "byte-order mark (BOM)" in logger.text()
        assert "Save the CSV using UTF-8 without a BOM" in logger.text()


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


class TestVerifyRightsCsv:
    file_path = "objects/reports/summary.pdf"
    file_listing = ["reports/summary.pdf", "metadata/rights.csv"]
    valid_rights_metadata = """\
file,basis,status,jurisdiction,grant_act,grant_restriction
objects/reports/summary.pdf,copyright,copyrighted,GB,disseminate,disallow
"""

    def test_rights_csv_is_optional(self):
        verify_rights_csv_is_valid(rights_metadata=None, file_listing=[])

    def test_valid_rights_csv_is_okay(self):
        verify_rights_csv_is_valid(
            rights_metadata=self.valid_rights_metadata,
            file_listing=self.file_listing,
        )

    @pytest.mark.parametrize(
        "basis, extra_values",
        [
            pytest.param(
                "copyright",
                {"status": "copyrighted", "jurisdiction": "GB"},
                id="copyright",
            ),
            pytest.param("donor", {}, id="donor"),
            pytest.param("license", {}, id="license"),
            pytest.param("other", {}, id="other"),
            pytest.param("policy", {}, id="policy"),
            pytest.param(
                "statute",
                {"citation": "Example Act 2026", "jurisdiction": "GB"},
                id="statute",
            ),
        ],
    )
    def test_accepts_supported_bases(self, basis, extra_values):
        rights_metadata = _make_rights_csv(
            {"file": self.file_path, "basis": basis, **extra_values}
        )

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    @pytest.mark.parametrize("restriction", ["allow", "conditional", "disallow"])
    def test_accepts_supported_grant_restrictions(self, restriction):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": "policy",
                "grant_act": "disseminate",
                "grant_restriction": restriction,
            }
        )

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    @pytest.mark.parametrize("role", [None, "source"])
    def test_accepts_complete_documentation_identifier(self, role):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": "policy",
                "doc_id_type": "URL",
                "doc_id_value": "https://example.com/rights",
                "doc_id_role": role,
            }
        )

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    def test_accepts_complete_rights_metadata(self):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": "copyright",
                "status": "copyrighted",
                "determination_date": "2026-01-01",
                "start_date": "2026-01-01",
                "end_date": "2026-12-31",
                "jurisdiction": "GB",
                "note": "Copyright statement",
                "grant_act": "disseminate",
                "grant_restriction": "disallow",
                "grant_start_date": "2026-01-01",
                "grant_end_date": "open",
                "grant_note": "Reading room only",
                "doc_id_type": "URL",
                "doc_id_value": "https://example.com/rights",
                "doc_id_role": "source",
            },
            {
                "file": self.file_path,
                "basis": "license",
                "terms": "Example licence terms",
            },
            {
                "file": self.file_path,
                "basis": "statute",
                "citation": "Example Act 2026",
                "jurisdiction": "GB",
            },
        )

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    def test_rights_csv_is_passed_to_package_verification(self):
        contents = io.BytesIO()
        with zipfile.ZipFile(contents, "w") as zf:
            zf.writestr("metadata/rights.csv", self.valid_rights_metadata)
            zf.writestr("reports/summary.pdf", b"")

        contents.seek(0)
        with zipfile.ZipFile(contents) as zf:
            assert verify_package(
                logger=Logger(),
                zip_file=zf,
                verifications=[verify_rights_csv_is_valid],
            )

    def test_accepts_unicode_and_quoted_multiline_values(self):
        first_path = "reports/Résumé, final.txt"
        second_path = "reports/報告.txt"
        rights_metadata = _make_rights_csv(
            {
                "file": f"objects/{first_path}",
                "basis": "policy",
                "note": "First line, with comma\nand second line",
            },
            {"file": f"objects/{second_path}", "basis": "policy"},
        )

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=[first_path, second_path],
        )

    @pytest.mark.parametrize("lineterminator", ["\r\n", "\r"])
    def test_accepts_supported_newlines(self, lineterminator):
        rights_metadata = _make_rights_csv(
            {"file": self.file_path, "basis": "policy"},
            lineterminator=lineterminator,
        )

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    @pytest.mark.parametrize(
        "file_listing, file_path",
        [
            (["reports/summary.pdf"], "objects/reports/missing.pdf"),
            (["reports/"], "objects/reports/"),
            (["metadata/rights.csv"], "objects/metadata/rights.csv"),
        ],
    )
    def test_file_must_resolve_to_an_imported_file(self, file_listing, file_path):
        rights_metadata = f"file,basis\n{file_path},policy\n"

        with pytest.raises(VerificationFailure, match="refers to a file"):
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=file_listing,
            )

    @pytest.mark.parametrize(
        "grant_column, value",
        [
            ("grant_act", "disseminate"),
            ("grant_restriction", "allow"),
            ("grant_start_date", "2026-01-01"),
            ("grant_end_date", "2026-12-31"),
            ("grant_note", "Only in the reading room"),
        ],
    )
    def test_grant_fields_must_be_paired(self, grant_column, value):
        rights_metadata = (
            f"file,basis,{grant_column}\n"
            f"objects/reports/summary.pdf,policy,{value}\n"
        )

        with pytest.raises(VerificationFailure, match="incomplete grant information"):
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )

    @pytest.mark.parametrize(
        "basis, supplied_field, supplied_value, missing_field",
        [
            ("copyright", "status", "copyrighted", "jurisdiction"),
            ("copyright", "jurisdiction", "GB", "status"),
            ("statute", "citation", "Example Act 2026", "jurisdiction"),
            ("statute", "jurisdiction", "GB", "citation"),
        ],
    )
    def test_requires_basis_specific_fields(
        self,
        basis,
        supplied_field,
        supplied_value,
        missing_field,
    ):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": basis,
                supplied_field: supplied_value,
            }
        )

        with pytest.raises(
            VerificationFailure,
            match=f"missing a '{missing_field}' value",
        ):
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )

    @pytest.mark.parametrize(
        "basis, field",
        [
            pytest.param(basis, field, id=f"{basis}-{field}")
            for basis, fields in _RIGHTS_PERSISTED_FIELDS_BY_BASIS.items()
            for field in fields
        ],
    )
    def test_accepts_fields_persisted_for_basis(self, basis, field):
        rights_values = {
            "file": self.file_path,
            "basis": basis,
            **_RIGHTS_REQUIRED_FIELDS_BY_BASIS.get(basis, {}),
            field: _RIGHTS_BASIS_FIELD_VALUES[field],
        }
        rights_metadata = _make_rights_csv(rights_values)

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    @pytest.mark.parametrize(
        "basis, field",
        [
            pytest.param(basis, field, id=f"{basis}-{field}")
            for basis, persisted_fields in _RIGHTS_PERSISTED_FIELDS_BY_BASIS.items()
            for field in sorted(
                _RIGHTS_BASIS_FIELD_VALUES.keys() - set(persisted_fields)
            )
        ],
    )
    def test_rejects_fields_discarded_for_basis(self, basis, field):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": basis,
                **_RIGHTS_REQUIRED_FIELDS_BY_BASIS.get(basis, {}),
                field: _RIGHTS_BASIS_FIELD_VALUES[field],
            }
        )

        with pytest.raises(VerificationFailure) as err:
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )

        assert "has fields that do not apply" in str(err.value)
        assert f"to the '{basis}' basis: {field}" in str(err.value)

    @pytest.mark.parametrize("end_date", ["open", "OPEN", " open "])
    def test_rejects_open_copyright_end_date(self, end_date):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": "copyright",
                "status": "copyrighted",
                "jurisdiction": "GB",
                "end_date": end_date,
            }
        )

        with pytest.raises(VerificationFailure, match="cannot use 'open'"):
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )

    @pytest.mark.parametrize(
        "basis", ["donor", "license", "other", "policy", "statute"]
    )
    def test_accepts_open_end_date_for_other_bases(self, basis):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": basis,
                **_RIGHTS_REQUIRED_FIELDS_BY_BASIS.get(basis, {}),
                "end_date": "open",
            }
        )

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    @pytest.mark.parametrize(
        "documentation_values",
        [
            pytest.param({"doc_id_type": "URL"}, id="type-only"),
            pytest.param(
                {"doc_id_value": "https://example.com/rights"},
                id="value-only",
            ),
            pytest.param({"doc_id_role": "source"}, id="role-only"),
            pytest.param(
                {"doc_id_type": "URL", "doc_id_role": "source"},
                id="type-and-role",
            ),
            pytest.param(
                {
                    "doc_id_value": "https://example.com/rights",
                    "doc_id_role": "source",
                },
                id="value-and-role",
            ),
        ],
    )
    def test_documentation_identifier_requires_type_and_value(
        self, documentation_values
    ):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": "policy",
                **documentation_values,
            }
        )

        with pytest.raises(VerificationFailure) as err:
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )

        assert "has incomplete documentation" in str(err.value)
        assert "identifier information" in str(err.value)

    @pytest.mark.parametrize(
        "rows",
        [
            pytest.param(
                (
                    {"file": "objects/reports/summary.pdf", "basis": "policy"},
                    {"file": "objects/reports/summary.pdf", "basis": "policy"},
                ),
                id="exact-without-grant-act",
            ),
            pytest.param(
                (
                    {
                        "file": "objects/reports/summary.pdf",
                        "basis": "Policy",
                        "grant_act": "Disseminate",
                        "grant_restriction": "Allow",
                    },
                    {
                        "file": " objects/reports/summary.pdf ",
                        "basis": " policy ",
                        "grant_act": " disseminate ",
                        "grant_restriction": " allow ",
                    },
                ),
                id="normalized-with-grant-act",
            ),
        ],
    )
    def test_rejects_duplicate_importer_combinations(self, rows):
        rights_metadata = _make_rights_csv(*rows)

        with pytest.raises(
            VerificationFailure,
            match="duplicates a file, basis,",
        ):
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )

    def test_accepts_different_grant_acts_for_same_file_and_basis(self):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": "policy",
                "grant_act": "disseminate",
                "grant_restriction": "allow",
            },
            {
                "file": self.file_path,
                "basis": "policy",
                "grant_act": "delete",
                "grant_restriction": "allow",
            },
        )

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    @pytest.mark.parametrize(
        "rights_metadata, line_number",
        [
            (
                "file,basis\n\nobjects/reports/summary.pdf,unknown\n",
                3,
            ),
            (
                'file,basis,note\nobjects/reports/summary.pdf,policy,"First\n'
                'line"\nobjects/reports/summary.pdf,unknown,\n',
                4,
            ),
        ],
    )
    def test_reports_physical_line_number(self, rights_metadata, line_number):
        with pytest.raises(
            VerificationFailure,
            match=f"Line {line_number} of your rights.csv has an unsupported basis",
        ):
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )

    @pytest.mark.parametrize(
        "rights_metadata, message",
        [
            ("", "Your rights.csv is empty."),
            ("file,basis\n", "Your rights.csv has no rights information."),
            (
                "file,basis,basis\n" "objects/reports/summary.pdf,policy,policy\n",
                "Your rights.csv has duplicate column headings: basis.",
            ),
            (
                "file,status\nobjects/reports/summary.pdf,copyrighted\n",
                "Your rights.csv is missing mandatory column headings: basis.",
            ),
            (
                "basis\npolicy\n",
                "Your rights.csv is missing mandatory column headings: file.",
            ),
            (
                "file,basis,unsupported\nobjects/reports/summary.pdf,policy,x\n",
                "Your rights.csv has unsupported column headings: unsupported.",
            ),
            (
                "file,basis\nobjects/reports/summary.pdf,policy,extra\n",
                "Line 2 of your rights.csv has more values than column",
            ),
            (
                "file,basis\n,policy\n",
                "Line 2 of your rights.csv has an empty 'file' value.",
            ),
            (
                "file,basis\nobjects/reports/summary.pdf,\n",
                "Line 2 of your rights.csv has an empty 'basis' value.",
            ),
            (
                "file,basis\nreports/summary.pdf,policy\n",
                "Line 2 of your rights.csv has an invalid file value:",
            ),
            (
                "file,basis\nobjects/reports/summary.pdf,unknown\n",
                "Line 2 of your rights.csv has an unsupported basis: unknown.",
            ),
            (
                "file,basis,grant_act,grant_restriction\n"
                "objects/reports/summary.pdf,policy,disseminate,maybe\n",
                "Line 2 of your rights.csv has an unsupported",
            ),
        ],
    )
    def test_rejects_invalid_rights_csv(self, rights_metadata, message):
        with pytest.raises(VerificationFailure, match=message):
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )


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
            f"filename,collection_reference,accession_number\n{filename},LEMON,1234"
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
