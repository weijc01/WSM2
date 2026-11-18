# Guide – WSM2 (Wreckfest 2 Server Manager)

Ce guide décrit pas à pas l'utilisation de WSM2. Consultez d'abord le [README.fr.md](README.fr.md) pour l'installation et les informations générales.

## Sommaire

1. [Démarrage du programme](#1-démarrage-du-programme)
2. [Présentation de la fenêtre](#2-présentation-de-la-fenêtre)
3. [Onglet Instellingen – chemins et profils](#3-onglet-instellingen--chemins-et-profils)
4. [Onglet Server – configuration de base](#4-onglet-server--configuration-de-base)
5. [Onglet Evenementen – courses et event loops](#5-onglet-evenementen--courses-et-event-loops)
6. [Onglet Cups – championnats](#6-onglet-cups--championnats)
7. [Onglet Rollen & Bans](#7-onglet-rollen--bans)
8. [Onglet Telemetrie](#8-onglet-telemetrie)
9. [Onglet Starten – gestion du serveur et journal](#9-onglet-starten--gestion-du-serveur-et-journal)
10. [Workflows courants](#10-workflows-courants)
11. [Dépannage](#11-dépannage)

---

## 1. Démarrage du programme

Double-cliquez sur `WSM2.cmd`. Une fenêtre intitulée *WSM2 - Wreckfest 2 Server Manager* apparaît. La console PowerShell reste masquée.

Lors du premier lancement, les fichiers de configuration manquants sont créés automatiquement dans le save-dir (par défaut `C:\WreckFest2server`). Si le chargement échoue, un message d'erreur indique la raison.

**Règle importante :** arrêtez toujours le serveur avant d'enregistrer une configuration. Le serveur réécrit sa propre configuration à la fermeture et pourrait annuler vos modifications. WSM2 bloque l'enregistrement tant que le serveur tourne.

## 2. Présentation de la fenêtre

La fenêtre comporte sept onglets et, en bas, une barre d'état indiquant le dernier fichier enregistré.

| Onglet | Fonction |
| --- | --- |
| Server | Nom, mot de passe, port, event loop, indicateurs et règles de bannissement. |
| Evenementen | Fichiers event loop `.becl` avec courses, levels et règles. |
| Cups | Configuration des cups (`.ccnl`) avec points et ordre de départ. |
| Rollen & Bans | Administrateurs/modérateurs et bannissements (`.sprv`). |
| Telemetrie | UDP, journalisation et télémétrie du serveur (`telemetry/config.json`). |
| Starten | Choix du profil, démarrage/arrêt du serveur et consultation du journal. |
| Instellingen | Gestion des chemins d'installation et des profils. |

## 3. Onglet Instellingen – chemins et profils

### Chemins d'installation

| Champ | Explication |
| --- | --- |
| Server-installatiemap | Dossier contenant `Wreckfest2.exe`, généralement `C:\Program Files (x86)\Steam\steamapps\common\Wreckfest 2 Dedicated Server`. |
| Steam.exe | Chemin vers `steam.exe` ; utilisé par WSM2 pour la détection et à titre de référence. |

Boutons :

- **Bladeren...** (parcourir, pour chaque champ) : choisissez manuellement le dossier ou le fichier.
- **Automatisch detecteren** (détection automatique) : recherche dans `Program Files (x86)`, `Program Files`, le registre et `libraryfolders.vdf` de Steam. Utile si Steam est installé sur un autre disque.
- **Instellingen opslaan** (enregistrer les paramètres) : écrit les chemins et le tableau des profils dans `WSM2.settings.json` et actualise les listes déroulantes avec les données du jeu.
- **Taal:** (Langue) : choisissez **Nederlands**, **English**, **Français** ou **Deutsch**. Le changement est appliqué immédiatement et enregistré comme `Language` dans `WSM2.settings.json`.

### Profils

Un profil est une combinaison d'un **nom**, d'un **save-dir** et d'un **mode**. Les profils permettent de gérer plusieurs serveurs sans changer les chemins à chaque fois.

- **Rij toevoegen** (ajouter une ligne) : crée une ligne `Nieuw` avec le save-dir actuel et le mode `community`.
- **Rij verwijderen** (supprimer la ligne) : supprime la ligne sélectionnée. Au moins un profil doit subsister.
- **Profielen opslaan** (enregistrer les profils) : enregistre le tableau (ainsi que les chemins d'installation).
- **Modus** : `community` (serveur visible dans la liste des serveurs) ou `local` (serveur local).

Colonnes :

| Colonne | Explication |
| --- | --- |
| Naam | Nom libre, par exemple `Standaard` ou `Testserver`. |
| Save-dir | Dossier contenant les fichiers de configuration de ce serveur. |
| Modus (community/local) | Argument de lancement `--server` ou `--local-server`. |

Redémarrez l'application si les nouveaux chemins ou profils ne sont pas immédiatement visibles dans les autres onglets.

## 4. Onglet Server – configuration de base

### Réseau (`server_config.scnf`)

| Champ | Valeur par défaut | Explication |
| --- | --- | --- |
| Naam | `Wreckfest 2 Server` | Nom affiché dans le navigateur de serveurs. |
| Beschrijving | – | Champ multiligne ; description affichée avec le serveur. |
| Wachtwoord | vide | Un champ vide signifie un serveur public. |
| Logbestand | vide | Nom de fichier dans le save-dir ou chemin complet ; utilisé par l'affichage du journal dans **Starten**. |
| Game poort | `30100` | Port du trafic de jeu ; doit être ouvert dans le pare-feu/le routeur. |

### Jeu

| Champ | Valeur par défaut | Explication |
| --- | --- | --- |
| Event loop | `default_loop` | Nom d'un fichier `.becl` dans le save-dir (sans extension). Créez ce fichier dans l'onglet **Evenementen**. |
| Cup list | vide | Référence à la configuration de la liste de cups. |
| Countdown (ms) | `100000` | Compte à rebours avant le départ ; plage 30000–500000 ms. |
| Voting (ms) | `20000` | Temps de vote pour la course suivante ; plage 10000–30000 ms. |

### Indicateurs du serveur

Chaque option active un indicateur dans le fichier de configuration :

- `leader enabled (race-director)` → `leader enabled`
- `idle kicker disabled` → `idle kicker disabled`
- `race timer disabled` → `race timer disabled`
- `event loop disabled` → `event loop disabled`
- `hide default user liveries` → `hide default user liveries`
- `disable auto-admin` → `disable auto-admin`

### Notifications de bannissement automatique

Nombre de signalements avant intervention automatique. **0 = désactivé**. Valeurs par défaut : censor 4, silence 8, suspend 12.

### Durées de bannissement (minutes)

Trois catégories (server, admin, default), chacune avec une durée pour censor, silence et suspend. Par défaut 1440 minutes (1 jour) et 525600 minutes (1 an) pour suspend.

Boutons : **Serverconfig opslaan** (enregistrer la configuration du serveur) écrit le fichier (avec sauvegarde) ; **Herladen** (recharger) relit les valeurs du fichier et annule les modifications non enregistrées.

## 5. Onglet Evenementen – courses et event loops

Un event loop est un fichier `.becl` dans le save-dir qui contient la liste des courses jouées par le serveur.

### Fichier d'event loop

- Choisissez un fichier existant dans la liste déroulante et cliquez sur **Laden** (charger).
- **Nieuw** (nouveau) crée une course vide en mémoire.
- **Opslaan als** (enregistrer sous) écrit dans `<naam>.becl` dans le save-dir, crée une sauvegarde si le fichier existe et définit ce nom dans cette liste et dans le champ **Event loop** de l'onglet **Server**. Utilisez donc le même nom que celui indiqué dans **Server**.

### Liste des événements

Les boutons **Nieuw**, **Dupliceer**, **Verwijder**, **Omhoog** et **Omlaag** permettent de gérer les courses et leur ordre. Lorsque vous sélectionnez une autre course dans la liste, les champs actuels sont automatiquement enregistrés dans l'événement précédent. Tout devient définitif après **Opslaan als**.

Une ligne vide de la liste ressemble à `1. track01_1 [bangerrace]`.

### Level

| Champ | Explication |
| --- | --- |
| Level id | Par exemple `track01_1` ; les choix proviennent des fichiers `.evse` de l'installation du serveur. |
| Weer | Chemin tel que `data/property/weather/track01_1.weat`. |
| AI-set | Chemin tel que `runtime/career/ai-class-all.aist`. |
| Game mode | `bangerrace`, `waypointrace`, `suiciderace` ou `demolitionderby`. |

### Règles

| Champ | Plage / options |
| --- | --- |
| Rondes | 0–100 (facultatif selon la limite de temps). |
| Tijdslimiet | 0–1000. |
| Teams | 1–10. |
| Max deelnemers | 1–24. |
| Vlaggen | Texte libre ; indicateurs de course propres au jeu. |
| Collecting | `Collecting Sequential` ou `Collecting Random`. |
| Car reset (s) | 0–60 secondes. |
| Team split (%) | 0–100. |
| Schade-id | vide, `normal`, `realistic` ou `wrecker`. |
| Bots | 0–24. |

### Car restrictions

Un **tableau** JSON de restrictions sur les véhicules. Utilisez `[]` s'il n'y a aucune restriction. Un JSON invalide affiche un message d'erreur et n'est pas enregistré.

## 6. Onglet Cups – championnats

Les cups sont enregistrées dans `server_cup_config.ccnl`. Les cups actives sont déterminées par le champ **Cup list** de l'onglet **Server**.

Utilisez **Nieuw**, **Dupliceer**, **Verwijder**, **Omhoog** et **Omlaag** pour la liste ; **Cups opslaan** (enregistrer les cups) écrit l'ensemble.

### Cup

| Champ | Explication |
| --- | --- |
| Naam | Nom de la cup. |
| Beschrijving | Champ multiligne. |
| Event loop | Chemin relatif vers un fichier `.becl` de l'installation du serveur (par exemple `data/property/settings/cup/waypoint_tracks.becl`). |
| Icon | Chemin/nom facultatif d'une icône. |

### Paramètres de course

| Champ | Valeur par défaut | Explication |
| --- | --- | --- |
| Point distribution | `30;27;25;20;19;...;1;0` | Points par position, séparés par `;`. |
| Vlaggen | vide | Indicateurs propres au jeu. |
| Start order | `random` | Également `points`, `points reversed` et `last race reversed`. |
| Punten beste ronde | 0 | Points supplémentaires pour le tour le plus rapide. |
| Punten hoogste score | 0 | Points supplémentaires pour le score le plus élevé. |
| Laatste race multiplier | 1 | Multiplicateur pour la dernière course (0–100). |

**Car restrictions** fonctionne comme pour les événements : un tableau JSON, `[]` signifiant aucune restriction.

## 7. Onglet Rollen & Bans

Cet onglet gère `server_privilege.sprv`.

### Rôles

La grille comporte deux colonnes :

- **Platform ID (SteamID64)** : l'ID Steam numérique du joueur.
- **Rol (admin/mod)** : `admin` ou `mod` ; si le champ est laissé vide, `admin` est utilisé.

Les boutons **Rij toevoegen** et **Rij verwijderen** permettent de modifier le tableau. Les lignes sans ID sont ignorées lors de l'enregistrement. Un ID numérique est écrit comme nombre, les autres valeurs comme texte.

### Bans

Le grand champ contient un tableau JSON de bannissements. `[]` signifie aucun bannissement. Un JSON invalide affiche un message d'erreur et rien n'est enregistré.

**Rollen & bans opslaan** (enregistrer les rôles et bans) écrit les deux éléments dans `server_privilege.sprv` (avec sauvegarde).

## 8. Onglet Telemetrie

Cet onglet gère `telemetry/config.json` dans le save-dir. Le dossier `telemetry` est créé automatiquement.

| Champ | Valeur par défaut | Explication |
| --- | --- | --- |
| UDP ingeschakeld | désactivé | Active/désactive la télémétrie UDP. |
| IP-adres | `127.0.0.1` | Adresse de destination des données UDP. |
| Poort | `23123` | Port de destination des données UDP. |
| Formaat | `none` | `none`, `json` ou `csv`. |
| Server-telemetrie ingeschakeld | désactivé | Télémétrie générale du serveur. |
| automaticMainCar | désactivé | Déterminer automatiquement la voiture principale. |

Cliquez sur **Telemetrie opslaan** pour enregistrer les valeurs.

## 9. Onglet Starten – gestion du serveur et journal

### Gestion du serveur

| Champ / bouton | Explication |
| --- | --- |
| Profiel | Choisissez un profil ; sa configuration est chargée. |
| Save-dir | Ouvre le dossier dans l'Explorateur. |
| Modus | community ou lokaal. |
| START server | Enregistre toutes les configurations, puis lance le serveur. |
| STOP server | Arrête les processus Wreckfest2 du dossier configuré. |
| Status vernieuwen | Actualise l'état immédiatement. |

La barre d'état affiche SERVER DRAAIT (vert) ou gestopt (rouge). L'état est actualisé toutes les 2,5 secondes.

Au démarrage, WSM2 crée si nécessaire steam_appid.txt avec l'AppID 1203190 dans le dossier d'installation. Comme le jeu attend un chemin sans guillemets, WSM2 utilise automatiquement le chemin court 8.3 si le chemin contient des espaces.

### Journal du serveur

- **Automatisch verversen** : affiche les 300 dernières lignes du journal ; l'état au démarrage provient de WSM2.settings.json. Les modifications pendant la session ne s'appliquent qu'à celle-ci.
- **Vernieuwen** : recharge le journal immédiatement.
- **Logbestand openen** : ouvre le journal dans le Bloc-notes.
- Le chemin du journal provient du champ **Logbestand** de l'onglet **Server** : un nom de fichier relatif est résolu depuis le save-dir, un chemin absolu est utilisé directement.

## 10. Workflows courants

### Configurer un nouveau serveur

1. Onglet **Instellingen** → **Automatisch detecteren** → **Instellingen opslaan**.
2. Vérifiez le save-dir dans **Starten** et choisissez le mode.
3. Onglet **Server** : nom, mot de passe, port et event loop → **Serverconfig opslaan**.
4. Onglet **Evenementen** → **Nieuw**, configurez les courses, **Opslaan als** avec le même nom que l'event loop dans **Server**.
5. Onglet **Cups** → ajoutez des cups si nécessaire → **Cups opslaan**.
6. Onglet **Rollen & Bans** → ajoutez des administrateurs → enregistrez.
7. Onglet **Starten** → **START server** → vérifiez l'état et le journal.

### Plusieurs serveurs avec profils

1. Créez une ligne par serveur dans **Instellingen**, avec son nom, save-dir et mode.
2. Enregistrez les profils.
3. Choisissez le profil souhaité dans **Starten** ; tous les onglets chargent la configuration de ce save-dir.
4. Arrêtez le serveur avant de changer de profil ou d'enregistrer une configuration.

### Modifier la configuration en toute sécurité

1. Cliquez sur **STOP server** dans l'onglet **Starten**.
2. Modifiez les paramètres dans les onglets concernés.
3. Enregistrez chaque modification (une sauvegarde .bak horodatée est créée automatiquement).
4. Redémarrez le serveur.

### Restaurer une sauvegarde

1. Arrêtez le serveur.
2. Cherchez le fichier nom.yyyymmdd_hhmmss.bak dans le save-dir.
3. Copiez la sauvegarde souhaitée par-dessus le fichier d'origine (supprimez la partie horodatée du nom).
4. Redémarrez WSM2 ou utilisez **Herladen** dans l'onglet **Server**.

## 11. Dépannage

| Problème | Cause possible / solution |
| --- | --- |
| Server niet gevonden in: ... | Le dossier d'installation est incorrect. Utilisez **Automatisch detecteren** ou **Bladeren...** et cherchez Wreckfest2.exe. |
| Les joueurs ne voient pas le serveur | Vérifiez le mode (community), le mot de passe et l'ouverture du port dans le pare-feu/le routeur. |
| Enregistrement refusé avec un message sur le serveur | Le serveur tourne encore. Cliquez sur **STOP server** et réessayez. |
| Les listes levels/météo/AI restent vides | Le dossier d'installation ne contient pas data/property/... ; vérifiez les chemins, enregistrez et redémarrez l'application. |
| Le journal reste vide | Renseignez **Logbestand** dans **Server** et vérifiez que le fichier existe dans le save-dir. |
| Erreur de JSON invalide pour car restrictions ou bans | Le texte n'est pas un tableau JSON valide. Utilisez [] pour repartir de zéro. |
| L'event loop ne démarre pas | Vérifiez que le nom dans **Server → Event loop** correspond exactement à un fichier .becl du save-dir. |
| Le serveur démarre avec Fatal Error: pad bestaat niet | Le save-dir existe-t-il ? WSM2 utilise un chemin court 8.3 en cas d'espaces ; vérifiez le chemin dans **Starten**. |

### Diagnostic via le selftest

Pour les développeurs : définissez la variable d'environnement WSM2_SELFTEST=1 avant de lancer WSM2.cmd. Le programme charge toutes les configurations, affiche une ligne comme SELFTEST OK | events=... cups=... levels=... puis se ferme sans afficher la fenêtre. Utile pour vérifier que les chemins et les données du jeu sont correctement détectés.
