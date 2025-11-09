#!/usr/bin/env node

/**
 * Script de migration des utilisateurs Firebase
 * Copie les utilisateurs (Auth + Firestore) d'un projet source vers chiasma-android
 *
 * Usage:
 *   node migrate_users.js                    # Migration réelle
 *   node migrate_users.js --dry-run          # Test sans écriture
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG_FILE = path.join(__dirname, 'migration_config.json');
const DEFAULT_PASSWORD = 'Chiasma2025!'; // Mot de passe temporaire

// Charger la configuration
let config;
try {
  config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  console.log('✅ Configuration chargée depuis migration_config.json\n');
} catch (error) {
  console.error('❌ ERREUR: Fichier migration_config.json introuvable');
  console.error('   Copiez migration_config.example.json vers migration_config.json');
  console.error('   et remplissez les chemins des service accounts.\n');
  process.exit(1);
}

// Options
const DRY_RUN = process.argv.includes('--dry-run');
const SKIP_DUPLICATES = config.skipDuplicates !== false;
const PASSWORD = config.defaultPassword || DEFAULT_PASSWORD;

// ============================================================================
// INITIALISATION FIREBASE
// ============================================================================

// App source
const sourceApp = admin.initializeApp({
  credential: admin.credential.cert(require(config.sourceServiceAccountPath)),
  projectId: config.sourceProjectId
}, 'source');

const sourceAuth = sourceApp.auth();
const sourceDb = sourceApp.firestore();

// App destination (chiasma-android)
const destApp = admin.initializeApp({
  credential: admin.credential.cert(require(config.destServiceAccountPath)),
  projectId: config.destProjectId
}, 'destination');

const destAuth = destApp.auth();
const destDb = destApp.firestore();

console.log(`🔧 Mode: ${DRY_RUN ? 'DRY-RUN (test)' : 'PRODUCTION (écriture réelle)'}`);
console.log(`📦 Source: ${config.sourceProjectId}`);
console.log(`🎯 Destination: ${config.destProjectId}`);
console.log(`🔑 Mot de passe temporaire: ${PASSWORD}`);
console.log(`⏭️  Ignorer les doublons: ${SKIP_DUPLICATES ? 'OUI' : 'NON'}\n`);

// ============================================================================
// FONCTIONS UTILITAIRES
// ============================================================================

/**
 * Valide le format du matricule pour teacher_transfer
 */
function validateMatricule(matricule) {
  const pattern = /^[0-9]{6}[A-Z]$/;
  return pattern.test(matricule);
}

/**
 * Vérifie si un utilisateur existe déjà dans la destination
 */
async function checkUserExists(email, matricule) {
  try {
    // Vérifier par email dans Auth
    try {
      await destAuth.getUserByEmail(email);
      return { exists: true, reason: 'email_exists_in_auth' };
    } catch (error) {
      if (error.code !== 'auth/user-not-found') {
        throw error;
      }
    }

    // Vérifier par matricule dans Firestore
    const usersSnapshot = await destDb.collection('users')
      .where('matricule', '==', matricule)
      .limit(1)
      .get();

    if (!usersSnapshot.empty) {
      return { exists: true, reason: 'matricule_exists_in_firestore' };
    }

    return { exists: false };
  } catch (error) {
    console.error(`   ⚠️  Erreur lors de la vérification de doublon:`, error.message);
    return { exists: false };
  }
}

/**
 * Convertit un timestamp Firestore en objet Date
 */
function convertTimestamp(timestamp) {
  if (!timestamp) return new Date();
  if (timestamp._seconds) {
    return new Date(timestamp._seconds * 1000);
  }
  if (timestamp.toDate) {
    return timestamp.toDate();
  }
  return new Date(timestamp);
}

/**
 * Transforme les données utilisateur pour le format destination
 */
