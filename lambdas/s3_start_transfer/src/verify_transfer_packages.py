"""
The Archivematica transfer format is a bit fiddly, and there are ways to get
it wrong that are non-obvious.

This runs some checks over the package before sending it to Archivematica.

It needs three things from the package:
*   The list of all files in the package (from zipfile.namelist())
*   The contents of ``metadata/metadata.csv`` (if present in the package)
*   The contents of ``metadata/rights.csv`` (if present in the package)

"""

import csv
import inspect
import io
import os
import textwrap


class VerificationFailure(Exception):
    def __init__(self, message):
        super().__init__(textwrap.dedent(message).strip())


def extract_csv(zip_file, path):
    try:
        csv_file = zip_file.open(path)
    except KeyError:
        return None
    else:
        try:
            csv_contents = csv_file.read().decode("utf8")
        except UnicodeDecodeError as err:
            raise VerificationFailure(
                f"""
                The ``{path}`` file in your transfer package is not valid UTF-8.

                Save the CSV using UTF-8 encoding, recompress the package, and
                upload it again.
                """
            ) from err

        # Replace any byte-order marks in the CSV, we don't need them.
        # These are sometimes written by Excel and the like, I think?
        if "\ufeff" in csv_contents:
            csv_contents = csv_contents.replace("\ufeff", "")

        return csv_contents


def extract_metadata(zip_file):
    return extract_csv(zip_file, "metadata/metadata.csv")


def extract_rights_metadata(zip_file):
    return extract_csv(zip_file, "metadata/rights.csv")


def verify_package(*, logger, zip_file, verifications):
    # Extract the zip file listing and metadata CSV contents for this transfer
    # package.
    file_listing = zip_file.namelist()

    logger.write(f"Running {len(verifications)} checks for {zip_file}")

    try:
        metadata = extract_metadata(zip_file)
        rights_metadata = extract_rights_metadata(zip_file)
    except VerificationFailure as err:
        logger.write("Check failed:\n")
        logger.write(str(err) + "\n")
        return False

    for i, verify_function in enumerate(verifications, start=1):
        logger.write(f"== Check {i}: {verify_function.__name__} ==")

        # This slightly hacky code is to get around the fact that not all
        # functions need both the file listing and the metadata, and rather
        # than have them take unused arguments, we build their signature
        # dynamically.  Dynamic programming, eh?
        kwargs = {}

        if "file_listing" in inspect.getfullargspec(verify_function).args:
            kwargs["file_listing"] = file_listing

        if "metadata" in inspect.getfullargspec(verify_function).args:
            kwargs["metadata"] = metadata

        if "rights_metadata" in inspect.getfullargspec(verify_function).args:
            kwargs["rights_metadata"] = rights_metadata

        try:
            verify_function(**kwargs)
        except VerificationFailure as err:
            logger.write("Check failed:\n")
            logger.write(str(err) + "\n")
            return False

    logger.write("All checks complete!")

    return True


def verify_all_files_not_under_single_dir(file_listing):
    common_path = os.path.commonpath(file_listing)
    if common_path:
        raise VerificationFailure(
            f"""
            All the files in your transfer package must be in the top level,
            not under a single folder.

            All the files in your package are under the single folder {common_path}.

            Recompress your transfer package with all the files at the top level,
            then upload it again.

            WRONG:

                transfer_package.zip
                  └─ LE/MON/
                       ├── recipe.txt
                       └── metadata/
                             └── metadata.csv

            RIGHT:

                transfer_package.zip
                  ├── recipe.txt
                  └── metadata/
                        ├── rights.csv
                        └── metadata.csv

            """
        )


def verify_all_files_not_under_objects_dir(file_listing):
    if all([f.startswith(("objects/", "metadata/")) for f in file_listing]):
        raise VerificationFailure(
            """
            You do not need to place the files in your transfer package under
            ``objects/`` (even though that's the prefix in ``metadata.csv``).

            Move your files up a level (out of ``objects``), recompress your
            transfer package, then upload it again.

            WRONG:

                transfer_package.zip
                  ├── objects/
                  │     ├── documents/
                  │     │     └── report.pdf
                  │     └── pictures/
                  │           ├── cat.jpg
                  │           └── dog.png
                  └── metadata/
                        └── metadata.csv

            RIGHT:

                transfer_package.zip
                  ├── documents/
                  │     └── report.pdf
                  ├── pictures/
                  │     ├── cat.jpg
                  │     └── dog.png
                  └── metadata/
                        └── metadata.csv

            """
        )


