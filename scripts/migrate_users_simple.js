/**
 * Script de migration SIMPLIFIÉ - Migration progressive
 *
 * Permet de migrer les utilisateurs petit à petit
 * Utile si vous avez beaucoup d'utilisateurs ou voulez tester
 *
 * UTILISATION :
 * node migrate_users_simple.js --limit 10
 */

const admin = require('firebase-admin');

// Configuration
const oldProjectServiceAccount = require('./old-project-service-account.json');
const newProjectServiceAccount = require('./chiasma-service-account.json');

const oldApp = admin.initializeApp({
  credential: admin.credential.cert(oldProjectServiceAccount)
}, 'oldApp');

const newApp = admin.initializeApp({
  credential: admin.credential.cert(newProjectServiceAccount)
}, 'newApp');

const oldAuth = oldApp.auth();
const oldDb = oldApp.firestore();
const newAuth = newApp.auth();
const newDb = newApp.firestore();

// Obtenir la limite depuis les arguments
const args = process.argv.slice(2);
const limitIndex = args.indexOf('--limit');
const LIMIT = limitIndex !== -1 ? parseInt(args[limitIndex + 1]) : 10;

console.log(`\n🔄 Migration de ${LIMIT} utilisateurs maximum\n`);

/**
 * Migre un utilisateur spécifique par email
 */
async function migrateUserByEmail(email) {
  try {
    console.log(`\n📧 Migration de : ${email}`);

    // 1. Récupérer l'utilisateur Authentication
    const oldUser = await oldAuth.getUserByEmail(email);
    console.log(`   ✅ Utilisateur trouvé (UID: ${oldUser.uid})`);

    // 2. Vérifier s'il existe déjà dans le nouveau projet
    try {
      await newAuth.getUser(oldUser.uid);
      console.log(`   ⚠️  Utilisateur existe déjà dans Chiasma, ignoré`);
      return { status: 'exists', email };
    } catch (error) {
      // L'utilisateur n'existe pas, on peut le créer
    }

    // 3. Créer l'utilisateur dans Authentication
    await newAuth.createUser({
      uid: oldUser.uid,
      email: oldUser.email,
      emailVerified: oldUser.emailVerified,
      displayName: oldUser.displayName,
      photoURL: oldUser.photoURL,
      phoneNumber: oldUser.phoneNumber,
      disabled: oldUser.disabled
    });
    console.log(`   ✅ Authentication créé`);

    // 4. Copier les données Firestore
    // Collection users
    const userDoc = await oldDb.collection('users').doc(oldUser.uid).get();
    if (userDoc.exists) {
      await newDb.collection('users').doc(oldUser.uid).set(userDoc.data());
      console.log(`   ✅ Document users copié`);
    }

    // Collection teachers (si existe)
    const teacherDoc = await oldDb.collection('teachers').doc(oldUser.uid).get();
    if (teacherDoc.exists) {
      await newDb.collection('teachers').doc(oldUser.uid).set(teacherDoc.data());
      console.log(`   ✅ Document teachers copié`);
    }

    // Collection schools (si existe)
    const schoolDoc = await oldDb.collection('schools').doc(oldUser.uid).get();
    if (schoolDoc.exists) {
      await newDb.collection('schools').doc(oldUser.uid).set(schoolDoc.data());
      console.log(`   ✅ Document schools copié`);
    }

    // 5. Copier les candidatures de l'utilisateur
    const applications = await oldDb.collection('job_applications')
      .where('candidateId', '==', oldUser.uid)
      .get();

    for (const app of applications.docs) {
      await newDb.collection('job_applications').doc(app.id).set(app.data());
    }
    if (applications.size > 0) {
      console.log(`   ✅ ${applications.size} candidature(s) copiée(s)`);
    }

    // 6. Copier les messages
    const messages = await oldDb.collection('messages')
      .where('participants', 'array-contains', oldUser.uid)
      .get();

    for (const msg of messages.docs) {
      await newDb.collection('messages').doc(msg.id).set(msg.data());
    }
    if (messages.size > 0) {
      console.log(`   ✅ ${messages.size} message(s) copié(s)`);
    }

    console.log(`   🎉 Migration de ${email} terminée avec succès`);
    return { status: 'success', email };

  } catch (error) {
    console.error(`   ❌ Erreur: ${error.message}`);
    return { status: 'error', email, error: error.message };
  }
}

/**
 * Migre les N premiers utilisateurs
 */
async function migrateBatch() {
  try {
    console.log('📊 Récupération des utilisateurs...');

    // Récupérer les utilisateurs de l'ancien projet
    const listResult = await oldAuth.listUsers(LIMIT);
    const users = listResult.users;

    console.log(`✅ ${users.length} utilisateur(s) à migrer\n`);
    console.log('='.repeat(60));

    const results = {
      success: [],
      exists: [],
      errors: []
    };

    for (const user of users) {
      const result = await migrateUserByEmail(user.email || user.phoneNumber);

      if (result.status === 'success') {
        results.success.push(result.email);
      } else if (result.status === 'exists') {
        results.exists.push(result.email);
      } else {
        results.errors.push(result);
      }

      // Pause de 100ms entre chaque utilisateur pour éviter les quotas
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    // Résumé
    console.log('\n' + '='.repeat(60));
    console.log('📊 RÉSUMÉ DE LA MIGRATION');
    console.log('='.repeat(60));
    console.log(`✅ Migrés avec succès : ${results.success.length}`);
    console.log(`⚠️  Déjà existants : ${results.exists.length}`);
    console.log(`❌ Erreurs : ${results.errors.length}`);
    console.log('='.repeat(60));

    if (results.errors.length > 0) {
      console.log('\n❌ ERREURS DÉTAILLÉES:');
      results.errors.forEach(err => {
        console.log(`   ${err.email}: ${err.error}`);
      });
    }

    console.log('\n💡 Pour migrer plus d\'utilisateurs, relancez avec --limit 50\n');

  } catch (error) {
    console.error('❌ Erreur fatale:', error);
  }

  process.exit(0);
}

// Fonction pour migrer UN utilisateur spécifique
if (args.includes('--email')) {
  const emailIndex = args.indexOf('--email');
  const email = args[emailIndex + 1];

  console.log(`\n🎯 Migration d'un utilisateur spécifique\n`);
  migrateUserByEmail(email).then(() => process.exit(0));
} else {
  // Migration par batch
  migrateBatch();
}
