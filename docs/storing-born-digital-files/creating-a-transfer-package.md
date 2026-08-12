# Creating a transfer package

A **transfer package** is a zip file containing the born-digital files you want to store, plus some metadata.

The files can be in any structure, including folders and subfolders.

![An example transfer package.
There's a folder called "transfer\_package", which contains three images and a folder called "metadata".
The metadata folder contains a single file, metadata.csv.](../howto/transfer_package.png)

The metadata files **must** be stored in a top-level folder called `metadata`.

## Metadata files

We use two metadata files in our transfer packages.
Both files must use UTF-8 encoding:

*   `metadata.csv`, which contains the identifier.

    If it's a catalogued package, the CSV should have two columns and the catalogue identifier in `dc.identifier`:

    ```csv
    filename,dc.identifier
    objects/,PP/MDM/A/3/1a
    ```

    If it's an accession, the CSV should have three columns and the accession number in `accession_number`:

    ```csv
    filename,collection_reference,accession_number
    objects/,SA/TIH,2314_2
    ```

    In both cases, the CSV only ever has `objects/` as the filename.
*   `rights.csv`, which is optional and describes the rights attached to individual files.

    The file must use UTF-8 without a byte-order mark (BOM).
    The file must have a header row and at least one row of rights information.
    Every row must have a `file` and `basis` value.
    The `file` must identify a file in the transfer package and use its Archivematica path, beginning with `objects/`.
    The supported bases are `copyright`, `donor`, `license`, `other`, `policy`, and `statute`.

    For a copyright basis, `status` and `jurisdiction` are also required.
    Copyright rows may also have `determination_date`, `start_date`, `end_date`, and `note` values.
    A copyright `end_date` must be a date or empty and cannot be `open`.
    For a donor, other, or policy basis, rows may have `start_date`, `end_date`, and `note` values.
    For a license basis, rows may have `start_date`, `end_date`, `terms`, and `note` values.
    For a statute basis, `citation` and `jurisdiction` are required.
    Statute rows may also have `determination_date`, `start_date`, `end_date`, and `note` values.
    Basis-specific fields not listed for the selected basis must be empty because Archivematica would discard them.
    If any grant information is supplied, both `grant_act` and `grant_restriction` must have values.
    The restriction must be `allow`, `conditional`, or `disallow`.
    If any documentation identifier information is supplied, both `doc_id_type` and `doc_id_value` must have values.
    The `doc_id_role` value is optional.
    Each combination of `file`, `basis`, and `grant_act` may appear only once after surrounding whitespace and letter case are normalized.

    The optional columns are `status`, `determination_date`, `start_date`, `end_date`, `jurisdiction`, `terms`, `citation`, `note`, `grant_act`, `grant_restriction`, `grant_start_date`, `grant_end_date`, `grant_note`, `doc_id_type`, `doc_id_value`, and `doc_id_role`.
    No other columns are accepted.

    For example, this applies a copyright statement to a file and disallows dissemination:

    ```csv
    file,basis,status,jurisdiction,grant_act,grant_restriction
    objects/reports/summary.pdf,copyright,copyrighted,GB,disseminate,disallow
    ```

## Compressing the package

The files **must** be in the top-level of the zip; there can't be an enclosing folder.

| ❌                                                                                                                                    | ✅                                                                                                                                  |
| ------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| ![Selecting the enclosing folder, then right-clicking and 'Compress folder', in the macOS Finder](../howto/transfer_package_bad.png) | ![Selecting all the top-level files, then right-clicking and 'Compress', in the macOS Finder.](../howto/transfer_package_good.png) |

## See also

[Transfer in the Archivematica documentation](https://www.archivematica.org/en/docs/archivematica-1.13/user-manual/transfer/transfer/#prepare-transfer) – we use the "zipped directory" transfer type.
