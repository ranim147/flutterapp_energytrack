# ⚡ EnergyTrack

**EnergyTrack** est une application mobile développée en **Flutter** permettant de suivre la **consommation énergétique** de plusieurs équipements industriels (TGBT, Compresseur, Climatisation).  
Elle permet de visualiser des **statistiques journalières et mensuelles** à travers des graphiques clairs, et de suivre la **puissance instantanée** ainsi que des **températures simulées** par zone.

---

## 📱 Fonctionnalités

- 🔐 Authentification (connexion, inscription)
- 📊 Visualisation des consommations d’énergie :
  - Par type d’équipement : TGBT, Compresseur, Climatisation
  - Par jour et par mois (en kWh)
- ⚡ Suivi de la puissance instantanée (kW)
- 🌡️ Affichage des températures estimées par zone
- 🧠 Interface fluide, professionnelle, responsive

---

## 🔧 Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.x)
- [Node.js](https://nodejs.org/) (>= 14.x)
- Android Studio ou VS Code avec extension Flutter
- Émulateur Android ou appareil physique Android
- Git

---

## 🛠️ Installation du backend (Node.js)

Le serveur fournit les données via des fichiers JSON.

### 📁 Structure du backend (`/server`)

energy_microservice/
├── EnergyStats_2025_06_30/
│   ├──stats
│             ├── tgbt.json
│             ├── compresseurs.json
│             └── climatisations.json
├── node_modules 
├── server.js
└── package.json



### ▶️ Étapes pour démarrer le serveur

1. Ouvrir un terminal et se placer dans le dossier `energy_microservice` :
   ```bash
   cd energy_microservice
2.Installer les dépendances : npm install
3. Lancer le serveur : node server.js


serveur tourne par défaut sur :
http://localhost:3000/api/energy
Sur un émulateur Android, utiliser l’adresse :
http://10.0.2.2:3000/api/energy

 Installation de l'application Flutter
  Installer les dépendances Flutter : flutter pub get
  Lancer l'application : flutter run


