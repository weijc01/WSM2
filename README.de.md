# WSM2 – Wreckfest 2 Server Manager

WSM2 ist ein grafisches Verwaltungsprogramm für einen **Wreckfest 2 Dedicated Server** unter Windows. Statt die JSON-Konfigurationsdateien manuell zu bearbeiten, verwalten Sie Servername, Rennen, Cups, Rollen, Bans und Telemetrie in einem einzigen Fenster. Der Server wird mit einem Klick in einem separaten Konsolenfenster gestartet und gestoppt.

## Funktionen

- WinForms-Oberfläche mit sieben Registerkarten: Server, Evenementen (Veranstaltungen), Cups, Rollen & Bans, Telemetrie, Starten und Instellingen (Einstellungen).
- Mehrsprachige Oberfläche: Englisch (Standard), Niederländisch, Französisch und Deutsch, umschaltbar über **Instellingen → Taal:** (Einstellungen → Sprache).
- Mehrere **Profile** mit jeweils eigener save-dir und eigenem Modus (`community` oder `lokaal`).
- Automatische Erkennung von Steam und dem Wreckfest 2 Dedicated Server, einschließlich zusätzlicher Steam-Bibliotheken.
- Dropdowns, gefüllt mit echten Spieldaten: Levels (`.evse`), Wetter (`.weat`), AI-Sets (`.aist`), Game Modes und Cup-Loops (`.becl`).
- Sicheres Speichern: Änderungen werden abgelehnt, solange der Server läuft (der Server überschreibt Konfigurationen beim Beenden).
- Automatische **Backups** mit Zeitstempel jeder Konfigurationsdatei beim Speichern.
- Live-Serverprotokoll im Fenster mit automatischer Aktualisierung und Öffnen in Notepad.
- Start in einem sichtbaren Konsolenfenster, mit Behandlung von Leerzeichen in Pfaden über den 8.3-Kurzpfad.

## Voraussetzungen

- Windows 10/11 mit **PowerShell 5.1** und .NET Framework (WinForms; standardmäßig vorhanden).
- Steam mit installiertem **Wreckfest 2 Dedicated Server** (AppID `1203190`).
- Schreibrechte im Installationsverzeichnis (`steam_appid.txt` wird bei Bedarf erstellt) und in der save-dir.

### Muss ich .NET Framework separat installieren?

In der Regel **nein**: Windows 10/11 liefert PowerShell 5.1 und .NET Framework 4.x mit WinForms standardmäßig mit. WSM2 benötigt weder ein .NET-**SDK** noch ein **Developer Pack**, sondern nur die **Runtime**.

Prüfen in PowerShell:

```powershell
$PSVersionTable.PSVersion          # muss 5.1.x sein
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release   # 528040 oder höher = .NET 4.8
```

Falls .NET Framework 4.8 fehlt oder deaktiviert ist:

1. Laden Sie die **.NET Framework 4.8 Runtime** (nicht das Developer Pack) von <https://dotnet.microsoft.com/download/dotnet-framework/net48> herunter.
2. Unter *Advanced downloads* können Sie optional den **offline installer** wählen, falls während der Installation kein Internet verfügbar ist.
3. Führen Sie das Installationsprogramm als Administrator aus und starten Sie Windows neu, falls Sie dazu aufgefordert werden.
4. Alternative unter Windows 10/11: **Systemsteuerung → Programme und Funktionen → Windows-Funktionen ein- oder ausschalten** → ".NET Framework 4.8" aktivieren.

## Installation

