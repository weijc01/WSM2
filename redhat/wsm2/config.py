import json
import shutil
from datetime import datetime
from pathlib import Path

from .errors import Wsm2Error


def save_dir_paths(save_dir):
    base = Path(save_dir)
    telemetry = base / "telemetry"
    return {
        "SaveDir": base,
        "ServerConfig": base / "server_config.scnf",
        "CupConfig": base / "server_cup_config.ccnl",
        "EventLoop": base / "event_loop.xml",
        "Privilege": base / "server_privilege.sprv",
        "TelemetryDir": telemetry,
        "Telemetry": telemetry / "config.json",
    }


def read_json(path, default=None):
    target = Path(path)
    if not target.exists():
        return default
    try:
        raw = target.read_text(encoding="utf-8")
    except OSError as exc:
        raise Wsm2Error(str(exc))
    if not raw.strip():
        return default
    try:
        return json.loads(raw)
    except ValueError as exc:
        raise Wsm2Error(str(exc))


def write_json(path, obj, backup=True):
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    if backup and target.exists():
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        try:
            shutil.copy2(str(target), str(target) + "." + stamp + ".bak")
        except OSError:
            pass
    text = json.dumps(obj, indent=2, ensure_ascii=False)
    target.write_text(text, encoding="utf-8")


def new_default_server_config():
    durations = {
        "censor duration": 1440,
        "silence duration": 1440,
        "suspend duration": 525600,
    }
    return {
        "net server config": [{
            "name": "Wreckfest 2 Server",
            "description": "Welkom op mijn server!",
            "password": "",
            "log file name": "",
            "game port": 30100,
        }],
        "game server config": [{
            "cup list": "",
            "event loop name": "default_loop",
            "countdown time": 100000,
            "voting time": 20000,
            "flags": "",
            "auto ban report limits": [{
                "censor report limit": 4,
                "silence report limit": 8,
                "suspend report limit": 12,
            }],
            "server ban durations": [dict(durations)],
            "admin ban durations": [dict(durations)],
            "default ban durations": [dict(durations)],
        }],
    }


def new_event_rule():
    return {
        "laps": 3,
        "time limit": 5,
        "number of teams": 1,
        "max number of participants": 24,
        "flags": "",
        "collecting order": "Collecting Sequential",
        "car reset delay (seconds)": 2,
        "team split (%)": 0,
        "vehicle damage id": "",
    }


def new_event_level():
    return {
        "level id": "",
        "weather path": "",
        "weather intent path": "",
        "ai set path": "runtime/career/ai-class-all.aist",
        "game mode id": "bangerrace",
    }


def new_event():
    return {
        "level": [new_event_level()],
        "rules": [new_event_rule()],
        "car restriction": [],
        "bot count": 8,
    }


def new_cup_race_settings():
    return {
        "point distribution": "30;27;25;20;19;18;17;16;15;14;13;12;11;10;9;8;7;6;5;4;3;2;1;0",
        "flags": "",
        "start order": "random",
        "points for best lap time": 0,
        "points for highest score": 0,
        "last race multiplier": 1,
    }


def new_cup():
    return {
        "race settings": [new_cup_race_settings()],
        "event loop": "data/property/settings/cup/waypoint_tracks.becl",
        "cup name": "Nieuwe cup",
        "cup description": "",
        "icon": "",
        "car restriction": [],
    }


def new_default_event_loop():
    event = new_event()
    event["level"][0]["level id"] = "track01_1"
    event["level"][0]["weather path"] = "data/property/weather/track01_1.weat"
    event["rules"][0]["laps"] = 4
    return {"events": [event]}


def new_default_cup_config():
    return {"cups": [new_cup()]}


def new_default_privilege():
    return {"bbmeta": "sprv v0 n1", "roles": [], "bans": []}


def new_default_telemetry():
    return {
        "udp": [{"enabled": 0, "ip": "127.0.0.1", "port": "23123"}],
        "logging": [{"format": "none"}],
        "server": [{"enabled": 0, "automaticMainCar": 0}],
    }


