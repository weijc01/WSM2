import os
import shutil
import signal
import subprocess
import time
from pathlib import Path

from . import gamedata
from .errors import Wsm2Error

SERVER_EXE_NAME = "Wreckfest2.exe"
NATIVE_EXE_NAME = "Wreckfest2"
APP_ID = "1203190"
NO_LAUNCHER_KEY = "Geen Proton/Wine gevonden om de server te starten."
NOT_FOUND_KEY = "Server-executable niet gevonden: {0}"


def server_executable(install_path):
    base = Path(install_path) if install_path else Path()
    for name in (NATIVE_EXE_NAME, SERVER_EXE_NAME):
        candidate = base / name
        if candidate.is_file():
            return candidate
    raise Wsm2Error(NOT_FOUND_KEY.format(str(base)), NOT_FOUND_KEY, (str(base),))


def find_proton():
    override = os.environ.get("PROTON_PATH")
    if override:
        candidate = Path(override)
        if candidate.is_file():
            return candidate
    candidates = []
    for root in gamedata.steam_roots():
        candidates.extend(root.glob("steamapps/common/Proton*/proton"))
        candidates.extend(root.glob("compatibilitytools.d/*/proton"))
        candidates.extend(root.glob("steamapps/common/Proton Experimental/proton"))
    candidates = [item for item in candidates if item.is_file()]
    if not candidates:
        return None
    candidates.sort(key=lambda item: (item.parent.name, str(item)), reverse=True)
    return candidates[0]


def find_wine():
    return shutil.which("wine")


def ensure_steam_app_id(install_path):
    base = Path(install_path)
    target = base / "steam_appid.txt"
    if not target.exists():
        target.write_text(APP_ID, encoding="ascii")


def build_launch(settings, save_dir, mode):
    install = str(settings.get("ServerInstallPath") or "")
    launcher = str(settings.get("Launcher") or "auto")
    native = Path(install) / NATIVE_EXE_NAME
    windows_exe = Path(install) / SERVER_EXE_NAME
    args = ["--server" if mode == "community" else "--local-server", "--save-dir=" + str(save_dir)]
    env = os.environ.copy()

    if launcher in ("auto", "native") and native.is_file():
        return [str(native)] + args, env, "native"

    if launcher == "native":
        raise Wsm2Error(NOT_FOUND_KEY.format(str(native)), NOT_FOUND_KEY, (str(native),))

    if launcher in ("auto", "proton"):
        proton = find_proton()
        if proton is not None:
            if not windows_exe.is_file():
                raise Wsm2Error(NOT_FOUND_KEY.format(str(windows_exe)), NOT_FOUND_KEY, (str(windows_exe),))
            prefix = Path(save_dir) / "proton_prefix"
            prefix.mkdir(parents=True, exist_ok=True)
            env["STEAM_COMPAT_DATA_PATH"] = str(prefix)
            steam_root = gamedata.find_steam_root()
            if steam_root:
                env["STEAM_COMPAT_CLIENT_INSTALL_PATH"] = steam_root
            return [str(proton), "run", str(windows_exe)] + args, env, "proton"
        if launcher == "proton":
            raise Wsm2Error(NO_LAUNCHER_KEY, NO_LAUNCHER_KEY, ())

    wine = find_wine()
    if wine and windows_exe.is_file():
        return [wine, str(windows_exe)] + args, env, "wine"

    if native.is_file():
        return [str(native)] + args, env, "native"

    if not windows_exe.is_file():
        raise Wsm2Error(NOT_FOUND_KEY.format(str(Path(install))), NOT_FOUND_KEY, (str(Path(install)),))
    raise Wsm2Error(NO_LAUNCHER_KEY, NO_LAUNCHER_KEY, ())


def start_server(settings, save_dir, mode):
    command, env, launcher = build_launch(settings, save_dir, mode)
    install = Path(str(settings.get("ServerInstallPath") or ""))
    ensure_steam_app_id(install)
    Path(save_dir).mkdir(parents=True, exist_ok=True)
    console_log = Path(save_dir) / "wsm2_server_console.log"
    with console_log.open("ab") as handle:
        process = subprocess.Popen(
            command,
            cwd=str(install),
            env=env,
            stdin=subprocess.DEVNULL,
            stdout=handle,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
    return process.pid, launcher, str(console_log)


def running_pids(install_path):
    base = Path(install_path) if install_path else Path()
    needles = set()
    for name in (SERVER_EXE_NAME, NATIVE_EXE_NAME):
        candidate = base / name
        try:
            needles.add(str(candidate.resolve()).casefold())
        except OSError:
            needles.add(str(candidate.absolute()).casefold())
    result = []
    proc = Path("/proc")
    if not proc.is_dir():
        return result
    for entry in proc.iterdir():
        if not entry.name.isdigit():
            continue
        try:
            raw = (entry / "cmdline").read_bytes().replace(b"\0", b" ")
            text = raw.decode("utf-8", "replace").casefold()
        except OSError:
            continue
        if any(needle in text for needle in needles):
            result.append(int(entry.name))
    return sorted(result)


def server_running(install_path):
    pids = running_pids(install_path)
    return bool(pids), pids


def stop_server(install_path):
    pids = running_pids(install_path)
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        except OSError:
            pass
    deadline = time.time() + 4
    while time.time() < deadline:
        remaining = [pid for pid in running_pids(install_path) if pid in pids]
        if not remaining:
            return len(pids), []
        time.sleep(0.2)
    for pid in pids:
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        except OSError:
            pass
    remaining = [pid for pid in running_pids(install_path) if pid in pids]
    return len(pids), remaining


def find_log_path(save_dir, log_file_name=""):
    base = Path(save_dir)
    if log_file_name:
        candidate = Path(log_file_name)
        if not candidate.is_absolute():
            candidate = base / candidate
        if candidate.is_file():
            return candidate
    candidates = [
        base / "server.log",
        base / "wsm2_server_console.log",
        base / "Wreckfest2.log",
        base / "dedicated-server.log",
        base / "logs" / "server.log",
    ]
    existing = [item for item in candidates if item.is_file()]
    if not existing:
        return candidates[0]
    return max(existing, key=lambda item: item.stat().st_mtime)


def read_log_tail(path, lines=300):
    target = Path(path)
    if not target.is_file():
        return ""
    try:
        content = target.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""
    return "".join(content.splitlines(keepends=True)[-max(1, int(lines)):])


def open_path(path):
    target = str(path)
    opener = shutil.which("xdg-open")
    if not opener:
        return False
    try:
        subprocess.Popen([opener, target], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return True
    except OSError:
        return False
