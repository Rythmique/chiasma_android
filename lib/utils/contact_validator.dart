/// Utilitaire pour détecter et bloquer les informations de contact
/// dans les champs de texte (emails, téléphones, etc.)
class ContactValidator {
  // Regex pour détecter les emails
  static final RegExp _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    caseSensitive: false,
  );

  // Regex pour détecter les numéros de téléphone (format international et local)
  static final RegExp _phoneRegex = RegExp(
    r'(\+?\d{1,4}[\s-]?)?(\(?\d{2,4}\)?[\s-]?)?[\d\s-]{6,}',
    caseSensitive: false,
  );

  // Regex pour détecter les numéros de téléphone ivoiriens
  static final RegExp _ivorianPhoneRegex = RegExp(
    r'(\+?225[\s-]?)?[0-9]{10}|[0-9]{8}',
    caseSensitive: false,
  );

  // Mots-clés suspects (WhatsApp, Telegram, etc.)
  static final List<String> _suspiciousKeywords = [
    'whatsapp',
    'telegram',
    'appel',
    'appelle',
    'contacte',
    'contacter',
    'joindre',
    'tel',
    'tél',
    'phone',
    'mobile',
    'email',
    'mail',
    '@',
  ];

  /// Vérifier si le texte contient des informations de contact
  static bool containsContactInfo(String text) {
    if (text.isEmpty) return false;

    final lowerText = text.toLowerCase();

    // Vérifier les emails
    if (_emailRegex.hasMatch(text)) {
      return true;
    }

    // Vérifier les numéros de téléphone
    if (_phoneRegex.hasMatch(text) || _ivorianPhoneRegex.hasMatch(text)) {
      // Vérifier si c'est vraiment un numéro (pas juste des chiffres aléatoires)
      final numbers = text.replaceAll(RegExp(r'[^\d]'), '');
      if (numbers.length >= 8) {
        return true;
      }
    }

    // Vérifier les mots-clés suspects avec numéros proches
    for (var keyword in _suspiciousKeywords) {
      if (lowerText.contains(keyword)) {
        // Si un mot-clé est trouvé, vérifier s'il y a des chiffres à proximité
        final index = lowerText.indexOf(keyword);
        final surrounding = text.substring(
          index > 10 ? index - 10 : 0,
          (index + keyword.length + 20) < text.length
              ? index + keyword.length + 20
              : text.length,
        );
        if (RegExp(r'\d{6,}').hasMatch(surrounding)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Obtenir un message d'erreur approprié
  static String getErrorMessage() {
    return 'Ce champ ne peut pas contenir d\'informations de contact (email, téléphone, WhatsApp, etc.). '
        'Veuillez utiliser uniquement les fonctionnalités de messagerie de l\'application pour communiquer.';
  }

  /// Valider un champ de formulaire
  static String? validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return null; // La validation de champ vide est gérée ailleurs
    }

    if (containsContactInfo(value)) {
      return 'Le champ "$fieldName" ne peut pas contenir d\'email, téléphone ou autres coordonnées.';
    }

    return null;
  }

  /// Nettoyer le texte en retirant les informations de contact (optionnel)
  static String sanitize(String text) {
    String cleaned = text;

    // Remplacer les emails par [email masqué]
    cleaned = cleaned.replaceAll(_emailRegex, '[email masqué]');

    // Remplacer les numéros de téléphone
    cleaned = cleaned.replaceAll(_phoneRegex, '[numéro masqué]');
    cleaned = cleaned.replaceAll(_ivorianPhoneRegex, '[numéro masqué]');

    return cleaned;
  }

  /// Détecter le type d'information de contact trouvée
  static String? detectContactType(String text) {
    if (_emailRegex.hasMatch(text)) {
      return 'email';
    }
    if (_phoneRegex.hasMatch(text) || _ivorianPhoneRegex.hasMatch(text)) {
      return 'téléphone';
    }
    for (var keyword in _suspiciousKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        return 'mot-clé suspect';
      }
    }
    return null;
  }
}
