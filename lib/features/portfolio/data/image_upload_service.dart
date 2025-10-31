import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/api_client.dart';
import '../../auth/data/auth_store.dart';

class ImageUploadService {
  final ApiClient _api;

  ImageUploadService(this._api);

  Future<List<String>> pickAndUploadFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null || result.files.isEmpty) return [];

    final uploadedUrls = <String>[];
    for (final f in result.files) {
      final url = await _uploadFile(
        bytes: f.bytes,
        path: f.path,
        filename: f.name,
      );
      if (url != null) uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  Future<List<String>> pickAndUploadFromGallery() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();

    final uploadedUrls = <String>[];
    for (final x in files) {
      final url = await _uploadFile(path: x.path);
      if (url != null) uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  Future<String?> pickAndUploadFromCamera() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera);
    if (x == null) return null;

    return await _uploadFile(path: x.path);
  }

  Future<String?> _uploadFile({
    List<int>? bytes,
    String? path,
    String? filename,
  }) async {
    if (bytes == null && path == null) return null;

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${_api.baseUrl}/api/image'),
    );

    if (bytes != null) {
      req.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    } else if (path != null) {
      req.files.add(await http.MultipartFile.fromPath('file', path));
    }

    final token = AuthStore.instance.tokenValue;
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final url = (jsonDecode(resp.body)['url'] as String?) ?? '';
        if (url.isNotEmpty) {
          return '${_api.baseUrl}$url';
        }
      }
    } catch (_) {
      // Ignore upload errors for individual files
    }
    return null;
  }
}
