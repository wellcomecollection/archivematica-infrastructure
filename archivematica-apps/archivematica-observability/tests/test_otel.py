"""Exercise the rendered collector's real HTTP exports against CloudWatch rules.

Only addresses, scrape intervals and the destination change for this test.
No AWS credentials or external network are used.
"""

import gzip
import json
from pathlib import Path
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from opentelemetry.proto.collector.metrics.v1.metrics_service_pb2 import (
    ExportMetricsServiceRequest,
)
from opentelemetry.proto.metrics.v1.metrics_pb2 import (
    AGGREGATION_TEMPORALITY_CUMULATIVE,
)
import pytest


class Fixture(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        if self.path == "/targets":
            self.send_header("Content-Type", "application/json")
            body = json.dumps(
                [
                    {
                        "targets": [f"127.0.0.1:{self.server.server_port}"],
                        "labels": {
                            "__metrics_path__": f"/metrics/{task}",
                            "environment": "staging",
                            "service": f"am-staging-{service}",
                            "task_id": task,
                        },
                    }
                    for task, service in [
                        *[(f"worker{i}", "mcp_client") for i in range(4)],
                        ("server", "mcp_server"),
                        ("storage", "storage-service"),
                    ]
                ]
            )
        else:
            self.send_header("Content-Type", "text/plain; version=0.0.4")
            with self.server.lock:
                sample = self.server.scrapes.get(self.path, 0) + 1
                self.server.scrapes[self.path] = sample
            if "/worker" in self.path:
                initial = 100
                if self.path.endswith("/worker0") and self.server.reset_at is not None:
                    if sample >= self.server.reset_at:
                        initial = 0
                        sample -= self.server.reset_at - 1
                body = f"""# TYPE mcpclient_job_total counter
mcpclient_job_total{{script_name="store"}} {initial + sample}
# TYPE mcpclient_task_execution_time_seconds histogram
mcpclient_task_execution_time_seconds_bucket{{script_name="store",le="1"}} {sample}
mcpclient_task_execution_time_seconds_bucket{{script_name="store",le="+Inf"}} {2 * sample}
mcpclient_task_execution_time_seconds_sum{{script_name="store"}} {4 * sample}
mcpclient_task_execution_time_seconds_count{{script_name="store"}} {2 * sample}
# TYPE mcpclient_job_progress gauge
"""
                body += "".join(
                    f'mcpclient_job_progress{{item="{i}"}} {i}\n'
                    for i in range(self.server.series)
                )
            elif self.path == "/cgroups":
                body = f"""# TYPE archivematica_cgroup_event_oom_total counter
archivematica_cgroup_event_oom_total{{task_id="storage",scope="task"}} {sample}
# TYPE archivematica_cgroup_current_bytes gauge
archivematica_cgroup_current_bytes{{task_id="storage",scope="task"}} 950
"""
            elif self.path.endswith("/server"):
                body = """# TYPE mcpserver_gearman_pending_jobs gauge
mcpserver_gearman_pending_jobs 3
"""
            else:
                body = f"""# TYPE django_http_requests_total_by_method_total counter
django_http_requests_total_by_method_total{{method="GET"}} {sample}
# TYPE async_manager_running_tasks gauge
async_manager_running_tasks 2
"""
            if self.path != "/cgroups":
                body += """# TYPE environment_variables_info gauge
environment_variables_info{SECRET="never-export-this"} 1
"""
        self.end_headers()
        self.wfile.write(body.encode())

    def log_message(self, *args):
        pass


def exported_metrics(requests):
    return [
        metric
        for request in requests
        for resource in request.resource_metrics
        for scope in resource.scope_metrics
        for metric in scope.metrics
    ]


class OtlpDestination(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers["Content-Length"]))
        if self.headers.get("Content-Encoding") == "gzip":
            body = gzip.decompress(body)
        request = ExportMetricsServiceRequest.FromString(body)
        points = []
        errors = []
        for metric in exported_metrics([request]):
            kind = metric.WhichOneof("data")
            if kind is None:
                errors.append(f"{metric.name}: metric has no data type")
                continue
            data = getattr(metric, kind)
            if not data.data_points:
                errors.append(f"{metric.name}: metric contains no datapoints")
            points.extend(data.data_points)
            if kind in {"sum", "histogram", "exponential_histogram"}:
                if data.aggregation_temporality == AGGREGATION_TEMPORALITY_CUMULATIVE:
                    for point in data.data_points:
                        if not 0 < point.start_time_unix_nano < point.time_unix_nano:
                            errors.append(
                                f"{metric.name}: missing or invalid start time"
                            )
        if len(points) > 1000:
            errors.append(f"Request contains {len(points)} datapoints; maximum is 1000")
        with self.server.lock:
            self.server.requests.append(request)
            self.server.errors.extend(errors)
        self.send_response(400 if errors else 200)
        self.send_header("Content-Type", "application/x-protobuf")
        self.end_headers()
        # An empty protobuf is a successful ExportMetricsServiceResponse.
        self.wfile.write("; ".join(errors).encode() if errors else b"")

    def log_message(self, *args):
        pass


@pytest.fixture
def otel_config(pytestconfig):
    config_path = pytestconfig.getoption("--otel-config")
    if config_path is None:
        pytest.skip("Provide --otel-config to run the OpenTelemetry integration test")
    return json.loads(Path(config_path).read_text())


@pytest.fixture
def endpoints():
    servers = [
        ThreadingHTTPServer(("127.0.0.1", 0), handler)
        for handler in (Fixture, OtlpDestination)
    ]
    threads = []
    for server in servers:
        server.lock = threading.Lock()
        server.scrapes = {}
        server.requests = []
        server.errors = []
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        threads.append(thread)
    try:
        yield servers
    finally:
        for server, thread in zip(servers, threads):
            server.shutdown()
            server.server_close()
            thread.join()


