"""Test Storage Service

Tests for the Archivematica Common Storage Service helpers.
"""

import json
from unittest import mock

import pytest
from requests import Response

from archivematica.archivematicaCommon import storageService
from archivematica.archivematicaCommon.storageService import (
    location_description_from_slug,
)
from archivematica.archivematicaCommon.storageService import request_file_deletion
from archivematica.archivematicaCommon.storageService import (
    retrieve_storage_location_description,
)


def mock_response(status_code, content_type, content):
    response = Response()
    response.status_code = status_code
    response.headers["content-type"] = content_type
    response.status = "Mocked status value"
    response._content = json.dumps(content).encode("utf8")
    return response


def async_response(location="/api/v2/async/158/"):
    response = Response()
    response.status_code = 202
    response.headers["Location"] = location
    return response


def async_status_response(payload=None, status_code=200):
    response = Response()
    response.status_code = status_code
    response.url = "http://ss/api/v2/async/158/"
    response.headers["content-type"] = "application/json"
    response._content = json.dumps(payload or {}).encode("utf8")
    return response


@pytest.fixture(params=["missing_status", "interrupted"], ids=["404", "interrupted"])
def unknown_async_status_response(request):
    if request.param == "missing_status":
        return async_status_response(status_code=404)
    return async_status_response(
        {
            "completed": True,
            "was_error": True,
            "error_code": "async_operation_interrupted",
            "error": (
                "<class 'RuntimeError'>: The asynchronous operation was "
                "interrupted after its heartbeat expired. Its final outcome is "
                "unknown; do not retry it automatically."
            ),
        }
    )


