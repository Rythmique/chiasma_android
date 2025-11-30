import 'package:flutter/material.dart';
import 'package:myapp/register_screen.dart';
import 'package:myapp/teacher_candidate/register_candidate_page.dart';
import 'package:myapp/school/register_school_page.dart';

/// Page d'accueil pour choisir le type de compte
/// 3 options : Enseignant (Permutation), Candidat Enseignant, Établissement
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF77F00).withValues(alpha: 0.1),
              const Color(0xFF009E60).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo et titre
                  const Icon(Icons.school, size: 80, color: Color(0xFFF77F00)),
                  const SizedBox(height: 16),
                  const Text(
                    'CHIASMA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF77F00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plateforme éducative de Côte d\'Ivoire',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 60),

                  // Question
                  const Text(
                    'Vous êtes :',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 32),

                  // Option 1 : Enseignant (Permutation)
                  _buildAccountTypeCard(
                    context: context,
                    icon: Icons.swap_horiz,
                    title: 'Enseignant',
                    subtitle: 'Je cherche à permuter mon poste',
                    color: const Color(0xFFF77F00),
                    accountType: 'teacher_transfer',
                    description:
                        'Échangez votre poste avec d\'autres enseignants',
                  ),
                  const SizedBox(height: 16),

                  // Option 2 : Candidat Enseignant
                  _buildAccountTypeCard(
                    context: context,
                    icon: Icons.person_add,
                    title: 'Candidat Enseignant',
                    subtitle: 'Je cherche un emploi',
                    color: const Color(0xFF009E60),
                    accountType: 'teacher_candidate',
                    description:
                        'Déposez votre candidature et consultez les offres',
                  ),
                  const SizedBox(height: 16),

                  // Option 3 : Établissement
                  _buildAccountTypeCard(
                    context: context,
                    icon: Icons.business,
                    title: 'Établissement',
                    subtitle: 'Je recrute des enseignants',
                    color: const Color(0xFF2196F3),
                    accountType: 'school',
                    description:
                        'Publiez des offres et consultez les candidatures',
                  ),

                  const SizedBox(height: 40),

                  // Bouton de connexion
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Retour à l'écran de login
                    },
                    child: const Text(
                      'Vous avez déjà un compte ? Connectez-vous',
                      style: TextStyle(color: Color(0xFFF77F00), fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String accountType,
    required String description,
  }) {
    return InkWell(
      onTap: () {
        // Rediriger vers la page d'inscription appropriée
        Widget destinationPage;
        switch (accountType) {
          case 'teacher_candidate':
            destinationPage = const RegisterCandidatePage();
            break;
          case 'school':
            destinationPage = const RegisterSchoolPage();
            break;
          case 'teacher_transfer':
          default:
            destinationPage = RegisterScreen(accountType: accountType);
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // Flèche
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
