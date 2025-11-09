#!/usr/bin/env node

/**
 * Script pour envoyer des emails de bienvenue avec lien de réinitialisation
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

// Template d'email
function getEmailTemplate(resetLink, userName) {
  return {
    subject: '🎉 Bienvenue sur la nouvelle application Chiasma !',
    html: `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 3px solid #FF9800;
            padding-bottom: 20px;
        }
        .header h1 {
            color: #FF9800;
            margin: 0;
            font-size: 28px;
        }
        .content {
            margin-bottom: 25px;
        }
        .content p {
            margin: 15px 0;
        }
        .highlight-box {
            background-color: #FFF3E0;
            border-left: 4px solid #FF9800;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
        }
        .button {
            display: inline-block;
            background-color: #FF9800;
            color: white !important;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 5px;
            font-weight: bold;
            text-align: center;
            margin: 20px 0;
        }
        .button:hover {
            background-color: #F57C00;
        }
        .download-section {
            background-color: #E8F5E9;
            border-left: 4px solid #4CAF50;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
        }
        .download-link {
            color: #4CAF50;
            font-weight: bold;
            font-size: 18px;
            text-decoration: none;
        }
        .steps {
            background-color: #F5F5F5;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .steps ol {
            margin: 10px 0;
            padding-left: 20px;
        }
        .steps li {
            margin: 10px 0;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            text-align: center;
            font-size: 12px;
            color: #666;
        }
        .warning {
            background-color: #FFF9C4;
            border-left: 4px solid #FBC02D;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Chiasma</h1>
            <p style="color: #666; margin: 10px 0 0 0;">Votre plateforme de permutation enseignante</p>
        </div>

        <div class="content">
            <p>Bonjour <strong>${userName}</strong>,</p>

            <p>Nous sommes ravis de vous annoncer que la <strong>nouvelle version de l'application Chiasma</strong> est maintenant disponible !</p>

            <div class="download-section">
                <h3 style="margin-top: 0; color: #4CAF50;">📱 Téléchargez l'application</h3>
                <p>L'application est désormais disponible en téléchargement sur :</p>
                <p style="text-align: center; margin: 20px 0;">
                    <a href="https://www.chiasma.pro" class="download-link">👉 www.chiasma.pro 👈</a>
                </p>
            </div>

            <div class="highlight-box">
                <h3 style="margin-top: 0; color: #FF9800;">🔐 Action requise : Définir votre mot de passe</h3>
                <p><strong>Pourquoi réinitialiser votre mot de passe ?</strong></p>
                <p>Votre compte a été migré vers notre nouvelle infrastructure pour vous offrir une meilleure expérience. Pour des raisons de sécurité, nous ne pouvons pas transférer les anciens mots de passe. Vous devez donc en créer un nouveau.</p>
            </div>

            <div class="steps">
                <h3 style="margin-top: 0; color: #333;">📝 Comment activer votre compte :</h3>
                <ol>
                    <li><strong>Cliquez sur le bouton ci-dessous</strong> pour définir votre nouveau mot de passe</li>
                    <li><strong>Créez un mot de passe sécurisé</strong> (minimum 6 caractères)</li>
                    <li><strong>Téléchargez l'application</strong> sur <a href="https://www.chiasma.pro">www.chiasma.pro</a></li>
                    <li><strong>Connectez-vous</strong> avec votre email et votre nouveau mot de passe</li>
                </ol>
            </div>

            <div style="text-align: center; margin: 30px 0;">
                <a href="${resetLink}" class="button">
                    🔑 Définir mon mot de passe
                </a>
            </div>

            <div class="warning">
                <p style="margin: 0;"><strong>⏰ Important :</strong> Ce lien est valide pendant <strong>1 heure</strong>. Si le lien expire, vous pourrez demander un nouveau lien depuis l'application en utilisant "Mot de passe oublié".</p>
            </div>

            <div class="highlight-box">
                <h3 style="margin-top: 0; color: #FF9800;">✨ Nouveautés de l'application</h3>
                <ul style="margin: 10px 0; padding-left: 20px;">
                    <li>Interface améliorée et plus intuitive</li>
                    <li>Recherche de permutation plus rapide</li>
                    <li>Système de notifications en temps réel</li>
                    <li>Messagerie intégrée sécurisée</li>
                    <li>Gestion optimisée de vos favoris</li>
                </ul>
            </div>

            <p style="margin-top: 30px;">Si vous rencontrez des difficultés, n'hésitez pas à nous contacter.</p>

            <p>Bienvenue dans la nouvelle ère de Chiasma ! 🚀</p>

            <p style="margin-top: 30px;">
                Cordialement,<br>
                <strong>L'équipe Chiasma</strong>
            </p>
        </div>

        <div class="footer">
            <p>Cet email a été envoyé à ${userName}</p>
            <p>© 2025 Chiasma - Plateforme de permutation enseignante</p>
            <p style="margin-top: 10px;">
                <a href="https://www.chiasma.pro" style="color: #FF9800; text-decoration: none;">www.chiasma.pro</a>
            </p>
        </div>
    </div>
</body>
</html>
    `,
    text: `
Bonjour ${userName},

Nous sommes ravis de vous annoncer que la nouvelle version de l'application Chiasma est maintenant disponible !

📱 TÉLÉCHARGEZ L'APPLICATION
L'application est désormais disponible sur : www.chiasma.pro

🔐 ACTION REQUISE : DÉFINIR VOTRE MOT DE PASSE

Pourquoi réinitialiser votre mot de passe ?
Votre compte a été migré vers notre nouvelle infrastructure pour vous offrir une meilleure expérience. Pour des raisons de sécurité, nous ne pouvons pas transférer les anciens mots de passe. Vous devez donc en créer un nouveau.

📝 COMMENT ACTIVER VOTRE COMPTE :
1. Cliquez sur le lien ci-dessous pour définir votre nouveau mot de passe
2. Créez un mot de passe sécurisé (minimum 6 caractères)
3. Téléchargez l'application sur www.chiasma.pro
4. Connectez-vous avec votre email et votre nouveau mot de passe

🔑 LIEN DE RÉINITIALISATION :
${resetLink}

⏰ IMPORTANT : Ce lien est valide pendant 1 heure. Si le lien expire, vous pourrez demander un nouveau lien depuis l'application en utilisant "Mot de passe oublié".

✨ NOUVEAUTÉS DE L'APPLICATION
- Interface améliorée et plus intuitive
- Recherche de permutation plus rapide
- Système de notifications en temps réel
- Messagerie intégrée sécurisée
- Gestion optimisée de vos favoris

Si vous rencontrez des difficultés, n'hésitez pas à nous contacter.

Bienvenue dans la nouvelle ère de Chiasma ! 🚀

Cordialement,
L'équipe Chiasma

www.chiasma.pro
© 2025 Chiasma - Plateforme de permutation enseignante
    `
  };
}

async function sendWelcomeEmails() {
  console.log('📧 Génération des emails de bienvenue avec liens de réinitialisation...\n');

  const stats = {
    total: 0,
    success: 0,
    errors: 0,
    emails: []
  };

  try {
    // Récupérer tous les utilisateurs
    const listUsersResult = await auth.listUsers();
    const users = listUsersResult.users;
    stats.total = users.length;

    console.log(`Trouvé: ${stats.total} utilisateurs\n`);

    for (let i = 0; i < users.length; i++) {
      const user = users[i];
      const userName = user.displayName || user.email.split('@')[0];

      console.log(`[${i + 1}/${stats.total}] 📧 ${user.email}`);

      try {
        // Générer un lien de réinitialisation de mot de passe
        const resetLink = await auth.generatePasswordResetLink(user.email);

        // Générer l'email personnalisé
        const emailContent = getEmailTemplate(resetLink, userName);

        console.log(`   ✓ Email généré pour ${userName}`);

        stats.success++;
        stats.emails.push({
          email: user.email,
          name: userName,
          resetLink: resetLink,
          subject: emailContent.subject,
          htmlContent: emailContent.html,
          textContent: emailContent.text,
          status: 'ready'
        });

      } catch (error) {
        console.error(`   ❌ Erreur: ${error.message}`);
        stats.errors++;
        stats.emails.push({
          email: user.email,
          status: 'error',
          reason: error.message
        });
      }
    }

    // Sauvegarder les emails dans un fichier
    const fs = require('fs');
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const emailsFile = `welcome_emails_${timestamp}.json`;

    fs.writeFileSync(emailsFile, JSON.stringify({
      date: new Date().toISOString(),
      summary: {
        total: stats.total,
        success: stats.success,
        errors: stats.errors
      },
      emails: stats.emails
    }, null, 2));

    console.log('\n═══════════════════════════════════════════════════════');
    console.log('📊 RÉSUMÉ');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`Total utilisateurs:     ${stats.total}`);
    console.log(`✅ Emails générés:      ${stats.success}`);
    console.log(`❌ Erreurs:             ${stats.errors}`);
    console.log('═══════════════════════════════════════════════════════\n');

    console.log(`📄 Emails sauvegardés dans: ${emailsFile}\n`);

    console.log('📧 INSTRUCTIONS POUR ENVOYER LES EMAILS :\n');
    console.log('Option 1 : Utiliser un service d\'emailing (Recommandé)');
    console.log('  - Utilisez SendGrid, Mailgun, ou AWS SES');
    console.log('  - Importez le fichier JSON généré');
    console.log('  - Configurez l\'envoi en masse\n');

    console.log('Option 2 : Envoyer manuellement');
    console.log('  - Ouvrez le fichier JSON');
    console.log('  - Copiez le contenu HTML de chaque email');
    console.log('  - Envoyez via votre client email\n');

    console.log('⚠️  IMPORTANT:');
    console.log('   - Les liens de réinitialisation sont valides pendant 1 heure');
    console.log('   - Envoyez les emails rapidement');
    console.log('   - Les utilisateurs peuvent demander un nouveau lien depuis l\'app\n');

    // Créer aussi un fichier HTML de prévisualisation
    const previewFile = `email_preview_${timestamp}.html`;
    const firstEmail = stats.emails.find(e => e.status === 'ready');

    if (firstEmail) {
      fs.writeFileSync(previewFile, firstEmail.htmlContent);
      console.log(`👀 Prévisualisation de l'email: ${previewFile}\n`);
    }

    process.exit(0);

  } catch (error) {
    console.error('❌ ERREUR FATALE:', error);
    process.exit(1);
  }
}

sendWelcomeEmails();
