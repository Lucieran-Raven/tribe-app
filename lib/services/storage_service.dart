import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class StorageService {
  static const String _cloudName = 'tehrbkph';
  static const String _uploadPreset = 'ml_default';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  Future<String> uploadAvatar(File file, String userId) async {
    return _upload(
        file, 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<String> uploadPostImage(File file, String postId) async {
    return _upload(
        file, 'post_${postId}_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<String> _upload(File file, String filename) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path,
        filename: '$filename.jpg'));

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Upload failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary returned no URL');
    }
    return url;
  }
}
