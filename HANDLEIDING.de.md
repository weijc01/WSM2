# Anleitung – WSM2 (Wreckfest 2 Server Manager)

Diese Anleitung beschreibt Schritt für Schritt, wie Sie WSM2 verwenden. Lesen Sie zuerst die [README.de.md](README.de.md) für Installation und allgemeine Informationen.

## Inhalt

1. [Starten des Programms](#1-starten-des-programms)
2. [Fensterübersicht](#2-fensterübersicht)
3. [Registerkarte Instellingen – Pfade und Profile](#3-registerkarte-instellingen--pfade-und-profile)
4. [Registerkarte Server – Grundkonfiguration](#4-registerkarte-server--grundkonfiguration)
5. [Registerkarte Evenementen – Rennen und Event-Loops](#5-registerkarte-evenementen--rennen-und-event-loops)
6. [Registerkarte Cups – Meisterschaften](#6-registerkarte-cups--meisterschaften)
7. [Registerkarte Rollen & Bans](#7-registerkarte-rollen--bans)
8. [Registerkarte Telemetrie](#8-registerkarte-telemetrie)
9. [Registerkarte Starten – Server steuern und Protokoll](#9-registerkarte-starten--server-steuern-und-protokoll)
10. [Häufig verwendete Workflows](#10-häufig-verwendete-workflows)
11. [Probleme beheben](#11-probleme-beheben)

---

## 1. Starten des Programms

Doppelklicken Sie auf `WSM2.cmd`. Es erscheint ein Fenster mit dem Titel *WSM2 - Wreckfest 2 Server Manager*. Die PowerShell-Konsole selbst bleibt verborgen.

Beim ersten Start werden fehlende Konfigurationsdateien automatisch in der save-dir erstellt (standardmäßig `C:\WreckFest2server`). Falls beim Laden etwas schiefgeht, erscheint eine Fehlermeldung mit der Ursache.

**Wichtige Regel:** Beenden Sie den Server immer, bevor Sie die Konfiguration speichern. Der Server schreibt beim Beenden seine eigene Konfiguration weg und könnte Ihre Änderungen sonst zunichtemachen. WSM2 blockiert das Speichern, solange der Server läuft.

## 2. Fensterübersicht

Das Fenster hat sieben Registerkarten und unten eine Statusleiste, die anzeigt, welche Datei zuletzt gespeichert wurde.

| Registerkarte | Was Sie dort tun |
| --- | --- |
| Server | Name, Passwort, Port, Event-Loop, Flags und Ban-Regeln. |
| Evenementen | Event-Loop-`.becl`-Dateien mit Rennen, Levels und Regeln. |
| Cups | Cup-Konfiguration (`.ccnl`) mit Punkten und Startreihenfolge. |
| Rollen & Bans | Admins/Moderatoren und Bans (`.sprv`). |
| Telemetrie | UDP, Protokollierung und Server-Telemetrie (`telemetry/config.json`). |
| Starten | Profil wählen, Server starten/stoppen und das Protokoll ansehen. |
| Instellingen | Installationspfade und Profile verwalten. |

## 3. Registerkarte Instellingen – Pfade und Profile

### Installationspfade

| Feld | Erläuterung |
| --- | --- |
| Server-installatiemap | Ordner mit `Wreckfest2.exe`, meist `C:\Program Files (x86)\Steam\steamapps\common\Wreckfest 2 Dedicated Server`. |
| Steam.exe | Pfad zu `steam.exe`; wird von WSM2 für die Erkennung und als Referenz verwendet. |

Schaltflächen:

- **Bladeren...** (Durchsuchen...) (bei jedem Feld): Ordner bzw. Datei manuell auswählen.
- **Automatisch detecteren** (Automatisch erkennen): Sucht in `Program Files (x86)`, `Program Files`, der Registrierung und in `libraryfolders.vdf` von Steam. Nützlich, wenn Steam auf einem anderen Laufwerk installiert ist.
- **Instellingen opslaan** (Einstellungen speichern): Schreibt die Pfade und die Profiltabelle nach `WSM2.settings.json` und aktualisiert die Dropdowns mit Spieldaten.
- **Taal:** (Sprache): Wählen Sie **Nederlands**, **English**, **Français** oder **Deutsch**. Die Änderung wird sofort angewendet und als `Language` in `WSM2.settings.json` gespeichert.

### Profile

Ein Profil ist eine Kombination aus **Name**, **save-dir** und **Modus**. Mit Profilen verwalten Sie mehrere Server, ohne Pfade jedes Mal zu ändern.

- **Rij toevoegen** (Zeile hinzufügen): Erstellt eine Zeile `Nieuw` mit der aktuellen save-dir und dem Modus `community`.
- **Rij verwijderen** (Zeile löschen): Löscht die ausgewählte Zeile. Es muss mindestens ein Profil übrig bleiben.
- **Profielen opslaan** (Profile speichern): Speichert die Tabelle (und auch die Installationspfade).
- **Modus** ist `community` (Server in der Serverliste sichtbar) oder `local` (lokaler Server).

Spalten:

| Spalte | Erläuterung |
| --- | --- |
| Naam | Freier Name, z. B. `Standaard` oder `Testserver`. |
| Save-dir | Ordner mit den Konfigurationsdateien dieses Servers. |
| Modus (community/local) | Startargument `--server` oder `--local-server`. |

Starten Sie die App neu, wenn neue Pfade oder Profile nicht sofort in den anderen Registerkarten sichtbar sind.

## 4. Registerkarte Server – Grundkonfiguration

### Netzwerk (`server_config.scnf`)

| Feld | Standard | Erläuterung |
| --- | --- | --- |
| Naam | `Wreckfest 2 Server` | Name im Serverbrowser. |
| Beschrijving | – | Mehrzeiliges Feld; wird beim Server angezeigt. |
| Wachtwoord | leer | Leer bedeutet einen öffentlichen Server. |
| Logbestand | leer | Dateiname in der save-dir oder ein vollständiger Pfad; wird von der Protokollanzeige in **Starten** verwendet. |
| Game poort | `30100` | Port für den Spieldatenverkehr; muss in Firewall/Router geöffnet sein. |

### Spiel

| Feld | Standard | Erläuterung |
| --- | --- | --- |
| Event loop | `default_loop` | Name einer `.becl`-Datei in der save-dir (ohne Erweiterung). Erstellen Sie diese Datei in der Registerkarte **Evenementen**. |
| Cup list | leer | Verweis auf die Cup-Listenkonfiguration. |
| Countdown (ms) | `100000` | Countdown vor dem Start; Bereich 30000–500000 ms. |
| Voting (ms) | `20000` | Zeit für die Abstimmung über das nächste Rennen; Bereich 10000–30000 ms. |

### Server-Flags

Jede Option setzt ein Flag in der Konfigurationsdatei:

- `leader enabled (race-director)` → `leader enabled`
- `idle kicker disabled` → `idle kicker disabled`
- `race timer disabled` → `race timer disabled`
- `event loop disabled` → `event loop disabled`
- `hide default user liveries` → `hide default user liveries`
- `disable auto-admin` → `disable auto-admin`

### Auto-Ban-Meldungen

Anzahl der Meldungen, bevor automatisch eingegriffen wird. **0 = deaktiviert**. Standard: censor 4, silence 8, suspend 12.

### Ban-Dauer (Minuten)

Drei Kategorien (server, admin, default) mit jeweils einer Dauer für censor, silence und suspend. Standardmäßig 1440 Minuten (1 Tag) und 525600 Minuten (1 Jahr) für suspend.

Schaltflächen: **Serverconfig opslaan** schreibt die Datei (mit Backup); **Herladen** (Neu laden) liest die Werte erneut aus der Datei und verwirft nicht gespeicherte Änderungen.

## 5. Registerkarte Evenementen – Rennen und Event-Loops

Ein Event-Loop ist eine `.becl`-Datei in der save-dir mit der Liste der Rennen, die der Server abspielt.

### Event-Loop-Datei

- Wählen Sie eine vorhandene Datei im Dropdown aus und klicken Sie auf **Laden**.
- **Nieuw** (Neu) erstellt ein leeres Rennen im Speicher.
- **Opslaan als** (Speichern unter) schreibt nach `<name>.becl` in der save-dir, erstellt bei einer vorhandenen Datei ein Backup und setzt sowohl dieses Dropdown als auch **Event loop** in der Registerkarte Server auf diesen Namen. Geben Sie also denselben Namen an, den Sie in **Server** eingetragen haben.

### Liste der Veranstaltungen

Mit **Nieuw**, **Dupliceer** (Duplizieren), **Verwijder** (Löschen), **Omhoog** (Nach oben) und **Omlaag** (Nach unten) verwalten Sie die Reihenfolge der Rennen. Wenn Sie ein anderes Rennen in der Liste auswählen, werden die aktuellen Felder automatisch im vorherigen Event gespeichert. Alles wird nach **Opslaan als** endgültig.

Eine leere Zeile in der Liste sieht aus wie `1. track01_1 [bangerrace]`.

### Level

| Feld | Erläuterung |
| --- | --- |
| Level id | Beispiel: `track01_1`; die Auswahl stammt aus den `.evse`-Dateien der Serverinstallation. |
| Weer | Pfad wie `data/property/weather/track01_1.weat`. |
| AI-set | Pfad wie `runtime/career/ai-class-all.aist`. |
| Game mode | `bangerrace`, `waypointrace`, `suiciderace` oder `demolitionderby`. |

### Regeln

| Feld | Bereich / Optionen |
| --- | --- |
| Rondes | 0–100 (optional in Verbindung mit der Zeitbegrenzung). |
| Tijdslimiet | 0–1000. |
| Teams | 1–10. |
| Max deelnemers | 1–24. |
| Vlaggen | Freitext; spielspezifische Renn-Flags. |
| Collecting | `Collecting Sequential` oder `Collecting Random`. |
| Car reset (s) | 0–60 Sekunden. |
| Team split (%) | 0–100. |
| Schade-id | leer, `normal`, `realistic` oder `wrecker`. |
| Bots | 0–24. |

### Car restrictions

Ein JSON-**Array** mit Einschränkungen für Fahrzeuge. Verwenden Sie `[]`, wenn es keine Einschränkungen gibt. Ungültiges JSON führt zu einer Fehlermeldung und wird nicht gespeichert.

## 6. Registerkarte Cups – Meisterschaften

Cups werden in `server_cup_config.ccnl` gespeichert. Welche Cups aktiv sind, wird durch das Feld **Cup list** in der Registerkarte Server bestimmt.

Verwenden Sie für die Liste **Nieuw**, **Dupliceer**, **Verwijder**, **Omhoog** und **Omlaag**; **Cups opslaan** schreibt alles weg.

### Cup

| Feld | Erläuterung |
| --- | --- |
| Naam | Name der Cup. |
| Beschrijving | Mehrzeiliges Feld. |
| Event loop | Relativer Pfad zu einer `.becl`-Datei aus der Serverinstallation (z. B. `data/property/settings/cup/waypoint_tracks.becl`). |
| Icon | Optionaler Pfad/Name eines Icons. |

### Renneinstellungen

| Feld | Standard | Erläuterung |
| --- | --- | --- |
| Point distribution | `30;27;25;20;19;...;1;0` | Punkte pro Position, getrennt durch `;`. |
| Vlaggen | leer | Spielspezifische Flags. |
| Start order | `random` | Auch `points`, `points reversed` und `last race reversed`. |
| Punten beste ronde | 0 | Extrapunkte für die schnellste Runde. |
| Punten hoogste score | 0 | Extrapunkte für die höchste Punktzahl. |
| Laatste race multiplier | 1 | Multiplikator für das letzte Rennen (0–100). |

**Car restrictions** funktioniert genauso wie bei Veranstaltungen: ein JSON-Array, `[]` bedeutet keine Einschränkungen.

## 7. Registerkarte Rollen & Bans

Diese Registerkarte verwaltet `server_privilege.sprv`.

### Rollen

Das Raster hat zwei Spalten:

- **Platform ID (SteamID64)**: die numerische Steam-ID des Spielers.
- **Rol (admin/mod)**: `admin` oder `mod`; wenn Sie das Feld leer lassen, wird `admin` verwendet.

Mit **Rij toevoegen** und **Rij verwijderen** passen Sie die Tabelle an. Zeilen mit leerer ID werden beim Speichern übersprungen. Eine numerische ID wird als Zahl geschrieben, andere Werte als Text.

### Bans

Das große Feld enthält ein JSON-Array mit Bans. `[]` bedeutet keine Bans. Bei ungültigem JSON erscheint eine Fehlermeldung und es wird nichts gespeichert.

**Rollen & bans opslaan** schreibt beide nach `server_privilege.sprv` (mit Backup).

## 8. Registerkarte Telemetrie

Diese Registerkarte verwaltet `telemetry/config.json` in der save-dir. Der Ordner `telemetry` wird automatisch erstellt.

| Feld | Standard | Erläuterung |
| --- | --- | --- |
| UDP ingeschakeld | aus | UDP-Telemetrie ein-/ausschalten. |
| IP-adres | `127.0.0.1` | Zieladresse der UDP-Daten. |
| Poort | `23123` | Zielport der UDP-Daten. |
| Formaat | `none` | `none`, `json` oder `csv`. |
| Server-telemetrie ingeschakeld | aus | Allgemeine Server-Telemetrie. |
| automaticMainCar | aus | Hauptfahrzeug automatisch bestimmen. |

Klicken Sie auf **Telemetrie opslaan** (Telemetrie speichern), um die Werte zu schreiben.

## 9. Registerkarte Starten – Server steuern und Protokoll

### Server steuern

| Feld / Schaltfläche | Erläuterung |
| --- | --- |
| Profiel | Wählen Sie ein Profil; die Konfiguration der zugehörigen save-dir wird sofort geladen. |
| Save-dir | Wird basierend auf dem Profil angezeigt; **Map openen** (Ordner öffnen) öffnet den Ordner im Explorer. |
| Modus | `community (--server)` oder `lokaal (--local-server)`. |
| START server | Speichert zuerst alle Konfigurationen und startet danach den Server in einem separaten, sichtbaren Konsolenfenster. |
| STOP server | Beendet alle `Wreckfest2`-Prozesse, die zur eingestellten Installationsmap gehören. |
| Status vernieuwen | Aktualisiert den Status sofort. |

Die Statusleiste zeigt `Status: SERVER DRAAIT` (grün) oder `Status: gestopt` (rot). Der Status wird alle 2,5 Sekunden automatisch aktualisiert.

Beim Start erstellt WSM2 bei Bedarf `steam_appid.txt` mit AppID `1203190` im Installationsverzeichnis. Da das Spiel `--save-dir=<pad>` ohne Anführungszeichen erwartet, verwendet WSM2 bei Leerzeichen im Pfad automatisch den 8.3-Kurzpfad.

### Serverprotokoll

- **Automatisch verversen** (Automatisch aktualisieren): Zeigt die letzten 300 Zeilen der Protokolldatei; der Zustand beim Start stammt aus `WSM2.settings.json`. Änderungen während der Sitzung gelten nur für diese Sitzung.
- **Vernieuwen** (Aktualisieren): Ruft das Protokoll sofort erneut ab.
- **Logbestand openen** (Protokolldatei öffnen): Öffnet die Protokolldatei in Notepad.
- Der Protokollpfad stammt aus dem Feld **Logbestand** in der Registerkarte Server: Ein relativer Dateiname wird gegen die save-dir aufgelöst, ein absoluter Pfad wird direkt verwendet.

## 10. Häufig verwendete Workflows

### Neuen Server einrichten

1. Registerkarte **Instellingen** → **Automatisch detecteren** → **Instellingen opslaan**.
2. Prüfen Sie in **Starten** die save-dir und wählen Sie den Modus.
3. Registerkarte **Server** → Name, Passwort, Port und Event loop eingeben → **Serverconfig opslaan**.
4. Registerkarte **Evenementen** → **Nieuw**, Rennen konfigurieren, **Opslaan als** mit demselben Namen wie der Event loop in **Server**.
5. Registerkarte **Cups** → bei Bedarf Cups hinzufügen → **Cups opslaan**.
6. Registerkarte **Rollen & Bans** → Admins hinzufügen → speichern.
7. Registerkarte **Starten** → **START server** → Status und Protokoll prüfen.

### Mehrere Server mit Profilen

1. Erstellen Sie in **Instellingen** für jeden Server eine Zeile mit eigenem Namen, eigener save-dir und eigenem Modus.
2. Speichern Sie die Profile.
3. Wählen Sie in **Starten** das gewünschte Profil; alle Registerkarten laden dann die Konfiguration aus dieser save-dir.
4. Beenden Sie den Server, bevor Sie zu einem anderen Profil wechseln oder die Konfiguration speichern.

### Konfiguration sicher ändern

1. **STOP server** in der Registerkarte **Starten**.
2. Ändern Sie die Einstellungen in den entsprechenden Registerkarten.
3. Speichern Sie jede Änderung (automatisch wird eine `.bak` mit Zeitstempel erstellt).
4. Starten Sie den Server erneut.

### Backup wiederherstellen

1. Beenden Sie den Server.
2. Suchen Sie in der save-dir nach `<dateiname>.yyyyMMdd_HHmmss.bak`.
3. Kopieren Sie das gewünschte Backup über die ursprüngliche Datei (entfernen Sie den Zeitstempelteil aus dem Dateinamen).
4. Starten Sie WSM2 neu oder verwenden Sie **Herladen** in der Registerkarte **Server**.

## 11. Probleme beheben

| Problem | Mögliche Ursache / Lösung |
| --- | --- |
| `Server niet gevonden in: ...` | Das Server-Installationsverzeichnis ist falsch. Verwenden Sie **Automatisch detecteren** oder **Bladeren...** und suchen Sie nach `Wreckfest2.exe`. |
| Spieler sehen den Server nicht | Prüfen Sie den Modus (`community`), das Passwort und ob der Game-Port in Firewall/Router geöffnet ist. |
| Speichern abgelehnt mit Meldung zum Server | Der Server läuft noch. Klicken Sie auf **STOP server** und versuchen Sie es erneut. |
| Dropdowns für Levels/Wetter/AI bleiben leer | Das Installationsverzeichnis enthält kein `data\property\...`; Pfade prüfen, speichern und die App gegebenenfalls neu starten. |
| Protokollfenster bleibt leer | Geben Sie in **Server** ein **Logbestand** an und prüfen Sie, ob diese Datei in der save-dir existiert. |
| Fehler "Ongeldige JSON" bei Car restrictions oder Bans | Der Text ist kein gültiges JSON-Array. Verwenden Sie `[]`, um leer zu beginnen. |
| Event-Loop startet nicht | Prüfen Sie, ob der Name in **Server → Event loop** exakt mit einer `.becl`-Datei in der save-dir übereinstimmt. |
| Server startet mit "Fatal Error: pad bestaat niet" | Existiert die save-dir? WSM2 verwendet bei Leerzeichen einen 8.3-Kurzpfad; prüfen Sie den Pfad in **Starten**. |

### Diagnose per Selftest

Für Entwickler: Setzen Sie die Umgebungsvariable `WSM2_SELFTEST=1`, bevor Sie `WSM2.cmd` starten. Das Programm lädt alle Konfigurationen, gibt eine Zeile wie `SELFTEST OK | events=... cups=... levels=...` aus und beendet sich selbst, ohne das Fenster anzuzeigen. Nützlich, um zu prüfen, ob Pfade und Spieldaten korrekt gefunden werden.
