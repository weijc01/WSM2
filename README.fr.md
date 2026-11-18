# WSM2 – Wreckfest 2 Server Manager

WSM2 est un utilitaire graphique de gestion d'un **serveur dédié Wreckfest 2** sous Windows. Au lieu de modifier manuellement les fichiers de configuration JSON, vous gérez le nom du serveur, les courses, les cups, les rôles, les bannissements et la télémétrie depuis une seule fenêtre. Le serveur se lance et s'arrête d'un simple clic dans une fenêtre de console distincte.

## Fonctionnalités

- Interface WinForms avec sept onglets : Server, Evenementen, Cups, Rollen & Bans, Telemetrie, Starten et Instellingen.
- Interface multilingue : anglais (par défaut), néerlandais, français et allemand, à changer via **Instellingen → Taal:** (Paramètres → Langue).
- Plusieurs **profils**, chacun avec son propre save-dir et son propre mode (`community` ou `lokaal`).
- Détection automatique de Steam et du serveur dédié Wreckfest 2, y compris les bibliothèques Steam supplémentaires.
- Listes déroulantes alimentées par les données réelles du jeu : levels (`.evse`), météo (`.weat`), sets d'IA (`.aist`), modes de jeu et cup loops (`.becl`).
- Enregistrement sécurisé : les modifications sont refusées tant que le serveur tourne (le serveur écrase les configurations à la fermeture).
- **Sauvegardes** automatiques horodatées de chaque fichier de configuration lors de l'enregistrement.
- Journal du serveur en direct dans la fenêtre, avec actualisation automatique et ouverture dans le Bloc-notes.
- Lancement dans une fenêtre de console visible, avec gestion des espaces dans les chemins via le chemin court 8.3.

## Configuration requise

- Windows 10/11 avec **PowerShell 5.1** et .NET Framework (WinForms ; inclus par défaut).
- Steam avec le **serveur dédié Wreckfest 2** installé (AppID `1203190`).
- Droits d'écriture sur le dossier d'installation (`steam_appid.txt` est créé si nécessaire) et sur le save-dir.

### Dois-je installer .NET Framework séparément ?

En général **non** : Windows 10/11 fournit PowerShell 5.1 et .NET Framework 4.x avec WinForms par défaut. WSM2 n'a besoin ni du **SDK** .NET ni du **Developer Pack**, uniquement du **runtime**.

Vérification dans PowerShell :

```powershell
$PSVersionTable.PSVersion          # doit être 5.1.x
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release   # 528040 ou supérieur = .NET 4.8
```

Si .NET Framework 4.8 est absent ou désactivé :

1. Téléchargez le **Runtime .NET Framework 4.8** (pas le Developer Pack) depuis <https://dotnet.microsoft.com/download/dotnet-framework/net48>.
2. Sous *Advanced downloads*, vous pouvez choisir l'**installateur hors ligne** si Internet n'est pas disponible pendant l'installation.
3. Exécutez l'installateur en tant qu'administrateur et redémarrez Windows si vous y êtes invité.
4. Autre solution sur Windows 10/11 : **Panneau de configuration → Programmes et fonctionnalités → Activer ou désactiver des fonctionnalités Windows** → cochez ".NET Framework 4.8".

## Installation

