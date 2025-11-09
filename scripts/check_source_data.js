#!/usr/bin/env node

/**
 * Script pour vérifier la structure des données du projet source
 */

const admin = require('firebase-admin');
const config = require('./migration_config.json');

// Initialiser Firebase
const sourceApp = admin.initializeApp({
  credential: admin.credential.cert(require(config.sourceServiceAccountPath)),
  projectId: config.sourceProjectId
}, 'source');

const sourceDb = sourceApp.firestore();

async function checkData() {
  console.log('🔍 Vérification de la structure des données du projet source\n');

  const snapshot = await sourceDb.collection('users').limit(3).get();

  console.log(`Nombre total d'utilisateurs: ${snapshot.size}\n`);

  snapshot.forEach((doc, index) => {
    console.log(`\n========== Utilisateur ${index + 1} ==========`);
    console.log(`Document ID: ${doc.id}`);
    const data = doc.data();
    console.log('Champs disponibles:');
    Object.keys(data).forEach(key => {
      const value = data[key];
      const type = typeof value;
      const preview = type === 'object' ?
        (Array.isArray(value) ? `Array[${value.length}]` : 'Object') :
        (String(value).length > 50 ? String(value).substring(0, 50) + '...' : value);
      console.log(`  - ${key}: ${preview} (${type})`);
    });
  });

  process.exit(0);
}

checkData().catch(error => {
  console.error('Erreur:', error);
  process.exit(1);
});
