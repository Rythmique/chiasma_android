#!/usr/bin/env node

const admin = require('firebase-admin');
const config = require('./migration_config.json');

// Initialiser Firebase
const app = admin.initializeApp({
  credential: admin.credential.cert(require(config.destServiceAccountPath)),
  projectId: config.destProjectId
});

const db = app.firestore();

async function countUsers() {
  console.log('📊 Comptage des utilisateurs...\n');

  try {
    // Compter tous les utilisateurs
    const allUsersSnapshot = await db.collection('users').get();
    console.log(`Total utilisateurs: ${allUsersSnapshot.size}`);

    // Compter par type de compte
    const teacherTransferSnapshot = await db.collection('users')
      .where('accountType', '==', 'teacher_transfer')
      .get();
    console.log(`  - teacher_transfer: ${teacherTransferSnapshot.size}`);

    const teacherCandidateSnapshot = await db.collection('users')
      .where('accountType', '==', 'teacher_candidate')
      .get();
    console.log(`  - teacher_candidate: ${teacherCandidateSnapshot.size}`);

    const schoolSnapshot = await db.collection('users')
      .where('accountType', '==', 'school')
      .get();
    console.log(`  - school: ${schoolSnapshot.size}`);

    // Afficher les 10 premiers utilisateurs
    console.log('\n📋 Premiers utilisateurs (teacher_transfer):');
    teacherTransferSnapshot.docs.slice(0, 10).forEach((doc, index) => {
      const data = doc.data();
      console.log(`  ${index + 1}. ${data.nom} (${data.email}) - createdAt: ${data.createdAt ? 'OK' : 'MANQUANT'}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

countUsers();