def initialize_save_dir(save_dir):
    paths = save_dir_paths(save_dir)
    paths["SaveDir"].mkdir(parents=True, exist_ok=True)
    paths["TelemetryDir"].mkdir(parents=True, exist_ok=True)
    for key, factory in (
        ("ServerConfig", new_default_server_config),
        ("CupConfig", new_default_cup_config),
        ("EventLoop", new_default_event_loop),
        ("Privilege", new_default_privilege),
        ("Telemetry", new_default_telemetry),
    ):
        path = paths[key]
        if not path.exists():
            write_json(path, factory(), backup=False)


def read_server_config_values(obj):
    root = obj if isinstance(obj, dict) else {}
    net_list = root.get("net server config") or [{}]
    game_list = root.get("game server config") or [{}]
    net = net_list[0] if isinstance(net_list, list) and net_list else {}
    game = game_list[0] if isinstance(game_list, list) and game_list else {}

    def first(collection, key, default):
        items = collection or [{}]
        item = items[0] if isinstance(items, list) and items else {}
        return item.get(key, default)

    report = game.get("auto ban report limits")
    server_bans = game.get("server ban durations")
    admin_bans = game.get("admin ban durations")
    default_bans = game.get("default ban durations")
    return {
        "name": net.get("name") or "Server",
        "description": net.get("description", ""),
        "password": net.get("password", ""),
        "logFileName": net.get("log file name", ""),
        "gamePort": net.get("game port", 30100),
        "cupList": game.get("cup list", ""),
        "eventLoopName": game.get("event loop name") or "default_loop",
        "countdownTime": game.get("countdown time", 100000),
        "votingTime": game.get("voting time", 20000),
        "flags": game.get("flags", ""),
        "censorReport": first(report, "censor report limit", 4),
        "silenceReport": first(report, "silence report limit", 8),
        "suspendReport": first(report, "suspend report limit", 12),
        "serverCensor": first(server_bans, "censor duration", 1440),
        "serverSilence": first(server_bans, "silence duration", 1440),
        "serverSuspend": first(server_bans, "suspend duration", 525600),
        "adminCensor": first(admin_bans, "censor duration", 1440),
        "adminSilence": first(admin_bans, "silence duration", 1440),
        "adminSuspend": first(admin_bans, "suspend duration", 525600),
        "defaultCensor": first(default_bans, "censor duration", 1440),
        "defaultSilence": first(default_bans, "silence duration", 1440),
        "defaultSuspend": first(default_bans, "suspend duration", 525600),
    }


def save_server_config(path, values, existing=None):
    root = existing if isinstance(existing, dict) else {}
    result = {}
    if root.get("bbmeta") is not None:
        result["bbmeta"] = root["bbmeta"]
    result["net server config"] = [{
        "name": values["name"],
        "description": values["description"],
        "password": values["password"],
        "log file name": values["logFileName"],
        "game port": int(values["gamePort"]),
    }]
    result["game server config"] = [{
        "cup list": values["cupList"],
        "event loop name": values["eventLoopName"],
        "countdown time": int(values["countdownTime"]),
        "voting time": int(values["votingTime"]),
        "flags": values["flags"],
        "auto ban report limits": [{
            "censor report limit": int(values["censorReport"]),
            "silence report limit": int(values["silenceReport"]),
            "suspend report limit": int(values["suspendReport"]),
        }],
        "server ban durations": [{
            "censor duration": int(values["serverCensor"]),
            "silence duration": int(values["serverSilence"]),
            "suspend duration": int(values["serverSuspend"]),
        }],
        "admin ban durations": [{
            "censor duration": int(values["adminCensor"]),
            "silence duration": int(values["adminSilence"]),
            "suspend duration": int(values["adminSuspend"]),
        }],
        "default ban durations": [{
            "censor duration": int(values["defaultCensor"]),
            "silence duration": int(values["defaultSilence"]),
            "suspend duration": int(values["defaultSuspend"]),
        }],
    }]
    write_json(path, result, backup=True)
    return result
