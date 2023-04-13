import errno
from functools import wraps
import logging
import os
import re
import subprocess
import tempfile
import time

import boto3
import botocore
from django.db import models
from django.core.urlresolvers import reverse
from django.utils.translation import ugettext_lazy as _
from django.utils.six.moves.urllib.parse import urljoin, urlencode
from wellcome_storage_service import BagNotFound, RequestsOAuthStorageServiceClient as StorageServiceClient

from . import StorageException
from . import Package
from .location import Location


TOKEN_HELP_TEXT = _('URL of the OAuth token endpoint, e.g. https://auth.wellcomecollection.org/oauth2/token')
API_HELP_TEXT = _('Root URL of the storage service API, e.g. https://api.wellcomecollection.org/storage/v1')
CALLBACK_HELP_TEXT = _('Publicly accessible URL of the Archivematica storage service accessible to Wellcome storage service for callback')

LOGGER = logging.getLogger(__name__)


# The script we use to download a compressed bag from S3.
# This is run in a subprocess.
DOWNLOAD_BAG_SCRIPT = '''
import json, sys
from wellcome_storage_service import download_compressed_bag

bag = json.load(open(sys.argv[1]))
dest_path = sys.argv[2]
top_level_dir=sys.argv[3]

download_compressed_bag(storage_manifest=bag, out_path=dest_path, top_level_dir=top_level_dir)
'''


def boto_exception(fn):
    @wraps(fn)
    def _inner(*args, **kwargs):
        try:
            return fn(*args, **kwargs)
        except botocore.exceptions.BotoCoreError as e:
            raise StorageException("AWS error: %r", e)

    return _inner


def handle_ingest(ingest, package):
    """
    Handle an ingest json response
    """
    status = ingest['status']['id']
    if status == 'succeeded':
        package.status = Package.UPLOADED
        # Strip the directory context from the package path so it is
        # in the format NAME-uuid.tar.gz
        package.current_path = os.path.basename(package.current_path)
        bag_info = ingest['bag']['info']
        package.misc_attributes["wellcome.version"] = bag_info["version"]

        LOGGER.debug('Package path: %s', package.current_path)
        LOGGER.debug('Package attributes: %s', package.misc_attributes)

        package.save()

    elif status == 'failed':
        LOGGER.error('Ingest failed')
        package.status = Package.FAIL
        package.save()
        for event in ingest['events']:
            LOGGER.info('{type}: {description}'.format(**event))

    else:
        LOGGER.info("Unrecognised package status: %s", status)


def mkdir_p(dirpath):
    """Create a directory, even if it already exists.

    When Archivematica is running exclusively in Python 3, calls to this function
    can be replaced with ``os.makedirs(dirpath, exist_ok=True)``.

    """
    try:
        os.makedirs(dirpath)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(dirpath):
            pass
        else:
            raise


FNULL = open(os.devnull, 'w')


class WellcomeIdentifier(object):
    def __init__(self, space, external_identifier, internal_identifier):
        self.space = space
        self.external_identifier = external_identifier
        self.internal_identifier = internal_identifier

    def __repr__(self):
        return (
            "WellcomeIdentifier(space=%r, external_identifier=%r, internal_identifier=%r)"
            % (self.space, self.external_identifier, self.internal_identifier)
        )

    def with_space(self, new_space):
        return WellcomeIdentifier(
            space=new_space,
            external_identifier=self.external_identifier,
            internal_identifier=self.internal_identifier
        )


class NoWellcomeIdentifierFound(ValueError):
    def __init__(self):
        return super(NoWellcomeIdentifierFound, self).__init__(
            "Unable to find a suitable identifier to use in the Wellcome identifier. "
            "Please re-send this transfer, supplying either (1) an accession number, "
            "or (2) a Dublin-Core identifier `dc.identifier` in the metadata."
        )


