import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as dev;

/// Service pour gérer l'upload de fichiers vers le stockage cloud
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload un fichier vers le stockage cloud
  /// Retourne l'URL de téléchargement du fichier
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String userId,
    required String conversationId,
    void Function(double)? onProgress,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Créer un nom de fichier unique
      final uniqueFileName = '${timestamp}_$fileName';

      // Chemin dans Storage: messages/{conversationId}/{userId}/{uniqueFileName}
      final storagePath = 'messages/$conversationId/$userId/$uniqueFileName';

      dev.log('Uploading file to: $storagePath', name: 'StorageService');

      // Créer la référence
      final ref = _storage.ref().child(storagePath);

      // Déterminer le content type
      final contentType = _getContentType(fileExtension);

      // Métadonnées
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': userId,
          'conversationId': conversationId,
          'originalName': fileName,
          'uploadedAt': timestamp.toString(),
        },
      );

      // Upload avec suivi de progression
      final uploadTask = ref.putFile(file, metadata);

      // Écouter la progression
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
        dev.log('Upload progress: ${(progress * 100).toStringAsFixed(1)}%',
                name: 'StorageService');
      });

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;

      // Obtenir l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Obtenir la taille du fichier
      final fileSize = await file.length();

      dev.log('File uploaded successfully: $downloadUrl', name: 'StorageService');

      return {
        'url': downloadUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileType': _getFileType(fileExtension),
        'storagePath': storagePath,
      };
    } catch (e) {
      dev.log('Error uploading file', name: 'StorageService', error: e);
      rethrow;
    }
  }

  /// Supprimer un fichier du stockage cloud
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
      dev.log('File deleted: $storagePath', name: 'StorageService');
    } catch (e) {
      dev.log('Error deleting file', name: 'StorageService', error: e);
      rethrow;
    }
  }

  /// Obtenir le type de contenu MIME
  String _getContentType(String extension) {
    switch (extension) {
      // Images
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';

      // Documents
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

      // Texte
      case '.txt':
        return 'text/plain';
      case '.csv':
        return 'text/csv';

      // Archives
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';

      // Audio
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';

      // Vidéo
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/x-msvideo';

      default:
        return 'application/octet-stream';
    }
  }

  /// Déterminer le type de fichier pour l'affichage
  String _getFileType(String extension) {
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      return 'image';
    } else if (['.pdf'].contains(extension)) {
      return 'pdf';
    } else if (['.doc', '.docx'].contains(extension)) {
      return 'document';
    } else if (['.xls', '.xlsx'].contains(extension)) {
      return 'spreadsheet';
    } else if (['.ppt', '.pptx'].contains(extension)) {
      return 'presentation';
    } else if (['.txt', '.csv'].contains(extension)) {
      return 'text';
    } else if (['.zip', '.rar'].contains(extension)) {
      return 'archive';
    } else if (['.mp3', '.wav'].contains(extension)) {
      return 'audio';
    } else if (['.mp4', '.avi'].contains(extension)) {
      return 'video';
    } else {
      return 'file';
    }
  }

  /// Formater la taille du fichier
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Vérifier si le fichier est une image
  static bool isImage(String? fileType) {
    return fileType == 'image';
  }

  /// Obtenir l'icône appropriée pour le type de fichier
  static String getFileIcon(String fileType) {
    switch (fileType) {
      case 'image':
        return '🖼️';
      case 'pdf':
        return '📄';
      case 'document':
        return '📝';
      case 'spreadsheet':
        return '📊';
      case 'presentation':
        return '📽️';
      case 'text':
        return '📃';
      case 'archive':
        return '🗜️';
      case 'audio':
        return '🎵';
      case 'video':
        return '🎬';
      default:
        return '📎';
    }
  }
}
