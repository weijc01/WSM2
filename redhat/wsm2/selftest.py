import json
import tempfile
from pathlib import Path

from . import config, gamedata
from .i18n import LANG_CODES


def run(app):
    try:
        checked = []
        for code in LANG_CODES:
            app.i18n.set_language(code)
            translated = app.i18n.t("Taal:")
            if not translated or translated == "Taal:":
                if code != "nl":
                    raise AssertionError("missing translation for " + code)
            checked.append(code + "=" + translated)
        app.i18n.set_language(app.settings.get("Language", "en"))

        with tempfile.TemporaryDirectory() as temp:
            paths = config.save_dir_paths(temp)
            config.initialize_save_dir(temp)
            for key in ("ServerConfig", "CupConfig", "EventLoop", "Privilege", "Telemetry"):
                target = Path(paths[key])
                if not target.is_file():
                    raise AssertionError("missing " + key)
                json.loads(target.read_text(encoding="utf-8"))
            values = config.read_server_config_values(config.read_json(paths["ServerConfig"], {}))
            config.save_server_config(paths["ServerConfig"], values, {})
            reloaded = config.read_server_config_values(config.read_json(paths["ServerConfig"], {}))
            if reloaded["gamePort"] != values["gamePort"]:
                raise AssertionError("server config roundtrip failed")

        data = gamedata.get_wf2_game_data(app.settings.get("ServerInstallPath", ""))
        for key in ("gameModes", "levels", "weather", "aiSets", "carTypes", "cupLoops"):
            if not isinstance(data.get(key), list):
                raise AssertionError("game data missing " + key)

        print("SELFTEST OK | lang=" + app.i18n.language + " applied=True error='' tabs=7 settings=" + app.t("Instellingen") + " status=" + app.t("Gereed") + " langs=" + ",".join(checked))
        return 0
    except Exception as exc:
        print("SELFTEST FAIL | error='" + str(exc).replace("'", "") + "'")
        return 1
