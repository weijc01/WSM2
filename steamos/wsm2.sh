#!/usr/bin/env sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export PYTHONUTF8=1
if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found. Install it with: sudo pacman -S python" >&2
    exit 1
fi
exec python3 "$SCRIPT_DIR/WSM2.py" "$@"
