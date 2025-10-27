FROM ghcr.io/foundry-rs/foundry:v1.3.5

RUN set -eux; \
    if command -v apt-get >/dev/null 2>&1; then \
        apt-get update; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3 python3-venv; \
        rm -rf /var/lib/apt/lists/*; \
    elif command -v apk >/dev/null 2>&1; then \
        apk add --no-cache python3 py3-virtualenv; \
    else \
        echo "Unable to determine package manager for Python installation." >&2; \
        exit 1; \
    fi
