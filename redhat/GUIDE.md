# WSM2 Linux guide

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

A profile contains `Name`, `SaveDir` and `Mode`. `SaveDir` is the game server save directory, not the application directory. Switching profile reloads all configuration files from that save directory.

## Launcher selection

- `auto`: native `Wreckfest2`, then Proton, then Wine.
- `native`: use `Wreckfest2` directly.
- `proton`: use a Proton found under the Steam library folders or `PROTON_PATH`.
- `wine`: use `wine` from `PATH`.

Proton uses `<SaveDir>/proton_prefix`. Steam library folders are detected from `STEAMROOT`, `~/.local/share/Steam`, `~/.steam/steam`, `~/.steam/root`, `/usr/share/steam` and `/opt/steam`, plus `libraryfolders.vdf`.

## Troubleshooting

- **Server executable not found**: set the install folder in Settings or run auto detection.
- **No Proton/Wine found**: install Proton through Steam or install Wine, or set `WSM2_LAUNCHER`.
- **Status shows stopped but the game is running**: the process command line must contain the configured install path; check the install folder in Settings.
- **Log not found yet**: start the server once; the console output is written to `wsm2_server_console.log` in the save directory.
- **Wrong language**: set `WSM2_LANG` or change Settings -> Language.

## Selftest

```sh
WSM2_SELFTEST=1 ./wsm2.sh
```

A successful run prints `SELFTEST OK` with the active language, tab count and test status.