@pytest.mark.parametrize(
    "series,reset_at",
    [(0, None), (1205, None), (0, 4)],
    ids=["start-times", "batch-limit", "counter-reset"],
)
def test_prometheus_exports_meet_cloudwatch_requirements(
    tmp_path, otel_config, endpoints, series, reset_at
):
    config = otel_config
    source, destination = endpoints
    source.series = series
    source.reset_at = reset_at
    config["extensions"] = {}
    config["service"]["extensions"] = []
    config["receivers"].pop("hostmetrics")
    scrapes = config["receivers"]["prometheus"]["config"]["scrape_configs"]
    for scrape in scrapes:
        scrape.update(scrape_interval="1s", scrape_timeout="1s")
    scrapes[0]["http_sd_configs"][0].update(
        url=f"http://127.0.0.1:{source.server_port}/targets", refresh_interval="1s"
    )
    scrapes[1].update(
        metrics_path="/cgroups",
        static_configs=[{"targets": [f"127.0.0.1:{source.server_port}"]}],
    )
    exporter = config["exporters"]["otlphttp"]
    exporter.pop("auth")
    exporter[
        "metrics_endpoint"
    ] = f"http://127.0.0.1:{destination.server_port}/v1/metrics"
    config["processors"]["batch"]["timeout"] = "1s"
    config["service"]["pipelines"]["metrics"]["receivers"] = ["prometheus"]
    path = tmp_path / "config.json"
    path.write_text(json.dumps(config))
    with (tmp_path / "collector.log").open("w+") as logs:
        child = subprocess.Popen(
            ["/otelcol-contrib", "--config", str(path)], stdout=logs, stderr=logs
        )
        try:
            deadline = time.monotonic() + 20
            workers = set()
            while time.monotonic() < deadline:
                with destination.lock:
                    requests = list(destination.requests)
                    errors = list(destination.errors)
                if errors:
                    break
                workers = {
                    attr.value.string_value
                    for metric in exported_metrics(requests)
                    if metric.name == "mcpclient_job_total"
                    for point in metric.sum.data_points
                    for attr in point.attributes
                    if attr.key == "task_id"
                }
                samples = {
                    worker: {
                        point.time_unix_nano
                        for metric in exported_metrics(requests)
                        if metric.name == "mcpclient_job_total"
                        for point in metric.sum.data_points
                        if any(
                            a.key == "task_id" and a.value.string_value == worker
                            for a in point.attributes
                        )
                    }
                    for worker in workers
                }
                if workers == {f"worker{i}" for i in range(4)} and all(
                    len(points) >= 2 for points in samples.values()
                ):
                    reset_points = [
                        point
                        for metric in exported_metrics(requests)
                        if metric.name == "mcpclient_job_total"
                        for point in metric.sum.data_points
                        if any(
                            a.key == "task_id" and a.value.string_value == "worker0"
                            for a in point.attributes
                        )
                    ]
                    starts = {point.start_time_unix_nano for point in reset_points}
                    if reset_at is None or (
                        len(starts) == 2
                        and sum(
                            point.start_time_unix_nano == max(starts)
                            for point in reset_points
                        )
                        >= 2
                    ):
                        break
                if child.poll() is not None:
                    logs.seek(0)
                    raise AssertionError(logs.read())
                time.sleep(0.2)
        finally:
            child.terminate()
            child.wait(timeout=10)
        assert destination.requests, "Collector never exported metrics"
        assert not destination.errors, "\n".join(sorted(set(destination.errors)))
        data = b"".join(r.SerializeToString() for r in destination.requests)
        assert b"never-export-this" not in data and b"environment_variables" not in data
        metrics = exported_metrics(destination.requests)
        assert {
            "mcpclient_job_total",
            "mcpclient_task_execution_time_seconds",
            "mcpserver_gearman_pending_jobs",
            "django_http_requests_total_by_method_total",
            "async_manager_running_tasks",
            "archivematica_cgroup_event_oom_total",
            "archivematica_cgroup_current_bytes",
        } <= {metric.name for metric in metrics}
        assert workers == {f"worker{i}" for i in range(4)}
        histogram = next(
            m
            for m in metrics
            if m.name == "mcpclient_task_execution_time_seconds"
            and m.histogram.data_points
        )
        point = histogram.histogram.data_points[0]
        assert point.count > 0 and point.sum == 2 * point.count
        attributes = {a.key: a.value.string_value for a in point.attributes}
        assert attributes["task_id"] in workers
        assert attributes["service"] == "am-staging-mcp_client"
        counter = next(
            m for m in metrics if m.name == "mcpclient_job_total" and m.sum.data_points
        )
        assert counter.sum.is_monotonic
        for worker in workers:
            points = {
                point.time_unix_nano: point
                for metric in metrics
                if metric.name == "mcpclient_job_total"
                for point in metric.sum.data_points
                if any(
                    a.key == "task_id" and a.value.string_value == worker
                    for a in point.attributes
                )
            }
            starts = {point.start_time_unix_nano for point in points.values()}
            assert len(starts) == (
                2 if reset_at is not None and worker == "worker0" else 1
            )
            for start in starts:
                values = [
                    points[t].as_double
                    for t in sorted(points)
                    if points[t].start_time_unix_nano == start
                ]
                assert len(values) >= 2
                assert values[0] == 1, "Existing activity must not become a rate spike"
                assert all(b - a == 1 for a, b in zip(values, values[1:]))
        if series:
            assert any(
                sum(
                    len(getattr(m, m.WhichOneof("data")).data_points)
                    for m in exported_metrics([request])
                )
                == 1000
                for request in destination.requests
            ), "The large scrape did not exercise the request limit"