def verify_has_a_metadata_csv(file_listing):
    if "metadata/metadata.csv" not in file_listing:
        raise VerificationFailure(
            """
            Your transfer package must have a file ``metadata/metadata.csv``
            that describes the objects in the package.

            Add a metadata file, recompress your transfer package, then
            upload it again.

            Example metadata.csv:

                filename,dc.identifier
                objects/,LE/MON/1

            """
        )


def verify_only_metadata_and_rights_csv_in_metadata_dir(file_listing):
    metadata_files = {f for f in file_listing if f.startswith("metadata/")}

    unexpected_metadata_files = metadata_files - {
        "metadata/",
        "metadata/metadata.csv",
        "metadata/rights.csv",
    }

    if unexpected_metadata_files:
        raise VerificationFailure(
            """
            Your transfer package has unexpected files in the ``metadata/`` folder.
            The only file in ``metadata/`` should be ``metadata/metadata.csv``.

            Move the other files to a different directory, recompress your transfer
            package, then upload it again.

            WRONG:

                transfer_package.zip
                  └── metadata/
                        ├── cat.jpg
                        └── metadata.csv

            RIGHT:

                transfer_package.zip
                  ├── pictures/
                  │     └── cat.jpg
                  └── metadata/
                        └── metadata.csv

            (This is based on Wellcome's Archivematica workflow in winter 2019.

            This check is meant to prevent accidental mistakes.  If this is
            blocking a legitimate transfer -- you definitely want other things
            in metadata.csv -- you can trigger a transfer manually from the
            Archivematica dashboard, or talk to the devs if you want to permanently
            remove this check.)

            """
        )


RIGHTS_CSV_REQUIRED_COLUMNS = {"file", "basis"}
RIGHTS_CSV_OPTIONAL_COLUMNS = {
    "status",
    "determination_date",
    "start_date",
    "end_date",
    "jurisdiction",
    "terms",
    "citation",
    "note",
    "grant_act",
    "grant_restriction",
    "grant_start_date",
    "grant_end_date",
    "grant_note",
    "doc_id_type",
    "doc_id_value",
    "doc_id_role",
}
RIGHTS_CSV_ALLOWED_COLUMNS = RIGHTS_CSV_REQUIRED_COLUMNS | RIGHTS_CSV_OPTIONAL_COLUMNS
RIGHTS_CSV_ALLOWED_BASES = {
    "copyright",
    "donor",
    "license",
    "other",
    "policy",
    "statute",
}
RIGHTS_CSV_ALLOWED_GRANT_RESTRICTIONS = {"allow", "conditional", "disallow"}
RIGHTS_CSV_GRANT_COLUMNS = {
    "grant_act",
    "grant_restriction",
    "grant_start_date",
    "grant_end_date",
    "grant_note",
}
RIGHTS_CSV_REQUIRED_FIELDS_BY_BASIS = {
    "copyright": {"status", "jurisdiction"},
    "statute": {"citation", "jurisdiction"},
}


