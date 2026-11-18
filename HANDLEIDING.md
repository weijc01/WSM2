# Handleiding – WSM2 (Wreckfest 2 Server Manager)

Deze handleiding beschrijft stap voor stap hoe je WSM2 gebruikt. Lees eerst de [README.md](README.md) voor installatie en algemene informatie.

## Inhoud

1. [Starten van het programma](#1-starten-van-het-programma)
2. [Overzicht van het venster](#2-overzicht-van-het-venster)
3. [Tabblad Instellingen – paden en profielen](#3-tabblad-instellingen--paden-en-profielen)
4. [Tabblad Server – basisconfiguratie](#4-tabblad-server--basisconfiguratie)
5. [Tabblad Evenementen – races en event loops](#5-tabblad-evenementen--races-en-event-loops)
6. [Tabblad Cups – kampioenschappen](#6-tabblad-cups--kampioenschappen)
7. [Tabblad Rollen & Bans](#7-tabblad-rollen--bans)
8. [Tabblad Telemetrie](#8-tabblad-telemetrie)
9. [Tabblad Starten – server bedienen en log](#9-tabblad-starten--server-bedienen-en-log)
10. [Veelgebruikte workflows](#10-veelgebruikte-workflows)
11. [Problemen oplossen](#11-problemen-oplossen)

---

## 1. Starten van het programma

Dubbelklik op `WSM2.cmd`. Er verschijnt een venster met de titel *WSM2 - Wreckfest 2 Server Manager*. De PowerShell-console zelf blijft verborgen.

Bij de eerste start worden ontbrekende configuratiebestanden automatisch aangemaakt in de save-dir (standaard `C:\WreckFest2server`). Als er iets misgaat bij het laden, verschijnt een foutmelding met de reden.

**Belangrijke regel:** stop de server altijd voordat je configuratie opslaat. De server schrijft bij het afsluiten zijn eigen configuratie weg en kan jouw wijzigingen anders tenietdoen. WSM2 blokkeert opslaan zolang de server draait.

## 2. Overzicht van het venster

Het venster heeft zeven tabbladen en onderaan een statusbalk die aangeeft welk bestand het laatst is opgeslagen.

| Tabblad | Wat je er doet |
| --- | --- |
| Server | Naam, wachtwoord, poort, event loop, vlaggen en ban-regels. |
| Evenementen | Event loop-`.becl`-bestanden met races, levels en regels. |
| Cups | Cup-configuratie (`.ccnl`) met punten en startvolgorde. |
| Rollen & Bans | Admins/moderators en bans (`.sprv`). |
| Telemetrie | UDP, logging en server-telemetrie (`telemetry/config.json`). |
| Starten | Profiel kiezen, server starten/stoppen en het log bekijken. |
| Instellingen | Installatiepaden en profielen beheren. |

## 3. Tabblad Instellingen – paden en profielen

### Installatiepaden

| Veld | Uitleg |
| --- | --- |
| Server-installatiemap | Map met `Wreckfest2.exe`, meestal `C:\Program Files (x86)\Steam\steamapps\common\Wreckfest 2 Dedicated Server`. |
| Steam.exe | Pad naar `steam.exe`; wordt door WSM2 gebruikt voor detectie en referentie. |

Knoppen:

- **Bladeren...** (bij elk veld): kies de map respectievelijk het bestand handmatig.
- **Automatisch detecteren**: zoekt in `Program Files (x86)`, `Program Files`, het register en `libraryfolders.vdf` van Steam. Handig als Steam op een andere schijf staat.
- **Instellingen opslaan**: schrijft de paden én de profielentabel weg naar `WSM2.settings.json` en vernieuwt de dropdowns met speldata.
- **Taal:** kies **Nederlands**, **English**, **Français** of **Deutsch**. De keuze wordt direct toegepast en opgeslagen als `Language` in `WSM2.settings.json`.

### Profielen

Een profiel is een combinatie van **naam**, **save-dir** en **modus**. Met profielen beheer je meerdere servers zonder telkens paden te wijzigen.

- **Rij toevoegen**: maakt een rij `Nieuw` met de huidige save-dir en modus `community` aan.
- **Rij verwijderen**: verwijdert de geselecteerde rij. Er moet minstens één profiel overblijven.
- **Profielen opslaan**: slaat de tabel op (en ook de installatiepaden).
- **Modus** is `community` (server zichtbaar in de serverlijst) of `local` (lokale server).

Kolommen:

| Kolom | Uitleg |
| --- | --- |
| Naam | Vrije naam, bijvoorbeeld `Standaard` of `Testserver`. |
| Save-dir | Map met de configuratiebestanden van die server. |
| Modus (community/local) | Startargument `--server` of `--local-server`. |

Herstart de app als nieuwe paden of profielen niet direct zichtbaar zijn in de andere tabbladen.

## 4. Tabblad Server – basisconfiguratie

### Netwerk (`server_config.scnf`)

| Veld | Standaard | Uitleg |
| --- | --- | --- |
| Naam | `Wreckfest 2 Server` | Naam in de serverbrowser. |
| Beschrijving | – | Meerregelig veld; verschijnt bij de server. |
| Wachtwoord | leeg | Leeg betekent een openbare server. |
| Logbestand | leeg | Bestandsnaam in de save-dir of een volledig pad; wordt gebruikt door de logweergave op **Starten**. |
| Game poort | `30100` | Poort voor het spelverkeer; moet openstaan in firewall/router. |

### Spel

| Veld | Standaard | Uitleg |
| --- | --- | --- |
| Event loop | `default_loop` | Naam van een `.becl`-bestand in de save-dir (zonder extensie). Maak dit bestand aan op het tabblad **Evenementen**. |
| Cup list | leeg | Verwijzing naar de cup-lijstconfiguratie. |
| Countdown (ms) | `100000` | Aftellen vóór de start; bereik 30000–500000 ms. |
| Voting (ms) | `20000` | Tijd voor het stemmen over de volgende race; bereik 10000–30000 ms. |

### Servervlaggen

Elke optie zet een vlag in het configuratiebestand:

- `leader enabled (race-director)` → `leader enabled`
- `idle kicker disabled` → `idle kicker disabled`
- `race timer disabled` → `race timer disabled`
- `event loop disabled` → `event loop disabled`
- `hide default user liveries` → `hide default user liveries`
- `disable auto-admin` → `disable auto-admin`

### Auto-ban meldingen

Aantal meldingen voordat automatisch wordt ingegrepen. **0 = uitgeschakeld**. Standaard: censor 4, silence 8, suspend 12.

### Ban-duren (minuten)

Drie categorieën (server, admin, default) met elk een duur voor censor, silence en suspend. Standaard 1440 minuten (1 dag) en 525600 minuten (1 jaar) voor suspend.

Knoppen: **Serverconfig opslaan** schrijft het bestand weg (met back-up); **Herladen** haalt de waarden weer uit het bestand en verwerpt niet-opgeslagen wijzigingen.

## 5. Tabblad Evenementen – races en event loops

Een event loop is een `.becl`-bestand in de save-dir met de lijst races die de server afspeelt.

### Event loop-bestand

- Kies een bestaand bestand in de dropdown en klik op **Laden**.
- **Nieuw** maakt één lege race in het geheugen.
- **Opslaan als** schrijft naar `<naam>.becl` in de save-dir, maakt een back-up bij een bestaand bestand en zet zowel deze dropdown als **Event loop** op de Server-tab naar die naam. Geef dus dezelfde naam op die je op **Server** hebt ingevuld.

### Lijst met evenementen

Met **Nieuw**, **Dupliceer**, **Verwijder**, **Omhoog** en **Omlaag** beheer je de volgorde van de races. Wanneer je een andere race in de lijst selecteert, worden de huidige velden automatisch in het vorige event opgeslagen. Alles wordt definitief na **Opslaan als**.

Een lege regel in de lijst ziet er uit als `1. track01_1 [bangerrace]`.

### Level

| Veld | Uitleg |
| --- | --- |
| Level id | Bijvoorbeeld `track01_1`; keuzes komen uit de `.evse`-bestanden van de serverinstallatie. |
| Weer | Pad zoals `data/property/weather/track01_1.weat`. |
| AI-set | Pad zoals `runtime/career/ai-class-all.aist`. |
| Game mode | `bangerrace`, `waypointrace`, `suiciderace` of `demolitionderby`. |

### Regels

| Veld | Bereik / opties |
| --- | --- |
| Rondes | 0–100 (optioneel i.v.m. tijdslimiet). |
| Tijdslimiet | 0–1000. |
| Teams | 1–10. |
| Max deelnemers | 1–24. |
| Vlaggen | Vrije tekst; spelspecifieke racevlaggen. |
| Collecting | `Collecting Sequential` of `Collecting Random`. |
| Car reset (s) | 0–60 seconden. |
| Team split (%) | 0–100. |
| Schade-id | leeg, `normal`, `realistic` of `wrecker`. |
| Bots | 0–24. |

### Car restrictions

Een JSON-**array** met beperkingen op voertuigen. Gebruik `[]` als er geen beperkingen zijn. Ongeldige JSON geeft een foutmelding en wordt niet opgeslagen.

## 6. Tabblad Cups – kampioenschappen

Cups worden opgeslagen in `server_cup_config.ccnl`. Welke cups actief zijn, wordt bepaald door het veld **Cup list** op de Server-tab.

Gebruik **Nieuw**, **Dupliceer**, **Verwijder**, **Omhoog** en **Omlaag** voor de lijst; **Cups opslaan** schrijft alles weg.

### Cup

| Veld | Uitleg |
| --- | --- |
| Naam | Naam van de cup. |
| Beschrijving | Meerregelig veld. |
| Event loop | Relatief pad naar een `.becl`-bestand uit de serverinstallatie (bijvoorbeeld `data/property/settings/cup/waypoint_tracks.becl`). |
| Icon | Optioneel pad/naam van een icoon. |

### Race-instellingen

| Veld | Standaard | Uitleg |
| --- | --- | --- |
| Point distribution | `30;27;25;20;19;...;1;0` | Punten per positie, gescheiden door `;`. |
| Vlaggen | leeg | Spelspecifieke vlaggen. |
| Start order | `random` | Ook `points`, `points reversed` en `last race reversed`. |
| Punten beste ronde | 0 | Extra punten voor de snelste ronde. |
| Punten hoogste score | 0 | Extra punten voor de hoogste score. |
| Laatste race multiplier | 1 | Vermenigvuldiger voor de laatste race (0–100). |

**Car restrictions** werkt hetzelfde als bij evenementen: een JSON-array, `[]` betekent geen beperkingen.

## 7. Tabblad Rollen & Bans

Dit tabblad beheert `server_privilege.sprv`.

### Rollen

Het grid heeft twee kolommen:

- **Platform ID (SteamID64)**: het numerieke Steam-ID van de speler.
- **Rol (admin/mod)**: `admin` of `mod`; laat je het veld leeg, dan wordt `admin` gebruikt.

Met **Rij toevoegen** en **Rij verwijderen** pas je de tabel aan. Rijen met een leeg ID worden bij opslaan overgeslagen. Een numeriek ID wordt als getal weggeschreven, andere waarden als tekst.

### Bans

Het grote veld bevat een JSON-array met bans. `[]` betekent geen bans. Bij ongeldige JSON verschijnt een foutmelding en wordt niets opgeslagen.

**Rollen & bans opslaan** schrijft beide naar `server_privilege.sprv` (met back-up).

## 8. Tabblad Telemetrie

Dit tabblad beheert `telemetry/config.json` in de save-dir. De map `telemetry` wordt automatisch aangemaakt.

| Veld | Standaard | Uitleg |
| --- | --- | --- |
| UDP ingeschakeld | uit | Zet UDP-telemetrie aan/uit. |
| IP-adres | `127.0.0.1` | Doeladres van de UDP-data. |
| Poort | `23123` | Doelpoort van de UDP-data. |
| Formaat | `none` | `none`, `json` of `csv`. |
| Server-telemetrie ingeschakeld | uit | Algemene servertelemetrie. |
| automaticMainCar | uit | Automatisch de hoofdauto bepalen. |

Klik op **Telemetrie opslaan** om de waarden weg te schrijven.

## 9. Tabblad Starten – server bedienen en log

### Server bedienen

| Veld / knop | Uitleg |
| --- | --- |
| Profiel | Kies een profiel; de configuratie van de bijbehorende save-dir wordt direct geladen. |
| Save-dir | Wordt getoond op basis van het profiel; **Map openen** opent de map in Verkenner. |
| Modus | `community (--server)` of `lokaal (--local-server)`. |
| START server | Slaat eerst alle configuraties op en start daarna de server in een apart, zichtbaar consolevenster. |
| STOP server | Stopt alle `Wreckfest2`-processen die bij de ingestelde installatiemap horen. |
| Status vernieuwen | Werkt de statusdirect bij. |

De statusbalk toont `Status: SERVER DRAAIT` (groen) of `Status: gestopt` (rood). De status wordt elke 2,5 seconde automatisch ververst.

Bij het starten maakt WSM2 indien nodig `steam_appid.txt` met AppID `1203190` aan in de installatiemap. Omdat het spel `--save-dir=<pad>` zonder quotes verwacht, gebruikt WSM2 bij spaties in het pad automatisch het 8.3-korte pad.

### Serverlog

- **Automatisch verversen**: toont de laatste 300 regels van het logbestand; de stand bij het opstarten komt uit `WSM2.settings.json`. Wijzigen tijdens de sessie geldt alleen voor die sessie.
- **Vernieuwen**: haalt de log direct opnieuw op.
- **Logbestand openen**: opent het logbestand in Kladblok.
- Het logpad komt uit het veld **Logbestand** op de Server-tab: een relatieve bestandsnaam wordt opgelost tegen de save-dir, een absolute pad wordt direct gebruikt.

## 10. Veelgebruikte workflows

### Een nieuwe server opzetten

1. Tab **Instellingen** → **Automatisch detecteren** → **Instellingen opslaan**.
2. Controleer op **Starten** de save-dir en kies de modus.
3. Tab **Server** → naam, wachtwoord, poort en event loop invullen → **Serverconfig opslaan**.
4. Tab **Evenementen** → **Nieuw**, races instellen, **Opslaan als** met dezelfde naam als de event loop op **Server**.
5. Tab **Cups** → eventueel cups toevoegen → **Cups opslaan**.
6. Tab **Rollen & Bans** → admins toevoegen → opslaan.
7. Tab **Starten** → **START server** → status en log controleren.

### Meerdere servers met profielen

1. Maak op **Instellingen** voor elke server een rij met een eigen naam, save-dir en modus.
2. Sla de profielen op.
3. Kies op **Starten** het gewenste profiel; alle tabbladen laden dan de configuratie uit die save-dir.
4. Stop de server voordat je naar een ander profiel wisselt of configuratie opslaat.

### Configuratie veilig aanpassen

1. **STOP server** op het tabblad **Starten**.
2. Wijzig de instellingen op de betreffende tabbladen.
3. Sla elke wijziging op (er wordt automatisch een `.bak` met tijdstempel gemaakt).
4. Start de server opnieuw.

### Een back-up terugzetten

1. Stop de server.
2. Zoek in de save-dir naar `<bestandsnaam>.yyyyMMdd_HHmmss.bak`.
3. Kopieer de gewenste back-up terug over het oorspronkelijke bestand heen (verwijder het tijdstempelgedeelte uit de bestandsnaam).
4. Herstart WSM2 of gebruik **Herladen** op het tabblad **Server**.

## 11. Problemen oplossen

| Probleem | Mogelijke oorzaak / oplossing |
| --- | --- |
| `Server niet gevonden in: ...` | De server-installatiemap klopt niet. Gebruik **Automatisch detecteren** of **Bladeren...** en zoek `Wreckfest2.exe`. |
| Spelers zien de server niet | Controleer modus (`community`), wachtwoord en of de gamepoort openstaat in firewall/router. |
| Opslaan geweigerd met melding over de server | De server draait nog. Klik op **STOP server** en probeer opnieuw. |
| Dropdowns voor levels/weer/AI blijven leeg | De installatiemap bevat geen `data\property\...`; paden controleren, opslaan en eventueel de app herstarten. |
| Logvenster blijft leeg | Vul op **Server** een **Logbestand** in en controleer of dat bestand in de save-dir bestaat. |
| Fout "Ongeldige JSON" bij car restrictions of bans | De tekst is geen geldige JSON-array. Gebruik `[]` om leeg te beginnen. |
| Event loop start niet | Controleer of de naam op **Server → Event loop** exact overeenkomt met een `.becl`-bestand in de save-dir. |
| Server start met "Fatal Error: pad bestaat niet" | Bestaat de save-dir? WSM2 gebruikt bij spaties een 8.3-kort pad; controleer het pad op **Starten**. |

### Diagnose via selftest

Voor ontwikkelaars: zet de omgevingsvariabele `WSM2_SELFTEST=1` voordat je `WSM2.cmd` start. Het programma laadt alle configuratie, print een regel als `SELFTEST OK | events=... cups=... levels=...` en sluit zichzelf zonder het venster te tonen. Handig om te controleren of paden en speldata correct worden gevonden.
