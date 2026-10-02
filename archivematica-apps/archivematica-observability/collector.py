"""ECS discovery and retained cgroup memory evidence.

No Docker socket or write access to the host is required. Detailed samples are
logged before cgroups disappear.
Prometheus histograms are scraped separately by OpenTelemetry and sent via OTLP.
"""

import json
import os
from pathlib import Path
import signal
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.request import urlopen

import boto3
from botocore.config import Config

PORT = 9401


def fetch(url):
    with urlopen(url, timeout=4) as response:
        # Bound exposure to unexpectedly large endpoints. Never log the body:
        # MCPServer includes an environment-variable info series.
        data = response.read(8 * 1024 * 1024 + 1)
        if len(data) > 8 * 1024 * 1024:
            raise ValueError("metrics response exceeds size limit")
        return data.decode()


def read_values(path):
    return {
        key: int(value)
        for key, value in (line.split() for line in path.read_text().splitlines())
    }


def read_memory(path):
    """Read the enforced accounting, not a cache-subtracted working set."""
    v2 = (path / "memory.current").exists()
    stat = read_values(path / "memory.stat")
    result = {"cgroup_version": 2 if v2 else 1}
    files = (
        {"current": "memory.current", "limit": "memory.max", "peak": "memory.peak"}
        if v2
        else {
            "current": "memory.usage_in_bytes",
            "limit": "memory.limit_in_bytes",
            "peak": "memory.max_usage_in_bytes",
            "limit_hits": "memory.failcnt",
        }
    )
    for key, filename in files.items():
        try:
            value = (path / filename).read_text().strip()
        except FileNotFoundError:
            if key in {"current", "limit"}:
                raise
            continue
        if value != "max":
            number = int(value)
            # cgroup v1 represents an unlimited limit using a huge sentinel.
            if key != "limit" or number < 2**60:
                result[key] = number
    if v2:
        for key in ("anon", "file", "file_dirty", "file_writeback"):
            if key in stat:
                result[key] = stat[key]
        for key, value in read_values(path / "memory.events").items():
            result[f"event_{key}"] = value
    else:
        # total_* includes children at the ECS task parent cgroup.
        for key, field in {
            "anon": "rss",
            "file": "cache",
            "file_dirty": "dirty",
            "file_writeback": "writeback",
        }.items():
            if f"total_{field}" in stat or field in stat:
                result[key] = stat.get(f"total_{field}", stat.get(field))
        oom = path / "memory.oom_control"
        if oom.exists():
            for key, value in read_values(oom).items():
                result[f"oom_{key}"] = value
    return result


def memory_records(root, tasks):
    """Match both ECS task parents and Docker container cgroups by identity."""
    identities = {}
    for task in tasks:
        task_id = task["taskArn"].rsplit("/", 1)[-1]
        base = {
            "task_id": task_id,
            "service": task.get("group", "").removeprefix("service:"),
        }
        identities[task_id] = {**base, "scope": "task", "container": ""}
        for container in task.get("containers", []):
            if container.get("runtimeId"):
                identities[container["runtimeId"]] = {
                    **base,
                    "scope": "container",
                    "container": container["name"],
                }
    records = []
    for filename in ("memory.current", "memory.usage_in_bytes"):
        for file in root.rglob(filename):
            # Exact component matching accommodates cgroupfs and systemd.
            name = file.parent.name
            if name.startswith("ecstasks-") and name.endswith(".slice"):
                name = name.removeprefix("ecstasks-").removesuffix(".slice")
            name = name.removesuffix(".scope")
            for prefix in ("docker-", "ecs-"):
                name = name.removeprefix(prefix)
            identity = identities.get(name)
            if identity is None:
                continue
            try:
                records.append({**identity, **read_memory(file.parent)})
            except (OSError, ValueError):
                # Tasks can disappear between discovery and reading. Coverage
                # is reported separately; do not fabricate a zero sample.
                continue
    return records