class FakeClock:
    def __init__(self):
        self.now = 0.0

    def monotonic(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


@pytest.fixture
def fake_clock(monkeypatch):
    clock = FakeClock()
    monkeypatch.setattr(storageService.time, "monotonic", clock.monotonic)
    monkeypatch.setattr(storageService.time, "sleep", clock.sleep)
    return clock


@pytest.mark.django_db
@pytest.mark.parametrize(
    "status_code,content_type,expected_result",
    [
        (200, "application/json", {"description": "a description", "path": "/a/path/"}),
        (200, "application/gzip", {}),
        (204, "x-application/mocked", {}),
        (400, "x-application/mocked", {}),
        (500, "x-application/mocked", {}),
        (0, "", {}),
    ],
)
@mock.patch("archivematica.archivematicaCommon.storageService._storage_service_url")
@mock.patch("requests.Session.get")
def test_location_desc_from_slug(
    get, _storage_service_url, status_code, content_type, expected_result
):
    """Test location description from slug

    Rudimentary test to ensure that we're returning something that
    implements .get() for any potential return from this function. And
    that we get something sensible for unexpected status codes.
    """

    get.return_value = mock_response(status_code, content_type, expected_result)
    res = location_description_from_slug("mock_uri")
    assert res == expected_result, f"Unexpected result for status test: {status_code}"


@pytest.mark.parametrize(
    "slug,return_value,expected_result",
    [
        (
            "/api/v2/location/3e796bef-0d56-4471-8700-eeb256859811/",
            {"description": "a description"},
            "a description",
        ),
        (
            "/api/v2/location/default/AS/",
            {"description": None, "path": "/path/one/"},
            "/path/one/",
        ),
        (
            "/api/v2/location/e0a9558c-ae00-4e39-886d-2a38bba98c72/",
            {"path": "/path/two"},
            "/path/two",
        ),
        (
            "/api/v2/location/e0a9558c-ae00-4e39-886d-2a38bba98c72/",
            {"description": "a description", "path": "/path/three"},
            "a description",
        ),
        ("/api/v2/location/fd46760b-567f-4c17-a2f4-a05e79074932/", {}, ""),
    ],
)
@mock.patch(
    "archivematica.archivematicaCommon.storageService.location_description_from_slug"
)
def test_retrieve_storage_location(
    location_description_from_slug, slug, return_value, expected_result
):
    """Test retrieve storage location

    Ensure that we're able to retrieve the resource description for the
    storage service from our request to the storage service. We should
    be able to retrieve a 'description' or "path" or "" (blank string)
    in that order, depending on the response, i.e. if a user hasn't
    specified a description, we should be able to fall-back on something
    else. Likewise if we receive something unexpected.
    """
    location_description_from_slug.return_value = return_value
    res = retrieve_storage_location_description(slug)
    assert res == expected_result


@pytest.mark.django_db
@mock.patch("archivematica.archivematicaCommon.storageService._storage_api_session")
@mock.patch(
    "archivematica.archivematicaCommon.storageService._storage_service_url",
    return_value="http://ss/",
)
def test_request_file_deletion_handles_non_json_response(
    _storage_service_url, _storage_api_session
):
    response = Response()
    response.status_code = 404
    response.headers["content-type"] = "text/plain"
    response._content = b"Not Found"
    session = mock.Mock()
    session.post.return_value = response
    _storage_api_session.return_value = session

    result = request_file_deletion(
        "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        0,
        "archivematica@example.com",
        "testing",
    )

    assert result == {"error": True, "message": "Not Found", "status": 404}


def test_async_observation_deadline_is_24_hours():
    assert storageService.ASYNC_OBSERVATION_DEADLINE_SECONDS == 24 * 60 * 60


def test_wait_for_async_returns_result_with_bounded_poll_timeouts(
    monkeypatch, fake_clock
):
    monkeypatch.setattr(storageService, "ASYNC_OBSERVATION_DEADLINE_SECONDS", 10)
    session = mock.Mock()
    session.get.side_effect = [
        async_status_response({"completed": False}),
        async_status_response(
            {"completed": True, "was_error": False, "result": {"uuid": "file"}}
        ),
    ]
    storage_api_session = mock.Mock(return_value=session)
    monkeypatch.setattr(storageService, "_storage_api_session", storage_api_session)
    monkeypatch.setattr(
        storageService, "_storage_service_url", lambda: "http://ss/api/v2/"
    )

    result = storageService.wait_for_async(async_response(), operation="copy_files")

    assert result == {"uuid": "file"}
    assert fake_clock.now == 2
    assert storage_api_session.call_args_list == [
        mock.call(timeout=10),
        mock.call(timeout=8),
    ]


def test_wait_for_async_stops_at_observation_deadline(monkeypatch, fake_clock, caplog):
    monkeypatch.setattr(storageService, "ASYNC_OBSERVATION_DEADLINE_SECONDS", 3)
    session = mock.Mock()
    session.get.return_value = async_status_response({"completed": False})
    storage_api_session = mock.Mock(return_value=session)
    monkeypatch.setattr(storageService, "_storage_api_session", storage_api_session)
    monkeypatch.setattr(
        storageService, "_storage_service_url", lambda: "http://ss/api/v2/"
    )

    with pytest.raises(storageService.AsyncObservationDeadlineExceeded) as exc_info:
        storageService.wait_for_async(async_response(), operation="copy_files")

    assert fake_clock.now == 3
    assert exc_info.value.async_id == "158"
    assert exc_info.value.deadline_seconds == 3
    assert "unknown outcome" in str(exc_info.value)
    assert "Do not submit it again" in str(exc_info.value)
    assert "Storage Service async operation 158" in caplog.text
    assert storage_api_session.call_args_list == [
        mock.call(timeout=3),
        mock.call(timeout=1),
    ]
    assert session.get.call_count == 2


def test_wait_for_async_reports_missing_status_as_unknown(monkeypatch, fake_clock):
    session = mock.Mock()
    session.get.return_value = async_status_response(status_code=404)
    monkeypatch.setattr(
        storageService, "_storage_api_session", mock.Mock(return_value=session)
    )
    monkeypatch.setattr(
        storageService, "_storage_service_url", lambda: "http://ss/api/v2/"
    )

    with pytest.raises(storageService.AsyncOutcomeUnknown) as exc_info:
        storageService.wait_for_async(async_response(), operation="create_file")

    assert not isinstance(
        exc_info.value, storageService.AsyncObservationDeadlineExceeded
    )
    assert exc_info.value.async_id == "158"
    assert "returned HTTP 404" in str(exc_info.value)
    assert "unknown outcome" in str(exc_info.value)


def test_wait_for_async_reports_terminal_interruption_as_unknown(
    monkeypatch, fake_clock
):
    interrupted_error = "The wording of this message can change."
    session = mock.Mock()
    terminal_payload = {
        "completed": True,
        "was_error": True,
        "error_code": "async_operation_interrupted",
        "error": interrupted_error,
    }
    session.get.side_effect = [
        async_status_response({"completed": False}),
        async_status_response(terminal_payload),
    ]
    monkeypatch.setattr(
        storageService, "_storage_api_session", mock.Mock(return_value=session)
    )
    monkeypatch.setattr(
        storageService, "_storage_service_url", lambda: "http://ss/api/v2/"
    )

    with pytest.raises(storageService.AsyncOutcomeUnknown) as exc_info:
        storageService.wait_for_async(async_response(), operation="create_file")

    assert not isinstance(
        exc_info.value, storageService.AsyncObservationDeadlineExceeded
    )
    assert exc_info.value.operation == "create_file"
    assert exc_info.value.async_id == "158"
    assert exc_info.value.poll_url == "http://ss/api/v2/async/158/"
    assert exc_info.value.elapsed_seconds == 2
    assert interrupted_error in exc_info.value.reason
    assert "Storage Service reported an interrupted operation" in exc_info.value.reason


@pytest.mark.parametrize(
    "transient_failure",
    [
        storageService.requests.ConnectionError("unavailable"),
        storageService.requests.exceptions.ChunkedEncodingError("incomplete response"),
        async_status_response(status_code=502),
    ],
    ids=["connection", "chunked", "502"],
)
def test_wait_for_async_retries_transient_poll_failure(
    monkeypatch, fake_clock, caplog, transient_failure
):
    session = mock.Mock()
    session.get.side_effect = [
        transient_failure,
        async_status_response(
            {"completed": True, "was_error": False, "result": {"uuid": "file"}}
        ),
    ]
    monkeypatch.setattr(
        storageService, "_storage_api_session", mock.Mock(return_value=session)
    )
    monkeypatch.setattr(
        storageService, "_storage_service_url", lambda: "http://ss/api/v2/"
    )

    result = storageService.wait_for_async(async_response(), operation="create_file")

    assert result == {"uuid": "file"}
    assert fake_clock.now == 2
    assert session.get.call_count == 2
    assert "failed transiently and will be retried" in caplog.text


def test_wait_for_async_reports_persistent_poll_failure_at_deadline(
    monkeypatch, fake_clock, caplog
):
    monkeypatch.setattr(storageService, "ASYNC_OBSERVATION_DEADLINE_SECONDS", 3)
    session = mock.Mock()
    session.get.side_effect = storageService.requests.ConnectionError("unavailable")
    monkeypatch.setattr(
        storageService, "_storage_api_session", mock.Mock(return_value=session)
    )
    monkeypatch.setattr(
        storageService, "_storage_service_url", lambda: "http://ss/api/v2/"
    )

    with pytest.raises(storageService.AsyncObservationDeadlineExceeded) as exc_info:
        storageService.wait_for_async(async_response(), operation="create_file")

    assert exc_info.value.async_id == "158"
    assert fake_clock.now == 3
    assert session.get.call_count == 2
    assert "failed transiently and will be retried" in caplog.text


def test_wait_for_async_reports_invalid_status_response_as_unknown(
    monkeypatch, fake_clock
):
    session = mock.Mock()
    session.get.return_value = async_status_response({"completed": True})
    monkeypatch.setattr(
        storageService, "_storage_api_session", mock.Mock(return_value=session)
    )
    monkeypatch.setattr(
        storageService, "_storage_service_url", lambda: "http://ss/api/v2/"
    )

    with pytest.raises(storageService.AsyncOutcomeUnknown) as exc_info:
        storageService.wait_for_async(async_response(), operation="create_file")

    assert exc_info.value.async_id == "158"
    assert "status response was invalid" in str(exc_info.value)
    assert "status request failed" not in str(exc_info.value)
    assert isinstance(exc_info.value.__cause__, KeyError)


def test_wait_for_async_preserves_reported_terminal_failure(monkeypatch, fake_clock):
    session = mock.Mock()
    session.get.return_value = async_status_response(
        {
            "completed": True,
            "was_error": True,
            "error_code": None,
            "error": "copy failed for an unknown reason",
        }
    )
    monkeypatch.setattr(
        storageService, "_storage_api_session", mock.Mock(return_value=session)
    )
    monkeypatch.setattr(
        storageService, "_storage_service_url", lambda: "http://ss/api/v2/"
    )

    with pytest.raises(storageService.WaitForAsyncError) as exc_info:
        storageService.wait_for_async(async_response(), operation="copy_files")

    assert not isinstance(exc_info.value, storageService.AsyncOutcomeUnknown)
    assert "reported failure: copy failed for an unknown reason" in str(exc_info.value)


def test_copy_files_does_not_resubmit_unknown_operation(
    monkeypatch, unknown_async_status_response
):
    monkeypatch.setattr(storageService.am, "get_setting", lambda _name: "dashboard")
    monkeypatch.setattr(
        storageService, "get_pipeline", lambda _uuid: {"resource_uri": "/pipeline/1/"}
    )
    monkeypatch.setattr(
        storageService, "_storage_service_url", lambda: "http://ss/api/v2/"
    )
    response = async_response()
    session = mock.Mock()
    session.post.return_value = response
    session.get.return_value = unknown_async_status_response
    monkeypatch.setattr(
        storageService, "_storage_api_session", mock.Mock(return_value=session)
    )

    result, error = storageService.copy_files(
        {"resource_uri": "/location/source/"},
        {"uuid": "destination"},
        [{"source": "source", "destination": "destination"}],
    )

    assert result is None
    assert isinstance(error, storageService.AsyncOutcomeUnknown)
    session.post.assert_called_once()


def test_create_file_does_not_resubmit_unknown_operation(
    monkeypatch, unknown_async_status_response
):
    monkeypatch.setattr(storageService.am, "get_setting", lambda _name: "dashboard")
    monkeypatch.setattr(
        storageService, "get_pipeline", lambda _uuid: {"resource_uri": "/pipeline/1/"}
    )
    monkeypatch.setattr(
        storageService, "_storage_service_url", lambda: "http://ss/api/v2/"
    )
    response = async_response()
    session = mock.Mock()
    session.post.return_value = response
    session.get.return_value = unknown_async_status_response
    monkeypatch.setattr(
        storageService, "_storage_api_session", mock.Mock(return_value=session)
    )

    with pytest.raises(storageService.AsyncOutcomeUnknown) as exc_info:
        storageService.create_file(
            "package-uuid",
            "/location/source/",
            "source-path",
            "/location/current/",
            "current-path",
            "AIP",
            123,
        )

    assert not isinstance(
        exc_info.value, storageService.AsyncObservationDeadlineExceeded
    )
    session.post.assert_called_once()
