# syntax=docker/dockerfile:1
FROM ghcr.io/astral-sh/uv:0.13.6@sha256:af22a52f5eafef3d78e551599d405c02df61919d18028f0cea8eda93bc9986d0 AS uv
FROM otel/opentelemetry-collector-contrib:0.164.0@sha256:340c9ca6a36617084c6661bdc4f0fe92b7cda5a805d61673ec8db375fddc522b AS otel

FROM debian:trixie-slim AS base
ENV UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_PYTHON_INSTALL_DIR=/opt/python \
    UV_PYTHON_BIN_DIR=/usr/local/bin \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"
# Upstream Python builds retain pip for compatibility with non-uv workflows:
# https://github.com/astral-sh/python-build-standalone/issues/1007
# This image uses uv during builds and Python directly at runtime, so pip and
# its ensurepip wheel are unused. Remove both in the installation layer to
# avoid shipping their vendored dependencies; mount uv only during builds.
RUN --mount=type=bind,from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && uv python install 3.15.2 \
    && PYTHON_PREFIX=$(python3.15 -c 'import sys; print(sys.prefix)') \
    && uv pip uninstall --python "$PYTHON_PREFIX/bin/python3" --break-system-packages pip \
    && rm -f "$PYTHON_PREFIX"/lib/python3.*/ensurepip/_bundled/pip-*.whl
ENV UV_PYTHON_DOWNLOADS=0
WORKDIR /app

FROM base AS dependencies
COPY pyproject.toml uv.lock .python-version ./
RUN --mount=type=bind,from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev --no-install-project

FROM base AS runtime
RUN groupadd --gid 10001 collector \
    && useradd --uid 10001 --gid 10001 --create-home --shell /usr/sbin/nologin collector
COPY --from=dependencies /opt/venv /opt/venv
COPY --from=otel /otelcol-contrib /otelcol-contrib
COPY pyproject.toml uv.lock .python-version collector.py ./
ENV PYTHONDONTWRITEBYTECODE=1
USER 10001:10001
# The image already contains its locked environment; startup never installs.
ENTRYPOINT ["/opt/venv/bin/python", "collector.py"]

FROM runtime AS test
USER root
RUN --mount=type=bind,from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    UV_CACHE_DIR=/root/.cache/uv uv sync --locked --no-install-project
COPY tests ./tests
USER 10001:10001
ENTRYPOINT ["/opt/venv/bin/python", "-m", "pytest", "-v", "-o", "cache_dir=/tmp/pytest-cache"]

FROM runtime AS final
