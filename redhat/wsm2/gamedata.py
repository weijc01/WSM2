import os
import re
import shutil
from pathlib import Path

GAME_MODE_IDS = [
    "racing",
    "bangerrace",
    "teamracing",
    "lastmanstanding",
    "knockout",
    "hotseat",
]

INSTALL_NAMES = [
    "Wreckfest 2 Dedicated Server",
    "Wreckfest2 Dedicated Server",
    "Wreckfest 2",
    "Wreckfest2",
]


def steam_roots():
    candidates = []
    env_root = os.environ.get("STEAMROOT")
    if env_root:
        candidates.append(Path(env_root))
    home = Path.home()
    candidates.extend([
        home / ".local" / "share" / "Steam",
        home / ".steam" / "steam",
        home / ".steam" / "root",
        Path("/usr/share/steam"),
        Path("/opt/steam"),
    ])
    result = []
    seen = set()
    for root in candidates:
        try:
            resolved = root.resolve()
        except OSError:
            resolved = root
        key = str(resolved).casefold()
        if resolved.is_dir() and key not in seen:
            seen.add(key)
            result.append(resolved)
    return result


def steam_libraries():
    roots = steam_roots()
    libraries = list(roots)
    seen = {str(root).casefold() for root in roots}
    for root in roots:
        vdf = root / "steamapps" / "libraryfolders.vdf"
        if not vdf.is_file():
            continue
        try:
            raw = vdf.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for match in re.finditer(r'"path"\s+"([^"]+)"', raw):
            value = match.group(1).replace("\\\\", "\\")
            candidate = Path(value)
            key = str(candidate).casefold()
            if candidate.is_dir() and key not in seen:
                seen.add(key)
                libraries.append(candidate)
    return libraries


def find_wf2_server_install():
    for library in steam_libraries():
        common = library / "steamapps" / "common"
        for name in INSTALL_NAMES:
            candidate = common / name
            if (candidate / "Wreckfest2.exe").is_file() or (candidate / "Wreckfest2").is_file():
                return str(candidate)
    return ""


def find_steam_exe():
    found = shutil.which("steam")
    if found:
        return found
    for root in steam_roots():
        for name in ("steam", "steam.sh"):
            candidate = root / name
            if candidate.is_file():
                return str(candidate)
    return ""


def find_steam_root():
    roots = steam_roots()
    return str(roots[0]) if roots else ""


def _relative(base, path):
    try:
        return path.relative_to(base).as_posix()
    except ValueError:
        return path.as_posix()


def get_wf2_game_data(install_path):
    base = Path(install_path) if install_path else Path()
    levels = []
    weather = []
    ai_sets = ["runtime/career/ai-class-all.aist"]
    car_types = []
    cup_loops = []
    if base.is_dir():
        data = base / "data" / "property"
        levels = sorted({_relative(base, p) for p in data.glob("event/**/*.evse")})
        weather = sorted({_relative(base, p) for p in data.glob("weather/*.weat")})
        ai_sets += sorted({_relative(base, p) for p in data.glob("career/**/*.aist")})
        car_types = sorted({p.name for p in (base / "data" / "vehicle").iterdir() if p.is_dir()}) if (base / "data" / "vehicle").is_dir() else []
        cup_loops = sorted({_relative(base, p) for p in data.glob("settings/cup/*.becl")})
    return {
        "installPath": str(base),
        "gameModes": list(GAME_MODE_IDS),
        "levels": levels,
        "weather": weather,
        "aiSets": list(dict.fromkeys(ai_sets)),
        "carTypes": car_types,
        "cupLoops": cup_loops,
    }
