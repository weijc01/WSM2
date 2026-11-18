# WSM2 – Wreckfest 2 Server Manager

WSM2 is a graphical management application for a **Wreckfest 2 dedicated server** on Windows. Instead of editing JSON configuration files by hand, you manage the server name, races, cups, roles, bans and telemetry from a single window. The server starts and stops with one click in a separate console window.

## Features

- WinForms interface with seven tabs: Server, Evenementen, Cups, Rollen & Bans, Telemetrie, Starten and Instellingen.
- Multilingual interface: English (default), Dutch, French and German, switchable via **Instellingen → Taal:** (Settings → Language).
- Multiple **profiles**, each with its own save-dir and mode (`community` or `lokaal`).
- Automatic detection of Steam and the Wreckfest 2 Dedicated Server, including additional Steam libraries.
- Dropdowns populated with real game data: levels (`.evse`), weather (`.weat`), AI sets (`.aist`), game modes and cup loops (`.becl`).
- Safe saving: changes are rejected while the server is running (the server overwrites configs on exit).
- Automatic timestamped **backups** of every configuration file when saving.
- Live server log in the window, with automatic refresh and opening in Notepad.
- Starts in a visible console window, handling spaces in paths via the 8.3 short path.

## Requirements

- Windows 10/11 with **PowerShell 5.1** and .NET Framework (WinForms; included by default).
- Steam with **Wreckfest 2 Dedicated Server** installed (AppID `1203190`).
- Write permissions on the installation folder (`steam_appid.txt` is created if needed) and on the save-dir.

### Do I need to install .NET Framework separately?

Usually **no**: Windows 10/11 ships with PowerShell 5.1 and .NET Framework 4.x with WinForms by default. WSM2 does not need the .NET **SDK** or **Developer Pack**, only the **runtime**.

Check in PowerShell:

```powershell
$PSVersionTable.PSVersion          # must be 5.1.x
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release   # 528040 or higher = .NET 4.8
```

If .NET Framework 4.8 is missing or disabled:

1. Download the **.NET Framework 4.8 Runtime** (not the Developer Pack) from <https://dotnet.microsoft.com/download/dotnet-framework/net48>.
2. Under *Advanced downloads* you can optionally choose the **offline installer** if no internet is available during installation.
3. Run the installer as administrator and restart Windows if prompted.
4. Alternative on Windows 10/11: **Configuratiescherm → Programma's en onderdelen → Windows-onderdelen in-/uitschakelen** (Control Panel → Programs and Features → Turn Windows features on or off) → check ".NET Framework 4.8".

## Installation

