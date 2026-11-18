# WSM2 SteamOS guide

## Menus

1. **Server** - edit network, event loop, flags, auto-ban reports, ban durations; save or reload.
2. **Events** - add, duplicate, delete, reorder and edit events; edit level, rules, bots and car restrictions; save a named event loop.
3. **Cups** - add, duplicate, delete, reorder and edit cups; race settings, event-loop file and car restrictions; save.
4. **Roles & Bans** - edit role rows as JSON, edit the bans JSON array, save or reload.
5. **Telemetry** - edit UDP, logging and server telemetry, save or reload.
6. **Start** - choose profile and mode, start/stop the server, refresh status, view or open the log, open the save folder.
7. **Settings** - installation paths, auto detection, profiles, language, launcher and save.

## Keyboard

Type the number of a menu item and press Enter. `0` goes back. Defaults are shown in brackets; press Enter to accept them. JSON fields accept the full JSON value.

## Profiles

A profile contains `Name`, `SaveDir` and `Mode`. `SaveDir` is the game server save directory, not the application directory. On SteamOS a good save directory is `~/WreckFest2server` or a folder on a writable microSD card. Switching profile reloads all configuration files from that save directory.

Application settings themselves live in `~/.config/wsm2/WSM2.settings.json` (or `$XDG_CONFIG_HOME/wsm2/WSM2.settings.json`).

## Launcher selection

- `auto`: native `Wreckfest2`, then Proton, then Wine.
- `native`: use `Wreckfest2` directly.
- `proton`: use Proton from a Steam library or `PROTON_PATH`.
- `wine`: use `wine` from `PATH`.

Steam libraries include `~/.local/share/Steam`, `~/.steam/steam`, `~/Steam`, `/home/deck/...`, `/run/media/*/SteamLibrary`, `/mnt/*/SteamLibrary` and paths listed in `libraryfolders.vdf`. Proton uses `<SaveDir>/proton_prefix`.

## Desktop launcher

Run `./install.sh` once to install `~/.local/share/applications/wsm2.desktop`. It opens WSM2 in Konsole from the folder where the script was installed. If Konsole is not available, run `./wsm2.sh` manually from a terminal.

## Troubleshooting

- **Server executable not found**: set the install folder in Settings or run auto detection; check the microSD mount path if the library is external.
- **No Proton/Wine found**: install Proton through Steam or set `WSM2_LAUNCHER`/`PROTON_PATH`.
- **Status shows stopped but the game is running**: the process command line must contain the configured install path; verify the install folder in Settings.
- **Log not found yet**: start the server once; output is written to `wsm2_server_console.log` in the save directory.
- **Wrong language**: set `WSM2_LANG` or change Settings -> Language.
- **Cannot save settings**: check that `~/.config/wsm2` or `$XDG_CONFIG_HOME/wsm2` is writable.

## Selftest

```sh
WSM2_SELFTEST=1 ./wsm2.sh
```

A successful run prints `SELFTEST OK` with the active language, tab count and test status.
