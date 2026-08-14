# -*- encoding: utf-8

import textwrap

import pytest

from verify_transfer_packages import (
    VerificationFailure,
    verify_metadata_csv_has_accession_fields,
    verify_metadata_csv_has_dc_identifier,
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
