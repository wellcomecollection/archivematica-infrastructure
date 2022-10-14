import io
import os
import zipfile

import boto3


def create_test_package():
    """
    Create a zipfile test package.  Returns the bytes of the zip.
    """
    # We write to a stream rather than a file because Lambda runs in a
    # read-only filesystem.
    stream = io.BytesIO()

    package_dir = os.path.abspath(os.path.dirname(__file__))

    with zipfile.ZipFile(stream, "w") as zf:
        zf.write(
            os.path.join(package_dir, "metadata.csv"), arcname="metadata/metadata.csv"
        )
        zf.write(os.path.join(package_dir, "manchineel.png"), arcname="manchineel.png")

    stream.seek(0)
    return stream.read()


def main(event, _):
    upload_bucket = os.environ["UPLOAD_BUCKET"]

    zip_bytes = create_test_package()
    print(f"Created test transfer package")

    upload_key = "born-digital/test_package.zip"

    s3 = boto3.client("s3")
    s3.put_object(Bucket=upload_bucket, Key=upload_key, Body=zip_bytes)
    print(f"Uploaded package to S3 at s3://{upload_bucket}/{upload_key}")
