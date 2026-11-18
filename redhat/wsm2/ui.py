import os

from . import selftest, ui_tabs, ui_tabs2
from .app import App
from .errors import Wsm2Error
from .i18n import I18n
from .uikit import numbered_menu, show_error, show_info

SAVE_WHILE_RUNNING_KEY = "De server draait nog. Stop de server eerst voordat je de configuratie opslaat (de server overschrijft de bestanden bij het afsluiten)."


def run(argv=None):
    argv = list(argv or [])
    i18n = I18n(os.environ.get("WSM2_LANG", "en"))
    app = App(i18n)
    try:
        app.load_all()
    except Exception as exc:
        show_error(app, exc)
        return 1
    if "--selftest" in argv or os.environ.get("WSM2_SELFTEST") == "1":
        return selftest.run(app)

    while True:
        os.system("cls" if os.name == "nt" else "clear")
        print("=" * 72)
        print(app.t("WSM2 - Wreckfest 2 Server Manager"))
        print(app.t("Profiel:") + " " + str(app.settings.get("LastProfile", "")) + " | " + app.t("Taal:") + " " + app.i18n.language)
        print("=" * 72)
        action = numbered_menu(app.t("WSM2 - Wreckfest 2 Server Manager"), [
            (app.t("Server"), lambda: ui_tabs.server_tab(app)),
            (app.t("Evenementen"), lambda: ui_tabs.events_tab(app)),
            (app.t("Cups"), lambda: ui_tabs.cups_tab(app)),
            (app.t("Rollen & Bans"), lambda: ui_tabs2.roles_tab(app)),
            (app.t("Telemetrie"), lambda: ui_tabs2.telemetry_tab(app)),
            (app.t("Starten"), lambda: ui_tabs2.start_tab(app)),
            (app.t("Instellingen"), lambda: ui_tabs2.settings_tab(app)),
            ("Opslaan alles", lambda: _save_all(app)),
            ("Afsluiten", lambda: "exit"),
        ])
        if action is None:
            return 0
        try:
            result = action()
            if result == "exit":
                return 0
        except Exception as exc:
            show_error(app, exc)


def _save_all(app):
    running, _ = app.server_status()
    if running:
        raise Wsm2Error(app.t(SAVE_WHILE_RUNNING_KEY), SAVE_WHILE_RUNNING_KEY, ())
    app.save_all()
    show_info(app.t("Instellingen en profielen opgeslagen."))
