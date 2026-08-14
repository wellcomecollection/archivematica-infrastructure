# -*- encoding: utf-8

import csv
import io
import zipfile

import pytest

from log_handler import Logger
from verify_transfer_packages import (
    VerificationFailure,
    verify_package,
    verify_rights_csv_is_valid,
)


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
    "copyright": {
        "status": "copyrighted",
        "jurisdiction": "GB",
        "note": "In copyright",
        "grant_act": "disseminate",
        "grant_note": "Open",
    },
    "license": {
        "note": "CC-BY",
        "grant_act": "disseminate",
        "grant_note": "Open",
    },
    "statute": {"citation": "Example Act 2026", "jurisdiction": "GB"},
}


class TestVerifyRightsCsv:
    file_path = "objects/reports/summary.pdf"
    file_listing = ["reports/summary.pdf", "metadata/rights.csv"]
    valid_rights_metadata = """\
file,basis,status,jurisdiction,note,grant_act,grant_note
objects/reports/summary.pdf,copyright,copyrighted,GB,In copyright,disseminate,Open
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
                _RIGHTS_REQUIRED_FIELDS_BY_BASIS["copyright"],
                id="copyright",
            ),
            pytest.param("donor", {}, id="donor"),
            pytest.param(
                "license",
                _RIGHTS_REQUIRED_FIELDS_BY_BASIS["license"],
                id="license",
            ),
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
                "note": "All Rights Reserved",
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
                **_RIGHTS_REQUIRED_FIELDS_BY_BASIS["license"],
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
            ("grant_restriction", "allow"),
            ("grant_start_date", "2026-01-01"),
            ("grant_end_date", "2026-12-31"),
            ("grant_note", "Only in the reading room"),
        ],
    )
    def test_grant_details_require_an_act(self, grant_column, value):
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
        "grant_values",
        [
            pytest.param({"grant_act": "disseminate"}, id="act-only"),
            pytest.param(
                {
                    "grant_act": "disseminate",
                    "grant_note": "Only in the reading room",
                },
                id="act-and-note",
            ),
        ],
    )
    def test_grant_restriction_is_optional(self, grant_values):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": "policy",
                **grant_values,
            }
        )

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    @pytest.mark.parametrize(
        "grant_date, value",
        [
            pytest.param("grant_start_date", "2026-01-01", id="start-date"),
            pytest.param("grant_end_date", "2026-12-31", id="end-date"),
        ],
    )
    def test_grant_dates_require_a_restriction(self, grant_date, value):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": "policy",
                "grant_act": "disseminate",
                grant_date: value,
            }
        )

        with pytest.raises(VerificationFailure, match="grant dates without"):
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )

    def test_accepts_grant_dates_with_a_restriction(self):
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": "policy",
                "grant_act": "disseminate",
                "grant_restriction": "conditional",
                "grant_start_date": "2026-01-01",
                "grant_end_date": "2026-12-31",
            }
        )

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    @pytest.mark.parametrize(
        "basis, missing_field",
        [
            pytest.param(basis, field, id=f"{basis}-{field}")
            for basis, values in _RIGHTS_REQUIRED_FIELDS_BY_BASIS.items()
            for field in values
        ],
    )
    def test_requires_basis_specific_fields(self, basis, missing_field):
        required_values = _RIGHTS_REQUIRED_FIELDS_BY_BASIS[basis].copy()
        required_values.pop(missing_field)
        rights_metadata = _make_rights_csv(
            {
                "file": self.file_path,
                "basis": basis,
                **required_values,
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
        "basis, note",
        [
            pytest.param("copyright", "In copyright", id="in-copyright"),
            pytest.param(
                "copyright",
                "All Rights Reserved",
                id="all-rights-reserved",
            ),
            pytest.param("license", "CC-0", id="cc-0"),
            pytest.param("license", "CC-BY", id="cc-by"),
            pytest.param("license", "CC-BY-NC", id="cc-by-nc"),
            pytest.param("license", "CC-BY-NC-ND", id="cc-by-nc-nd"),
            pytest.param("license", "CC-BY-NC-SA", id="cc-by-nc-sa"),
            pytest.param("license", "CC-BY-SA", id="cc-by-sa"),
            pytest.param("license", "OGL", id="ogl"),
            pytest.param("license", "OPL", id="opl"),
            pytest.param("license", "PDM", id="pdm"),
        ],
    )
    def test_accepts_wellcome_rights_note_codes(self, basis, note):
        rights_values = {
            "file": self.file_path,
            "basis": basis,
            **_RIGHTS_REQUIRED_FIELDS_BY_BASIS[basis],
            "note": note,
        }
        rights_metadata = _make_rights_csv(rights_values)

        verify_rights_csv_is_valid(
            rights_metadata=rights_metadata,
            file_listing=self.file_listing,
        )

    @pytest.mark.parametrize(
        "basis, note",
        [
            pytest.param("copyright", "Copyright statement", id="copyright"),
            pytest.param("license", "cc-by", id="license-wrong-case"),
            pytest.param("license", "CC-BY-ND", id="license-unsupported-code"),
        ],
    )
    def test_rejects_unsupported_wellcome_rights_note_codes(self, basis, note):
        rights_values = {
            "file": self.file_path,
            "basis": basis,
            **_RIGHTS_REQUIRED_FIELDS_BY_BASIS[basis],
            "note": note,
        }
        rights_metadata = _make_rights_csv(rights_values)

        with pytest.raises(VerificationFailure, match="unsupported note"):
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
        field_value = _RIGHTS_BASIS_FIELD_VALUES[field]
        if field == "note" and field in _RIGHTS_REQUIRED_FIELDS_BY_BASIS.get(basis, {}):
            field_value = _RIGHTS_REQUIRED_FIELDS_BY_BASIS[basis][field]

        rights_values = {
            "file": self.file_path,
            "basis": basis,
            **_RIGHTS_REQUIRED_FIELDS_BY_BASIS.get(basis, {}),
            field: field_value,
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
                **_RIGHTS_REQUIRED_FIELDS_BY_BASIS["copyright"],
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
            pytest.param(
                (
                    {
                        "file": "objects/reports/summary.pdf",
                        "basis": "policy",
                        "grant_act": "ß",
                        "grant_restriction": "allow",
                    },
                    {
                        "file": "objects/reports/summary.pdf",
                        "basis": "policy",
                        "grant_act": "ss",
                        "grant_restriction": "allow",
                    },
                ),
                id="importer-unicode-normalization",
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

    def test_csv_parser_errors_are_verification_failures(self):
        rights_metadata = (
            "file,basis,note\n"
            "objects/reports/summary.pdf,policy,"
            f"{'a' * 131_073}\n"
        )

        with pytest.raises(
            VerificationFailure,
            match="Line 2 of your rights.csv could not be read as CSV",
        ) as err:
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )

        assert isinstance(err.value.__cause__, csv.Error)

    @pytest.mark.parametrize(
        "rights_metadata, line_number, missing_value",
        [
            pytest.param(
                "file,basis,note\nobjects/reports/summary.pdf,policy\n",
                2,
                "note",
                id="ordinary-row",
            ),
            pytest.param(
                'file,basis,note\nobjects/reports/summary.pdf,policy,"First\n'
                'line"\nobjects/reports/summary.pdf,policy\n',
                4,
                "note",
                id="after-multiline-row",
            ),
        ],
    )
    def test_rejects_rows_with_missing_trailing_values(
        self,
        rights_metadata,
        line_number,
        missing_value,
    ):
        with pytest.raises(
            VerificationFailure,
            match=f"Line {line_number} of your rights.csv has fewer values",
        ) as err:
            verify_rights_csv_is_valid(
                rights_metadata=rights_metadata,
                file_listing=self.file_listing,
            )

        assert f"Missing values: {missing_value}." in str(err.value)

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
