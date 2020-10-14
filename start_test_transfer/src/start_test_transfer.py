import os
import zipfile

import boto3


def create_test_package():
    """
    Create a zipfile test package.
    """
    package_dir = os.path.abspath(os.path.dirname(__file__))

    with zipfile.ZipFile("transfer_package.zip", "w") as zf:
        for name in ("metadata/metadata.csv", "manchineel.png"):
            zf.write(os.path.join(package_dir, "test_package", name), arcname=name)

    return "transfer_package.zip"


def main(event, _):
    upload_bucket = os.environ["UPLOAD_BUCKET"]

    package_path = create_test_package()
    print(f"Created package at {package_path}")

    upload_key = f"born-digital/{package_path}"

    s3 = boto3.client("s3")
    s3.upload_file(
        Bucket=upload_bucket,
        Key=upload_key,
        Filename=package_path
    )
    print(f"Uploaded package to S3 at s3://{upload_bucket}/{upload_key}")
