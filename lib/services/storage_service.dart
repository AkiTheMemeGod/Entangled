import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static const String _bucketName = 'media';

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> uploadProfileImage(String uid, File imageFile) async {
    return _uploadToSupabaseStorage(
      imageFile,
      folder: 'profile_images/$uid',
      contentType: _contentTypeFromPath(imageFile.path, fallback: 'image/jpeg'),
    );
  }

  Future<String?> uploadChatImage(String chatId, File imageFile) async {
    return _uploadToSupabaseStorage(
      imageFile,
      folder: 'chat_images/$chatId',
      contentType: _contentTypeFromPath(imageFile.path, fallback: 'image/jpeg'),
    );
  }

  // Alias to prevent naming mismatch errors in ChatScreen
  Future<String?> uploadChatMessageImage(String chatId, File imageFile) async {
    return uploadChatImage(chatId, imageFile);
  }

  Future<String?> uploadChatAudio(String chatId, File audioFile) async {
    return _uploadToSupabaseStorage(
      audioFile,
      folder: 'chat_audio/$chatId',
      contentType: _contentTypeFromPath(audioFile.path, fallback: 'audio/mpeg'),
    );
  }

  Future<void> deletePublicMediaUrl(String? publicUrl) async {
    if (publicUrl == null || publicUrl.isEmpty) return;

    final objectPath = _extractObjectPathFromPublicUrl(publicUrl);
    if (objectPath == null) return;

    try {
      await _supabase.storage.from(_bucketName).remove([objectPath]);
    } catch (e, stack) {
      debugPrint('CLOUD_STORAGE_DELETE_EXCEPTION: $e');
      debugPrint('STACKTRACE: $stack');
    }
  }

  Future<String?> _uploadToSupabaseStorage(
    File file, {
    required String folder,
    required String contentType,
  }) async {
    if (!file.existsSync()) {
      debugPrint('CLOUD_STORAGE_ERROR: File not found at ${file.path}');
      return null;
    }

    try {
      final storage = _supabase.storage.from(_bucketName);
      final extension = _fileExtension(file.path);
      final filename = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final objectPath = '$folder/$filename';

      await storage.upload(
        objectPath,
        file,
        fileOptions: FileOptions(
          upsert: true,
          cacheControl: '3600',
          contentType: contentType,
        ),
      );

      return storage.getPublicUrl(objectPath);
    } catch (e, stack) {
      debugPrint('CLOUD_STORAGE_EXCEPTION: $e');
      debugPrint('STACKTRACE: $stack');
      return null;
    }
  }

  String _fileExtension(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segment = normalized.split('/').last;
    final dotIndex = segment.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == segment.length - 1) {
      return 'bin';
    }
    return segment.substring(dotIndex + 1).toLowerCase();
  }

  String _contentTypeFromPath(String path, {required String fallback}) {
    switch (_fileExtension(path)) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return fallback;
    }
  }

  String? _extractObjectPathFromPublicUrl(String publicUrl) {
    final uri = Uri.tryParse(publicUrl);
    if (uri == null || uri.pathSegments.isEmpty) return null;

    final segments = uri.pathSegments
        .map((segment) => Uri.decodeComponent(segment))
        .toList();
    final bucketIndex = segments.lastIndexOf(_bucketName);
    if (bucketIndex == -1 || bucketIndex >= segments.length - 1) {
      return null;
    }

    return segments.sublist(bucketIndex + 1).join('/');
  }
}
