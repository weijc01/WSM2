import json

from . import config, gamedata, server, settings
from .errors import Wsm2Error

INVALID_KEY = "Ongeldige waarde: {0}"
RUNNING_KEY = "Server wordt uitgevoerd. Stop eerst de server."


def copy_obj(value):
    return json.loads(json.dumps(value))


def list_from(obj, key):
    container = obj.get(key) if isinstance(obj, dict) else None
    if not isinstance(container, list):
        return []
    return [item if isinstance(item, dict) else {} for item in container]


class App:
    def __init__(self, i18n):
        self.i18n = i18n
        self.settings = settings.load_settings()
        self.i18n.set_language(self.settings.get("Language", "en"))
        self.game_data = gamedata.get_wf2_game_data(self.settings.get("ServerInstallPath", ""))
        self.paths = None
        self.server_config = {}
        self.server_values = {}
        self.event_loop = {}
        self.cup_config = {}
        self.privilege = {}
        self.telemetry = {}
        self.event_index = 0
        self.cup_index = 0

    def t(self, key, *args):
        return self.i18n.t(key, *args)

    def error_text(self, exc):
        if isinstance(exc, Wsm2Error) and exc.key:
            return self.t(exc.key, *exc.args)
        return str(exc)

    def _read(self, key, factory):
        try:
            value = config.read_json(self.paths[key], factory())
            return value if isinstance(value, dict) else factory()
        except Wsm2Error as exc:
            raise Wsm2Error(self.t("Fout bij laden: {0}", str(exc)))

    def load_all(self):
        save_dir = settings.current_save_dir(self.settings)
        self.paths = config.save_dir_paths(save_dir)
        config.initialize_save_dir(save_dir)
        self.game_data = gamedata.get_wf2_game_data(self.settings.get("ServerInstallPath", ""))
        self.server_config = self._read("ServerConfig", config.new_default_server_config)
        self.server_values = config.read_server_config_values(self.server_config)
        self.event_loop = self._read("EventLoop", config.new_default_event_loop)
        self.cup_config = self._read("CupConfig", config.new_default_cup_config)
        self.privilege = self._read("Privilege", config.new_default_privilege)
        self.telemetry = self._read("Telemetry", config.new_default_telemetry)
        if not isinstance(self.event_loop.get("events"), list):
            self.event_loop["events"] = config.new_default_event_loop()["events"]
        if not isinstance(self.cup_config.get("cups"), list):
            self.cup_config["cups"] = config.new_default_cup_config()["cups"]
        if not isinstance(self.privilege.get("roles"), list):
            self.privilege["roles"] = []
        if not isinstance(self.privilege.get("bans"), list):
            self.privilege["bans"] = []
        self.event_index = min(self.event_index, max(0, len(self.events()) - 1))
        self.cup_index = min(self.cup_index, max(0, len(self.cups()) - 1))

    def save_all(self):
        self.save_server_config()
        self.save_event_loop()
        self.save_cup_config()
        self.save_privilege()
        self.save_telemetry()
        settings.save_settings(self.settings)

    def _write(self, key, value):
        try:
            config.write_json(self.paths[key], value, backup=True)
        except OSError as exc:
            raise Wsm2Error(self.t("Fout bij opslaan: {0}", str(exc)))
        except Wsm2Error as exc:
            raise Wsm2Error(self.t("Fout bij opslaan: {0}", str(exc)))

    def save_server_config(self):
        result = config.save_server_config(self.paths["ServerConfig"], self.server_values, self.server_config)
        self.server_config = result

    def save_event_loop(self):
        self._write("EventLoop", self.event_loop)

    def save_cup_config(self):
        self._write("CupConfig", self.cup_config)

    def save_privilege(self):
        self._write("Privilege", self.privilege)

    def save_telemetry(self):
        self._write("Telemetry", self.telemetry)

    def save_settings_only(self):
        try:
            settings.save_settings(self.settings)
        except OSError as exc:
            raise Wsm2Error(self.t("Fout bij opslaan: {0}", str(exc)))
        except Wsm2Error as exc:
            raise Wsm2Error(self.t("Fout bij opslaan: {0}", str(exc)))

    def events(self):
        return list_from(self.event_loop, "events")

    def cups(self):
        return list_from(self.cup_config, "cups")

    def current_event(self):
        items = self.events()
        if not items:
            return None
        return items[min(self.event_index, len(items) - 1)]

    def current_cup(self):
        items = self.cups()
        if not items:
            return None
        return items[min(self.cup_index, len(items) - 1)]

    def roles(self):
        return list_from(self.privilege, "roles")

    def bans(self):
        return list_from(self.privilege, "bans")

    def validate_server_values(self):
        checks = [
            ("gamePort", 1, 65535),
            ("countdownTime", 0, 86400000),
            ("votingTime", 0, 86400000),
            ("censorReport", 0, 1000000),
            ("silenceReport", 0, 1000000),
            ("suspendReport", 0, 1000000),
            ("serverCensor", -1, 52560000),
            ("serverSilence", -1, 52560000),
            ("serverSuspend", -1, 52560000),
            ("adminCensor", -1, 52560000),
            ("adminSilence", -1, 52560000),
            ("adminSuspend", -1, 52560000),
            ("defaultCensor", -1, 52560000),
            ("defaultSilence", -1, 52560000),
            ("defaultSuspend", -1, 52560000),
        ]
        for key, low, high in checks:
            try:
                value = int(self.server_values.get(key, low))
            except (TypeError, ValueError):
                raise Wsm2Error(self.t(INVALID_KEY, key), INVALID_KEY, (key,))
            if value < low or value > high:
                raise Wsm2Error(self.t(INVALID_KEY, key), INVALID_KEY, (key,))
            self.server_values[key] = value

    def server_status(self):
        return server.server_running(self.settings.get("ServerInstallPath", ""))

    def start_server(self, mode=None):
        running, pids = self.server_status()
        if running:
            raise Wsm2Error(self.t(RUNNING_KEY), RUNNING_KEY, ())
        selected_mode = mode or settings.current_mode(self.settings)
        pid, launcher, log_path = server.start_server(self.settings, settings.current_save_dir(self.settings), selected_mode)
        return pid, launcher, log_path

    def stop_server(self):
        return server.stop_server(self.settings.get("ServerInstallPath", ""))

    def log_path(self):
        return server.find_log_path(settings.current_save_dir(self.settings), self.server_values.get("logFileName", ""))

    def log_tail(self):
        return server.read_log_tail(self.log_path(), self.settings.get("LogLines", 300))

    def open_path(self, path):
        return server.open_path(path)