function transformUserData(userData, uid) {
  const now = admin.firestore.Timestamp.now();

  // Mapper les champs de l'ancien format vers le nouveau
  const nom = userData.prenom ? `${userData.prenom} ${userData.nom}`.trim() : userData.nom || '';
  let matricule = userData.numeroMatricule || userData.matricule || '';
  if (matricule) {
    matricule = matricule.toUpperCase(); // Convertir en majuscule
  }
  const infosZoneActuelle = userData.infoZoneActuelle || userData.infosZoneActuelle || '';
  const showContactInfo = userData.showPhone !== undefined ? userData.showPhone : (userData.showContactInfo !== false);

  return {
    uid: uid,
    email: userData.email,
    accountType: 'teacher_transfer', // Tous les utilisateurs migrés sont des enseignants
    matricule: matricule,
    nom: nom,
    telephones: Array.isArray(userData.telephones) ? userData.telephones : [],
    fonction: userData.fonction || '',
    zoneActuelle: userData.zoneActuelle || '',
    dren: userData.dren || null,
    infosZoneActuelle: infosZoneActuelle,
    zonesSouhaitees: Array.isArray(userData.zonesSouhaitees) ? userData.zonesSouhaitees : [],

    // Métadonnées
    createdAt: userData.createdAt ? admin.firestore.Timestamp.fromDate(convertTimestamp(userData.createdAt)) : now,
    updatedAt: now,
    isOnline: false,
    isVerified: true, // Tous les utilisateurs migrés sont vérifiés
    isAdmin: userData.isAdmin || false,

    // Fonctionnalités
    showContactInfo: showContactInfo,
    profileViewsCount: userData.profileViews || userData.profileViewsCount || 0,

    // Quotas (5 consultations pour teacher_transfer)
    freeQuotaUsed: userData.freeQuotaUsed || 0,
    freeQuotaLimit: 5,
    verificationExpiresAt: null,
    subscriptionDuration: null,
    lastQuotaResetDate: null
  };
}

// ============================================================================
// MIGRATION PRINCIPALE
// ============================================================================

async function migrateUsers() {
  console.log('🚀 Démarrage de la migration...\n');

  const stats = {
    total: 0,
    success: 0,
    skipped: 0,
    errors: 0,
    details: []
  };

  try {
    // 1. Récupérer tous les utilisateurs de la source
    console.log('📥 Récupération des utilisateurs du projet source...');
    const sourceUsersSnapshot = await sourceDb.collection('users').get();
    stats.total = sourceUsersSnapshot.size;
    console.log(`   Trouvé: ${stats.total} utilisateurs\n`);

    if (stats.total === 0) {
      console.log('⚠️  Aucun utilisateur à migrer.');
      return stats;
    }

    // 2. Traiter chaque utilisateur
    let count = 0;
    for (const doc of sourceUsersSnapshot.docs) {
      count++;
      const sourceUid = doc.id;
      const userData = doc.data();

      console.log(`[${count}/${stats.total}] 👤 ${userData.email || sourceUid}`);

      try {
        // Récupérer les infos Auth de la source (optionnel)
        let sourceAuthUser = null;
        try {
          sourceAuthUser = await sourceAuth.getUser(sourceUid);
        } catch (error) {
          // Si l'utilisateur n'existe pas dans Auth source, on utilise les données Firestore
          console.log(`   ℹ️  Pas de compte Auth dans la source, utilisation des données Firestore`);
        }

        // Utiliser l'email du Firestore si pas d'Auth
        const email = sourceAuthUser ? sourceAuthUser.email : userData.email;
        const displayName = sourceAuthUser ? sourceAuthUser.displayName : userData.nom;

        // Récupérer le matricule (gérer les deux formats) et le convertir en majuscule
        let matricule = userData.numeroMatricule || userData.matricule;
        if (matricule) {
          matricule = matricule.toUpperCase();
        }

        // Validation du matricule
        if (!validateMatricule(matricule)) {
          console.log(`   ⚠️  Matricule invalide: ${matricule}`);
          stats.details.push({
            email: userData.email,
            status: 'error',
            reason: 'invalid_matricule'
          });
          stats.errors++;
          continue;
        }

        // Vérifier les doublons
        const duplicateCheck = await checkUserExists(email, matricule);
        if (duplicateCheck.exists) {
          if (SKIP_DUPLICATES) {
            console.log(`   ⏭️  Ignoré: ${duplicateCheck.reason}`);
            stats.details.push({
              email: email,
              matricule: matricule,
              status: 'skipped',
              reason: duplicateCheck.reason
            });
            stats.skipped++;
            continue;
          }
        }

        if (DRY_RUN) {
          console.log(`   ✓ [DRY-RUN] Serait migré: ${email}`);
          stats.success++;
          stats.details.push({
            email: email,
            matricule: matricule,
            status: 'would_migrate'
          });
          continue;
        }

        // 3. Créer le compte Auth dans la destination
        let newUid;
        try {
          const newUser = await destAuth.createUser({
            email: email,
            emailVerified: true,
            password: PASSWORD,
            displayName: displayName,
            disabled: false
          });
          newUid = newUser.uid;
          console.log(`   ✓ Compte Auth créé (UID: ${newUid})`);
        } catch (error) {
          if (error.code === 'auth/email-already-exists') {
            console.log(`   ⏭️  Email existe déjà dans Auth destination`);
            stats.skipped++;
            stats.details.push({
              email: email,
              status: 'skipped',
              reason: 'email_exists'
            });
            continue;
          }
          throw error;
        }

        // 4. Créer le document Firestore
        const transformedData = transformUserData(userData, newUid);
        await destDb.collection('users').doc(newUid).set(transformedData);
        console.log(`   ✓ Document Firestore créé`);

        stats.success++;
        stats.details.push({
          email: email,
          matricule: matricule,
          oldUid: sourceUid,
          newUid: newUid,
          status: 'success'
        });

      } catch (error) {
        console.error(`   ❌ Erreur: ${error.message}`);
        stats.errors++;
        stats.details.push({
          email: userData.email || 'unknown',
          status: 'error',
          reason: error.message
        });
      }

      console.log(''); // Ligne vide entre utilisateurs
    }

  } catch (error) {
    console.error('\n❌ ERREUR FATALE:', error);
    throw error;
  }

  return stats;
}