def verify_rights_csv_is_valid(rights_metadata, file_listing):
    if rights_metadata is None:
        return

    csv_reader = csv.DictReader(io.StringIO(rights_metadata))

    if csv_reader.fieldnames is None:
        raise VerificationFailure(
            """
            Your rights.csv is empty. It must have a header row and at least one
            row of rights information.
            """
        )

    duplicate_columns = {
        column
        for column in csv_reader.fieldnames
        if csv_reader.fieldnames.count(column) > 1
    }
    if duplicate_columns:
        raise VerificationFailure(
            f"""
            Your rights.csv has duplicate column headings: {', '.join(sorted(duplicate_columns))}.

            Each column heading may only appear once.
            """
        )

    supplied_columns = set(csv_reader.fieldnames)
    unexpected_columns = supplied_columns - RIGHTS_CSV_ALLOWED_COLUMNS
    if unexpected_columns:
        raise VerificationFailure(
            f"""
            Your rights.csv has unsupported column headings: {', '.join(sorted(unexpected_columns))}.

            See the transfer-package documentation for the supported columns.
            """
        )

    missing_columns = RIGHTS_CSV_REQUIRED_COLUMNS - supplied_columns
    if missing_columns:
        raise VerificationFailure(
            f"""
            Your rights.csv is missing mandatory column headings: {', '.join(sorted(missing_columns))}.

            Add the missing columns, then upload a new transfer package.
            """
        )

    package_files = {
        path
        for path in file_listing
        if not path.endswith("/") and not path.startswith("metadata/")
    }

    has_rights_information = False
    for row in csv_reader:
        has_rights_information = True
        line_number = csv_reader.line_num

        if row.get(None):
            raise VerificationFailure(
                f"""
                Line {line_number} of your rights.csv has more values than column
                headings.

                Check that every value containing a comma is quoted.
                """
            )

        for column in RIGHTS_CSV_REQUIRED_COLUMNS:
            if not (row.get(column) or "").strip():
                raise VerificationFailure(
                    f"""
                    Line {line_number} of your rights.csv has an empty '{column}' value.

                    The 'file' and 'basis' values are required for every row.
                    """
                )

        file_path = row["file"].strip()
        if not file_path.startswith("objects/"):
            raise VerificationFailure(
                f"""
                Line {line_number} of your rights.csv has an invalid file value:
                {row['file']}.

                The file path must begin with 'objects/'.
                """
            )

        package_path = file_path[len("objects/") :]
        if package_path not in package_files:
            raise VerificationFailure(
                f"""
                Line {line_number} of your rights.csv refers to a file that is not
                present in the transfer package: {file_path}.

                The 'file' value must identify a file in the package, using the
                'objects/' prefix.
                """
            )

        basis = row["basis"].strip().lower()
        if basis not in RIGHTS_CSV_ALLOWED_BASES:
            raise VerificationFailure(
                f"""
                Line {line_number} of your rights.csv has an unsupported basis: {row['basis']}.

                The basis must be one of: {', '.join(sorted(RIGHTS_CSV_ALLOWED_BASES))}.
                """
            )

        for column in RIGHTS_CSV_REQUIRED_FIELDS_BY_BASIS.get(basis, set()):
            if not (row.get(column) or "").strip():
                raise VerificationFailure(
                    f"""
                    Line {line_number} of your rights.csv is missing a '{column}' value.

                    It is required when the basis is '{basis}'.
                    """
                )

        supplied_grant_columns = {
            column
            for column in RIGHTS_CSV_GRANT_COLUMNS
            if (row.get(column) or "").strip()
        }
        if supplied_grant_columns and not {
            "grant_act",
            "grant_restriction",
        }.issubset(supplied_grant_columns):
            raise VerificationFailure(
                f"""
                Line {line_number} of your rights.csv has incomplete grant information.

                If any grant information is supplied, both 'grant_act' and
                'grant_restriction' must have values.
                """
            )

        restriction = (row.get("grant_restriction") or "").strip().lower()
        if restriction and restriction not in RIGHTS_CSV_ALLOWED_GRANT_RESTRICTIONS:
            raise VerificationFailure(
                f"""
                Line {line_number} of your rights.csv has an unsupported
                grant_restriction value: {row['grant_restriction']}.

                The value must be one of: {', '.join(sorted(RIGHTS_CSV_ALLOWED_GRANT_RESTRICTIONS))}.
                """
            )

    if not has_rights_information:
        raise VerificationFailure(
            """
            Your rights.csv has no rights information. Add at least one row, or
            remove the file from the transfer package.
            """
        )


