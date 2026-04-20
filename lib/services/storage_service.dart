import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class StorageService {
  // IMPORTANT: Replace these with your actual Cloudinary credentials
  // Get these from your Cloudinary Dashboard and Settings -> Upload
  static const String _cloudName = 'djutzk9gd';
  static const String _uploadPreset = 'entangled';

  Future<String?> uploadProfileImage(String uid, File imageFile) async {
    return _uploadToCloudinary(imageFile, folder: 'profile_images');
  }

  Future<String?> uploadChatImage(String chatId, File imageFile) async {
    return _uploadToCloudinary(imageFile, folder: 'chat_images/$chatId');
  }

  // Alias to prevent naming mismatch errors in ChatScreen
  Future<String?> uploadChatMessageImage(String chatId, File imageFile) async {
    return uploadChatImage(chatId, imageFile);
  }

  Future<String?> _uploadToCloudinary(
    File imageFile, {
    required String folder,
  }) async {
    if (_cloudName == 'YOUR_CLOUD_NAME') {
      debugPrint('CLOUD_STORAGE_ERROR: Cloudinary credentials not configured.');
      return null;
    }

    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);
      final jsonData = json.decode(responseString);

      if (response.statusCode == 200) {
        return jsonData['secure_url'] as String;
      } else {
        debugPrint(
          'CLOUD_STORAGE_ERROR: ${jsonData['error']?['message'] ?? 'Unknown error'}',
        );
        return null;
      }
    } catch (e, stack) {
      debugPrint('CLOUD_STORAGE_EXCEPTION: $e');
      debugPrint('STACKTRACE: $stack');
      return null;
    }
  }
}
