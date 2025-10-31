import 'dart:convert';
import '../../../core/api_client.dart';

class AiService {
  AiService(this._api);
  final ApiClient _api;

  Future<String> careerChat(String message) async {
    try {
      final r = await _api.post('/api/ai/career-chat', body: {'message': message});
      final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
      
      // Verificar si hay un error en la respuesta
      if (j.containsKey('error')) {
        throw Exception(j['error'] as String);
      }
      
      return (j['reply'] ?? '') as String;
    } on ApiError catch (e) {
      // Intentar extraer el mensaje de error del JSON en el cuerpo de la respuesta
      try {
        final errorBody = e.message;
        if (errorBody.contains('{')) {
          final jsonStart = errorBody.indexOf('{');
          final jsonStr = errorBody.substring(jsonStart);
          final errorJson = jsonDecode(jsonStr) as Map<String, dynamic>;
          if (errorJson.containsKey('error')) {
            throw Exception(errorJson['error'] as String);
          }
        }
      } catch (_) {
        // Si no se puede parsear, usar el mensaje original
      }
      rethrow;
    } catch (e) {
      // Re-lanzar el error con un mensaje más claro
      if (e.toString().contains('OPENAI_API_KEY')) {
        throw Exception('La API key de OpenAI no está configurada. Contacta al administrador.');
      }
      rethrow;
    }
  }
}


