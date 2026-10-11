import json
import threading
from http.server import ThreadingHTTPServer

import pytest
from prometheus_client.parser import text_string_to_metric_families

from collector import Monitor, fetch, targets_for


def task(identifier="task1", service="storage-service", address="10.0.0.1"):
    return {
        "taskArn": f"arn:aws:ecs:eu-west-1:123456789012:task/cluster/{identifier}",
        "group": f"service:am-staging-{service}",
        "containers": [{"runtimeId": "container1", "name": "app"}],
        "attachments": [
            {
                "type": "ElasticNetworkInterface",
                "details": [{"name": "privateIPv4Address", "value": address}],
            }
        ],
    }


@pytest.mark.parametrize("version", [1, 2], ids=["cgroup-v1", "cgroup-v2"])
def test_accounting_is_retained_after_task_disappears(tmp_path, version):
    parent = tmp_path / "ecs" / "task1"
    container = parent / "docker-container1.scope"
    container.mkdir(parents=True)
    values = (
        {
            "memory.current": "950",
            "memory.max": "1000",
            "memory.peak": "990",
            "memory.stat": "anon 200\nfile 750\nfile_dirty 100\nfile_writeback 40\n",
            "memory.events": "high 3\nmax 1\noom 1\noom_kill 1\n",
        }
        if version == 2
        else {
            "memory.usage_in_bytes": "950",
            "memory.limit_in_bytes": "1000",
            "memory.max_usage_in_bytes": "990",
            "memory.failcnt": "2",
            "memory.stat": "rss 1\ncache 2\ntotal_rss 200\ntotal_cache 750\ntotal_dirty 100\ntotal_writeback 40\n",
            "memory.oom_control": "oom_kill_disable 0\nunder_oom 0\noom_kill 1\n",
        }
    )
    for directory in [parent, container]:
        for filename, value in values.items():
            (directory / filename).write_text(value)
    meminfo = tmp_path / "meminfo"
    meminfo.write_text("Dirty: 10 kB\nWriteback: 2 kB\nMemAvailable: 100 kB\n")
    logs = []
    monitor = Monitor("staging", emit=logs.append)
    monitor.sample_memory([task()], tmp_path, meminfo, 100)
    assert monitor.memory_healthy
    retained = [json.loads(line) for line in logs]
    evidence = [r for r in retained if r["event"] == "cgroup_memory"]
    assert {r["scope"] for r in evidence} == {"task", "container"}
    assert all(r["file"] == 750 and r["file_dirty"] == 100 for r in evidence)
    server = ThreadingHTTPServer(("127.0.0.1", 0), monitor.handler())
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        exposed = fetch(f"http://127.0.0.1:{server.server_port}/metrics")
        families = list(text_string_to_metric_families(exposed))
        assert any(f.type == "counter" for f in families)
        assert "archivematica_cgroup_file_dirty_bytes" in exposed
        monitor.sample_memory([], tmp_path, meminfo, 110)
        assert not monitor.memory_healthy
        assert "task1" not in fetch(f"http://127.0.0.1:{server.server_port}/metrics")
        assert evidence[0]["peak"] == 990
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


def test_unlimited_container_is_not_treated_as_task_limit(tmp_path):
    container = tmp_path / "container1"
    container.mkdir()
    for name, value in {
        "memory.current": "123",
        "memory.max": "max",
        "memory.stat": "anon 123\n",
        "memory.events": "oom 0\n",
    }.items():
        (container / name).write_text(value)
    meminfo = tmp_path / "meminfo"
    meminfo.write_text("Dirty: 0 kB\n")
    monitor = Monitor("staging", emit=lambda _: None)
    monitor.sample_memory([task()], tmp_path, meminfo, 0)
    assert not monitor.memory_healthy


def test_discovery_targets_keep_all_worker_identities():
    tasks = [task(f"worker{i}", "mcp_client", f"10.0.0.{i + 1}") for i in range(4)]
    tasks += [
        task("server", "mcp_server"),
        task("storage"),
        task("dashboard", "dashboard"),
    ]
    targets = targets_for(tasks, "staging")
    assert len(targets) == 6
    assert len({t["labels"]["task_id"] for t in targets}) == 6
    assert all(t["labels"]["environment"] == "staging" for t in targets)
    assert targets[-1]["targets"] == ["10.0.0.1:9000"]
