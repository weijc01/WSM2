from pathlib import Path

from .errors import Wsm2Error

OS_RELEASE_PATH = Path("/etc/os-release")


def read_os_release(path=None):
    target = path or OS_RELEASE_PATH
    values = {}
    try:
        raw = target.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return values
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key] = value.strip().strip('"').strip("'")
    return values


def is_cachyos(values=None):
    data = values if values is not None else read_os_release()
    identifier = data.get("ID", "").casefold()
    name = data.get("NAME", "").casefold()
    return identifier == "cachyos" or name.startswith("cachyos")


def assert_cachyos():
    values = read_os_release()
    if is_cachyos(values):
        return
    detected = values.get("PRETTY_NAME") or values.get("NAME") or "unknown"
    raise Wsm2Error("WSM2 for CachyOS only. Detected: " + str(detected))