def _find_transfer_mets_path(bag_dir):
    # The transfer METS path is written into the bag at something like
    #
    #       data/objects/submissionDocumentation/WT_1234-{uuid}/METS.xml
    #
    # We don't know what that directory name will be, so guess and find it
    # that way.
    submission_docs_dir = os.path.join(bag_dir, "data/objects/submissionDocumentation")

    if len(os.listdir(submission_docs_dir)) == 1:
        return os.path.join(
            submission_docs_dir,
            os.listdir(submission_docs_dir)[0],
            "METS.xml"
        )
    else:
        return None


def get_wellcome_identifier(src_path, package_uuid, space):
    """
    By default, Archivematica will use the UUID as the External-Identifier
    when calling the Wellcome Storage.

    This is somewhat unpleasant -- if you're browsing the storage without
    Archivematica references, it's hard to know where to find a given archive.
    For example, if you're looking for PPMIA/1/2, what UUID is that?

    If all the objects in the bag have a common value in the dc.identifier field,
    which should be a catalogue reference, use that in preference to the
    Archivematica external identifier.

    """
    LOGGER.debug("Trying to find Wellcome identifier in %s", src_path)

    # If we're not looking at a tar.gz compressed bag, stop.
    if not src_path.endswith(".tar.gz"):
        raise NoWellcomeIdentifierFound()

    # Unpack the tar.gz to a temporary directory.  We run tar in a subprocess
    # because it's CPU intensive and we don't want to hang the main Archivematica
    # thread.
    with tempfile.TemporaryDirectory() as temp_dir:
        try:
            subprocess.check_call(
                ["tar", "-xzf", src_path, "-C", temp_dir],
                stdout=FNULL,
                stderr=FNULL
            )
        except subprocess.CalledProcessError as err:
            LOGGER.debug("Error uncompressing tar.gz bag: %r", err)
            raise NoWellcomeIdentifierFound()

        # There should be a single directory in the temporary directory -- the
        # uncompressed bag.
        if len(os.listdir(temp_dir)) != 1:
            LOGGER.debug(
                "Unable to identify root of bag in: os.listdir(%r) = %r",
                temp_dir, os.listdir(temp_dir)
            )
            raise NoWellcomeIdentifierFound()

        # Inside the bag, we look for the METS.xml file that contains information
        # about the package.  If we can't find it unambiguously, give up.
        bag_dir = os.path.join(temp_dir, os.listdir(temp_dir)[0])
        assert os.path.exists(bag_dir)
        LOGGER.debug("Expanded bag into directory %s" % bag_dir)

        mets_path = os.path.join(bag_dir, "data/METS.%s.xml" % package_uuid)

        transfer_mets_path = _find_transfer_mets_path(bag_dir)

        if not os.path.isfile(mets_path):
            LOGGER.warn("Unable to find METS file in bag at path: %r", mets_path)
            raise NoWellcomeIdentifierFound()

        if not os.path.isfile(transfer_mets_path):
            LOGGER.warn(
                "Unable to find transfer METS file in bag at path: %r", transfer_mets_path)
            raise NoWellcomeIdentifierFound()

        # Try to get some identifiers from the METS files.  We try to use the
        # Dublin Core identifiers first, if not the accession number, and if
        # both of those fail we fall back to the package UUID.
        try:
            LOGGER.debug("Looking for Dublin-Core identifiers in the METS")
            wellcome_identifier = WellcomeIdentifier(
                space=space,
                external_identifier=get_common_prefix(extract_dc_identifiers(mets_path)),
                internal_identifier=package_uuid
            )
        except NoCommonPrefix as err:
            LOGGER.debug("No common prefix in the Dublin-Core identifiers")
            LOGGER.debug("Looking for accession numbers in the transfer METS")
            try:
                accession_numbers = list(
                    extract_accession_identifiers(transfer_mets_path)
                )
                LOGGER.debug("Found accession numbers: %r", accession_numbers)
                external_identifier = get_common_prefix(accession_numbers)

                if not space.endswith("-accessions"):
                    space = "%s-accessions" % space

                wellcome_identifier = WellcomeIdentifier(
                    space=space,
                    external_identifier=external_identifier,
                    internal_identifier=package_uuid
                )
            except NoCommonPrefix:
                LOGGER.debug("No common prefix in the accession numbers")
                raise NoWellcomeIdentifierFound()

        # If this is a test package, we divert it to a separate space.  This prefix
        # for the dc.identifier is deliberately chosen to be one that would never
        # appear in a real catalogue record.
        if wellcome_identifier.external_identifier.startswith("archivematica-dev/TEST"):
            wellcome_identifier = wellcome_identifier.with_space("testing")

        LOGGER.debug("Detected Wellcome identifier as %s", wellcome_identifier)

        # At this point, we've found a common prefix and it's non-empty.
        # Write it back into the bag, then compress the bag back up under
        # the original path.
        #
        # Recreate the checksums in the manifests, because we've edited
        # the bag-info.txt.  Note: we run this in a subprocess to avoid
        # locking up the main thread.
        script = (
            "import sys, bagit; "
            "bag = bagit.Bag(sys.argv[1]); "
            "bag.info['External-Identifier'] = sys.argv[2]; "
            "bag.info['Internal-Sender-Identifier'] = sys.argv[3]; "
            "bag.save(manifests=True)"
        )
        subprocess.check_call(
            [
                "python",
                "-c",
                script,
                bag_dir,
                wellcome_identifier.external_identifier,
                wellcome_identifier.internal_identifier
            ],
            stdout=FNULL,
            stderr=FNULL
        )

        # Recompress the bag.  We write it to a temporary path first, so if we
        # corrupt something, the original tar.gz is preserved.
        try:
            subprocess.check_call([
                "tar",

                # Compress to /src_path.tmp using gzip compression (-z)
                "-czvf", src_path + ".tmp",

                # cd into temp_dir first, then compress everything it contains.
                # This means all the files in the tar.gz are relative, not
                # absolute paths to /tmp/...
                "-C", temp_dir, "."
            ], stdout=FNULL, stderr=FNULL)
        except subprocess.CalledProcessError as err:
            LOGGER.debug("Error repacking bag as tar.gz: %r" % err)

        # This rename should be atomic.
        os.rename(src_path + ".tmp", src_path)
        return wellcome_identifier


