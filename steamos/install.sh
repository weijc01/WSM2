#!/usr/bin/env sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found. Install it with: sudo pacman -S python" >&2
    exit 1
fi
APPLICATIONS="$HOME/.local/share/applications"
mkdir -p "$APPLICATIONS"
chmod +x "$SCRIPT_DIR/wsm2.sh"
python3 - "$SCRIPT_DIR/wsm2.desktop" "$SCRIPT_DIR" "$APPLICATIONS/wsm2.desktop" <<'PY'
import sys
from pathlib import Path
template, app_dir, target = sys.argv[1], sys.argv[2], sys.argv[3]
text = Path(template).read_text(encoding="utf-8").replace("@APP_DIR@", app_dir)
Path(target).write_text(text, encoding="utf-8")
PY
echo "Installed launcher: $APPLICATIONS/wsm2.desktop"