1. Téléchargez ou clonez ce dépôt dans un dossier fixe, par exemple `C:\Tools\WSM2`.
2. Conservez ensemble `WSM2.cmd`, `WSM2.ps1`, `WSM2.settings.json` et le dossier `lib\`.
3. Double-cliquez sur **`WSM2.cmd`**. Aucune installation ni droit d'administrateur n'est nécessaire ; le lanceur démarre PowerShell avec `-ExecutionPolicy Bypass` uniquement pour ce processus.
4. Au premier lancement, allez dans **Instellingen** → **Automatisch detecteren**, vérifiez les chemins et cliquez sur **Instellingen opslaan**.

> Windows Defender/SmartScreen peut afficher un avertissement pour un script PowerShell. Le lanceur n'utilise que les scripts locaux de ce dossier.

## Démarrage rapide

1. **Instellingen** : détectez et enregistrez les chemins d'installation ; créez un profil si nécessaire.
2. **Server** : indiquez un nom, éventuellement un mot de passe et un port de jeu (30100 par défaut) → **Serverconfig opslaan**.
3. **Evenementen** : choisissez un fichier d'event loop ou créez-en un nouveau, ajoutez des courses → **Opslaan als**.
4. **Cups** (facultatif) : configurez les cups → **Cups opslaan**.
5. **Starten** : choisissez le profil et le mode → **START server**. Arrêtez toujours le serveur avant de modifier une configuration.

## Routeur KPN : redirection de ports

Dans le routeur KPN, allez dans **Beveiliging → Portforwarding** (Sécurité → Redirection de ports) et ajoutez :

| Protocole | Port(s) | IP Internet | IP de destination |
| --- | --- | --- | --- |
| UDP | `30100,27015,27016,33540` | laisser vide | le serveur |

Laissez le champ **IP Internet** vide et indiquez l'adresse IP locale du serveur comme **IP de destination**. Si le routeur n'accepte pas une liste de ports séparés par des virgules, créez quatre règles distinctes.

## Pare-feu Windows

Autorisez le trafic UDP entrant depuis l'extérieur sur les mêmes quatre ports. Exécutez PowerShell **en tant qu'administrateur** :

```powershell
New-NetFirewallRule -DisplayName "Wreckfest 2 Server (UDP 30100,27015,27016,33540)" -Direction Inbound -Protocol UDP -LocalPort 30100,27015,27016,33540 -RemoteAddress Any -Action Allow -Profile Any
```

Ou via l'interface : **Pare-feu Windows Defender → Paramètres avancés → Règles de trafic entrant → Nouvelle règle...** → **Port** → **UDP** → saisissez les quatre ports → autorisez la connexion. Supprimez ou limitez cette règle si le serveur ne doit pas être accessible depuis Internet.

Consultez [GUIDE.fr.md](GUIDE.fr.md) pour les explications détaillées, étape par étape, de tous les champs et workflows.

## Structure du projet

| Fichier | Rôle |
| --- | --- |
| `WSM2.cmd` | Lanceur ; démarre la fenêtre principale sans console PowerShell visible. |
| `WSM2.ps1` | Programme principal : interface WinForms, gestion des événements et logique de chargement/enregistrement. |
| `WSM2.settings.json` | Paramètres de l'application : chemins, dernier profil, langue, suivi du journal et profils. |
| `lib/Config.ps1` | Lecture, validation et écriture de la configuration du serveur, des cups, des privilèges et de la télémétrie, avec sauvegardes. |
| `lib/GameData.ps1` | Détection des bibliothèques Steam et lecture des données de jeu pour les listes déroulantes. |
| `lib/Profiles.ps1` | Gestion de `WSM2.settings.json` et des profils. |
| `lib/Languages.ps1` | Fonctions de langue centrales et sélection de la langue (NL/EN/FR/DE). |
| `lib/Languages.*.ps1` | Clés néerlandaises et traductions pour EN, FR et DE. |
| `lib/Server.ps1` | Démarrage/arrêt du serveur, contrôle de l'état et lecture du journal. |

## Fichiers de configuration

Tous les fichiers se trouvent dans le **save-dir** du profil actif (par défaut `C:\WreckFest2server`).

| Fichier | Onglet | Contenu |
| --- | --- | --- |
| `server_config.scnf` | Server | Nom, mot de passe, port, event loop, indicateurs et règles de bannissement. |
| `<naam>.becl` | Evenementen | Event loop avec courses, levels, règles et nombre de bots. |
| `server_cup_config.ccnl` | Cups | Cups, répartition des points et ordre de départ. |
| `server_privilege.sprv` | Rollen & Bans | Rôles admin/mod et bannissements. |
| `telemetry/config.json` | Telemetrie | UDP, journalisation et télémétrie du serveur. |

À chaque enregistrement, WSM2 crée d'abord une copie `<nom de fichier>.yyyyMMdd_HHmmss.bak` à côté de l'original.

## Problèmes courants

| Symptôme | Solution |
| --- | --- |
| Serveur introuvable | Vérifiez **Instellingen → Server-installatiemap** ; cherchez `Wreckfest2.exe` ou utilisez **Automatisch detecteren**. |
| Les joueurs ne peuvent pas se connecter | Vérifiez le port de jeu dans **Server** et ouvrez-le dans le pare-feu/le routeur. |
| Enregistrement refusé | Arrêtez d'abord le serveur ; WSM2 empêche le serveur d'écraser vos modifications à la fermeture. |
| Les listes (levels/météo) restent vides | Le dossier d'installation du serveur est incorrect ; relancez la détection et cliquez sur **Instellingen opslaan**. |
| Aucun journal affiché | Renseignez le champ **Logbestand** dans **Server** (nom de fichier dans le save-dir ou chemin complet). |
| Le serveur démarre avec « Fatal Error: pad bestaat niet » | Vérifiez que le save-dir existe ; WSM2 utilise automatiquement le chemin court 8.3 en cas d'espaces. |

## Avancé

- Avec la variable d'environnement `WSM2_SELFTEST=1`, le programme effectue un test de diagnostic sans fenêtre et affiche un résumé des données chargées.
- Avec `WSM2_LANG=en|nl|fr|de`, vous pouvez forcer temporairement une langue ; sans cette variable, le choix de `WSM2.settings.json` s'applique (par défaut `en`).
- `WSM2.settings.json` est écrit **sans** sauvegarde ; faites une copie manuelle avant de modifier les chemins ou les profils à la main.

## Avertissement

WSM2 est un outil non officiel et n'est affilié ni à Bugbear Entertainment, ni à THQ Nordic, ni à Valve. Utilisation à vos risques ; sauvegardez régulièrement votre save-dir.
