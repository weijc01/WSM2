from pathlib import Path

from . import config
from .errors import Wsm2Error
from .uikit import ask_choice, ask_int, edit_fields, edit_json, move_item, numbered_menu, print_indexed, prompt, show_error, show_info

SAVE_WHILE_RUNNING_KEY = "De server draait nog. Stop de server eerst voordat je de configuratie opslaat (de server overschrijft de bestanden bij het afsluiten)."


def _ensure(obj, key, factory):
    items = obj.get(key)
    if not isinstance(items, list) or not items:
        items = [factory()]
        obj[key] = items
    if not isinstance(items[0], dict):
        items[0] = factory()
    return items[0]


def _guard_running(app):
    running, _ = app.server_status()
    if running:
        raise Wsm2Error(app.t(SAVE_WHILE_RUNNING_KEY), SAVE_WHILE_RUNNING_KEY, ())


def _choice_values(values, current):
    result = list(values)
    if current and current not in result:
        result.insert(0, current)
    return [(item, item) for item in result] or [(current or "", current or "")]


def _edit_event(app, event):
    while True:
        rules = _ensure(event, "rules", config.new_event_rule)
        level = _ensure(event, "level", config.new_event_level)
        action = numbered_menu(app.t("Evenementen"), [
            (app.t("Regels"), lambda: edit_fields(app, app.t("Regels"), rules, [
                ("laps", app.t("Rondes:"), "int", 3, 0, 1000),
                ("time limit", app.t("Tijdslimiet:"), "int", 5, 0, 1000),
                ("number of teams", app.t("Teams:"), "int", 1, 1, 64),
                ("max number of participants", app.t("Max deelnemers:"), "int", 24, 1, 128),
                ("flags", app.t("Vlaggen:"), "str", ""),
                ("collecting order", app.t("Collecting:"), "str", "Collecting Sequential"),
                ("car reset delay (seconds)", app.t("Car reset (s):"), "int", 2, 0, 600),
                ("team split (%)", app.t("Team split (%):"), "int", 0, 0, 100),
                ("vehicle damage id", app.t("Schade-id:"), "str", ""),
            ])),
            (app.t("Level"), lambda: edit_fields(app, app.t("Level"), level, [
                ("level id", app.t("Level id:"), "choice", "", _choice_values(app.game_data.get("levels", []), level.get("level id", ""))),
                ("weather path", app.t("Weer:"), "choice", "", _choice_values(app.game_data.get("weather", []), level.get("weather path", ""))),
                ("ai set path", app.t("AI-set:"), "choice", "", _choice_values(app.game_data.get("aiSets", []), level.get("ai set path", ""))),
                ("game mode id", app.t("Game mode:"), "choice", "", _choice_values(app.game_data.get("gameModes", []), level.get("game mode id", ""))),
                ("weather intent path", app.t("Weer:") + " intent", "str", ""),
            ])),
            (app.t("Bots:"), lambda: event.__setitem__("bot count", ask_int(app.t("Bots:"), event.get("bot count", 8), 0, 64))),
            (app.t("Car restrictions (JSON-array)"), lambda: event.__setitem__("car restriction", edit_json(app.t("Car restrictions (JSON-array)"), event.get("car restriction", [])))),
        ])
        if action is None:
            return
        try:
            action()
        except Exception as exc:
            show_error(app, exc)