1. Laden Sie dieses Repository herunter oder klonen Sie es in einen festen Ordner, z. B. `C:\Tools\WSM2`.
2. Halten Sie `WSM2.cmd`, `WSM2.ps1`, `WSM2.settings.json` und den Ordner `lib\` zusammen.
3. Doppelklicken Sie auf **`WSM2.cmd`**. Es ist keine Installation und kein Administratorrecht erforderlich; der Launcher startet PowerShell mit `-ExecutionPolicy Bypass` nur für diesen Prozess.
4. Gehen Sie beim ersten Start zu **Instellingen** → **Automatisch detecteren** (Automatisch erkennen), prüfen Sie die Pfade und klicken Sie auf **Instellingen opslaan** (Einstellungen speichern).

> Windows Defender/SmartScreen kann vor einem PowerShell-Skript warnen. Der Launcher verwendet nur lokale Skripte aus diesem Ordner.

## Schnellstart

1. **Instellingen**: Installationspfade erkennen und speichern; bei Bedarf ein Profil anlegen.
2. **Server**: Name, optional ein Passwort und ein Game-Port (Standard `30100`) angeben → **Serverconfig opslaan** (Serverkonfiguration speichern).
3. **Evenementen**: Eine Event-Loop-Datei auswählen oder eine neue erstellen, Rennen hinzufügen → **Opslaan als** (Speichern unter).
4. **Cups** (optional): Cups konfigurieren → **Cups opslaan** (Cups speichern).
5. **Starten**: Profil und Modus wählen → **START server**. Beenden Sie den Server immer zuerst, bevor Sie die Konfiguration ändern.

## KPN-Router: Portweiterleitung

Im KPN-Router unter **Beveiliging → Portforwarding** (Sicherheit → Portweiterleitung) folgende Regel hinzufügen:

| Protokoll | Port(s) | Internet-IP | Ziel-IP |
| --- | --- | --- | --- |
| UDP | `30100,27015,27016,33540` | leer lassen | der Server |

Das Feld **Internet-IP** leer lassen und als **Ziel-IP** die lokale IP-Adresse des Servers eintragen. Falls der Router keine durch Kommas getrennte Portliste akzeptiert, vier einzelne Regeln erstellen.

## Windows-Firewall

Eingehenden UDP-Datenverkehr von außen auf denselben vier Ports erlauben. PowerShell **als Administrator** ausführen:

```powershell
New-NetFirewallRule -DisplayName "Wreckfest 2 Server (UDP 30100,27015,27016,33540)" -Direction Inbound -Protocol UDP -LocalPort 30100,27015,27016,33540 -RemoteAddress Any -Action Allow -Profile Any
```

Oder über die Oberfläche: **Windows Defender-Firewall → Erweiterte Einstellungen → Eingehende Regeln → Neue Regel...** → **Port** → **UDP** → die vier Ports eingeben → Verbindung zulassen. Die Regel entfernen oder einschränken, wenn der Server nicht aus dem Internet erreichbar sein soll.

Weitere ausführliche Schritt-für-Schritt-Erläuterungen zu allen Feldern und Workflows finden Sie in [GUIDE.de.md](GUIDE.de.md).

## Projektstruktur

| Datei | Zweck |
| --- | --- |
| `WSM2.cmd` | Launcher; startet das Hauptfenster ohne sichtbare PowerShell-Konsole. |
| `WSM2.ps1` | Hauptprogramm: WinForms-Oberfläche, Event-Verdrahtung und Lade-/Speicherlogik. |
| `WSM2.settings.json` | App-Einstellungen: Pfade, letztes Profil, Sprache, Protokoll-Verfolgung und Profile. |
| `lib/Config.ps1` | Lesen, Validieren und Schreiben von Serverkonfiguration, Cups, Berechtigungen und Telemetrie, einschließlich Backups. |
| `lib/GameData.ps1` | Erkennung von Steam-Bibliotheken und Auslesen von Spieldaten für Dropdowns. |
| `lib/Profiles.ps1` | Verwaltung von `WSM2.settings.json` und Profilen. |
| `lib/Languages.ps1` | Zentrale Sprachfunktionen und Sprachauswahl (NL/EN/FR/DE). |
| `lib/Languages.*.ps1` | Niederländische Schlüssel und Übersetzungen für EN, FR und DE. |
| `lib/Server.ps1` | Server starten/stoppen, Statusprüfung und Protokollauslese. |

## Konfigurationsdateien

Alle Dateien liegen in der **save-dir** des aktiven Profils (standardmäßig `C:\WreckFest2server`).

| Datei | Registerkarte | Inhalt |
| --- | --- | --- |
| `server_config.scnf` | Server | Name, Passwort, Port, Event-Loop, Flags, Ban-Regeln. |
| `<name>.becl` | Evenementen | Event-Loop mit Rennen, Levels, Regeln und Bot-Anzahlen. |
| `server_cup_config.ccnl` | Cups | Cups, Punktverteilung und Startreihenfolge. |
| `server_privilege.sprv` | Rollen & Bans | Admin-/Mod-Rollen und Bans. |
| `telemetry/config.json` | Telemetrie | UDP, Protokollierung und Server-Telemetrie. |

Bei jedem Speichern erstellt WSM2 zuerst eine Kopie als `<dateiname>.yyyyMMdd_HHmmss.bak` neben dem Original.

## Häufige Probleme

| Symptom | Lösung |
| --- | --- |
| Server nicht gefunden | Prüfen Sie **Instellingen → Server-installatiemap** (Einstellungen → Server-Installationsverzeichnis); suchen Sie nach `Wreckfest2.exe` oder verwenden Sie **Automatisch detecteren**. |
| Spieler können keine Verbindung herstellen | Prüfen Sie den Game-Port in **Server** und öffnen Sie ihn in Firewall/Router. |
| Speichern abgelehnt | Beenden Sie zuerst den Server; WSM2 verhindert, dass der Server Ihre Änderungen beim Beenden überschreibt. |
| Comboboxen (Levels/Wetter) bleiben leer | Das Server-Installationsverzeichnis ist falsch; erneut erkennen und **Instellingen opslaan**. |
| Kein Protokoll sichtbar | Geben Sie in **Server** ein **Logbestand** (Protokolldatei) an (Dateiname in der save-dir oder ein vollständiger Pfad). |
| Server startet mit "Fatal Error: pad bestaat niet" | Prüfen Sie, ob die save-dir existiert; WSM2 verwendet bei Leerzeichen automatisch den 8.3-Kurzpfad. |

## Erweitert

- Mit der Umgebungsvariablen `WSM2_SELFTEST=1` führt das Programm einen Diagnosedurchlauf ohne Fenster aus und gibt eine Zusammenfassung der geladenen Daten aus.
- Mit `WSM2_LANG=en|nl|fr|de` können Sie eine Sprache vorübergehend erzwingen; ohne diese Variable gilt die Auswahl aus `WSM2.settings.json` (Standard `en`).
- `WSM2.settings.json` wird bewusst **ohne** Backup geschrieben; erstellen Sie selbst eine Kopie, bevor Sie Pfade oder Profile manuell anpassen.

## Haftungsausschluss

WSM2 ist ein inoffizielles Hilfsmittel und steht nicht in Verbindung mit Bugbear Entertainment, THQ Nordic oder Valve. Die Verwendung erfolgt auf eigene Gefahr; erstellen Sie regelmäßig Backups Ihrer save-dir.
