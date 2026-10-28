# syntax=docker/dockerfile:1
FROM ghcr.io/astral-sh/uv:0.13.6@sha256:af22a52f5eafef3d78e551599d405c02df61919d18028f0cea8eda93bc9986d0 AS uv
FROM otel/opentelemetry-collector-contrib:0.163.2-386@sha256:bd0aac7fc525d8016b7bba1e35287b1f3a43c1e2d52e2426e2496d8d45668784 AS otel

FROM debian:trixie-slim AS base
COPY --from=uv /uv /usr/local/bin/uv
ENV UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_PYTHON_INSTALL_DIR=/opt/python \
    UV_PYTHON_BIN_DIR=/usr/local/bin \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && uv python install 3.15.1
ENV UV_PYTHON_DOWNLOADS=0
WORKDIR /app

FROM base AS dependencies
COPY pyproject.toml uv.lock .python-version ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev --no-install-project

FROM base AS runtime
RUN groupadd --gid 10001 collector \
    && useradd --uid 10001 --gid 10001 --create-home --shell /usr/sbin/nologin collector
COPY --from=dependencies /opt/venv /opt/venv
COPY --from=otel /otelcol-contrib /otelcol-contrib
COPY pyproject.toml uv.lock .python-version collector.py ./
ENV UV_CACHE_DIR=/tmp/uv \
    PYTHONDONTWRITEBYTECODE=1
USER 10001:10001
# The image already contains its locked environment; startup never installs.
ENTRYPOINT ["uv", "run", "--no-sync", "--offline", "collector.py"]

FROM runtime AS test
USER root
RUN --mount=type=cache,target=/root/.cache/uv \
    UV_CACHE_DIR=/root/.cache/uv uv sync --locked --no-install-project
COPY tests ./tests
USER 10001:10001
ENTRYPOINT ["uv", "run", "--no-sync", "--offline", "pytest", "-v", "-o", "cache_dir=/tmp/pytest-cache"]

FROM runtime AS final
