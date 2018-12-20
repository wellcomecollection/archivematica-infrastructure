#!/usr/bin/env python
# -*- encoding: utf-8

import subprocess
import time

import pytest
import requests


@pytest.fixture(scope="session")
def container_url():
    subprocess.check_call(["docker-compose", "up", "--build", "--detach"])
    time.sleep(2)
    yield "http://localhost:8080"
    subprocess.check_call(["docker-compose", "stop"])


def test_root_endpoint_is_404(container_url):
    r = requests.get(container_url + "/")
    assert r.status_code == 404


class TestDashboardEndpoint:

    def test_endpoint_is_200(self, container_url):
        r = requests.get(container_url + "/archivematica/dashboard/")
        assert r.status_code == 200
        assert r.json() == {
            "name": "dashboard",
            "path": "/",
        }

    def test_get_redirect_endpoint_is_200(self, container_url):
        r = requests.get(container_url + "/archivematica/dashboard/foo")
        print(r.text)
        assert r.status_code == 200
        assert r.json() == {
            "name": "dashboard",
            "path": "/bar",
            "from_redirect": True,
        }

    def test_head_redirect_endpoint_is_302(self, container_url):
        r = requests.head(container_url + "/archivematica/dashboard/foo")
        assert r.status_code == 302
        assert (
            r.headers["Location"] ==
            "http://localhost:8080/archivematica/dashboard/bar"
        )
