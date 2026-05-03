# Guide de test terrain — Projet Jetski

Validation de l'app contre du vrai matériel. Le code est testé unitairement,
mais Bluetooth Classic SPP et l'écoute UDP locale sont par nature dépendants
de l'environnement physique — ce guide couvre les deux scénarios end-to-end.

---

## Prérequis communs

- Téléphone iOS ou Android avec l'app installée (`flutter run` en mode debug
  pour voir les logs en console).
- Au premier lancement de chaque mode :
  - **iOS** : accepter le prompt « Bluetooth » et/ou « Réseau local ».
  - **Android** : accepter les prompts Bluetooth + Localisation (la
    permission Location est requise par Android pour scanner BT, même si
    l'app ne s'en sert pas pour ça).
- GPS activé dans les réglages OS (sinon la trace sur la carte ne s'écrit pas).

---

## Test 1 — Mode Simulation (sanity check, sans matériel)

But : valider que la pipeline interne fonctionne avant de brancher du
matériel. Si ce test rate, le matériel n'aidera pas.

1. Ouvrir l'app → onglet **Réglages**.
2. Section **Source de profondeur** → choisir **Sim**.
3. Sélectionner le scénario **suddenDanger** dans le dropdown.
4. Revenir à l'onglet **Profondeur**.
5. **Attendu** :
   - Pendant ~6 s, la profondeur affiche `3.0 m` sur fond vert.
   - Puis bascule à `0.3 m` sur fond rouge, vibration courte triple +
     son `danger.wav`.
6. Aller à l'onglet **Carte**.
7. **Attendu** : aucune trace si le GPS n'a pas encore de fix ; sinon
   un trait coloré s'allonge depuis ta position.

Si tout est OK, la pipeline (source → engine → notif → log → map) marche.

---

## Test 2 — Mode Bluetooth (sondeur câblé via module BT-série)

### Matériel à acheter (~150 $ CAD au total)

| Composant | Modèle de référence | Prix approx |
|---|---|---|
| Fishfinder avec sortie NMEA 0183 | Garmin Striker 4 | 130 $ CAD |
| Module Bluetooth Classic SPP | HC-05 ou IOGEAR GBS301 | 20-50 $ CAD |
| Câbles + souder | (à avoir) | — |

### Câblage

Sur le câble d'alimentation/données du Striker (4 fils nus côté NMEA) :

| Fil Striker | Connecter à |
|---|---|
| Rouge (12V) | + batterie 12V |
| Noir (GND) | – batterie + GND module BT |
| Bleu (NMEA OUT/TX) | RX du module HC-05 |
| Marron (NMEA IN/RX) | TX du module HC-05 (ou laisser flottant si tu ne configures pas le HC-05 par AT) |

⚠️ Le HC-05 fonctionne en 3.3V logique. Le NMEA Garmin sort en
RS-232 niveau (~5V swing). Pour être propre il faut un diviseur de
tension (résistances 1k + 2k) entre TX Striker et RX HC-05. En pratique
le HC-05 tolère 5V brièvement mais ce n'est pas garanti — pour un
prototype c'est OK, pour un produit c'est à corriger.

Configuration HC-05 par défaut :
- Nom : `HC-05`
- PIN : `1234` ou `0000`
- Vitesse série : 9600 bps (NMEA standard ; Garmin émet à 4800 par
  défaut → reconfigurer le HC-05 à 4800 via commandes AT, OU régler
  le Striker en 9600 dans son menu System → NMEA).

### Procédure de test

1. Alimenter le Striker en 12V, vérifier qu'il affiche une profondeur
   quelconque sur son écran. C'est la preuve que le transducteur marche.
2. Téléphone : **Réglages OS → Bluetooth → Appairer** avec `HC-05`
   (PIN 1234).
3. Ouvrir l'app → **Réglages** → Source : **Bluetooth** → bouton
   **Choisir** → sélectionner `HC-05` dans la liste.
4. **Attendu** : l'indicateur en haut à droite passe par `BT : connexion…`
   puis `BT : connecté` (vert) en quelques secondes.
5. Onglet **Profondeur** : la valeur doit afficher la même profondeur
   que l'écran du Striker (à 0.1 m près) et se rafraîchir ~1×/seconde.

### Troubleshooting

| Symptôme | Cause probable | Action |
|---|---|---|
| `BT : erreur` | Vitesse série discordante ou câblage TX/RX inversé | Inverser TX/RX, ou aligner les bauds Striker ↔ HC-05 |
| Connecté mais `--.-` | Les trames NMEA arrivent mais pas du `$DPT/$DBT` | Activer la sortie `DPT` dans le menu NMEA du Striker |
| Connexion drop après 30 s | HC-05 non alimenté en continu (alim USB plutôt que 12V boat) | Souder l'alim BT sur le 12V du Striker |
| Crash app au tap **Choisir** | Permission BT non accordée | iOS : Réglages → Projet Jetski → activer Bluetooth |

---

## Test 3 — Mode WiFi (Deeper PRO+ 2.0, recommandé pour grand public)

### Matériel à acheter (~250 $ CAD)

| Composant | Modèle | Prix approx |
|---|---|---|
| Sondeur WiFi castable | Deeper PRO+ 2.0 (ou CHIRP+ 2.0) | 250 $ CAD |

⚠️ Les modèles antérieurs (Deeper PRO+ original sans le "2.0", Deeper
START) **ne supportent pas l'export NMEA UDP**. Vérifier la fiche du
modèle avant d'acheter.

### Procédure de test

1. Charger le Deeper, le mettre à l'eau (ou dans un seau d'eau pour
   un test au sec — le sondeur a besoin d'eau pour s'allumer).
