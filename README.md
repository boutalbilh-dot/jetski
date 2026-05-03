# Projet Jetski

Application Flutter (iOS + Android) qui aide les propriétaires et locataires de
jetski à éviter les dommages en eau peu profonde. Lit la profondeur en temps
réel depuis un sondeur NMEA 0183 et affiche l'information avec alertes sonores
et visuelles.

## Sources de profondeur

L'app supporte trois sources interchangeables, sélectionnables dans les Réglages :

- **Bluetooth Classic SPP** — sondeur tiers (ex : Garmin Striker via module HC-05)
- **WiFi UDP** — sondeur castable (ex : Deeper PRO+ 2.0) ou passerelle marine, port 10110 par défaut
- **Simulation** — flux fake selon 4 scénarios (approche progressive, danger soudain, lecture instable, manuel) — pas besoin de matériel pour développer ou démontrer

Le pipeline en aval (alertes, log SQLite, carte) est identique quel que soit le mode.

## Documentation

- [Spec de design](docs/superpowers/specs/2026-05-03-jetski-design.md)
- [Plan d'implémentation](docs/superpowers/plans/2026-05-03-jetski-app.md)
- [Guide de test terrain](docs/TEST_TERRAIN.md) — procédure de validation contre matériel réel

## Démarrage

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test          # 63 tests : unit + widget + intégration
flutter analyze       # lint
```
