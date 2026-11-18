from . import gamedata, settings
from .errors import Wsm2Error
from .uikit import ask_bool, ask_choice, ask_int, edit_fields, edit_json, numbered_menu, print_indexed, prompt, show_error, show_info
from .ui_tabs import _guard_running

SAVE_WHILE_RUNNING_KEY = "De server draait nog. Stop de server eerst voordat je de configuratie opslaat (de server overschrijft de bestanden bij het afsluiten)."


def roles_tab(app):
    while True:
        roles = app.roles()
        bans = app.bans()
        print_indexed(app.t("Rollen (server_privilege.sprv)"), roles, 0, lambda item: str(item.get("name", item)))
        print("  " + app.t("Bans (JSON-array)") + ": " + str(len(bans)))
        action = numbered_menu(app.t("Rollen & Bans"), [
            (app.t("Rij toevoegen"), lambda: roles.append({})),
            (app.t("Type"), lambda: _edit_role(app, roles)),
            (app.t("Rij verwijderen"), lambda: _delete_role(app, roles)),
            (app.t("Bans (JSON-array)"), lambda: _edit_bans(app)),
            (app.t("Rollen & bans opslaan"), lambda: _save_privilege(app)),
            (app.t("Herladen"), lambda: app.load_all()),
        ])
        if action is None:
            return
        try:
            action()
        except Exception as exc:
            show_error(app, exc)


def _edit_role(app, roles):
    if not roles:
        return
    raw = prompt(app.t("Rol (admin/mod)"), "1").strip()
    try:
        index = max(0, min(len(roles) - 1, int(raw) - 1))
    except ValueError:
        index = 0
    value = edit_json(app.t("Rollen (server_privilege.sprv)"), roles[index])
    if isinstance(value, dict):
        roles[index] = value


def _delete_role(app, roles):
    if roles:
        del roles[0]


def _edit_bans(app):
    value = edit_json(app.t("Bans (JSON-array)"), app.bans())
    if not isinstance(value, list):
        raise Wsm2Error(app.t("Bans bevatten ongeldige JSON: {0}", "list"))
    app.privilege["bans"] = value


def _save_privilege(app):
    app.save_privilege()
    show_info(app.t("Rollen & bans opgeslagen: {0}", len(app.roles())))


def telemetry_tab(app):
    udp = _first(app.telemetry, "udp", {"enabled": 0, "ip": "127.0.0.1", "port": "23123"})
    logging = _first(app.telemetry, "logging", {"format": "none"})
    server_entry = _first(app.telemetry, "server", {"enabled": 0, "automaticMainCar": 0})
    while True:
        action = numbered_menu(app.t("Server-telemetrie"), [
            (app.t("UDP (telemetry/config.json)"), lambda: edit_fields(app, app.t("UDP (telemetry/config.json)"), udp, [
                ("enabled", app.t("UDP ingeschakeld"), "int", 0, 0, 1),
                ("ip", app.t("IP-adres:"), "str", "127.0.0.1"),
                ("port", app.t("Poort:"), "str", "23123"),
            ])),
            (app.t("Logging"), lambda: edit_fields(app, app.t("Logging"), logging, [
                ("format", app.t("Formaat:"), "str", "none"),
            ])),
            (app.t("Server-telemetrie ingeschakeld"), lambda: edit_fields(app, app.t("Server-telemetrie ingeschakeld"), server_entry, [
                ("enabled", app.t("UDP ingeschakeld"), "int", 0, 0, 1),
                ("automaticMainCar", app.t("automaticMainCar"), "int", 0, 0, 1),
            ])),
            (app.t("Telemetrie opslaan"), lambda: _save_telemetry(app)),
            (app.t("Herladen"), lambda: app.load_all()),
        ])
        if action is None:
            return
        try:
            action()
        except Exception as exc:
            show_error(app, exc)


def _first(obj, key, default):
    items = obj.get(key)
    if not isinstance(items, list) or not items:
        items = [dict(default)]
        obj[key] = items
    if not isinstance(items[0], dict):
        items[0] = dict(default)
    return items[0]


def _save_telemetry(app):
    app.save_telemetry()
    show_info(app.t("Telemetrie opgeslagen: {0}", app.paths["Telemetry"]))


def start_tab(app):
    while True:
        running, pids = app.server_status()
        state = app.t("Status: SERVER DRAAIT") if running else app.t("Status: gestopt")
        profile = settings.current_profile(app.settings)
        print("\n" + app.t("Starten") + " - " + state + " " + str(pids))
        print("  " + app.t("Profiel:") + " " + str(profile.get("Name", "")))
        print("  " + app.t("Modus:") + " " + str(profile.get("Mode", "")))
        action = numbered_menu(app.t("Server bedienen"), [
            (app.t("START server"), lambda: _start(app)),
            (app.t("STOP server"), lambda: _stop(app)),
            (app.t("Status vernieuwen"), lambda: None),
            (app.t("Modus (community/local)"), lambda: _choose_mode(app)),
            (app.t("Profiel:"), lambda: _choose_profile(app)),
            (app.t("Serverlog"), lambda: _show_log(app)),
            (app.t("Logbestand openen"), lambda: app.open_path(app.log_path())),
            (app.t("Map openen"), lambda: app.open_path(app.paths["SaveDir"])),
        ])
        if action is None:
            return
        try:
            action()
        except Exception as exc:
            show_error(app, exc)


def _start(app):
    pid, launcher, log_path = app.start_server()
    show_info(app.t("Server gestart (PID {0}, launcher {1}).", pid, launcher) + "\n" + str(log_path))