def discover(ecs, cluster, own_task):
    own = ecs.describe_tasks(cluster=cluster, tasks=[own_task])
    if own.get("failures") or len(own.get("tasks", [])) != 1:
        raise ValueError("collector task could not be discovered")
    instance = own["tasks"][0]["containerInstanceArn"]
    arns = []
    for page in ecs.get_paginator("list_tasks").paginate(
        cluster=cluster, containerInstance=instance, desiredStatus="RUNNING"
    ):
        arns.extend(page["taskArns"])
    tasks = []
    for offset in range(0, len(arns), 100):
        response = ecs.describe_tasks(
            cluster=cluster, tasks=arns[offset : offset + 100]
        )
        if response.get("failures"):
            raise ValueError("incomplete ECS discovery")
        tasks.extend(
            task for task in response["tasks"] if task["lastStatus"] == "RUNNING"
        )
    return tasks, instance


def targets_for(tasks, environment):
    targets = []
    for task in tasks:
        service = task.get("group", "").removeprefix("service:")
        suffix = service.removeprefix(f"am-{environment}-")
        port = {"mcp_server": 9100, "mcp_client": 9100, "storage-service": 9000}.get(
            suffix
        )
        if port is None:
            continue
        addresses = [
            detail["value"]
            for attachment in task.get("attachments", [])
            if attachment["type"] == "ElasticNetworkInterface"
            for detail in attachment.get("details", [])
            if detail["name"] == "privateIPv4Address"
        ]
        if len(addresses) != 1:
            raise ValueError("task has no unique private address")
        targets.append(
            {
                "targets": [f"{addresses[0]}:{port}"],
                "labels": {
                    "environment": environment,
                    "service": service,
                    "task_id": task["taskArn"].rsplit("/", 1)[-1],
                },
            }
        )
    return targets


def exposition(records):
    families = {}
    counters = {
        "limit_hits",
        "event_low",
        "event_high",
        "event_max",
        "event_oom",
        "event_oom_kill",
        "event_oom_group_kill",
        "oom_oom_kill",
    }
    for record in records:
        labels = ",".join(
            f"{key}={json.dumps(str(record[key]))}"
            for key in ("task_id", "service", "scope", "container")
        )
        for key, value in record.items():
            if key in {"task_id", "service", "scope", "container", "cgroup_version"}:
                continue
            kind = "counter" if key in counters else "gauge"
            suffix = (
                "_total"
                if key in counters
                else ("" if key.startswith("oom_") else "_bytes")
            )
            name = f"archivematica_cgroup_{key}{suffix}"
            families.setdefault(name, [f"# TYPE {name} {kind}"]).append(
                f"{name}{{{labels}}} {value}"
            )
    return "\n".join(line for lines in families.values() for line in lines) + "\n"