class S3SpaceModelMixin(models.Model):
    class Meta:
        app_label = "locations"
        abstract = True

    aws_access_key_id = models.CharField(
        max_length=64, blank=True, verbose_name=_("Access Key ID to authenticate")
    )
    aws_secret_access_key = models.CharField(
        max_length=256,
        blank=True,
        verbose_name=_("Secret Access Key to authenticate with"),
    )
    aws_assumed_role = models.CharField(
        max_length=256,
        blank=True,
        verbose_name=_('Assumed AWS IAM Role'),
    )
    s3_endpoint_url = models.CharField(
        max_length=2048,
        verbose_name=_("S3 Endpoint URL"),
        help_text=_("S3 Endpoint URL. Eg. https://s3.amazonaws.com"),
    )
    s3_region = models.CharField(
        max_length=64,
        verbose_name=_("Region"),
        help_text=_("Region in S3. Eg. us-east-2"),
    )
    s3_bucket = models.CharField(
        max_length=64,
        verbose_name=_("S3 Bucket"),
        blank=True,
        help_text=_("S3 Bucket Name"),
    )

    @property
    def bucket_name(self):
        return self.s3_bucket or self.space_id

    @property
    def s3_resource(self):
        if not hasattr(self, "_s3_resource"):
            boto_args = {
                "service_name": "s3",
                "endpoint_url": self.s3_endpoint_url,
                "region_name": self.s3_region,
            }
            if self.aws_access_key_id and self.aws_secret_access_key:
                boto_args.update(
                    aws_access_key_id=self.aws_access_key_id,
                    aws_secret_access_key=self.aws_secret_access_key,
                )

            self._s3_resource = boto3.resource(**boto_args)

        return self._s3_resource

    @boto_exception
    def _ensure_bucket_exists(self):
        """Ensure that the bucket exists by asking it something about itself.
        If we cannot retrieve metadata about it, and specifically, we can
        determine the endpoint has returned a `NoSuchBucket' error code then
        we attempt to create the bucket, else, we raise a StorageException.
        NB. Boto3 has an API called head_bucket that looks to return 400,
        Bad Request at time of 1.9.174 when the S3 documents suggest 404, or
        more 'specifically':
            > Otherwise, the operation might return responses such as 404 Not
            > Found and 403 Forbidden. "
            via-- Amazon AWS: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketHEAD.html
        """
        LOGGER.debug("Test the S3 bucket '%s' exists", self.bucket_name)
        try:
            loc_info = self.s3_resource.meta.client.head_bucket(
                Bucket=self.bucket_name
            )
            LOGGER.debug("S3 bucket's response: %s", loc_info)
        except botocore.exceptions.ClientError as err:
            error_code = err.response["Error"]["Code"]
            if error_code not in ["NoSuchBucket", "404"]:
                raise StorageException(err)
            LOGGER.info("Creating S3 bucket '%s'", self.bucket_name)
            # LocationConstraint cannot be specified if it us-east-1 because it is the default, see: https://github.com/boto/boto3/issues/125
            if self.s3_region.lower() == "us-east-1":
                self.s3_resource.create_bucket(Bucket=self.bucket_name)
            else:
                self.s3_resource.create_bucket(
                    Bucket=self.bucket_name,
                    CreateBucketConfiguration={"LocationConstraint": self.s3_region},
                )


