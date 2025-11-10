/**
 * Script de migration : Mettre à jour le quota des enseignants (permutation) de 3 à 5
 *
 * Ce script met à jour tous les utilisateurs de type 'teacher_transfer'
 * qui ont actuellement freeQuotaLimit = 3 pour le passer à 5.
 *
 * Date : 10 novembre 2025
 * Raison : Augmentation du quota gratuit pour les enseignants
 */

const admin = require('firebase-admin');

// Initialiser Firebase Admin (utilise les credentials par défaut)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function updateTeacherQuota() {
  console.log('🚀 Démarrage de la migration : Quota enseignants 3 → 5');
  console.log('================================================\n');

  try {
    // Étape 1 : Récupérer tous les enseignants (teacher_transfer)
    console.log('📊 Récupération des enseignants...');
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('accountType', '==', 'teacher_transfer').get();

    if (snapshot.empty) {
      console.log('⚠️  Aucun enseignant trouvé dans la base de données.');
      return;
    }

    console.log(`✅ ${snapshot.size} enseignant(s) trouvé(s)\n`);

    // Étape 2 : Analyser les quotas actuels
    let countQuota3 = 0;
    let countQuota5 = 0;
    let countOther = 0;

    snapshot.forEach(doc => {
      const data = doc.data();
      const quota = data.freeQuotaLimit || 0;

      if (quota === 3) countQuota3++;
      else if (quota === 5) countQuota5++;
      else countOther++;
    });

    console.log('📈 Analyse des quotas actuels :');
    console.log(`   - Quota = 3 : ${countQuota3} utilisateur(s) → À METTRE À JOUR`);
    console.log(`   - Quota = 5 : ${countQuota5} utilisateur(s) → Déjà correct`);
    console.log(`   - Autre     : ${countOther} utilisateur(s) → À vérifier\n`);

    if (countQuota3 === 0) {
      console.log('✅ Tous les enseignants ont déjà le quota de 5.');
      console.log('✅ Aucune mise à jour nécessaire.\n');
      return;
    }

    // Étape 3 : Mise à jour par batch
    console.log('🔄 Mise à jour en cours...\n');

    const batch = db.batch();
    let updatedCount = 0;
    let skippedCount = 0;

    snapshot.forEach(doc => {
      const data = doc.data();
      const currentQuota = data.freeQuotaLimit || 0;

      // Mettre à jour uniquement si le quota est 3
      if (currentQuota === 3) {
        batch.update(doc.ref, {
          freeQuotaLimit: 5,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        updatedCount++;
        console.log(`   ✓ ${data.nom} (${data.email}) : 3 → 5`);
      } else if (currentQuota === 5) {
        skippedCount++;
      } else {
        console.log(`   ⚠️  ${data.nom} (${data.email}) : Quota = ${currentQuota} (non modifié)`);
      }
    });

    // Commit du batch
    if (updatedCount > 0) {
      await batch.commit();
      console.log(`\n✅ Batch commit réussi : ${updatedCount} utilisateur(s) mis à jour`);
    }

    // Résumé final
    console.log('\n================================================');
    console.log('📊 RÉSUMÉ DE LA MIGRATION');
    console.log('================================================');
    console.log(`Total d'enseignants      : ${snapshot.size}`);
    console.log(`Mis à jour (3 → 5)       : ${updatedCount}`);
    console.log(`Déjà à jour (quota = 5)  : ${skippedCount}`);
    console.log(`Non modifiés (autre)     : ${countOther}`);
    console.log('================================================\n');

    // Vérification post-migration
    console.log('🔍 Vérification post-migration...');
    const verifySnapshot = await usersRef.where('accountType', '==', 'teacher_transfer').get();

    let finalCount3 = 0;
    let finalCount5 = 0;

    verifySnapshot.forEach(doc => {
      const quota = doc.data().freeQuotaLimit || 0;
      if (quota === 3) finalCount3++;
      else if (quota === 5) finalCount5++;
    });

    console.log(`   - Quota = 3 : ${finalCount3} utilisateur(s)`);
    console.log(`   - Quota = 5 : ${finalCount5} utilisateur(s)`);

    if (finalCount3 === 0) {
      console.log('\n✅ Migration réussie ! Tous les enseignants ont maintenant 5 consultations gratuites.\n');
    } else {
      console.log(`\n⚠️  Attention : ${finalCount3} enseignant(s) ont encore le quota de 3.\n`);
    }

  } catch (error) {
    console.error('\n❌ Erreur lors de la migration :', error);
    throw error;
  }
}

// Exécuter le script
updateTeacherQuota()
  .then(() => {
    console.log('✅ Script terminé avec succès');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Le script a échoué :', error);
    process.exit(1);
  });
