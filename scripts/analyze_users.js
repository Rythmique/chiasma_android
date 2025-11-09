#!/usr/bin/env node

const admin = require('firebase-admin');
const config = require('./migration_config.json');

const app = admin.initializeApp({
  credential: admin.credential.cert(require(config.destServiceAccountPath)),
  projectId: config.destProjectId
});

const db = app.firestore();

async function analyzeUsers() {
  console.log('🔍 Analyse des utilisateurs...\n');

  try {
    const snapshot = await db.collection('users')
      .where('accountType', '==', 'teacher_transfer')
      .get();

    console.log(`Total: ${snapshot.size} utilisateurs\n`);

    const requiredFields = ['uid', 'email', 'nom', 'accountType', 'fonction', 'zoneActuelle', 'zonesSouhaitees', 'createdAt'];
    let validCount = 0;
    let invalidUsers = [];

    snapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      const missing = [];

      requiredFields.forEach(field => {
        if (!data[field] || (Array.isArray(data[field]) && data[field].length === 0)) {
          missing.push(field);
        }
      });

      if (missing.length > 0) {
        invalidUsers.push({
          index: index + 1,
          nom: data.nom || 'N/A',
          email: data.email || 'N/A',
          missing: missing
        });
      } else {
        validCount++;
      }
    });

    console.log(`✅ Utilisateurs valides (tous les champs requis): ${validCount}`);
    console.log(`❌ Utilisateurs avec champs manquants: ${invalidUsers.length}\n`);

    if (invalidUsers.length > 0) {
      console.log('Détails des utilisateurs problématiques:');
      invalidUsers.forEach(user => {
        console.log(`  ${user.index}. ${user.nom} (${user.email})`);
        console.log(`     Champs manquants: ${user.missing.join(', ')}`);
      });
    }

    // Afficher tous les utilisateurs avec leur index
    console.log('\n📋 Liste complète des utilisateurs:');
    snapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      console.log(`${index + 1}. ${data.nom} (${data.email})`);
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

analyzeUsers();
