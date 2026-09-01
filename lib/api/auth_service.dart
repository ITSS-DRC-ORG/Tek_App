import 'package:dio/dio.dart';
import '../utils/config.dart';

class AuthService {
  final Dio _dio = Dio();

  AuthService() {
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      print('🔐 Connexion avec Dio pour: $username');

      // ✅ Utiliser FormData pour forcer l'envoi
      final formData = FormData.fromMap({
        'username': username,
        'password': password,
      });

      final response = await _dio.post(
        '/auth/login',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          // ✅ Forcer la validation même pour 422
          validateStatus: (status) => true,
        ),
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 Data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        print('❌ Status Code: ${response.statusCode}');
        print('❌ Response: ${response.data}');
        return null;
      }
    } catch (e) {
      print('❌ Dio Exception: $e');
      return null;
    }
  }
}