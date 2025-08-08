# ⚡ EnergyTrack

EnergyTrack est une application mobile développée avec Flutter, qui permet de suivre en temps réel la consommation énergétique de plusieurs équipements industriels tels que :

TGBT

Compresseurs

Climatisation

Elle offre une interface claire et fluide pour visualiser les statistiques journalières et mensuelles en kWh, surveiller la puissance instantanée (kW) et consulter les températures estimées par zones.

---
📱 Fonctionnalités principales
🔐 Authentification (inscription, connexion)

📊 Visualisation des consommations d’énergie :

Par type d’équipement (TGBT, Compresseur, Climatisation)

Par jour et par mois (converti automatiquement en kWh)

⚡ Affichage de la puissance instantanée

🌡️ Températures estimées pour chaque zone

💡 Interface responsive et professionnelle, adaptée à tous types d’écrans

---
energy_app/             # Application mobile Flutter
├── lib/
│   ├── views/          # Interfaces utilisateur (accueil, login, signup, etc.)
│   ├── services/       # Appels API, logique métier
│   └── main.dart       # Point d'entrée de l'application
└── pubspec.yaml

energy_microservice/    # Microservice backend Node.js
├── EnergyStats_YYYY_MM_DD/
│   └── stats/
│       ├── tgbt.json
│       ├── compresseurs.json
│       └── climatisations.json
├── server.js
└── package.json

----

##🔧 Prérequis
Ces outils doivent être installés sur votre machine avant de démarrer :

Flutter SDK (≥ 3.x)

Node.js (≥ 14.x recommandé)

Android Studio ou VS Code (avec extension Flutter)

Un émulateur Android ou un smartphone connecté

Git (pour cloner ou gérer le code)

---

##🛠️ Démarrage du backend (microservice Node.js)



### ▶️ Étapes pour démarrer le serveur

1. Ouvrir un terminal et se placer dans le dossier `energy_microservice` :
 cd energy_microservice
2.Installer les dépendances : npm install
3. Lancer le serveur : node server.js

---
Le serveur tourne par défaut à l'adresse :

Sur PC local : http://localhost:3000/api/energy

Sur émulateur Android Flutter : http://10.0.2.2:3000/api/energy

---
## ▶️ Démarrage de l’application Flutter
Ouvrir un terminal dans le dossier de l’app : cd energy_app
Installer les dépendances : flutter pub get
Lancer l’application : flutter run


---

🔌 Connexion Flutter ↔ Backend
Vérifie que :

L'URL de l’API dans Flutter est bien http://10.0.2.2:3000/api/energy pour les tests Android

Le backend tourne avant de lancer Flutter

---

## 🙏 Remerciements

Je remercie chaleureusement mon maître de stage ainsi que toute l’équipe encadrante pour leur accompagnement et leurs conseils tout au long de ce projet.

---

## 📬 Contact

Pour toute question ou remarque, vous pouvez me contacter à :  
**Email** : ton.email@example.com

---

Merci d’avoir pris le temps de consulter ce projet !




