# WSM2 – Wreckfest 2 Server Manager

WSM2 is een grafisch beheerprogramma voor een **Wreckfest 2 dedicated server** op Windows. In plaats van de JSON-configuratiebestanden met de hand te bewerken, beheer je servernaam, races, cups, rollen, bans en telemetrie vanuit één venster. De server start en stopt met één klik in een apart consolevenster.

## Functies

- WinForms-interface met zeven tabbladen: Server, Evenementen, Cups, Rollen & Bans, Telemetrie, Starten en Instellingen.
- Meerdere **profielen** met elk een eigen save-dir en modus (`community` of `lokaal`).
- Automatische detectie van Steam en de Wreckfest 2 Dedicated Server, inclusief extra Steam-bibliotheken.
- Dropdowns gevuld met echte speldata: levels (`.evse`), weer (`.weat`), AI-sets (`.aist`), game modes en cup-loops (`.becl`).
- Veilig opslaan: wijzigingen worden geweigerd zolang de server draait (de server overschrijft configs bij afsluiten).
- Automatische **back-ups** met tijdstempel van elk configuratiebestand bij opslaan.
- Live serverlog in het venster, met automatische verversing en openen in Kladblok.
- Starten in een zichtbaar consolevenster, met omgang met spaties in paden via het 8.3-korte pad.

## Vereisten

- Windows 10/11 met **PowerShell 5.1** en .NET Framework (WinForms; standaard aanwezig).
- Steam met **Wreckfest 2 Dedicated Server** geïnstalleerd (AppID `1203190`).
- Schrijfrechten op de installatiemap (`steam_appid.txt` wordt indien nodig aangemaakt) en op de save-dir.

### Moet ik .NET Framework apart installeren?

Meestal **nee**: Windows 10/11 levert PowerShell 5.1 en .NET Framework 4.x met WinForms standaard mee. WSM2 heeft geen .NET **SDK** of **Developer Pack** nodig, alleen de **runtime**.

Controleren in PowerShell:

```powershell
$PSVersionTable.PSVersion          # moet 5.1.x zijn
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release   # 528040 of hoger = .NET 4.8
```

Als .NET Framework 4.8 ontbreekt of is uitgeschakeld:

1. Download de **.NET Framework 4.8 Runtime** (niet het Developer Pack) van <https://dotnet.microsoft.com/download/dotnet-framework/net48>.
2. Onder *Advanced downloads* kun je eventueel de **offline installer** kiezen als er tijdens de installatie geen internet beschikbaar is.
3. Voer de installer uit als administrator en herstart Windows als dat wordt gevraagd.
4. Alternatief op Windows 10/11: **Configuratiescherm → Programma's en onderdelen → Windows-onderdelen in-/uitschakelen** → ".NET Framework 4.8" aanvinken.

## Installatie

1. Download of clone deze repository naar een vaste map, bijvoorbeeld `C:\Tools\WSM2`.
2. Houd `WSM2.cmd`, `WSM2.ps1`, `WSM2.settings.json` en de map `lib\` bij elkaar.
3. Dubbelklik op **`WSM2.cmd`**. Er is geen installatie of administratorrecht nodig; de launcher start PowerShell met `-ExecutionPolicy Bypass` alleen voor dit proces.
4. Ga bij de eerste start naar **Instellingen** → **Automatisch detecteren**, controleer de paden en klik op **Instellingen opslaan**.

> Windows Defender/SmartScreen kan waarschuwen voor een PowerShell-script. De launcher gebruikt alleen lokale scripts uit deze map.

## Snel starten

1. **Instellingen**: detecteer en sla de installatiepaden op; maak eventueel een profiel aan.
2. **Server**: geef een naam, eventueel een wachtwoord en een gamepoort (standaard `30100`) op → **Serverconfig opslaan**.
3. **Evenementen**: kies een event loop-bestand of maak er een nieuw aan, voeg races toe → **Opslaan als**.
4. **Cups** (optioneel): stel cups in → **Cups opslaan**.
5. **Starten**: kies profiel en modus → **START server**. Stop de server altijd eerst voordat je configuratie wijzigt.

Zie [HANDLEIDING.md](HANDLEIDING.md) voor de uitgebreide stapsgewijze uitleg van alle velden en workflows.

## Projectstructuur

| Bestand | Doel |
| --- | --- |
| `WSM2.cmd` | Launcher; start het hoofdvenster zonder zichtbare PowerShell-console. |
| `WSM2.ps1` | Hoofdprogramma: WinForms-interface, event wiring en load/save-logica. |
| `WSM2.settings.json` | App-instellingen: paden, laatste profiel, log-volgen en profielen. |
| `lib/Config.ps1` | Lezen, valideren en schrijven van serverconfig, cups, privileges en telemetrie, inclusief back-ups. |
| `lib/GameData.ps1` | Detectie van Steam-bibliotheken en uitlezen van speldata voor dropdowns. |
| `lib/Profiles.ps1` | Beheer van `WSM2.settings.json` en profielen. |
| `lib/Server.ps1` | Server starten/stoppen, statuscontrole en log uitlezen. |

## Configuratiebestanden

Alle bestanden staan in de **save-dir** van het actieve profiel (standaard `C:\WreckFest2server`).

| Bestand | Tabblad | Inhoud |
| --- | --- | --- |
| `server_config.scnf` | Server | Naam, wachtwoord, poort, event loop, vlaggen, ban-regels. |
| `<naam>.becl` | Evenementen | Event loop met races, levels, regels en bot-aantallen. |
| `server_cup_config.ccnl` | Cups | Cups, puntenverdeling en startvolgorde. |
| `server_privilege.sprv` | Rollen & Bans | Admin/mod-rollen en bans. |
| `telemetry/config.json` | Telemetrie | UDP, logging en server-telemetrie. |

Bij elk opslaan maakt WSM2 eerst een kopie als `<bestandsnaam>.yyyyMMdd_HHmmss.bak` naast het origineel.

## Veelvoorkomende problemen

| Symptoom | Oplossing |
| --- | --- |
| Server niet gevonden | Controleer **Instellingen → Server-installatiemap**; zoek naar `Wreckfest2.exe` of gebruik **Automatisch detecteren**. |
| Spelers kunnen niet verbinden | Controleer de gamepoort in **Server** en zet deze open in firewall/router. |
| Opslaan geweigerd | Stop eerst de server; WSM2 voorkomt dat de server je wijzigingen bij afsluiten overschrijft. |
| Comboboxen (levels/weer) blijven leeg | De server-installatiemap klopt niet; opnieuw detecteren en **Instellingen opslaan**. |
| Geen log zichtbaar | Vul op **Server** een **Logbestand** in (bestandsnaam in de save-dir of een volledig pad). |
| Server start met "Fatal Error: pad bestaat niet" | Controleer of de save-dir bestaat; WSM2 gebruikt bij spaties automatisch het 8.3-korte pad. |

## Geavanceerd

- Met de omgevingsvariabele `WSM2_SELFTEST=1` voert het programma een diagnostische run uit zonder venster en print een samenvatting van geladen data.
- `WSM2.settings.json` wordt bewust **zonder** back-up geschreven; maak zelf een kopie voordat je paden of profielen handmatig aanpast.

## Disclaimer

WSM2 is een onofficieel hulpmiddel en is niet verbonden aan Bugbear Entertainment, THQ Nordic of Valve. Gebruik op eigen risico; maak regelmatig back-ups van je save-dir.
