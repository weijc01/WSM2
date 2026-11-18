# WSM2 for Red Hat Enterprise Linux 10

Console version of the Wreckfest 2 Server Manager with the same functions as the Windows GUI version: server, events, cups, roles and bans, telemetry, start/stop and settings/profiles. English is the default language; Dutch, French and German are included.

## Requirements

- Red Hat Enterprise Linux 10
- Python 3 (`sudo dnf install python3`)
- A Wreckfest 2 Dedicated Server installation
- One of: a native `Wreckfest2` binary, Proton, or Wine

## Install and run

```sh
cd redhat
chmod +x wsm2.sh
./wsm2.sh
```

Without the launcher script:

```sh
python3 WSM2.py
```

Run the built-in check:

```sh
WSM2_SELFTEST=1 ./wsm2.sh
```

## Configuration

Settings are stored in `redhat/WSM2.settings.json`. Profiles point to save directories; each save directory contains:

- `server_config.scnf`
- `event_loop.xml`
- `server_cup_config.ccnl`
- `server_privilege.sprv`
- `telemetry/config.json`

Use **Settings** to set the server install folder and Steam path, or choose **Auto detect**. The launcher is selected automatically: native binary first, then Proton, then Wine. Set `WSM2_LAUNCHER=native|proton|wine|auto` or the `Launcher` setting to override it. Set `WSM2_LANG=en|nl|fr|de` to override the interface language. Set `STEAMROOT` or `PROTON_PATH` if auto detection fails.

## Linux server launch

The application starts the server with:

- `--server` for community mode, `--local-server` for local mode
- `--save-dir=<profile save directory>`

Under Proton/Wine, the Windows `Wreckfest2.exe` is launched from the configured install folder and the save directory is passed as one argument, so spaces in paths work without the Windows 8.3 short-path workaround. Console output is written to `wsm2_server_console.log` in the save directory. Use **Start -> Server log** to view it.

## Notes

- This is a console UI because Windows Forms is not available on Linux.
- Backups of changed JSON files use `<file>.<timestamp>.bak`.
- Stop the server before saving configuration; otherwise the game may overwrite the files on exit.
