#!/usr/bin/env sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export PYTHONUTF8=1
if ! grep -Eiq '^ID="?cachyos"?$' /etc/os-release 2>/dev/null; then
    echo "WSM2 for CachyOS only." >&2
    exit 2
fi
exec python3 "$SCRIPT_DIR/WSM2.py" "$@"
