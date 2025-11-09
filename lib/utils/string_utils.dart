/// Utilitaires pour la manipulation des chaînes de caractères
library;

/// Normalise une chaîne en retirant les accents et en convertissant en minuscules
///
/// Exemple:
/// ```dart
/// normalizeString('Éléphant') // retourne 'elephant'
/// normalizeString('Côte d\'Ivoire') // retourne 'cote d\'ivoire'
/// ```
String normalizeString(String input) {
  if (input.isEmpty) return input;

  // Conversion en minuscules
  String result = input.toLowerCase();

  // Mapping des caractères accentués vers leurs équivalents non accentués
  const accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
    'ñ': 'n',
    'ç': 'c',
    'æ': 'ae',
    'œ': 'oe',
    // Majuscules accentuées (au cas où elles ne seraient pas converties)
    'À': 'a', 'Á': 'a', 'Â': 'a', 'Ã': 'a', 'Ä': 'a', 'Å': 'a',
    'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e',
    'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i',
    'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Õ': 'o', 'Ö': 'o',
    'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u',
    'Ý': 'y', 'Ÿ': 'y',
    'Ñ': 'n',
    'Ç': 'c',
    'Æ': 'ae',
    'Œ': 'oe',
  };

  // Remplacer tous les caractères accentués
  accents.forEach((accented, unaccented) {
    result = result.replaceAll(accented, unaccented);
  });

  return result;
}

/// Vérifie si une chaîne contient une autre chaîne, en ignorant les accents et la casse
///
/// Exemple:
/// ```dart
/// containsIgnoringAccents('École primaire', 'ecole') // retourne true
/// containsIgnoringAccents('Côte d\'Ivoire', 'cote') // retourne true
/// ```
bool containsIgnoringAccents(String text, String search) {
  if (text.isEmpty || search.isEmpty) return false;

  final normalizedText = normalizeString(text);
  final normalizedSearch = normalizeString(search);

  return normalizedText.contains(normalizedSearch);
}

/// Compare deux chaînes en ignorant les accents et la casse
///
/// Exemple:
/// ```dart
/// equalsIgnoringAccents('École', 'ecole') // retourne true
/// equalsIgnoringAccents('Côte', 'cote') // retourne true
/// ```
bool equalsIgnoringAccents(String text1, String text2) {
  return normalizeString(text1) == normalizeString(text2);
}

/// Filtre une liste d'éléments en fonction d'une recherche, en ignorant les accents
///
/// Exemple:
/// ```dart
/// final users = [{'nom': 'Dupré'}, {'nom': 'Martin'}];
/// filterIgnoringAccents(users, 'dupre', (u) => u['nom'] as String)
/// // retourne [{'nom': 'Dupré'}]
/// ```
List<T> filterIgnoringAccents<T>(
  List<T> items,
  String searchQuery,
  String Function(T) getText,
) {
  if (searchQuery.isEmpty) return items;

  final normalizedQuery = normalizeString(searchQuery);

  return items.where((item) {
    final text = getText(item);
    final normalizedText = normalizeString(text);
    return normalizedText.contains(normalizedQuery);
  }).toList();
}

/// Masque un numéro de téléphone en ne montrant que les premiers et derniers chiffres
///
/// Exemple:
/// ```dart
/// maskPhoneNumber('+225 0758747888') // retourne '+225 07****7888'
/// maskPhoneNumber('0758747888') // retourne '07****7888'
/// ```
String maskPhoneNumber(String phoneNumber) {
  if (phoneNumber.isEmpty) return phoneNumber;

  // Retirer les espaces pour traiter les chiffres
  final cleanNumber = phoneNumber.replaceAll(' ', '');

  // Si le numéro est très court, masquer complètement
  if (cleanNumber.length <= 4) {
    return '****';
  }

  // Extraire le préfixe international s'il existe
  String prefix = '';
  String numberPart = cleanNumber;

  if (cleanNumber.startsWith('+')) {
    // Trouver où commence le numéro local (après le code pays)
    final match = RegExp(r'^\+\d{1,3}').firstMatch(cleanNumber);
    if (match != null) {
      prefix = '${match.group(0)!} ';
      numberPart = cleanNumber.substring(match.end);
    }
  }

  // Masquer le milieu du numéro
  if (numberPart.length <= 4) {
    return '$prefix****';
  }

  final firstPart = numberPart.substring(0, 2);
  final lastPart = numberPart.substring(numberPart.length - 4);
  final maskedPart = '*' * (numberPart.length - 6);

  return '$prefix$firstPart$maskedPart$lastPart';
}

/// Masque une adresse email en ne montrant que la première lettre et le domaine
///
/// Exemple:
/// ```dart
/// maskEmail('jean.dupont@education.ci') // retourne 'j****@education.ci'
/// maskEmail('contact@school.com') // retourne 'c****@school.com'
/// ```
String maskEmail(String email) {
  if (email.isEmpty) return email;

  // Séparer la partie locale et le domaine
  final parts = email.split('@');
  if (parts.length != 2) return email; // Email invalide, retourner tel quel

  final localPart = parts[0];
  final domain = parts[1];

  // Si la partie locale est très courte, masquer complètement
  if (localPart.length <= 1) {
    return '****@$domain';
  }

  // Montrer seulement la première lettre
  return '${localPart[0]}****@$domain';
}