def server_tab(app):
    while True:
        running, pids = app.server_status()
        state = app.t("Status: SERVER DRAAIT") if running else app.t("Status: gestopt")
        print("\n" + app.t("Server") + " - " + state + " " + str(pids))
        action = numbered_menu(app.t("Server"), [
            (app.t("Netwerk (server_config.scnf)"), lambda: edit_fields(app, app.t("Netwerk (server_config.scnf)"), app.server_values, [
                ("name", app.t("Naam:"), "str", "Server"),
                ("description", app.t("Beschrijving:"), "str", ""),
                ("password", app.t("Wachtwoord:"), "str", ""),
                ("logFileName", app.t("Logbestand:"), "str", ""),
                ("gamePort", app.t("Game poort:"), "int", 30100, 1, 65535),
            ])),
            (app.t("Spel"), lambda: edit_fields(app, app.t("Spel"), app.server_values, [
                ("eventLoopName", app.t("Event loop:"), "str", "default_loop"),
                ("cupList", app.t("Cup list:"), "str", ""),
                ("countdownTime", app.t("Countdown (ms):"), "int", 100000, 0, 86400000),
                ("votingTime", app.t("Voting (ms):"), "int", 20000, 0, 86400000),
                ("flags", app.t("Vlaggen:"), "str", ""),
            ])),
            (app.t("Auto-ban meldingen"), lambda: edit_fields(app, app.t("Auto-ban meldingen"), app.server_values, [
                ("censorReport", app.t("Censor:"), "int", 4, 0, 1000000),
                ("silenceReport", app.t("Silence:"), "int", 8, 0, 1000000),
                ("suspendReport", app.t("Suspend:"), "int", 12, 0, 1000000),
            ])),
            (app.t("Ban-duren (minuten)"), lambda: edit_fields(app, app.t("Ban-duren (minuten)"), app.server_values, [
                ("serverCensor", app.t("Server bans:") + " " + app.t("Censor:"), "int", 1440, -1, 52560000),
                ("serverSilence", app.t("Server bans:") + " " + app.t("Silence:"), "int", 1440, -1, 52560000),
                ("serverSuspend", app.t("Server bans:") + " " + app.t("Suspend:"), "int", 525600, -1, 52560000),
                ("adminCensor", app.t("Admin bans:") + " " + app.t("Censor:"), "int", 1440, -1, 52560000),
                ("adminSilence", app.t("Admin bans:") + " " + app.t("Silence:"), "int", 1440, -1, 52560000),
                ("adminSuspend", app.t("Admin bans:") + " " + app.t("Suspend:"), "int", 525600, -1, 52560000),
                ("defaultCensor", app.t("Default bans:") + " " + app.t("Censor:"), "int", 1440, -1, 52560000),
                ("defaultSilence", app.t("Default bans:") + " " + app.t("Silence:"), "int", 1440, -1, 52560000),
                ("defaultSuspend", app.t("Default bans:") + " " + app.t("Suspend:"), "int", 525600, -1, 52560000),
            ])),
            (app.t("Serverconfig opslaan"), lambda: _save_server(app)),
            (app.t("Herladen"), lambda: app.load_all()),
            (app.t("Map openen"), lambda: app.open_path(app.paths["SaveDir"])),
        ])
        if action is None:
            return
        try:
            action()
        except Exception as exc:
            show_error(app, exc)


def _save_server(app):
    _guard_running(app)
    app.validate_server_values()
    app.save_server_config()
    show_info(app.t("Serverconfiguratie opgeslagen."))


def events_tab(app):
    while True:
        events = app.events()
        print_indexed(app.t("Evenementen"), events, app.event_index, lambda item: " / ".join([
            str(_ensure(item, "level", config.new_event_level).get("level id", "")),
            str(_ensure(item, "rules", config.new_event_rule).get("laps", "")),
        ]))
        action = numbered_menu(app.t("Evenementen"), [
            (app.t("Regels"), lambda: _edit_event(app, app.current_event()) if app.current_event() else None),
            (app.t("Nieuw"), lambda: events.append(config.new_event())),
            (app.t("Dupliceer"), lambda: _duplicate_event(app, events)),
            (app.t("Verwijder"), lambda: _delete_event(app, events)),
            (app.t("Omhoog"), lambda: _move_event(app, events, -1)),
            (app.t("Omlaag"), lambda: _move_event(app, events, 1)),
            (app.t("Opslaan als"), lambda: _save_event_loop(app)),
            (app.t("Laden"), lambda: app.load_all()),
        ])
        if action is None:
            return
        try:
            action()
        except Exception as exc:
            show_error(app, exc)


def _duplicate_event(app, events):
    current = app.current_event()
    if current is not None:
        events.append(config.copy_obj(current))
        app.event_index = len(events) - 1


