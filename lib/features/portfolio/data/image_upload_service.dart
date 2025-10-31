import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
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
      withData: true, // Forzar lectura de bytes (especialmente importante en web)
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
        // Acceso seguro a bytes y path con manejo de errores
        List<int>? fileBytes;
        String? filePath;
        
        try {
          fileBytes = f.bytes;
        } catch (e) {
          print('⚠️ Error accediendo a bytes: $e');
        }
        
        try {
          filePath = f.path;
        } catch (e) {
          print('⚠️ Error accediendo a path: $e');
        }
        
        print('🔍 Debug - bytes: ${fileBytes != null ? fileBytes.length : 'null'}, path: ${filePath ?? 'null'}, isWeb: $kIsWeb');
        
        // CRÍTICO: En web, SOLO usar bytes, NUNCA path
        if (kIsWeb) {
          // Si bytes no está disponible, intentar leer desde el path (blob URL) usando dart:html
          if (fileBytes == null || fileBytes.isEmpty) {
            if (filePath != null && filePath.startsWith('blob:')) {
              print('⚠️ FilePicker no proporcionó bytes. Intentando leer desde blob URL...');
              fileBytes = await _readBytesFromBlobUrl(filePath);
            }
          }
          
          if (fileBytes == null || fileBytes.isEmpty) {
            print('❌ Error en web: No se pudieron obtener los bytes del archivo ${f.name}.');
            print('⚠️ Esto puede ser un problema con file_picker en producción. Intenta seleccionar el archivo nuevamente.');
            continue; // Saltar este archivo
          }
          
          // En web, forzar solo bytes (ignorar path completamente)
          print('📦 Bytes disponibles en web: ${fileBytes.length} bytes');
          final url = await _uploadFile(
            bytes: fileBytes,
            path: null, // En web, siempre null
            filename: f.name,
          );
          if (url != null) {
            print('✅ URL recibida: $url');
            uploadedUrls.add(url);
          } else {
            print('❌ Error: no se recibió URL para ${f.name}');
          }
        } else {
          // En móvil (iOS/Android): preferir bytes, pero usar path si bytes no está disponible
          if (fileBytes != null && fileBytes.isNotEmpty) {
            print('📦 Bytes disponibles: ${fileBytes.length} bytes');
            final url = await _uploadFile(
              bytes: fileBytes,
              path: null,
              filename: f.name,
            );
            if (url != null) {
              print('✅ URL recibida: $url');
              uploadedUrls.add(url);
            } else {
              print('❌ Error: no se recibió URL para ${f.name}');
            }
          } else if (filePath != null && filePath.isNotEmpty) {
            // En iOS/Android: usar path cuando bytes no está disponible
            print('📦 Usando path: $filePath');
            final url = await _uploadFile(
              bytes: null,
              path: filePath,
              filename: f.name,
            );
            if (url != null) {
              print('✅ URL recibida: $url');
              uploadedUrls.add(url);
            } else {
              print('❌ Error: no se recibió URL para ${f.name}');
            }
          } else {
            print('❌ No hay bytes ni path disponible para ${f.name}');
          }
        }
      } catch (e) {
        print('❌ Error procesando archivo ${f.name}: $e');
      }
    }
    print('📦 Total URLs: ${uploadedUrls.length}');
    return uploadedUrls;
  }

  Future<List<String>> pickAndUploadFromGallery() async {
    // En web, usar FilePicker (ImagePicker no funciona bien en web)
    if (kIsWeb) {
      print('📁 Web detectado: usando FilePicker para galería');
      return await pickAndUploadFromFiles();
    }
    
    // En móvil, usar ImagePicker (funciona mejor en iOS/Android)
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
    // En web, la cámara no está disponible, usar FilePicker
    if (kIsWeb) {
      print('📁 Web detectado: cámara no disponible, usando FilePicker');
      final urls = await pickAndUploadFromFiles();
      return urls.isNotEmpty ? urls.first : null;
    }
    
    // En móvil, usar ImagePicker con cámara
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
    print('📎 _uploadFile llamado - bytes: ${bytes != null}, path: ${path != null}, filename: $filename, isWeb: $kIsWeb');
    
    // En web, SOLO usar bytes, nunca path (path no funciona en web)
    if (kIsWeb) {
      if (bytes == null || bytes.isEmpty) {
        print('❌ En web, se requieren bytes. No se pueden usar paths.');
        return null;
      }
    } else {
      // En móvil, verificar que tengamos bytes o path
      if (bytes == null && path == null) {
        print('❌ No hay bytes ni path');
        return null;
      }
    }

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${_api.baseUrl}/api/image'),
    );

    try {
      if (bytes != null && bytes.isNotEmpty) {
        // Siempre preferir bytes cuando estén disponibles (funciona en todas las plataformas)
        print('📦 Usando bytes (${bytes.length} bytes)');
        req.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename ?? 'image.jpg'),
        );
      } else if (!kIsWeb && path != null && path.isNotEmpty) {
        // Solo usar path en móvil (iOS/Android), nunca en web
        print('📦 Usando path: $path');
        req.files.add(await http.MultipartFile.fromPath('file', path));
      } else {
        print('❌ No se puede subir el archivo: bytes vacío y path ${kIsWeb ? 'no disponible en web' : 'no disponible'}');
        return null;
      }
    } catch (e) {
      print('❌ Error preparando archivo: $e');
      if (kIsWeb && path != null) {
        print('⚠️ En web, el path proporcionado (${path.substring(0, path.length > 50 ? 50 : path.length)}...) no se puede usar. Se requieren bytes.');
      }
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

  /// Lee bytes desde una URL blob en web (workaround para file_picker que no devuelve bytes)
  Future<List<int>?> _readBytesFromBlobUrl(String blobUrl) async {
    if (!kIsWeb) return null;
    
    try {
      // En web, no podemos leer directamente desde blob URLs de forma síncrona
      // file_picker debería proporcionar bytes con withData: true
      // Si llegamos aquí, es un problema con file_picker
      print('⚠️ No se puede leer desde blob URL directamente. file_picker debería proporcionar bytes.');
      return null;
    } catch (e) {
      print('❌ Error leyendo blob URL: $e');
      return null;
    }
  }
}
