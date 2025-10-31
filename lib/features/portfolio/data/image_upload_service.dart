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
    print('📁 Abriendo selector de archivos...');
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    print('📁 Archivos seleccionados: ${result?.files.length ?? 0}');
    if (result == null || result.files.isEmpty) {
      print('📁 No se seleccionaron archivos');
      return [];
    }

    final uploadedUrls = <String>[];
    for (final f in result.files) {
      print('⬆️ Subiendo: ${f.name}');
      try {
        // En web, solo bytes está disponible (path NO se puede acceder)
        if (f.bytes == null) {
          print('❌ No hay bytes disponibles para ${f.name}');
          continue;
        }
        
        print('📦 Bytes disponibles: ${f.bytes!.length} bytes');
        
        final url = await _uploadFile(
          bytes: f.bytes,
          path: null,  // En web, path no está disponible
          filename: f.name,
        );
        if (url != null) {
          print('✅ URL recibida: $url');
          uploadedUrls.add(url);
        } else {
          print('❌ Error: no se recibió URL para ${f.name}');
        }
      } catch (e) {
        print('❌ Error procesando archivo ${f.name}: $e');
      }
    }
    print('📦 Total URLs: ${uploadedUrls.length}');
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
    print('📎 _uploadFile llamado - bytes: ${bytes != null}, path: ${path != null}, filename: $filename');
    
    if (bytes == null && path == null) {
      print('❌ No hay bytes ni path');
      return null;
    }

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${_api.baseUrl}/api/image'),
    );

    try {
      if (bytes != null && bytes.isNotEmpty) {
        print('📦 Usando bytes (${bytes.length} bytes)');
        req.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename ?? 'image.jpg'),
        );
      } else if (path != null) {
        print('📦 Usando path: $path');
        req.files.add(await http.MultipartFile.fromPath('file', path));
      } else {
        print('❌ bytes está vacío');
        return null;
      }
    } catch (e) {
      print('❌ Error preparando archivo: $e');
      return null;
    }

    final token = AuthStore.instance.tokenValue;
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    try {
      print('🌐 Enviando archivo al servidor...');
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      print('🌐 Status code: ${resp.statusCode}');
      print('🌐 Response body: ${resp.body}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final url = (jsonDecode(resp.body)['url'] as String?) ?? '';
        print('🌐 URL extraída: $url');
        if (url.isNotEmpty) {
          // Si la URL ya es absoluta (Firebase Storage), usar tal cual
          // Si es relativa (almacenamiento local), convertir a absoluta
          if (url.startsWith('http://') || url.startsWith('https://')) {
            print('🌐 URL absoluta detectada');
            return url;
          }
          final fullUrl = '${_api.baseUrl}$url';
          print('🌐 URL relativa convertida: $fullUrl');
          return fullUrl;
        }
      }
    } catch (e) {
      print('❌ Error subiendo archivo: $e');
    }
    return null;
  }
}
