# How to create a transfer package

A **transfer package** is a zip file containing the born-digital files you want to store, plus some metadata.

The files can be in any structure, including folders and subfolders.

![An example transfer package. There's a folder called "transfer_package", which contains three images and a folder called "metadata". The metadata folder contains a single file, metadata.csv.](transfer_package.png)

The metadata files **must** be stored in a top-level folder called `metadata`.

## Metadata files

There are two metadata files:

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

*   `rights.csv`, which contains the rights information.

    [**TODO:** Document how this file is structured. See <https://github.com/wellcomecollection/archivematica-infrastructure/issues/113>]

## Compressing the package

The files **must** be in the top-level of the zip; there can't be an enclosing folder.

<table>
<tr>
<th>❌</th>
<th>✅</th>
</tr>
<tr>
<td><img src="transfer_package_bad.png" alt="Selecting the enclosing folder, then right-clicking and 'Compress folder', in the macOS Finder"></td>
<td><img src="transfer_package_good.png" alt="Selecting all the top-level files, then right-clicking and 'Compress', in the macOS Finder."></td>
</tr>
</table>