class WellcomeStorageService(S3SpaceModelMixin):
    space = models.OneToOneField('Space', to_field='uuid')
    token_url = models.URLField(max_length=256, help_text=TOKEN_HELP_TEXT)
    api_root_url = models.URLField(max_length=256, help_text=API_HELP_TEXT)

    # oauth details:
    app_client_id = models.CharField(max_length=300, blank=True, null=True)
    app_client_secret = models.CharField(max_length=300, blank=True, null=True)

    callback_host = models.URLField(max_length=256, help_text=CALLBACK_HELP_TEXT, blank=True)
    callback_username = models.CharField(max_length=150, blank=True)
    callback_api_key = models.CharField(max_length=256, blank=True)

    def browse(self, path):
        LOGGER.debug('Browsing %s on Wellcome storage', path)
        return {
            'directories': set(),
            'entries': set(),
            'properties': {},
        }

    @property
    def wellcome_client(self):
        return StorageServiceClient(
            api_url=self.api_root_url,
            token_url=self.token_url,
            client_id=self.app_client_id,
            client_secret=self.app_client_secret,
        )

    def delete_path(self, delete_path):
        LOGGER.debug('Deleting %s from Wellcome storage', delete_path)

    def move_to_storage_service(self, src_path, dest_path, dest_space):
        raise NotImplementedError(_("Wellcome Storage service does not implement fetching packages through Archivematica"))

    def move_from_storage_service(self, src_path, dest_path, package=None):
        """
        Upload an AIP from Archivematica to the Wellcome Storage.
        """
        LOGGER.debug('Moving %s to %s on Wellcome storage', src_path, dest_path)

        s3_temporary_path = dest_path.lstrip('/')
        bucket = self.s3_resource.Bucket(self.s3_bucket)

        # The src_path to the package is typically a string of the form
        #
        #     /u/u/i/d/{sip_name}-{uuid}.tar.gz
        #
        # The {sip_name} is a human-readable identifier -- if we can use that,
        # it better corresponds to the catalogue records.
        #
        # See if we can extract it, and if not, fall back to the UUID.
        src_filename = os.path.basename(src_path)
        src_name, __ = os.path.splitext(src_filename)

        # Use the relative_path as the storage service space ID
        location = package.current_location
        space = location.relative_path.strip(os.path.sep)

        wellcome_identifier = get_wellcome_identifier(
            src_path=src_path,
            package_uuid=package.uuid,
            space=space
        )

        # The Wellcome Storage reads packages out of S3, so we need to
        # upload the AIP to S3 before asking the WS to ingest it.
        #
        # We have to upload to S3 *after* calling get_wellcome_identifier,
        # because that might modify the External-Identifier in the bag-info.txt.
        try:
            with open(src_path, "rb") as data:
                bucket.upload_fileobj(data, s3_temporary_path)
        except Exception as err:
            LOGGER.warn("Error uploading %s to S3: %r", src_path, err)
            raise StorageException(
                _('%(path)s is not a file, may be a directory or not exist') %
                {'path': src_path})

        # We don't know if other packages have been ingested to the
        # Wellcome Storage for this identifier -- query for existing bags,
        # and select an ingest type appropriately.
        if wellcome_identifier.external_identifier == package.uuid:
            ingest_type = "create"
        else:
            try:
                self.wellcome_client.get_bag(
                    space=wellcome_identifier.space,
                    external_identifier=wellcome_identifier.external_identifier
                )
            except BagNotFound:
                ingest_type = "create"
            else:
                ingest_type = "update"

        # Construct a callback URL that the storage service can use to
        # notify Archivematica of a completed ingest.
        # TODO: Don't embed raw API credentials.
        # See https://github.com/wellcometrust/platform/issues/3534
        callback_url = urljoin(
            self.callback_host,
            '%s?%s' % (
                reverse('wellcome_callback', args=['v2', 'file', package.uuid]),
                urlencode([
                    ("username", self.callback_username),
                    ("api_key", self.callback_api_key),
                ])
            ))

        # Record the attributes on the package, so we can use them to
        # retrieve a bag later.
        package.misc_attributes["wellcome.external_identifier"] = wellcome_identifier.external_identifier
        package.misc_attributes["wellcome.space"] = wellcome_identifier.space

        LOGGER.info(
            "Uploading to Wellcome Storage with external identifier %s, space %s, ingest type %s",
            wellcome_identifier.external_identifier, wellcome_identifier.space, ingest_type
        )

        # For reingests, the package status will still be 'uploaded'
        # We use the status to detect when upload is complete,
        # so it is explicitly reset here.
        package.status = Package.STAGING
        package.save()

        # Either create or update a bag on the storage service
        # https://github.com/wellcometrust/platform/tree/master/docs/rfcs/002-archival_storage#updating-an-existing-bag
        LOGGER.info("Callback will be to %s", callback_url)
        location = self.wellcome_client.create_s3_ingest(
            space=wellcome_identifier.space,
            external_identifier=wellcome_identifier.external_identifier,
            s3_key=s3_temporary_path,
            s3_bucket=self.s3_bucket,
            callback_url=callback_url,
            ingest_type=ingest_type,
        )
        LOGGER.info('Ingest_location: %s', location)

        LOGGER.debug('Current package status is %s', package.status)
        while package.status == Package.STAGING:
            # Wait for callback to have been called
            for i in range(6):
                package.refresh_from_db()
                LOGGER.debug('Polled package; status is %s', package.status)
                time.sleep(10)
                if package.status != Package.STAGING:
                    break

            if package.status == Package.STAGING:
                LOGGER.info("Callback wasn't called yet - let's check the ingest URL")

                # It wasn't. Query the ingest URL to see if anything happened.
                # It's possible we missed the callback (e.g. Archivematica was unavailable?)
                # because the storage service won't retry.
                ingest = self.wellcome_client.get_ingest_from_location(location)
                if ingest['callback']['status']['id'] == 'processing':
                    # Just keep waiting for the callback
                    LOGGER.info("Still waiting for callback")
                else:
                    # We missed the callback. Take results from the ingest body
                    LOGGER.info("Ingest result found")
                    handle_ingest(ingest, package)

        if package.status == Package.FAIL:
            raise StorageException(
                _("Failed to store package %(path)s") %
                {'path': src_path})

    class Meta(S3SpaceModelMixin.Meta):
        verbose_name = _("Wellcome Storage Service")

    ALLOWED_LOCATION_PURPOSE = [
        Location.AIP_STORAGE,
    ]