class Monitor:
    def __init__(self, environment, emit=print):
        self.environment = environment
        self.emit = emit
        self.targets = []
        self.records = []
        self.lock = threading.Lock()
        self.last_cycle = 0
        self.discovery_healthy = False
        self.memory_healthy = False

    def sample_memory(self, tasks, root, meminfo, now):
        records = memory_records(root, tasks)
        ss = [
            t
            for t in tasks
            if t.get("group") == f"service:am-{self.environment}-storage-service"
        ]
        expected = {t["taskArn"].rsplit("/", 1)[-1] for t in ss}
        covered = {r["task_id"] for r in records if r["scope"] == "task"}
        # A container-only reading cannot establish the aggregate ECS task limit.
        healthy = bool(expected) and expected <= covered
        for r in records:
            self.emit(
                json.dumps(
                    {
                        "event": "cgroup_memory",
                        "environment": self.environment,
                        "timestamp": now,
                        **r,
                    }
                )
            )
        host = {}
        for line in meminfo.read_text().splitlines():
            key, value, *_ = line.split()
            if key in {"Dirty:", "Writeback:", "MemAvailable:", "Cached:"}:
                host[key.rstrip(":")] = int(value) * 1024
        self.emit(
            json.dumps(
                {
                    "event": "host_memory",
                    "environment": self.environment,
                    "timestamp": now,
                    **host,
                }
            )
        )
        with self.lock:
            self.records = records
            self.memory_healthy = healthy

    def handler(self):
        monitor = self

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                with monitor.lock:
                    if self.path == "/targets":
                        body = json.dumps(monitor.targets)
                    elif self.path == "/metrics":
                        body = exposition(monitor.records)
                        body += f"# TYPE archivematica_discovery_healthy gauge\narchivematica_discovery_healthy {int(monitor.discovery_healthy)}\n"
                        body += f"# TYPE archivematica_cgroup_collection_healthy gauge\narchivematica_cgroup_collection_healthy {int(monitor.memory_healthy)}\n"
                    elif (
                        self.path == "/health"
                        and time.monotonic() - monitor.last_cycle < 120
                    ):
                        body = "ok"
                    else:
                        self.send_error(503)
                        return
                self.send_response(200)
                self.send_header(
                    "Content-Type",
                    (
                        "application/json"
                        if self.path == "/targets"
                        else "text/plain; version=0.0.4"
                    ),
                )
                self.end_headers()
                self.wfile.write(body.encode())

            def log_message(self, *args):
                pass

        return Handler


def main():
    environment = os.environ["ENVIRONMENT"]
    metadata = json.loads(fetch(os.environ["ECS_CONTAINER_METADATA_URI_V4"] + "/task"))
    ecs = boto3.client(
        "ecs",
        config=Config(connect_timeout=3, read_timeout=5, retries={"max_attempts": 2}),
    )
    monitor = Monitor(environment)
    server = ThreadingHTTPServer(("127.0.0.1", PORT), monitor.handler())
    threading.Thread(target=server.serve_forever, daemon=True).start()
    config = Path("/tmp/otel.json")
    settings = json.loads(os.environ["OTEL_CONFIG"])
    settings["processors"]["resource"]["attributes"].append(
        {
            "key": "archivematica.collector.task.arn",
            "value": metadata["TaskARN"],
            "action": "upsert",
        }
    )
    config.write_text(json.dumps(settings))
    child = subprocess.Popen(["/otelcol-contrib", "--config", str(config)])
    stopped = threading.Event()
    for sig in (signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, lambda *_: stopped.set())
    tasks, targets = [], []
    next_discovery = 0
    try:
        while not stopped.is_set():
            if child.poll() is not None:
                raise RuntimeError("OpenTelemetry collector exited")
            now = time.time()
            if now >= next_discovery:
                try:
                    tasks, _ = discover(ecs, metadata["Cluster"], metadata["TaskARN"])
                    targets = targets_for(tasks, environment)
                    with monitor.lock:
                        monitor.targets = targets
                    monitor.discovery_healthy = True
                except Exception as exc:
                    tasks, targets = [], []
                    with monitor.lock:
                        monitor.targets = []
                    monitor.discovery_healthy = False
                    print(
                        json.dumps(
                            {
                                "event": "discovery_error",
                                "error_type": type(exc).__name__,
                            }
                        ),
                        flush=True,
                    )
                next_discovery = now + 60
            try:
                monitor.sample_memory(
                    tasks,
                    Path("/hostfs/sys/fs/cgroup"),
                    Path("/hostfs/proc/meminfo"),
                    now,
                )
            except (OSError, ValueError) as exc:
                with monitor.lock:
                    monitor.records = []
                monitor.memory_healthy = False
                print(
                    json.dumps(
                        {"event": "memory_error", "error_type": type(exc).__name__}
                    ),
                    flush=True,
                )
            monitor.last_cycle = time.monotonic()
            stopped.wait(10)
    finally:
        child.terminate()
        try:
            child.wait(timeout=20)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait()
        server.shutdown()


if __name__ == "__main__":
    main()