// ============================================================================
// GÉNÉRATION DU RAPPORT
// ============================================================================

function generateReport(stats) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const reportFile = path.join(__dirname, `migration_report_${timestamp}.json`);

  const report = {
    date: new Date().toISOString(),
    mode: DRY_RUN ? 'dry-run' : 'production',
    source: config.sourceProjectId,
    destination: config.destProjectId,
    summary: {
      total: stats.total,
      success: stats.success,
      skipped: stats.skipped,
      errors: stats.errors
    },
    details: stats.details
  };

  fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
  console.log(`📄 Rapport sauvegardé: ${reportFile}\n`);

  return report;
}

// ============================================================================
// EXÉCUTION
// ============================================================================

async function main() {
  try {
    const startTime = Date.now();

    const stats = await migrateUsers();
    const report = generateReport(stats);

    const duration = ((Date.now() - startTime) / 1000).toFixed(2);

    // Résumé final
    console.log('═══════════════════════════════════════════════════════');
    console.log('📊 RÉSUMÉ DE LA MIGRATION');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`Total utilisateurs:     ${stats.total}`);
    console.log(`✅ Migrés avec succès:  ${stats.success}`);
    console.log(`⏭️  Ignorés (doublons):  ${stats.skipped}`);
    console.log(`❌ Erreurs:             ${stats.errors}`);
    console.log(`⏱️  Durée:               ${duration}s`);
    console.log('═══════════════════════════════════════════════════════\n');

    if (DRY_RUN) {
      console.log('ℹ️  Mode DRY-RUN: Aucune modification réelle effectuée');
      console.log('   Relancez sans --dry-run pour effectuer la migration.\n');
    } else if (stats.success > 0) {
      console.log('✅ Migration terminée avec succès!');
      console.log(`   ${stats.success} utilisateurs ont été migrés.`);
      console.log(`   Mot de passe temporaire: ${PASSWORD}`);
      console.log('   Les utilisateurs doivent réinitialiser leur mot de passe.\n');
    }

    process.exit(stats.errors > 0 ? 1 : 0);

  } catch (error) {
    console.error('\n❌ ERREUR FATALE:', error);
    process.exit(1);
  }
}

// Lancer la migration
main();
