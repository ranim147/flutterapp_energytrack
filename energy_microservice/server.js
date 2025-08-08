const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

app.use(cors());

// Chemin de base réel sur ton disque
const BASE_PATH = 'C:/Users/HP/energy_microservice/EnergyStats_2025_06_30/Stats';

const folderMap = {
  tgbt: { folder: 'TGBT', prefix: 'TGBT' },
  climatisation: { folder: 'Climatisations', prefix: 'Climatisation' },
  compresseurs: { folder: 'Compresseurs', prefix: 'Compresseurs' },
};

// Route test
app.get('/', (req, res) => {
  res.send('✅ Serveur opérationnel');
});

// Récupérer toutes les données de tous les fichiers dans le dossier
app.get('/api/energy/:type/all', (req, res) => {
  const type = req.params.type.toLowerCase();
  const config = folderMap[type];
  if (!config) {
    return res.status(404).json({ error: 'Type non reconnu' });
  }

  const baseFolder = path.join(BASE_PATH, config.folder);

  fs.readdir(baseFolder, (err, files) => {
    if (err) {
      console.error('Erreur lecture dossier:', err.message);
      return res.status(500).json({ error: 'Erreur lecture dossier' });
    }

    const jsonFiles = files.filter(f => f.startsWith(config.prefix) && f.endsWith('.json'));

    let allData = [];

    jsonFiles.forEach(file => {
      const filePath = path.join(baseFolder, file);
      try {
        const rawData = fs.readFileSync(filePath, 'utf8');
        const jsonData = JSON.parse(rawData);

        if (jsonData.data && jsonData.data.AccumulatedActiveEnergyDelivered) {
          allData.push(...jsonData.data.AccumulatedActiveEnergyDelivered);
        }
      } catch (e) {
        console.error(`Erreur parsing fichier ${file}: ${e.message}`);
      }
    });

    allData.sort((a, b) => a.ts - b.ts);

    res.json(allData);
  });
});

// Lister les dates disponibles pour un type donné
app.get('/api/energy/:type/dates', (req, res) => {
  const type = req.params.type.toLowerCase();
  const config = folderMap[type];
  if (!config) {
    return res.status(404).json({ error: 'Type non reconnu' });
  }

  const baseFolder = path.join(BASE_PATH, config.folder);

  fs.readdir(baseFolder, (err, files) => {
    if (err) {
      console.error('Erreur lecture dossier:', err.message);
      return res.status(500).json({ error: 'Erreur lecture dossier' });
    }

    // Regex élargie pour accepter les 4 suffixes
    const regex = new RegExp(`^${config.prefix}_(\\d{8})_(00_to_12|12_to_23_59|00_to_23_59_59|00_to_23_59)\\.json$`);

    const dateSet = new Set();

    files.forEach(file => {
      const match = file.match(regex);
      if (match) {
        dateSet.add(match[1]);
      }
    });

    const dates = Array.from(dateSet).sort();

    res.json(dates);
  });
});

// Route principale : /api/energy/:type/:date
app.get('/api/energy/:type/:date', (req, res) => {
  const type = req.params.type.toLowerCase();
  const date = req.params.date;

  console.log(`📥 Requête reçue : type = ${type}, date = ${date}`);

  const config = folderMap[type];
  if (!config) {
    console.log(`❌ Type non reconnu : ${type}`);
    return res.status(404).json({ error: 'Type de donnée non reconnu' });
  }

  const baseFolder = path.join(BASE_PATH, config.folder);

  // 4 formats complets possibles
  const fullDayCandidates = [
    `${config.prefix}_${date}_00_to_23_59_59.json`,
    `${config.prefix}_${date}_00_to_23_59.json`,
  ];

  const morning = `${config.prefix}_${date}_00_to_12.json`;
  const afternoon = `${config.prefix}_${date}_12_to_23_59.json`;

  // Cherche un fichier complet parmi les candidats
  let fullDayPath = null;
  for (const candidate of fullDayCandidates) {
    const candidatePath = path.join(baseFolder, candidate);
    if (fs.existsSync(candidatePath)) {
      fullDayPath = candidatePath;
      console.log(`📂 Fichier complet trouvé : ${candidate}`);
      break;
    }
  }

  if (fullDayPath) {
    const data = fs.readFileSync(fullDayPath, 'utf8');
    try {
      const jsonData = JSON.parse(data);
      const result = jsonData.data.AccumulatedActiveEnergyDelivered;
      return res.json(result);
    } catch (e) {
      console.error(`❌ Erreur parsing JSON complet :`, e.message);
      return res.status(500).json({ error: 'Erreur parsing JSON (fichier complet)' });
    }
  }

  // Sinon combine matin + après-midi
  const mergedData = [];

  const morningPath = path.join(baseFolder, morning);
  const afternoonPath = path.join(baseFolder, afternoon);

  if (fs.existsSync(morningPath)) {
    console.log(`📂 Fichier matin trouvé : ${morning}`);
    const morningData = fs.readFileSync(morningPath, 'utf8');
    try {
      const jsonData = JSON.parse(morningData);
      mergedData.push(...jsonData.data.AccumulatedActiveEnergyDelivered);
    } catch (e) {
      console.error(`❌ Erreur parsing JSON matin :`, e.message);
    }
  }

  if (fs.existsSync(afternoonPath)) {
    console.log(`📂 Fichier après-midi trouvé : ${afternoon}`);
    const afternoonData = fs.readFileSync(afternoonPath, 'utf8');
    try {
      const jsonData = JSON.parse(afternoonData);
      mergedData.push(...jsonData.data.AccumulatedActiveEnergyDelivered);
    } catch (e) {
      console.error(`❌ Erreur parsing JSON après-midi :`, e.message);
    }
  }

  if (mergedData.length > 0) {
    console.log(`✅ Fichiers partiels combinés (${mergedData.length} entrées)`);
    return res.json(mergedData);
  }

  console.error(`❌ Aucun fichier trouvé pour ${type} à la date ${date}`);
  return res.status(404).json({ error: `Aucun fichier trouvé pour ${type} à la date ${date}` });
});

app.listen(PORT, () => {
  console.log(`🚀 Serveur lancé sur http://localhost:${PORT}`);
});
