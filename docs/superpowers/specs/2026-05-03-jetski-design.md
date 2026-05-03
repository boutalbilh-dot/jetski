# Projet Jetski — Design Spec

**Date :** 2026-05-03
**Auteur :** finan + Claude
**Statut :** Brouillon, en attente de revue

---

## 1. Vue d'ensemble

Application mobile (iOS + Android) qui aide les propriétaires et locataires de jetski à éviter d'endommager leur embarcation en zones d'eau peu profondes. L'app affiche en temps réel la profondeur sous le jetski (lue via un sondeur Bluetooth), déclenche des alertes sonores et visuelles quand la profondeur passe sous un seuil, et enregistre la trajectoire GPS avec les profondeurs pour bâtir progressivement une carte personnelle des zones à éviter.

**Public cible :** propriétaires et locataires de jetski, principalement au Canada (rivières et lacs où les hauts-fonds sont fréquents et mal cartographiés).

**Problème résolu :** un jetski qui touche le fond peut subir des dommages coûteux à la coque, à la pompe, ou à l'hélice. La connaissance de la profondeur en temps réel évite ces incidents. Aucune app grand public ne combine actuellement lecture sondeur + carte personnelle + interface user-friendly pour ce cas d'usage.

---

## 2. Périmètre

### Inclus dans le MVP (v1)

- Connexion Bluetooth à un sondeur de profondeur tiers (NMEA 0183)
- Affichage temps réel de la profondeur (grand chiffre, fond coloré selon seuil)
- Alertes sonores + vibration en zone danger
- Carte montrant la position GPS courante et la trace de la sortie en cours, colorée selon la profondeur
- Réglages : seuils d'alerte, unités (m/ft), gestion connexion Bluetooth
- **Mode simulation** — émetteur de profondeurs fake pour développer et démontrer l'app sans matériel
- Persistence locale (SQLite) des sondages d'une sortie

### Reporté à v2