2. Téléphone : **Réglages OS → WiFi** → se connecter au réseau
   `Deeper-XXXX` (mot de passe par défaut : `12345678`).
3. Ouvrir l'**app Deeper** officielle → **Settings → Boat mode →
   activer "Send NMEA over UDP"** → noter le port (par défaut ils
   utilisent 10110).
4. Fermer l'app Deeper, ouvrir notre app → **Réglages** →
   Source : **WiFi** → vérifier que le **Port UDP** affiche `10110`.
5. **Attendu** : indicateur passe à `WiFi : connecté` (vert) dès que
   notre app commence à recevoir les datagrammes.
6. Onglet **Profondeur** : valeur live, ~5 Hz.

### Test alternatif sans Deeper — passerelle marine

Si tu as accès à un bateau équipé d'un Yacht Devices YDWN-02 ou d'un
Digital Yacht WLN10 :

1. Connecter le téléphone au WiFi de la passerelle.
2. App → Réglages → WiFi → port selon la doc de la passerelle (souvent
   2000, 2947 ou 10110).
3. Vérifier l'indicateur passe au vert.

### Test ultra-simple sans matériel — simuler un Deeper depuis un PC

Pour valider le mode WiFi sans aller sur l'eau :

1. Téléphone et PC sur le même WiFi domestique.
2. Trouver l'IP du téléphone (Réglages OS → WiFi → détails réseau).
3. Sur le PC, depuis PowerShell :

   ```powershell
   $sock = New-Object System.Net.Sockets.UdpClient
   $endpoint = [System.Net.IPEndPoint]::new(
     [System.Net.IPAddress]::Parse('IP_DU_TELEPHONE'), 10110)
   while ($true) {
     $msg = "`$SDDPT,3.5,0.0*54`r`n"
     $bytes = [System.Text.Encoding]::ASCII.GetBytes($msg)
     $sock.Send($bytes, $bytes.Length, $endpoint) | Out-Null
     Start-Sleep -Milliseconds 200
   }
   ```

4. Mettre l'app en mode WiFi → indicateur devrait passer au vert,
   profondeur affiche `3.5 m`.

### Troubleshooting

| Symptôme | Cause probable | Action |
|---|---|---|
| `WiFi : erreur` au démarrage | Port < 1024 ou occupé | Garder ≥ 1024, défaut 10110 OK |
| `WiFi : connecté` mais `--.-` | Datagrammes arrivent mais pas du `$DPT/$DBT` | Vérifier la config Deeper (cocher DPT dans les sentences à émettre) |
| Pas de prompt iOS « Réseau local » au 1er lancement | Déjà accordé / OS antérieur à iOS 14 | OK, devrait juste marcher |
| iOS reste bloqué `WiFi : déconnecté` | Permission « Réseau local » refusée | iOS Réglages → Projet Jetski → activer **Réseau local** |
| Firewall PC bloque le test PowerShell | Windows Defender filtre l'UDP sortant | Désactiver temporairement, ou ajouter une règle |

---

## Critères de succès global

L'app est prête pour livraison quand :

- [x] Mode Sim : tous les scénarios déclenchent les bons changements d'état
- [ ] Mode BT : connexion stable >5 min avec un sondeur réel, profondeur
      cohérente avec l'écran du fishfinder à ±10 cm
- [ ] Mode WiFi : connexion stable >5 min avec un Deeper PRO+ 2.0 réel
- [ ] iOS : pas de crash sur prompt permissions, app passe en background
      sans perdre la connexion
- [ ] Android : idem
- [ ] Toggle entre les 3 modes pendant que l'app tourne, sans crash
- [ ] Sortie réelle de 30+ minutes sur l'eau, vérifier sur la carte
      que la trace est continue et colorée

Tant que les 3 derniers ne sont pas cochés, ne pas pousser sur les stores.
