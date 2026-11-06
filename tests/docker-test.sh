#!/usr/bin/env bash
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)

docker run --rm -v "$root:/src:ro" -w /src alpine:3.22 sh -ec '
    apk add --no-cache bash zsh fish starship python3
    bash tests/test.sh
    python3 tests/interactive.py
    python3 tests/starship.py
'
