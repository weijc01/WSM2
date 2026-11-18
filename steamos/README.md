# WSM2 for SteamOS

Console version of the Wreckfest 2 Server Manager with the same functions as the Windows GUI version and the Red Hat port: server, events, cups, roles and bans, telemetry, start/stop and settings/profiles. English is the default language; Dutch, French and German are included.

## Requirements

- SteamOS 3 / Arch-based Steam Deck
- Python 3 (`sudo pacman -S python`)
- Steam with Proton installed
- A Wreckfest 2 Dedicated Server installation in a Steam library
- A writable game library or external drive for the save directory

## Install and run

Copy this `steamos` folder to a writable location, for example `~/Applications/WSM2-SteamOS`.

```sh
cd ~/Applications/WSM2-SteamOS
chmod +x wsm2.sh
./wsm2.sh
```

Install a desktop launcher into `~/.local/share/applications`:

```sh
./install.sh
```

The launcher opens WSM2 in Konsole. You can also run the built-in check:

```sh
WSM2_SELFTEST=1 ./wsm2.sh
```

## SteamOS paths and settings

Settings are stored in `~/.config/wsm2/WSM2.settings.json`, or `$XDG_CONFIG_HOME/wsm2/WSM2.settings.json` when that variable is set. Keeping settings outside the application folder avoids problems with read-only or immutable locations.

Steam libraries are detected from:

- `$STEAMROOT`
- `~/.local/share/Steam`
- `~/.steam/steam`
- `~/.steam/root`
- `~/Steam`
- `/home/deck/.local/share/Steam`
- `/home/deck/.steam/steam`
- `/run/media/*/SteamLibrary` and `/run/media/*/*/SteamLibrary`
- `/mnt/*/SteamLibrary`
- `libraryfolders.vdf` entries in each detected root

Use **Settings -> Auto detect** if the server install or `steam` path is not found. Set `STEAMROOT` or `PROTON_PATH` as overrides.

## Launcher behavior

`auto` prefers a native `Wreckfest2` binary, then Proton, then Wine. Override with `WSM2_LAUNCHER=native|proton|wine|auto` or the `Launcher` setting. Proton uses `<SaveDir>/proton_prefix` as its compatibility data path. The server is started with `--server` or `--local-server` and `--save-dir=<profile save directory>`; console output is written to `wsm2_server_console.log` in the save directory.

## KPN router port forwarding

For the KPN router, go to **Beveiliging → Portforwarding** (Security → Port forwarding) and add:

| Protocol | Port(s) | Internet IP | Destination IP |
| --- | --- | --- | --- |
| UDP | `30100,27015,27016,33540` | leave empty | the server |
| TCP | `27015` | leave empty | the server |

Leave the **Internet IP** field empty and set the **destination IP** to the server's local IP address. If the router does not accept a comma-separated list, create separate rules per port and protocol.

## firewalld on SteamOS

SteamOS normally uses firewalld. Open the same UDP ports and TCP `27015`:

```sh
sudo systemctl enable --now firewalld
sudo firewall-cmd --zone=public --permanent --add-port=30100/udp --add-port=27015/udp --add-port=27016/udp --add-port=33540/udp --add-port=27015/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-ports
```

If `firewall-cmd` is not available, no host firewall is likely active and only the router port forwarding is needed. On a Steam Deck with a read-only system, check the rules again after a SteamOS update and re-apply them if they disappeared. To undo, use `--remove-port` instead of `--add-port`.

## Notes

- This is a console UI; SteamOS does not provide Windows Forms.
- All JSON configuration files and profiles behave the same as in the Windows and Red Hat versions.
- Backups of changed JSON files use `<file>.<timestamp>.bak`.
- Stop the server before saving configuration; otherwise the game may overwrite the files on exit.
- Do not install the application under `/usr`; keep it in your home directory or on a writable microSD card.