1. Download or clone this repository to a fixed folder, for example `C:\Tools\WSM2`.
2. Keep `WSM2.cmd`, `WSM2.ps1`, `WSM2.settings.json` and the `lib\` folder together.
3. Double-click **`WSM2.cmd`**. No installation or administrator rights are needed; the launcher starts PowerShell with `-ExecutionPolicy Bypass` for this process only.
4. On first launch, go to **Instellingen** (Settings) → **Automatisch detecteren** (Auto-detect), check the paths and click **Instellingen opslaan** (Save settings).

> Windows Defender/SmartScreen may warn about a PowerShell script. The launcher only uses local scripts from this folder.

## Quick start

1. **Instellingen**: detect and save the installation paths; optionally create a profile.
2. **Server**: enter a name, optionally a password and a game port (default `30100`) → **Serverconfig opslaan** (Save server config).
3. **Evenementen**: choose an event loop file or create a new one, add races → **Opslaan als** (Save as).
4. **Cups** (optional): configure cups → **Cups opslaan** (Save cups).
5. **Starten**: choose a profile and mode → **START server**. Always stop the server before changing configuration.

## KPN router port forwarding

For the KPN router, go to **Beveiliging → Portforwarding** (Security → Port forwarding) and add:

| Protocol | Port(s) | Internet IP | Destination IP |
| --- | --- | --- | --- |
| UDP | `30100,27015,27016,33540` | leave empty | the server |
| TCP | `27015` | leave empty | the server |

Leave the **Internet IP** field empty and set the **destination IP** to the server's local IP address. If the router does not accept a comma-separated list, create separate rules per port and protocol.

## Windows Firewall

Allow inbound traffic from outside on the same ports: UDP `30100,27015,27016,33540` and TCP `27015`. Run PowerShell **as Administrator**:

```powershell
New-NetFirewallRule -DisplayName "Wreckfest 2 Server (UDP 30100,27015,27016,33540)" -Direction Inbound -Protocol UDP -LocalPort 30100,27015,27016,33540 -RemoteAddress Any -Action Allow -Profile Any
New-NetFirewallRule -DisplayName "Wreckfest 2 Server (TCP 27015)" -Direction Inbound -Protocol TCP -LocalPort 27015 -RemoteAddress Any -Action Allow -Profile Any
```

Or use the GUI: **Windows Defender Firewall → Advanced settings → Inbound Rules → New Rule...** → **Port** → create one rule for **UDP** with those four ports and one for **TCP** with `27015` → allow the connection. Remove or restrict these rules if the server should not be reachable from the internet.

See [GUIDE.md](GUIDE.md) for the detailed step-by-step explanation of all fields and workflows.

## Project structure

| File | Purpose |
| --- | --- |
| `WSM2.cmd` | Launcher; starts the main window without a visible PowerShell console. |
| `WSM2.ps1` | Main program: WinForms interface, event wiring and load/save logic. |
| `WSM2.settings.json` | App settings: paths, last profile, language, log following and profiles. |
| `lib/Config.ps1` | Reading, validating and writing server config, cups, privileges and telemetry, including backups. |
| `lib/GameData.ps1` | Detection of Steam libraries and reading game data for dropdowns. |
| `lib/Profiles.ps1` | Management of `WSM2.settings.json` and profiles. |
| `lib/Languages.ps1` | Central language functions and language selection (NL/EN/FR/DE). |
| `lib/Languages.*.ps1` | Dutch keys and translations for EN, FR and DE. |
| `lib/Server.ps1` | Starting/stopping the server, status checks and reading the log. |

## Configuration files

All files are located in the **save-dir** of the active profile (default `C:\WreckFest2server`).

| File | Tab | Contents |
| --- | --- | --- |
| `server_config.scnf` | Server | Name, password, port, event loop, flags, ban rules. |
| `<naam>.becl` | Evenementen | Event loop with races, levels, rules and bot counts. |
| `server_cup_config.ccnl` | Cups | Cups, point distribution and start order. |
| `server_privilege.sprv` | Rollen & Bans | Admin/mod roles and bans. |
| `telemetry/config.json` | Telemetrie | UDP, logging and server telemetry. |

On every save, WSM2 first creates a copy named `<bestandsnaam>.yyyyMMdd_HHmmss.bak` next to the original.

## Common problems

| Symptom | Solution |
| --- | --- |
| Server not found | Check **Instellingen → Server-installatiemap**; look for `Wreckfest2.exe` or use **Automatisch detecteren**. |
| Players cannot connect | Check the game port in **Server** and open it in the firewall/router. |
| Saving rejected | Stop the server first; WSM2 prevents the server from overwriting your changes on exit. |
| Combo boxes (levels/weather) remain empty | The server installation folder is incorrect; detect again and click **Instellingen opslaan**. |
| No log visible | Enter a **Logbestand** on **Server** (file name in the save-dir or a full path). |
| Server starts with "Fatal Error: pad bestaat niet" | Check that the save-dir exists; WSM2 automatically uses the 8.3 short path when there are spaces. |

## Advanced

- With the environment variable `WSM2_SELFTEST=1`, the program performs a diagnostic run without a window and prints a summary of the loaded data.
- With `WSM2_LANG=en|nl|fr|de` you can temporarily force a language; without this variable the choice from `WSM2.settings.json` applies (default `en`).
- `WSM2.settings.json` is deliberately written **without** a backup; make your own copy before manually changing paths or profiles.

## Disclaimer

WSM2 is an unofficial tool and is not affiliated with Bugbear Entertainment, THQ Nordic or Valve. Use at your own risk; back up your save-dir regularly.
