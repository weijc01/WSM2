import os
from pathlib import Path

from . import gamedata
from .config import read_json, write_json
from .i18n import LANG_CODES

APP_ROOT = Path(__file__).resolve().parent.parent


def config_dir():
    configured = os.environ.get("XDG_CONFIG_HOME")
    base = Path(configured) if configured else Path.home() / ".config"
    return base / "wsm2"


SETTINGS_PATH = config_dir() / "WSM2.settings.json"


def default_save_dir():
    return Path.home() / "WreckFest2server"


def new_default_settings(install_path="", steam_exe=""):
    return {
        "ServerInstallPath": str(install_path or gamedata.find_wf2_server_install()),
        "SteamExe": str(steam_exe or gamedata.find_steam_exe()),
        "LastProfile": "Standaard",
        "Language": os.environ.get("WSM2_LANG", "en"),
        "FollowLog": True,
        "Launcher": os.environ.get("WSM2_LAUNCHER", "auto"),
        "LogLines": 300,
        "Profiles": [{
            "Name": "Standaard",
            "SaveDir": str(default_save_dir()),
            "Mode": "community",
        }],
    }


def load_settings():
    data = read_json(SETTINGS_PATH, {})
    if not isinstance(data, dict):
        data = {}
    defaults = new_default_settings()
    for key, value in defaults.items():
        data.setdefault(key, value)
    profiles = data.get("Profiles")
    if not isinstance(profiles, list) or not profiles:
        profiles = defaults["Profiles"]
    else:
        normalized = []
        for profile in profiles:
            if not isinstance(profile, dict):
                continue
            normalized.append({
                "Name": str(profile.get("Name") or "Profiel"),
                "SaveDir": str(profile.get("SaveDir") or default_save_dir()),
                "Mode": str(profile.get("Mode") or "community"),
            })
        profiles = normalized or defaults["Profiles"]
    data["Profiles"] = profiles
    language = os.environ.get("WSM2_LANG", data.get("Language", "en"))
    data["Language"] = language if language in LANG_CODES else "en"
    launcher = os.environ.get("WSM2_LAUNCHER", data.get("Launcher", "auto"))
    data["Launcher"] = launcher if launcher in ("auto", "native", "proton", "wine") else "auto"
    try:
        data["LogLines"] = max(1, min(5000, int(data.get("LogLines", 300))))
    except (TypeError, ValueError):
        data["LogLines"] = 300
    data["FollowLog"] = bool(data.get("FollowLog", True))
    return data


def save_settings(data):
    write_json(SETTINGS_PATH, data, backup=False)


def current_profile(settings):
    wanted = settings.get("LastProfile", "")
    for profile in settings.get("Profiles", []):
        if profile.get("Name") == wanted:
            return profile
    profiles = settings.get("Profiles") or []
    return profiles[0] if profiles else {"Name": "Standaard", "SaveDir": str(default_save_dir()), "Mode": "community"}


def current_save_dir(settings):
    return str(current_profile(settings).get("SaveDir") or default_save_dir())


def current_mode(settings):
    return str(current_profile(settings).get("Mode") or "community")


def set_current_profile(settings, name):
    settings["LastProfile"] = name