def _stop(app):
    count, remaining = app.stop_server()
    show_info(app.t("Server gestopt ({0} proces(sen)).", count) + ("\n" + str(remaining) if remaining else ""))


def _choose_mode(app):
    _guard_running(app)
    options = [(item, app.t(label)) for item, label in (
        ("community", "community (--server)"),
        ("local", "lokaal (--local-server)"),
    )]
    profile = settings.current_profile(app.settings)
    profile["Mode"] = ask_choice(app.t("Modus (community/local)"), options, profile.get("Mode", "community"))


def _choose_profile(app):
    _guard_running(app)
    options = [(item.get("Name", ""), str(item.get("Name", ""))) for item in app.settings.get("Profiles", [])]
    name = ask_choice(app.t("Profiel:"), options, settings.current_profile(app.settings).get("Name"))
    settings.set_current_profile(app.settings, name)
    app.save_settings_only()
    app.load_all()


def _show_log(app):
    path = app.log_path()
    if not path.is_file():
        show_info(app.t("Logbestand nog niet gevonden: {0}", path))
        return
    text = app.log_tail()
    if not text:
        show_info(app.t("Geen serverlog gevonden."))
        return
    print("\n" + app.t("Serverlog") + ": " + str(path))
    print(text)
    input("\n[Enter] ")


def settings_tab(app):
    while True:
        print("\n" + app.t("Instellingen") + " - " + str(app.paths["SaveDir"]))
        action = numbered_menu(app.t("Instellingen"), [
            (app.t("Installatiepaden"), lambda: edit_fields(app, app.t("Installatiepaden"), app.settings, [
                ("ServerInstallPath", app.t("Server-installatiemap:"), "str", ""),
                ("SteamExe", app.t("Steam.exe:"), "str", ""),
            ])),
            (app.t("Automatisch detecteren"), lambda: _auto_detect(app)),
            (app.t("Profielen (naam, save-dir, modus)"), lambda: _profiles(app)),
            (app.t("Taal:"), lambda: _choose_language(app)),
            (app.t("Launcher"), lambda: _choose_launcher(app)),
            (app.t("Instellingen opslaan"), lambda: _save_settings(app)),
            (app.t("Herladen"), lambda: app.load_all()),
        ])
        if action is None:
            return
        try:
            action()
        except Exception as exc:
            show_error(app, exc)


def _auto_detect(app):
    app.settings["ServerInstallPath"] = gamedata.find_wf2_server_install()
    app.settings["SteamExe"] = gamedata.find_steam_exe()
    app.game_data = gamedata.get_wf2_game_data(app.settings["ServerInstallPath"])
    show_info(app.t("Server-installatie niet gevonden.") if not app.settings["ServerInstallPath"] else app.settings["ServerInstallPath"])


def _profiles(app):
    profiles = app.settings.get("Profiles", [])
    while True:
        print_indexed(app.t("Profielen (naam, save-dir, modus)"), profiles, 0, lambda item: str(item.get("Name", "")) + " | " + str(item.get("SaveDir", "")) + " | " + str(item.get("Mode", "")))
        action = numbered_menu(app.t("Profielen opslaan"), [
            (app.t("Rij toevoegen"), lambda: profiles.append({"Name": "Profiel", "SaveDir": str(settings.default_save_dir()), "Mode": "community"})),
            (app.t("Regels"), lambda: _edit_profile(app, profiles)),
            (app.t("Rij verwijderen"), lambda: _delete_profile(app, profiles)),
            (app.t("Profielen opslaan"), lambda: _save_settings(app)),
        ])
        if action is None:
            return
        try:
            action()
        except Exception as exc:
            show_error(app, exc)


def _edit_profile(app, profiles):
    if not profiles:
        return
    raw = prompt(app.t("Profiel:"), "1").strip()
    try:
        index = max(0, min(len(profiles) - 1, int(raw) - 1))
    except ValueError:
        index = 0
    edit_fields(app, app.t("Profiel:"), profiles[index], [
        ("Name", app.t("Naam:"), "str", "Profiel"),
        ("SaveDir", app.t("Save-dir:"), "str", str(settings.default_save_dir())),
        ("Mode", app.t("Modus (community/local)"), "str", "community"),
    ])


def _delete_profile(app, profiles):
    if len(profiles) <= 1:
        raise Wsm2Error(app.t("Er moet minstens één profiel zijn."))
    del profiles[0]


def _choose_language(app):
    from .i18n import LANG_CODES, LANG_NAMES
    options = [(code, LANG_NAMES[code]) for code in LANG_CODES]
    code = ask_choice(app.t("Taal:"), options, app.settings.get("Language", "en"))
    app.settings["Language"] = code
    app.i18n.set_language(code)
    app.save_settings_only()


def _choose_launcher(app):
    options = [(item, item) for item in ("auto", "native", "proton", "wine")]
    app.settings["Launcher"] = ask_choice("Launcher", options, app.settings.get("Launcher", "auto"))
    app.save_settings_only()


def _save_settings(app):
    profiles = app.settings.get("Profiles", [])
    if not profiles:
        raise Wsm2Error(app.t("Er moet minstens één profiel zijn."))
    app.settings["LogLines"] = ask_int("LogLines", app.settings.get("LogLines", 300), 1, 5000)
    app.settings["FollowLog"] = ask_bool(app.t("Automatisch verversen"), app.settings.get("FollowLog", True))
    app.save_settings_only()
    app.load_all()
    show_info(app.t("Instellingen en profielen opgeslagen."))