class NoCommonPrefix(Exception):
    pass


def get_common_prefix(identifiers):
    """
    A METS file may contain an identifier at multiple points.  We want to pick
    a common prefix, if any, to use as the external identifier in the
    Wellcome Archival Storage.

    e.g. get_common_prefix(["AA/1", "AA/2"]) == "AA"

    """
    split_identifiers = [ident.split("/") for ident in identifiers]
    common_components = os.path.commonprefix(split_identifiers)

    if not common_components:
        raise NoCommonPrefix()

    # If the last element is an empty string, remove it -- this avoids
    # getting an identifier that ends with a /.
    while common_components[-1] == "":
        common_components = common_components[:-1]

    return "/".join(common_components)


def extract_dc_identifiers(mets_path):
    """
    Find all Dublin-Core identifier values in a METS file.
    """
    # The Dublin-Core identifiers are typically in a block a bit like:
    #
    #       <mets:dmdSec ID="dmdSec_2">
    #         <mets:mdWrap MDTYPE="DC">
    #           <mets:xmlData>
    #             <dcterms:dublincore xmlns:dc="http://purl.org/dc/elements/1.1/" ...>
    #               <dc:identifier>ID/1/2/3/4</dc:identifier>
    #             </dcterms:dublincore>
    #           </mets:xmlData>
    #         </mets:mdWrap>
    #       </mets:dmdSec>
    #
    # So we look for instances of "identifier" in the "dc:" namespace.
    #
    # The "correct" thing to do here is to use an XML parser, but these METS
    # files can be arbitrarily big.  Attempting to use a real XML parser tends
    # to cause the worker to crash with an out-of-memory error, so instead we
    # cheat and stream the file manually.
    #
    # If the structure of the Archivematica METS breaks, this will fail, so
    # we rely on it not doing that!
    #
    with open(mets_path) as mets_file:
        for line in mets_file:
            if not line.strip().startswith("<dc:identifier>"):
                continue

            LOGGER.debug("Found line that looks like a dc:identifier: %r", line)

            match = re.match(
                r"^<dc:identifier>(?P<identifier>[^<]+)</dc:identifier>$", line.strip()
            )

            if match is None:
                LOGGER.debug("Line didn't match regex: %r", line)
            else:
                yield match.group("identifier")


def extract_accession_identifiers(transfer_mets_path):
    """
    Find all accession identifiers in the transfer METS files.
    """
    # The Accession identifier is written into the METS header:
    #
    #     <mets:altRecordID TYPE="Accession ID">1148</mets:altRecordID>
    #
    # The "correct" thing to do here is to use an XML parser, but these METS
    # files can be arbitrarily big.  Attempting to use a real XML parser tends
    # to cause the worker to crash with an out-of-memory error, so instead we
    # cheat and stream the file manually.
    #
    # If the structure of the Archivematica METS breaks, this will fail, so
    # we rely on it not doing that!
    #
    with open(transfer_mets_path) as mets_file:
        for line in mets_file:
            if not line.strip().startswith('<mets:altRecordID TYPE="Accession ID">'):
                continue

            LOGGER.debug("Found line that looks like a mets:altRecordID: %r", line)

            match = re.match(
                r'^<mets:altRecordID TYPE="Accession ID">(?P<identifier>[^<]+)</mets:altRecordID>$',
                line.strip()
            )

            if match is None:
                LOGGER.debug("Line didn't match regex: %r", line)
            else:
                yield match.group("identifier")