def verify_metadata_csv_has_dc_identifier(metadata):
    reader = io.StringIO(metadata)

    csv_reader = csv.DictReader(reader)
    rows = list(csv_reader)

    if len(rows) != 1:
        raise VerificationFailure(
            f"""
            Your metadata.csv should only contain a single row, but the
            CSV in your transfer package contains {len(rows)} rows.

            Please upload a new transfer package with a single row in metadata.csv.

            WRONG:

                filename,dc.identifier
                objects/lemon.png,LE/MON/1
                objects/lemon_curd.jpg,LE/MON/2

            RIGHT:

                filename,dc.identifier
                objects/,LE/MON

            (This is a Wellcome policy decision, because we have a 1-to-1
            association between Archivematica transfer packages and item level
            records, so the metadata in metadata.csv comes from the item record.

            If you want multiple rows in metadata.csv, you can trigger a transfer
            manually from the Archivematica dashboard, or talk to the devs if you
            want to permanently remove this check.)
            """
        )

    metadata_row = rows[0]

    if "filename" not in metadata_row or "dc.identifier" not in metadata_row:
        raise VerificationFailure(
            """
            Your metadata.csv is missing one of the mandatory columns ('filename'
            and 'dc.identifier'.)  Please add these columns to your metadata.csv,
            then upload a new transfer package.

            You can have other columns beside these two, but you must *always*
            have both of these columns.

            WRONG:

                filename
                objects/

            RIGHT:

                filename,dc.identifier
                objects/,LE/MON

            RIGHT:

                filename,dc.identifier,dc.title
                objects/,LE/MON,The Citrus Archives

            """
        )

    if metadata_row["filename"] != "objects/":
        raise VerificationFailure(
            f"""
            Your metadata.csv has an incorrect value in the 'filename' column.
            The value in this column should be 'objects/'.

            Please correct this value, and upload a new transfer package.

            WRONG:

                filename,dc.identifier
                {metadata_row['filename']!r},LE/MON

            RIGHT:

                filename,dc.identifier
                objects/,LE/MON

            """
        )

    if not metadata_row["dc.identifier"]:
        raise VerificationFailure(
            f"""
            You have supplied an empty value in the 'dc.identifier' field of
            your metadata.csv.

            Please write a non-empty value in this field, and upload a new
            transfer package.

            WRONG:

                filename,dc.identifier,dc.title
                objects/,,The Citrus Archives

            RIGHT:

                filename,dc.identifier,dc.title
                objects/,LE/MON,The Citrus Archives

            """
        )


def verify_metadata_csv_has_accession_fields(metadata):
    reader = io.StringIO(metadata)

    csv_reader = csv.DictReader(reader)
    rows = list(csv_reader)

    if len(rows) != 1:
        raise VerificationFailure(
            f"""
            Your metadata.csv should only contain a single row, but the
            CSV in your transfer package contains {len(rows)} rows.

            Please upload a new transfer package with a single row in metadata.csv.

            WRONG:

                filename,collection_reference,accession_number
                objects/lemon.png,LEMON,1
                objects/lemon_curd.jpg,LEMON,1

            RIGHT:

                filename,collection_reference,accession_number
                objects/,LEMON,1

            (This is a Wellcome policy decision, because we have a 1-to-1
            association between Archivematica transfer packages and item level
            records, so the metadata in metadata.csv comes from the item record.

            If you want multiple rows in metadata.csv, you can trigger a transfer
            manually from the Archivematica dashboard, or talk to the devs if you
            want to permanently remove this check.)
            """
        )

    metadata_row = rows[0]

    if (
        "filename" not in metadata_row
        or "collection_reference" not in metadata_row
        or "accession_number" not in metadata_row
    ):
        raise VerificationFailure(
            """
            Your metadata.csv is missing one of the mandatory columns ('filename'
            'collection_reference', and 'accession_number'.)  Please add these
            columns to your metadata.csv, then upload a new transfer package.

            You can have other columns beside these three, but you must *always*
            have all of these columns.

            WRONG:

                filename
                objects/

            RIGHT:

                filename,collection_reference,accession_number
                objects/,LEMON,1

            RIGHT:

                filename,collection_reference,accession_number,dc.title
                objects/,LEMON,1,The Citrus Archives

            """
        )

    if metadata_row["filename"] != "objects/":
        raise VerificationFailure(
            f"""
            Your metadata.csv has an incorrect value in the 'filename' column.
            The value in this column should be 'objects/'.

            Please correct this value, and upload a new transfer package.

            WRONG:

                filename,collection_reference,accession_number
                {metadata_row['filename']!r},LEMON,1

            RIGHT:

                filename,collection_reference,accession_number
                objects/,LEMON,1

            """
        )

    if not metadata_row["accession_number"] or not metadata_row["collection_reference"]:
        raise VerificationFailure(
            f"""
            You have supplied an empty value in the 'accession_number' or
            'collection_reference' fields of your metadata.csv.

            Please write a non-empty value in these fields, and upload a new
            transfer package.

            WRONG:

                filename,collection_reference,accession_number
                objects/,,1

            WRONG:

                filename,collection_reference,accession_number
                objects/,LEMON,

            RIGHT:

                filename,collection_reference,accession_number
                objects/,LEMON,1

            """
        )
