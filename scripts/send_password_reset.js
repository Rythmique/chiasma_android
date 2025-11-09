#!/usr/bin/env node

/**
 * Script pour envoyer des emails de réinitialisation de mot de passe
 * aux utilisateurs migrés
 */

const admin = require('firebase-admin');
const config = require('./migration_config.json');

// Initialiser Firebase avec le projet destination
const app = admin.initializeApp({
  credential: admin.credential.cert(require(config.destServiceAccountPath)),
  projectId: config.destProjectId
});

const auth = app.auth();

async function sendPasswordResetEmails() {
  console.log('📧 Envoi des emails de réinitialisation de mot de passe...\n');

  const stats = {
    total: 0,
    success: 0,
    errors: 0,
    details: []
  };

  try {
    // Récupérer tous les utilisateurs
    const listUsersResult = await auth.listUsers();
    const users = listUsersResult.users;
    stats.total = users.length;

    console.log(`Trouvé: ${stats.total} utilisateurs\n`);

    for (let i = 0; i < users.length; i++) {
      const user = users[i];
      console.log(`[${i + 1}/${stats.total}] 📧 ${user.email}`);

      try {
        // Générer un lien de réinitialisation de mot de passe
        const link = await auth.generatePasswordResetLink(user.email);

        console.log(`   ✓ Lien généré: ${link}`);
        console.log(`   ℹ️  Envoyez ce lien à l'utilisateur par email ou SMS\n`);

        stats.success++;
        stats.details.push({
          email: user.email,
          resetLink: link,
          status: 'success'
        });

      } catch (error) {
        console.error(`   ❌ Erreur: ${error.message}\n`);
        stats.errors++;
        stats.details.push({
          email: user.email,
          status: 'error',
          reason: error.message
        });
      }
    }

    // Sauvegarder les liens dans un fichier
    const fs = require('fs');
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const reportFile = `password_reset_links_${timestamp}.json`;

    fs.writeFileSync(reportFile, JSON.stringify({
      date: new Date().toISOString(),
      summary: stats,
      links: stats.details
    }, null, 2));

    console.log('═══════════════════════════════════════════════════════');
    console.log('📊 RÉSUMÉ');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`Total utilisateurs:     ${stats.total}`);
    console.log(`✅ Liens générés:       ${stats.success}`);
    console.log(`❌ Erreurs:             ${stats.errors}`);
    console.log('═══════════════════════════════════════════════════════\n');

    console.log(`📄 Liens sauvegardés dans: ${reportFile}\n`);

    console.log('⚠️  IMPORTANT:');
    console.log('   Les liens de réinitialisation sont valides pendant 1 heure.');
    console.log('   Envoyez-les aux utilisateurs par email ou SMS.\n');

    process.exit(0);

  } catch (error) {
    console.error('❌ ERREUR FATALE:', error);
    process.exit(1);
  }
}

sendPasswordResetEmails();