- Carte personnelle bâtie à partir de l'historique des sorties (« où je suis déjà passé »)
- Comparaison historique (« il y a 3 mois cette zone faisait 2m, aujourd'hui 0.8m »)
- Export GPX des trajets

### Reporté à v3

- Partage / agrégation des logs entre utilisateurs (carte communautaire)
- Intégration de données bathymétriques officielles (Service hydrographique du Canada)

### Hors périmètre

- Données de marée prédictives (rivières → pas de marée significative)
- Météo, conditions de navigation
- Réseau social autour des sorties

---

## 3. Décisions techniques

| Sujet | Choix | Raison |
|---|---|---|
| Framework | Flutter (Dart) | Un seul codebase iOS + Android |
| State management | Riverpod | Mature, testable, idiomatique Flutter moderne |
| Bluetooth | `flutter_blue_plus` (BLE) + `flutter_bluetooth_serial` (SPP Classic) | Couvre BLE et Classic — la majorité des sondeurs grand public émettent NMEA 0183 sur Bluetooth Classic SPP |
| Parsing NMEA | Parser maison léger | Le format est simple ($DPT, $DBT, $GGA), un parser maison reste 200 lignes et permet une couverture des trames malformées sur mesure |
| Carte | `flutter_map` + tuiles OpenStreetMap | Gratuit, sans clé API, bonne couverture Canada |
| GPS | `geolocator` | Standard Flutter, gestion permissions intégrée |
| Persistence | `sqflite` (SQLite local) | Léger, suffisant pour l'historique local |
| Vibration | `vibration` package | Patterns custom (court/long selon niveau d'alerte) |
| Son | `audioplayers` | Lecture asynchrone, indépendante de l'UI |

---

## 4. Architecture

```
┌─────────────────────────────────────────────────┐
│                  App Flutter                    │
├─────────────────────────────────────────────────┤
│  UI Layer  : écrans Carte / Profondeur / Réglages│
│  State     : Riverpod (provider d'état)         │
│  Services  :                                    │
│    ├─ BluetoothService    (connexion sondeur)   │
│    ├─ NmeaParser          ($DPT / $DBT)         │
│    ├─ SimulationService   (faux flux dev/démo)  │
│    ├─ LocationService     (GPS via geolocator)  │
│    ├─ DepthLogService     (sauvegarde SQLite)   │
│    └─ AlertEngine         (seuils + hystérésis) │
│  Storage   : SQLite local (sqflite)             │
└─────────────────────────────────────────────────┘
                       │
        ┌──────────────┴───────────────┐
        ▼                              ▼
   Sondeur Bluetooth              GPS du téléphone
   (NMEA 0183)                    (latitude/longitude)
```

### Modules

- **`BluetoothService`** — découverte, appairage, abonnement au flux de données. Expose `Stream<String>` de lignes NMEA brutes.
- **`SimulationService`** — implémente la même interface que `BluetoothService`. Émet une profondeur selon un scénario (approche progressive, entrée brusque, lecture instable, manuel). Toggle dans les Réglages bascule l'app sans redémarrage.
- **`NmeaParser`** — lit les lignes NMEA, valide le checksum, extrait la profondeur en mètres depuis `$DPT` ou `$DBT`. Trames invalides → ignorées sans crash.
- **`LocationService`** — wrapper sur `geolocator`, expose `Stream<Position>`.
- **`DepthLogService`** — combine profondeur + GPS en `DepthSample`, persiste en SQLite (table `depth_samples`).
- **`AlertEngine`** — observe le flux de profondeur, déclenche vibration + son aux franchissements de seuils, applique l'hystérésis.

### Modèle principal

```dart
class DepthSample {
  final DateTime timestamp;
  final double depthMeters;
  final double? latitude;
  final double? longitude;
  final SampleSource source; // real | simulated
}
```

---

## 5. Flux de données

```
Sondeur BT  →  BluetoothService  →  NmeaParser  →  DepthStream
                                                       │
                                          + LocationService (GPS)
                                                       │
                                                       ▼
                                                 DepthSample
                                                       │
                              ┌────────────────────────┼────────────────────────┐
                              ▼                        ▼                        ▼
                        AlertEngine             DepthLogService              UI Layer
                       (vibration/son)         (SQLite)                  (Profondeur/Carte)
```

En mode simulation, `BluetoothService` est remplacé par `SimulationService` derrière la même interface — le reste du pipeline est identique.

---

## 6. Spécifications UI

### 6.1 Écran Profondeur (principal)

- **Affichage central** : profondeur en grands chiffres (ex: « 3.2 m »)
- **Fond coloré** selon seuil :
  - 🟢 Vert si `> seuil_warning`
  - 🟡 Jaune si `seuil_danger < depth ≤ seuil_warning`
  - 🔴 Rouge si `≤ seuil_danger`
- **Header** : état connexion sondeur, état GPS
- **Footer** : vitesse (depuis GPS), coordonnées
- **Alertes** : vibration + son en zone jaune/rouge

### 6.2 Écran Carte

- Vue OpenStreetMap centrée sur position GPS
- Trace de la sortie courante, segments colorés selon profondeur (mêmes seuils)
- Marqueur position (point bleu)
- Bouton « recentrer »

### 6.3 Écran Réglages

- Connexion Bluetooth : scan, liste, appairage
- Toggle mode simulation (avec choix de scénario)
- Sliders : seuil avertissement (défaut **1.0 m**), seuil danger (défaut **0.5 m**)
- Choix unité : mètres / pieds (défaut : mètres)

### 6.4 Navigation

- Barre d'onglets en bas : Profondeur • Carte • Réglages
- Écran Profondeur par défaut au lancement

---

## 7. Comportement des alertes (hystérésis)

Pour éviter le déclenchement en boucle quand la profondeur oscille autour d'un seuil :

- Alerte **se déclenche** quand profondeur **descend sous** le seuil
- Alerte **se libère** uniquement quand profondeur **remonte au-dessus de** `seuil + 0.3 m`

Patterns vibration :
- Avertissement (jaune) : 1 vibration courte toutes les 2s
- Danger (rouge) : 3 vibrations courtes répétées toutes les 1s

Sons : un son d'alerte distinct par niveau (assets WAV/MP3 inclus dans l'app, volume indépendant des médias).

---

## 8. Stratégie de tests

### Unit
- `NmeaParser` — trames valides, malformées, checksum invalide, plusieurs formats ($DPT, $DBT en mètres et pieds)
- `AlertEngine` — déclenchement aux seuils, hystérésis (oscillation autour du seuil), pas de double déclenchement
- `DepthLogService` — insertion, lecture, requête par plage de temps
- `SimulationService` — chaque scénario produit le profil attendu

### Widget
- Écran Profondeur — couleurs vert/jaune/rouge selon valeur injectée
- Écran Carte — marqueur position rendu, trace colorée correctement
- Écran Réglages — sliders modifient bien les seuils, toggle simulation prend effet

### Intégration
- Pipeline complet en mode simulation : fake sensor descend en zone danger → écran rouge + alerte déclenchée
- Persistence : sortie complète logguée puis relue depuis SQLite

### Manuel
- GPS : vérification en marchant dehors avec téléphone
- Bluetooth réel : reporté tant que pas de matériel disponible — couverture fonctionnelle assurée par le mode simulation

### Approche
TDD systématique pour les services (skill `test-driven-development`) — tests d'abord, implémentation ensuite. Le mode simulation rend ça possible sans matériel.

---

## 9. Structure du projet

```
projet jetski/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── models/
│   │   │   ├── depth_sample.dart
│   │   │   └── nmea_sentence.dart
│   │   ├── services/
│   │   │   ├── bluetooth_service.dart
│   │   │   ├── nmea_parser.dart
│   │   │   ├── simulation_service.dart
│   │   │   ├── location_service.dart
│   │   │   ├── depth_log_service.dart
│   │   │   └── alert_engine.dart
│   │   ├── providers/      (Riverpod)
│   │   └── theme/
│   ├── features/
│   │   ├── depth/
│   │   │   ├── depth_screen.dart
│   │   │   └── depth_display.dart
│   │   ├── map/
│   │   │   ├── map_screen.dart
│   │   │   └── track_layer.dart
│   │   └── settings/
│   │       ├── settings_screen.dart
│   │       └── threshold_slider.dart
│   └── shell/
│       └── home_shell.dart   (bottom nav)
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── docs/superpowers/specs/
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

---

## 10. Critères de succès du MVP

1. L'app se connecte à un sondeur Bluetooth (ou au mode simulation) et affiche une profondeur qui se met à jour à au moins 1 Hz.
2. Quand la profondeur passe sous le seuil d'avertissement, l'écran change de couleur **et** une vibration se déclenche en moins de 500 ms.
3. La carte affiche la trace de la sortie en cours, segments colorés selon profondeur.
4. Les seuils peuvent être ajustés depuis les Réglages et la nouvelle valeur prend effet immédiatement.
5. Une sortie de 30 minutes est entièrement loggée en SQLite et peut être relue sans perte.
6. La suite de tests (unit + widget + intégration) passe à 100 %.
7. Le mode simulation permet de démontrer toutes les fonctionnalités sans matériel.

---

## 11. Risques connus

- **Compatibilité Bluetooth** : les sondeurs grand public utilisent un mélange de BLE et Bluetooth Classic SPP, parfois avec des protocoles propriétaires en plus de NMEA. Sans matériel à tester, l'intégration réelle reste à valider quand un sondeur sera disponible.
- **Permissions iOS** : Bluetooth + GPS nécessitent des entrées Info.plist explicites, et iOS impose une description utilisateur pour chaque permission.
- **Background mode** : pour que l'alerte fonctionne quand l'écran est verrouillé, il faut activer le background mode iOS et un service Android persistant — à confirmer en cours d'implémentation.
- **Précision GPS** : la précision en eau peut varier (satellites masqués sur rivière encaissée). On affichera l'erreur estimée du GPS.

---

## 12. Prochaines étapes

1. Revue de ce document par l'utilisateur
2. Création du plan d'implémentation (skill `writing-plans`)
3. Exécution du plan par étapes (skill `executing-plans` ou `subagent-driven-development`) avec TDD systématique
