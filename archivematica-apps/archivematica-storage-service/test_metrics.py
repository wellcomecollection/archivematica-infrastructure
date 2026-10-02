#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["gunicorn==26.2.0", "prometheus-client==0.26.0"]
# [tool.uv]
# exclude-newer = "2026-10-11T06:33:38Z"
# ///
"""Check an overlaid Storage Service checkout or image without Django or a DB."""

import argparse
import os
from pathlib import Path
import runpy
import select
import subprocess
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from prometheus_client import CollectorRegistry, generate_latest, multiprocess
from prometheus_client.parser import text_string_to_metric_families

WORKER = """
import runpy
import sys

metrics = runpy.run_path(sys.argv[1])
metrics["async_manager_running_tasks"].inc(int(sys.argv[2]))
metrics["async_manager_interrupted_tasks_counter"].inc()
print("ready", flush=True)
sys.stdin.read()
"""


def samples(exposition, name):
    return [
        (sample.labels, sample.value)
        for family in text_string_to_metric_families(exposition)
        for sample in family.samples
        if sample.name == name
    ]


class MetricsTest(unittest.TestCase):
    source: Path
    gunicorn_config: Path

    def setUp(self):
        # Prometheus decides its storage mode when a worker imports it. Each
        # worker below starts a fresh interpreter with Gunicorn's environment.
        environment = {
            key: value
            for key, value in os.environ.items()
            if key.lower() != "prometheus_multiproc_dir"
        }
        environment.update(SS_PROMETHEUS_ENABLED="true", SS_GUNICORN_WORKERS="2")
        env_patch = patch.dict(os.environ, environment, clear=True)
        env_patch.start()
        self.addCleanup(env_patch.stop)
        source_path = str(self.source / "src")
        sys.path.insert(0, source_path)
        self.addCleanup(sys.path.remove, source_path)
        self.config = runpy.run_path(str(self.gunicorn_config))
        self.addCleanup(self.config["on_exit"], None)
        for setting in self.config["raw_env"]:
            key, value = setting.split("=", 1)
            os.environ[key] = value
        self.metrics_path = (
            self.source / "src/archivematica/storage_service/locations/metrics.py"
        )

    def start_worker(self, running):
        worker = subprocess.Popen(
            [sys.executable, "-c", WORKER, str(self.metrics_path), str(running)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
        )

        def cleanup():
            if worker.poll() is None:
                worker.kill()
            worker.wait(timeout=5)
            worker.stdin.close()
            worker.stdout.close()

        self.addCleanup(cleanup)
        self.assertTrue(select.select([worker.stdout], [], [], 10)[0])
        self.assertEqual(worker.stdout.readline(), "ready\n")
        return worker

    def scrape(self):
        registry = CollectorRegistry()
        multiprocess.MultiProcessCollector(registry)
        return generate_latest(registry).decode()

    def test_dead_worker_leaves_no_running_work_but_keeps_counters(self):
        first = self.start_worker(1)
        second = self.start_worker(2)
        self.start_worker(0)
        gauge = "async_manager_running_tasks"
        self.assertEqual(sum(value for _, value in samples(self.scrape(), gauge)), 3)

        # An abrupt exit cannot decrement its gauge. Run the actual configured
        # Gunicorn hook, then inspect the public Prometheus exposition again.
        first.kill()
        first.wait(timeout=5)
        self.config["child_exit"](None, SimpleNamespace(pid=first.pid))
        self.assertEqual(samples(self.scrape(), gauge), [({}, 2)])

        second.kill()
        second.wait(timeout=5)
        self.config["child_exit"](None, SimpleNamespace(pid=second.pid))
        self.assertEqual(samples(self.scrape(), gauge), [({}, 0)])
        self.assertEqual(
            samples(self.scrape(), "async_manager_interrupted_tasks_total"), [({}, 3)]
        )

    def test_single_process_still_reports_running_tasks(self):
        environment = {
            key: value
            for key, value in os.environ.items()
            if key.lower() != "prometheus_multiproc_dir"
        }
        result = subprocess.run(
            [
                sys.executable,
                "-c",
                "import runpy, sys; from prometheus_client import generate_latest; "
                "m = runpy.run_path(sys.argv[1]); "
                "m['async_manager_running_tasks'].inc(2); "
                "m['async_manager_running_tasks'].dec(); "
                "print(generate_latest().decode())",
                str(self.metrics_path),
            ],
            env=environment,
            capture_output=True,
            text=True,
            check=True,
            timeout=10,
        )
        self.assertEqual(
            samples(result.stdout, "async_manager_running_tasks"), [({}, 1)]
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--gunicorn-config", type=Path)
    args, test_args = parser.parse_known_args()
    MetricsTest.source = args.source.resolve()
    MetricsTest.gunicorn_config = args.gunicorn_config or (
        MetricsTest.source / "install/storage-service.gunicorn-config.py"
    )
    unittest.main(argv=[sys.argv[0], *test_args])
