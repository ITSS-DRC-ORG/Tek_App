import 'package:dio/dio.dart';
import '../utils/config.dart';

class AuthService {
  final Dio _dio = Dio();

  AuthService({String? token}) {
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  /// Connecte l'utilisateur et retourne la réponse (token + user)
  /// ou un Map contenant `error` en cas d'échec.
  Future<Map<String, dynamic>?> login(
      String username,
      String password,
      ) async {
    try {
      final formData = FormData.fromMap({
        'username': username,
        'password': password,
      });

      final response = await _dio.post(
        '/auth/login',
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      // ✅ Retourner un message d'erreur explicite
      String message = 'Identifiants incorrects';
      final data = response.data;
      if (data is Map) {
        message = (data['error'] ?? data['detail'] ?? message).toString();
      }
      return {'error': message, 'status': response.statusCode};
    } on DioException catch (e) {
      // ✅ Erreurs réseau : timeout, connexion refusée, etc.
      String message;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        message = 'Le serveur ne répond pas. Vérifiez votre connexion.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossible de joindre le serveur. Vérifiez que l\'API est démarrée.';
      } else {
        message = e.message ?? 'Erreur de connexion inconnue';
      }
      return {'error': message, 'type': e.type.toString()};
    } catch (e) {
      return {'error': 'Erreur inattendue: ${e.toString()}'};
    }
  }

  /// Vérifie que l'API est joignable (health check)
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}