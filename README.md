# Projet Jetski

Application Flutter (iOS + Android) qui aide les propriétaires et locataires de
jetski à éviter les dommages en eau peu profonde, en lisant la profondeur en
temps réel depuis un sondeur Bluetooth NMEA 0183 et en affichant l'information
de manière user-friendly avec alertes sonores et visuelles.

## Documentation

- [Spec de design](docs/superpowers/specs/2026-05-03-jetski-design.md)
- [Plan d'implémentation](docs/superpowers/plans/2026-05-03-jetski-app.md)

## Démarrage

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```

## Mode simulation

Pas besoin de sondeur pour développer ou démontrer l'app : le mode simulation
émet un flux de profondeurs fake selon 4 scénarios (approche progressive,
entrée brusque en danger, lecture instable, manuel).
