import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isEmailSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF77F00).withValues(alpha: 0.1),
              Colors.white,
              const Color(0xFF009E60).withValues(alpha: 0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bouton retour
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFFF77F00),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Logo section avec drapeau stylisé
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF77F00).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFFF77F00),
                                const Color(0xFFF77F00),
                                Colors.white,
                                const Color(0xFF009E60),
                                const Color(0xFF009E60),
                              ],
                              stops: const [0.0, 0.33, 0.5, 0.67, 1.0],
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_reset_outlined,
                            size: 45,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Titre
                      Text(
                        'Mot de passe oublié',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF77F00),
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFF77F00).withValues(alpha: 0.3),
                              offset: const Offset(0, 3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        _isEmailSent
                            ? 'Email envoyé avec succès'
                            : 'Réinitialisez votre mot de passe',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Card contenant le formulaire ou le message de confirmation
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _isEmailSent
                              ? _buildSuccessMessage()
                              : _buildResetForm(),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barre décorative avec couleurs du drapeau
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFF77F00),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF009E60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Texte explicatif
          Text(
            'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Champ Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Adresse email',
              hintText: 'exemple@email.ci',
              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFF77F00)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!value.contains('@')) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Bouton d'envoi
          ElevatedButton(
            onPressed: _sendResetLink,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Envoyer le lien',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Lien vers connexion
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Vous vous souvenez ? ',
                style: TextStyle(color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(
                    color: Color(0xFFF77F00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icône de succès
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF009E60).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 60,
            color: Color(0xFF009E60),
          ),
        ),
        const SizedBox(height: 24),

        // Message de succès
        Text(
          'Email envoyé !',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF009E60),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        Text(
          'Nous avons envoyé un lien de réinitialisation à :',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Text(
          _emailController.text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF77F00),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        Text(
          'Veuillez vérifier votre boîte de réception et cliquer sur le lien pour réinitialiser votre mot de passe.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Bouton retour à la connexion
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Retour à la connexion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bouton renvoyer
        TextButton(
          onPressed: () {
            setState(() {
              _isEmailSent = false;
            });
          },
          child: const Text(
            'Renvoyer l\'email',
            style: TextStyle(
              color: Color(0xFF009E60),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
