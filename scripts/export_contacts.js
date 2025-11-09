#!/usr/bin/env node

/**
 * Script pour exporter les contacts (emails et téléphones) des utilisateurs
 * vers un fichier Excel
 */

const admin = require('firebase-admin');
const XLSX = require('xlsx');
const config = require('./migration_config.json');

// Initialiser Firebase avec le projet destination
const app = admin.initializeApp({
  credential: admin.credential.cert(require(config.destServiceAccountPath)),
  projectId: config.destProjectId
});

const db = app.firestore();

async function exportContacts() {
  console.log('📊 Exportation des contacts utilisateurs...\n');

  try {
    // Récupérer tous les utilisateurs
    const snapshot = await db.collection('users').get();
    console.log(`Total utilisateurs trouvés: ${snapshot.size}\n`);

    const contacts = [];
    let stats = {
      total: 0,
      withEmail: 0,
      withPhone: 0,
      withBoth: 0,
      byAccountType: {
        teacher_transfer: 0,
        teacher_candidate: 0,
        school: 0,
        other: 0
      }
    };

    snapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      const accountType = data.accountType || 'unknown';

      // Compter par type de compte
      if (stats.byAccountType[accountType] !== undefined) {
        stats.byAccountType[accountType]++;
      } else {
        stats.byAccountType.other++;
      }

      // Extraire les informations
      const nom = data.nom || 'N/A';
      const email = data.email || 'N/A';
      const matricule = data.matricule || 'N/A';
      const fonction = data.fonction || 'N/A';
      const zoneActuelle = data.zoneActuelle || 'N/A';
      const telephones = data.telephones || [];

      // Formater les numéros de téléphone
      const telephone1 = telephones[0] || '';
      const telephone2 = telephones[1] || '';
      const telephone3 = telephones[2] || '';
      const allPhones = telephones.join(', ');

      // Statistiques
      stats.total++;
      if (email && email !== 'N/A') stats.withEmail++;
      if (telephones.length > 0) stats.withPhone++;
      if (email && email !== 'N/A' && telephones.length > 0) stats.withBoth++;

      // Ajouter au tableau de contacts
      contacts.push({
        'N°': index + 1,
        'Nom': nom,
        'Email': email,
        'Téléphone 1': telephone1,
        'Téléphone 2': telephone2,
        'Téléphone 3': telephone3,
        'Tous les téléphones': allPhones,
        'Matricule': matricule,
        'Fonction': fonction,
        'Zone Actuelle': zoneActuelle,
        'Type de Compte': accountType,
        'Vérifié': data.isVerified ? 'Oui' : 'Non',
        'Admin': data.isAdmin ? 'Oui' : 'Non',
        'Date Création': data.createdAt ? new Date(data.createdAt.toDate()).toLocaleDateString('fr-FR') : 'N/A'
      });

      console.log(`[${index + 1}/${snapshot.size}] ${nom} - ${email} - ${allPhones || 'Pas de téléphone'}`);
    });

    // Créer un classeur Excel
    const wb = XLSX.utils.book_new();

    // Feuille 1 : Tous les contacts
    const ws1 = XLSX.utils.json_to_sheet(contacts);

    // Ajuster la largeur des colonnes
    const wscols = [
      { wch: 5 },   // N°
      { wch: 30 },  // Nom
      { wch: 35 },  // Email
      { wch: 15 },  // Téléphone 1
      { wch: 15 },  // Téléphone 2
      { wch: 15 },  // Téléphone 3
      { wch: 40 },  // Tous les téléphones
      { wch: 12 },  // Matricule
      { wch: 30 },  // Fonction
      { wch: 30 },  // Zone Actuelle
      { wch: 18 },  // Type de Compte
      { wch: 10 },  // Vérifié
      { wch: 8 },   // Admin
      { wch: 15 }   // Date Création
    ];
    ws1['!cols'] = wscols;

    XLSX.utils.book_append_sheet(wb, ws1, 'Tous les contacts');

    // Feuille 2 : Statistiques
    const statsData = [
      { 'Statistique': 'Total utilisateurs', 'Valeur': stats.total },
      { 'Statistique': 'Avec email', 'Valeur': stats.withEmail },
      { 'Statistique': 'Avec téléphone', 'Valeur': stats.withPhone },
      { 'Statistique': 'Avec email ET téléphone', 'Valeur': stats.withBoth },
      { 'Statistique': '', 'Valeur': '' },
      { 'Statistique': 'Par type de compte:', 'Valeur': '' },
      { 'Statistique': '  - Enseignants (Permutation)', 'Valeur': stats.byAccountType.teacher_transfer },
      { 'Statistique': '  - Candidats', 'Valeur': stats.byAccountType.teacher_candidate },
      { 'Statistique': '  - Écoles', 'Valeur': stats.byAccountType.school },
      { 'Statistique': '  - Autres', 'Valeur': stats.byAccountType.other }
    ];

    const ws2 = XLSX.utils.json_to_sheet(statsData);
    ws2['!cols'] = [{ wch: 35 }, { wch: 15 }];
    XLSX.utils.book_append_sheet(wb, ws2, 'Statistiques');

    // Feuille 3 : Contacts simplifiés (Nom, Email, Téléphone)
    const contactsSimple = contacts.map(c => ({
      'Nom': c.Nom,
      'Email': c.Email,
      'Téléphone Principal': c['Téléphone 1'],
      'Type': c['Type de Compte']
    }));
    const ws3 = XLSX.utils.json_to_sheet(contactsSimple);
    ws3['!cols'] = [{ wch: 30 }, { wch: 35 }, { wch: 15 }, { wch: 18 }];
    XLSX.utils.book_append_sheet(wb, ws3, 'Contacts Simplifiés');

    // Feuille 4 : Enseignants uniquement
    const teachers = contacts.filter(c => c['Type de Compte'] === 'teacher_transfer');
    if (teachers.length > 0) {
      const ws4 = XLSX.utils.json_to_sheet(teachers);
      ws4['!cols'] = wscols;
      XLSX.utils.book_append_sheet(wb, ws4, 'Enseignants');
    }

    // Feuille 5 : Candidats uniquement
    const candidates = contacts.filter(c => c['Type de Compte'] === 'teacher_candidate');
    if (candidates.length > 0) {
      const ws5 = XLSX.utils.json_to_sheet(candidates);
      ws5['!cols'] = wscols;
      XLSX.utils.book_append_sheet(wb, ws5, 'Candidats');
    }

    // Feuille 6 : Écoles uniquement
    const schools = contacts.filter(c => c['Type de Compte'] === 'school');
    if (schools.length > 0) {
      const ws6 = XLSX.utils.json_to_sheet(schools);
      ws6['!cols'] = wscols;
      XLSX.utils.book_append_sheet(wb, ws6, 'Écoles');
    }

    // Sauvegarder le fichier Excel
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').split('T')[0];
    const filename = `/home/user/myapp/contacts_chiasma_${timestamp}.xlsx`;
    XLSX.writeFile(wb, filename);

    console.log('\n═══════════════════════════════════════════════════════');
    console.log('📊 STATISTIQUES');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`Total utilisateurs:              ${stats.total}`);
    console.log(`Avec email:                      ${stats.withEmail}`);
    console.log(`Avec téléphone:                  ${stats.withPhone}`);
    console.log(`Avec email ET téléphone:         ${stats.withBoth}`);
    console.log('');
    console.log('Par type de compte:');
    console.log(`  - Enseignants (Permutation):   ${stats.byAccountType.teacher_transfer}`);
    console.log(`  - Candidats:                   ${stats.byAccountType.teacher_candidate}`);
    console.log(`  - Écoles:                      ${stats.byAccountType.school}`);
    console.log(`  - Autres:                      ${stats.byAccountType.other}`);
    console.log('═══════════════════════════════════════════════════════\n');

    console.log(`✅ Fichier Excel créé avec succès: ${filename}`);
    console.log(`\nLe fichier contient ${wb.SheetNames.length} feuilles:`);
    wb.SheetNames.forEach((name, idx) => {
      console.log(`   ${idx + 1}. ${name}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ ERREUR:', error);
    process.exit(1);
  }
}

exportContacts();
