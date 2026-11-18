# Guide – WSM2 (Wreckfest 2 Server Manager)

This guide describes step by step how to use WSM2. First read the [README.md](README.md) for installation and general information.

## Contents

1. [Starting the program](#1-starting-the-program)
2. [Window overview](#2-window-overview)
3. [Instellingen tab – paths and profiles](#3-instellingen-tab--paths-and-profiles)
4. [Server tab – basic configuration](#4-server-tab--basic-configuration)
5. [Evenementen tab – races and event loops](#5-evenementen-tab--races-and-event-loops)
6. [Cups tab – championships](#6-cups-tab--championships)
7. [Rollen & Bans tab](#7-rollen--bans-tab)
8. [Telemetrie tab](#8-telemetrie-tab)
9. [Starten tab – controlling the server and the log](#9-starten-tab--controlling-the-server-and-the-log)
10. [Common workflows](#10-common-workflows)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Starting the program

Double-click `WSM2.cmd`. A window appears with the title *WSM2 - Wreckfest 2 Server Manager*. The PowerShell console itself remains hidden.

On first launch, missing configuration files are created automatically in the save-dir (default `C:\WreckFest2server`). If loading fails, an error message appears with the reason.

**Important rule:** always stop the server before saving configuration. On exit, the server writes its own configuration and could otherwise undo your changes. WSM2 blocks saving while the server is running.

## 2. Window overview

The window has seven tabs and a status bar at the bottom showing which file was saved last.

| Tab | What you do there |
| --- | --- |
| Server | Name, password, port, event loop, flags and ban rules. |
| Evenementen | Event loop `.becl` files with races, levels and rules. |
| Cups | Cup configuration (`.ccnl`) with points and start order. |
| Rollen & Bans | Admins/moderators and bans (`.sprv`). |
| Telemetrie | UDP, logging and server telemetry (`telemetry/config.json`). |
| Starten | Choose a profile, start/stop the server and view the log. |
| Instellingen | Manage installation paths and profiles. |

## 3. Instellingen tab – paths and profiles

### Installation paths

| Field | Explanation |
| --- | --- |
| Server-installatiemap | Folder containing `Wreckfest2.exe`, usually `C:\Program Files (x86)\Steam\steamapps\common\Wreckfest 2 Dedicated Server`. |
| Steam.exe | Path to `steam.exe`; used by WSM2 for detection and reference. |

Buttons:

- **Bladeren...** (Browse) (next to each field): choose the folder or file manually.
- **Automatisch detecteren** (Auto-detect): searches `Program Files (x86)`, `Program Files`, the registry and Steam's `libraryfolders.vdf`. Useful if Steam is on a different drive.
- **Instellingen opslaan** (Save settings): writes the paths and the profile table to `WSM2.settings.json` and refreshes the dropdowns with game data.
- **Taal:** (Language): choose **English** (default), **Nederlands**, **Français** or **Deutsch**. The change is applied immediately and saved as `Language` in `WSM2.settings.json`.

### Profiles

A profile is a combination of **name**, **save-dir** and **mode**. Profiles let you manage multiple servers without changing paths each time.

- **Rij toevoegen** (Add row): creates a `Nieuw` row with the current save-dir and mode `community`.
- **Rij verwijderen** (Delete row): removes the selected row. At least one profile must remain.
- **Profielen opslaan** (Save profiles): saves the table (and also the installation paths).
- **Modus** is `community` (server visible in the server list) or `local` (local server).

Columns:

| Column | Explanation |
| --- | --- |
| Naam | Free-form name, for example `Standaard` or `Testserver`. |
| Save-dir | Folder containing that server's configuration files. |
| Modus (community/local) | Startup argument `--server` or `--local-server`. |

Restart the app if new paths or profiles are not immediately visible in the other tabs.

## 4. Server tab – basic configuration

### Network (`server_config.scnf`)

| Field | Default | Explanation |
| --- | --- | --- |
| Naam | `Wreckfest 2 Server` | Name in the server browser. |
| Beschrijving | – | Multi-line field; appears with the server. |
| Wachtwoord | empty | Empty means a public server. |
| Logbestand | empty | File name in the save-dir or a full path; used by the log view on **Starten**. |
| Game poort | `30100` | Port for game traffic; must be open in the firewall/router. |

### Game

| Field | Default | Explanation |
| --- | --- | --- |
| Event loop | `default_loop` | Name of a `.becl` file in the save-dir (without extension). Create this file on the **Evenementen** tab. |
| Cup list | empty | Reference to the cup list configuration. |
| Countdown (ms) | `100000` | Countdown before the start; range 30000–500000 ms. |
| Voting (ms) | `20000` | Time for voting on the next race; range 10000–30000 ms. |

### Server flags

Each option sets a flag in the configuration file:

- `leader enabled (race-director)` → `leader enabled`
- `idle kicker disabled` → `idle kicker disabled`
- `race timer disabled` → `race timer disabled`
- `event loop disabled` → `event loop disabled`
- `hide default user liveries` → `hide default user liveries`
- `disable auto-admin` → `disable auto-admin`

### Auto-ban notifications

Number of notifications before automatic action is taken. **0 = disabled**. Defaults: censor 4, silence 8, suspend 12.

### Ban durations (minutes)

Three categories (server, admin, default), each with a duration for censor, silence and suspend. Default 1440 minutes (1 day) and 525600 minutes (1 year) for suspend.

Buttons: **Serverconfig opslaan** (Save server config) writes the file (with a backup); **Herladen** (Reload) reads the values back from the file and discards unsaved changes.

## 5. Evenementen tab – races and event loops

An event loop is a `.becl` file in the save-dir containing the list of races the server plays.

### Event loop file

- Choose an existing file in the dropdown and click **Laden** (Load).
- **Nieuw** (New) creates one empty race in memory.
- **Opslaan als** (Save as) writes to `<naam>.becl` in the save-dir, creates a backup if the file already exists, and sets both this dropdown and **Event loop** on the Server tab to that name. So use the same name you entered on **Server**.

### Event list

Use **Nieuw**, **Dupliceer**, **Verwijder**, **Omhoog** and **Omlaag** to manage the order of the races. When you select another race in the list, the current fields are automatically saved to the previous event. Everything becomes final after **Opslaan als**.

An empty row in the list looks like `1. track01_1 [bangerrace]`.

### Level

| Field | Explanation |
| --- | --- |
| Level id | For example `track01_1`; choices come from the `.evse` files in the server installation. |
| Weer | Path such as `data/property/weather/track01_1.weat`. |
| AI-set | Path such as `runtime/career/ai-class-all.aist`. |
| Game mode | `bangerrace`, `waypointrace`, `suiciderace` or `demolitionderby`. |

### Rules

| Field | Range / options |
| --- | --- |
| Rondes | 0–100 (optional in relation to the time limit). |
| Tijdslimiet | 0–1000. |
| Teams | 1–10. |
| Max deelnemers | 1–24. |
| Vlaggen | Free text; game-specific race flags. |
| Collecting | `Collecting Sequential` or `Collecting Random`. |
| Car reset (s) | 0–60 seconds. |
| Team split (%) | 0–100. |
| Schade-id | empty, `normal`, `realistic` or `wrecker`. |
| Bots | 0–24. |

### Car restrictions

A JSON **array** of vehicle restrictions. Use `[]` if there are no restrictions. Invalid JSON produces an error message and is not saved.

## 6. Cups tab – championships

Cups are saved in `server_cup_config.ccnl`. Which cups are active is determined by the **Cup list** field on the Server tab.

Use **Nieuw**, **Dupliceer**, **Verwijder**, **Omhoog** and **Omlaag** for the list; **Cups opslaan** saves everything.

### Cup

| Field | Explanation |
| --- | --- |
| Naam | Name of the cup. |
| Beschrijving | Multi-line field. |
| Event loop | Relative path to a `.becl` file from the server installation (for example `data/property/settings/cup/waypoint_tracks.becl`). |
| Icon | Optional path/name of an icon. |

### Race settings

| Field | Default | Explanation |
| --- | --- | --- |
| Point distribution | `30;27;25;20;19;...;1;0` | Points per position, separated by `;`. |
| Vlaggen | empty | Game-specific flags. |
| Start order | `random` | Also `points`, `points reversed` and `last race reversed`. |
| Punten beste ronde | 0 | Extra points for the fastest lap. |
| Punten hoogste score | 0 | Extra points for the highest score. |
| Laatste race multiplier | 1 | Multiplier for the last race (0–100). |

**Car restrictions** works the same way as for events: a JSON array, where `[]` means no restrictions.

## 7. Rollen & Bans tab

This tab manages `server_privilege.sprv`.

### Roles

The grid has two columns:

- **Platform ID (SteamID64)**: the player's numeric Steam ID.
- **Rol (admin/mod)**: `admin` or `mod`; if you leave the field empty, `admin` is used.

Use **Rij toevoegen** and **Rij verwijderen** to modify the table. Rows with an empty ID are skipped when saving. A numeric ID is written as a number, other values as text.

### Bans

The large field contains a JSON array of bans. `[]` means no bans. Invalid JSON shows an error message and nothing is saved.

**Rollen & bans opslaan** writes both to `server_privilege.sprv` (with a backup).

## 8. Telemetrie tab

This tab manages `telemetry/config.json` in the save-dir. The `telemetry` folder is created automatically.

| Field | Default | Explanation |
| --- | --- | --- |
| UDP ingeschakeld | off | Turns UDP telemetry on/off. |
| IP-adres | `127.0.0.1` | Destination address of the UDP data. |
| Poort | `23123` | Destination port of the UDP data. |
| Formaat | `none` | `none`, `json` or `csv`. |
| Server-telemetrie ingeschakeld | off | General server telemetry. |
| automaticMainCar | off | Automatically determine the main car. |

Click **Telemetrie opslaan** to write the values.

## 9. Starten tab – controlling the server and the log

### Controlling the server

| Field / button | Explanation |
| --- | --- |
| Profiel | Choose a profile; the configuration of the corresponding save-dir is loaded immediately. |
| Save-dir | Shown based on the profile; **Map openen** opens the folder in File Explorer. |
| Modus | `community (--server)` or `lokaal (--local-server)`. |
| START server | First saves all configurations, then starts the server in a separate, visible console window. |
| STOP server | Stops all `Wreckfest2` processes belonging to the configured installation folder. |
| Status vernieuwen | Refreshes the status immediately. |

The status bar shows `Status: SERVER DRAAIT` (green) or `Status: gestopt` (red). The status is refreshed automatically every 2.5 seconds.

On startup, WSM2 creates `steam_appid.txt` with AppID `1203190` in the installation folder if needed. Because the game expects `--save-dir=<pad>` without quotes, WSM2 automatically uses the 8.3 short path when the path contains spaces.

### Server log

- **Automatisch verversen** (Auto-refresh): shows the last 300 lines of the log file; the startup state comes from `WSM2.settings.json`. Changing it during the session applies only to that session.
- **Vernieuwen** (Refresh): retrieves the log immediately.
- **Logbestand openen** (Open log file): opens the log file in Notepad.
- The log path comes from the **Logbestand** field on the Server tab: a relative file name is resolved against the save-dir, an absolute path is used directly.

## 10. Common workflows

### Setting up a new server

1. **Instellingen** tab → **Automatisch detecteren** → **Instellingen opslaan**.
2. On **Starten**, check the save-dir and choose the mode.
3. **Server** tab → enter name, password, port and event loop → **Serverconfig opslaan**.
4. **Evenementen** tab → **Nieuw**, configure races, **Opslaan als** with the same name as the event loop on **Server**.
5. **Cups** tab → optionally add cups → **Cups opslaan**.
6. **Rollen & Bans** tab → add admins → save.
7. **Starten** tab → **START server** → check the status and log.

### Multiple servers with profiles

1. On **Instellingen**, create a row for each server with its own name, save-dir and mode.
2. Save the profiles.
3. On **Starten**, choose the desired profile; all tabs then load the configuration from that save-dir.
4. Stop the server before switching to another profile or saving configuration.

### Changing configuration safely

1. **STOP server** on the **Starten** tab.
2. Change the settings on the relevant tabs.
3. Save each change (a timestamped `.bak` is created automatically).
4. Restart the server.

### Restoring a backup

1. Stop the server.
2. Look in the save-dir for `<bestandsnaam>.yyyyMMdd_HHmmss.bak`.
3. Copy the desired backup back over the original file (remove the timestamp portion from the file name).
4. Restart WSM2 or use **Herladen** on the **Server** tab.

## 11. Troubleshooting

| Problem | Possible cause / solution |
| --- | --- |
| `Server niet gevonden in: ...` | The server installation folder is incorrect. Use **Automatisch detecteren** or **Bladeren...** and look for `Wreckfest2.exe`. |
| Players cannot see the server | Check the mode (`community`), password and whether the game port is open in the firewall/router. |
| Saving rejected with a message about the server | The server is still running. Click **STOP server** and try again. |
| Dropdowns for levels/weather/AI remain empty | The installation folder does not contain `data\property\...`; check the paths, save and restart the app if needed. |
| Log window remains empty | Enter a **Logbestand** on **Server** and check that the file exists in the save-dir. |
| Error "Ongeldige JSON" for car restrictions or bans | The text is not a valid JSON array. Use `[]` to start empty. |
| Event loop does not start | Check that the name in **Server → Event loop** exactly matches a `.becl` file in the save-dir. |
| Server starts with "Fatal Error: pad bestaat niet" | Does the save-dir exist? WSM2 uses an 8.3 short path when there are spaces; check the path on **Starten**. |

### Diagnostics via selftest

For developers: set the environment variable `WSM2_SELFTEST=1` before starting `WSM2.cmd`. The program loads all configuration, prints a line such as `SELFTEST OK | events=... cups=... levels=...` and closes itself without showing the window. Useful for checking that paths and game data are found correctly.