def _delete_event(app, events):
    if events:
        del events[app.event_index]
        app.event_index = min(app.event_index, max(0, len(events) - 1))


def _move_event(app, events, direction):
    app.event_index = move_item(events, app.event_index, direction)


def _save_event_loop(app):
    _guard_running(app)
    name = prompt(app.t("Geef een naam voor het event loop-bestand."), app.server_values.get("eventLoopName", "default_loop"))
    app.server_values["eventLoopName"] = name
    app.save_event_loop()
    target = Path(app.paths["SaveDir"]) / (name + ".becl")
    config.write_json(target, app.event_loop, backup=True)
    show_info(app.t("Event loop opgeslagen: {0}", name))


def _edit_cup(app, cup):
    while True:
        settings = _ensure(cup, "race settings", config.new_cup_race_settings)
        action = numbered_menu(app.t("Cup"), [
            (app.t("Naam"), lambda: edit_fields(app, app.t("Cup"), cup, [
                ("cup name", app.t("Naam:"), "str", "Nieuwe cup"),
                ("cup description", app.t("Beschrijving:"), "str", ""),
                ("icon", app.t("Icon:"), "str", ""),
            ])),
            (app.t("Race-instellingen"), lambda: edit_fields(app, app.t("Race-instellingen"), settings, [
                ("point distribution", app.t("Point distribution:"), "str", "30;27;25"),
                ("flags", app.t("Vlaggen:"), "str", ""),
                ("start order", app.t("Start order:"), "str", "random"),
                ("points for best lap time", app.t("Punten beste ronde:"), "int", 0, 0, 1000),
                ("points for highest score", app.t("Punten hoogste score:"), "int", 0, 0, 1000),
                ("last race multiplier", app.t("Laatste race multiplier:"), "int", 1, 0, 100),
            ])),
            (app.t("Event loop-bestand:"), lambda: cup.__setitem__("event loop", ask_choice(app.t("Event loop-bestand:"), _choice_values(app.game_data.get("cupLoops", []), cup.get("event loop", "")), cup.get("event loop", "")))),
            (app.t("Car restrictions (JSON-array)"), lambda: cup.__setitem__("car restriction", edit_json(app.t("Car restrictions (JSON-array)"), cup.get("car restriction", [])))),
        ])
        if action is None:
            return
        try:
            action()
        except Exception as exc:
            show_error(app, exc)


def cups_tab(app):
    while True:
        cups = app.cups()
        print_indexed(app.t("Cups"), cups, app.cup_index, lambda item: str(item.get("cup name", "")))
        action = numbered_menu(app.t("Cups"), [
            (app.t("Cup"), lambda: _edit_cup(app, app.current_cup()) if app.current_cup() else None),
            (app.t("Nieuw"), lambda: (cups.append(config.new_cup()), app.__setattr__("cup_index", len(cups) - 1))),
            (app.t("Dupliceer"), lambda: _duplicate_cup(app, cups)),
            (app.t("Verwijder"), lambda: _delete_cup(app, cups)),
            (app.t("Omhoog"), lambda: _move_cup(app, cups, -1)),
            (app.t("Omlaag"), lambda: _move_cup(app, cups, 1)),
            (app.t("Cups opslaan"), lambda: _save_cups(app)),
            (app.t("Laden"), lambda: app.load_all()),
        ])
        if action is None:
            return
        try:
            action()
        except Exception as exc:
            show_error(app, exc)


def _duplicate_cup(app, cups):
    current = app.current_cup()
    if current is not None:
        cups.append(config.copy_obj(current))
        app.cup_index = len(cups) - 1


def _delete_cup(app, cups):
    if cups:
        del cups[app.cup_index]
        app.cup_index = min(app.cup_index, max(0, len(cups) - 1))


def _move_cup(app, cups, direction):
    app.cup_index = move_item(cups, app.cup_index, direction)


def _save_cups(app):
    _guard_running(app)
    app.save_cup_config()
    show_info(app.t("Cups opgeslagen: {0}", len(app.cups())))
