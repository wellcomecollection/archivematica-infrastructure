# -*- encoding: utf-8

import boto3
import pytest

METS = "data/objects/submissionDocumentation/transfer-pkg-{}/METS.xml"


def stored(external_identifier, transfer_id):
    """The .xml name the storage service holds for a stored transfer."""
    return f"{external_identifier}/{METS.format(transfer_id)}"


class TestSecretCaching:
    """
    The 2026-08-03 timeout was get_secret_string being lru_cached with a
    boto3 Session in its key, so every call missed and pinned a new Session.
    Counting the calls is what catches that coming back.
    """

    def test_each_secret_is_fetched_once_however_many_packages(
        self, monitor, aws, upload_package, urlopen
    ):
        for i in range(5):
            upload_package(
                f"born-digital/pkg-{i}.zip",
                transfer_id=f"transfer-{i}",
                external_identifier="PP/ABC",
            )
        urlopen()

        monitor.main(None, None)

        get_secret_value = [c for c in aws if c == "secretsmanager.GetSecretValue"]
        assert len(get_secret_value) == 2

    def test_a_second_query_reuses_the_cached_credentials(
        self, monitor, aws, upload_package, urlopen
    ):
        # Two identifiers means two Elasticsearch queries, each needing the
        # reporting credentials. The second should come from the cache.
        upload_package(
            "born-digital/a.zip", transfer_id="t1", external_identifier="PP/ABC"
        )
        upload_package(
            "born-digital/b.zip", transfer_id="t2", external_identifier="PP/DEF"
        )
        urlopen()

        monitor.main(None, None)

        assert monitor.get_secret_string.cache_info().hits == 1
        assert len([c for c in aws if c == "secretsmanager.GetSecretValue"]) == 2


class TestElasticsearchQueries:
    """
    has_matching_bag used to be cached on the transfer ID too, so every
    transfer of a package issued its own query. Only the external
    identifier changes the answer.
    """

    def test_one_query_per_external_identifier(
        self, monitor, aws, upload_package, urlopen
    ):
        for i in range(4):
            upload_package(
                f"born-digital/pkg-{i}.zip",
                transfer_id=f"transfer-{i}",
                external_identifier="PP/ABC",
            )
        fake = urlopen()

        monitor.main(None, None)

        assert len(fake.es_calls) == 1

    def test_distinct_identifiers_get_their_own_query(
        self, monitor, aws, upload_package, urlopen
    ):
        upload_package(
            "born-digital/a.zip", transfer_id="t1", external_identifier="PP/ABC"
        )
        upload_package(
            "born-digital/b.zip", transfer_id="t2", external_identifier="PP/DEF"
        )
        fake = urlopen()

        monitor.main(None, None)

        assert len(fake.es_calls) == 2


class TestTimeouts:
    def test_every_request_has_a_timeout(self, monitor, aws, upload_package, urlopen):
        upload_package(
            "born-digital/one.zip", transfer_id="t1", external_identifier="PP/ABC"
        )
        fake = urlopen()

        monitor.main(None, None)

        assert fake.calls
        assert all(call["timeout"] == 30 for call in fake.calls)


class TestCacheIsPerInvocation:
    """
    Lambda reuses execution environments, so a cache left populated would
    let one run's file listing answer the next.
    """

    def test_cache_is_cleared_after_a_successful_run(
        self, monitor, aws, upload_package, urlopen
    ):
        upload_package(
            "born-digital/one.zip", transfer_id="t1", external_identifier="PP/ABC"
        )
        urlopen()

        monitor.main(None, None)

        assert monitor.get_stored_xml_file_names.cache_info().currsize == 0

    def test_cache_is_cleared_when_the_run_fails(
        self, monitor, aws, upload_package, urlopen, monkeypatch
    ):
        upload_package(
            "born-digital/one.zip", transfer_id="t1", external_identifier="PP/ABC"
        )
        urlopen()

        def boom(**kwargs):
            raise RuntimeError("Slack is down")

        monkeypatch.setattr(monitor, "post_to_slack", boom)

        with pytest.raises(RuntimeError):
            monitor.main(None, None)

        assert monitor.get_stored_xml_file_names.cache_info().currsize == 0

    def test_the_cache_still_dedupes_within_one_invocation(
        self, monitor, aws, upload_package, urlopen
    ):
        for i in range(3):
            upload_package(
                f"born-digital/pkg-{i}.zip",
                transfer_id=f"transfer-{i}",
                external_identifier="PP/ABC",
            )
        fake = urlopen()

        monitor.main(None, None)

        # One query answered three lookups.
        assert len(fake.es_calls) == 1


class TestReportedResults:
    def test_a_stored_package_is_deleted_from_the_transfer_bucket(
        self, monitor, aws, transfer_bucket, upload_package, urlopen
    ):
        upload_package(
            "born-digital/stored.zip", transfer_id="t1", external_identifier="PP/ABC"
        )
        urlopen(stored_names=[stored("PP/ABC", "t1")])

        monitor.main(None, None)

        listing = boto3.client("s3").list_objects_v2(Bucket=transfer_bucket)
        assert listing.get("Contents", []) == []

    def test_an_unstored_package_is_left_alone(
        self, monitor, aws, transfer_bucket, upload_package, urlopen
    ):
        upload_package(
            "born-digital/missing.zip", transfer_id="t1", external_identifier="PP/ABC"
        )
        urlopen(stored_names=[])

        monitor.main(None, None)

        listing = boto3.client("s3").list_objects_v2(Bucket=transfer_bucket)
        assert [o["Key"] for o in listing["Contents"]] == ["born-digital/missing.zip"]

    def test_an_untagged_object_is_ignored(
        self, monitor, aws, transfer_bucket, urlopen
    ):
        boto3.client("s3").put_object(
            Bucket=transfer_bucket, Key="born-digital/untagged.zip", Body=b"zip"
        )
        fake = urlopen()

        monitor.main(None, None)

        assert fake.es_calls == []
