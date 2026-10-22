import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/user_model.dart';
import '../../api/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  final AuthService _authService = AuthService();

  // ---------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(username, password);

      // ✅ Erreur métier ou réseau
      if (response == null || response.containsKey('error')) {
        _error = response?['error'] as String? ?? 'Erreur de connexion au serveur';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ✅ Vérifier la présence du token
      final token = response['access_token'];
      if (token == null || token is! String || token.isEmpty) {
        _error = 'Réponse du serveur invalide (token manquant)';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ✅ Créer l'utilisateur depuis la réponse
      _user = UserModel.fromJson(response, token);

      // ✅ Sauvegarder token + user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString(
        'user',
        jsonEncode(response.containsKey('user') ? response['user'] : response),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur inattendue: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------
  Future<void> logout() async {
    _user = null;
    _error = null;
    _isLoading = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // LOAD USER FROM STORAGE
  // ---------------------------------------------------------------------
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userString = prefs.getString('user');

    if (token == null || token.isEmpty || userString == null) return;

    try {
      final Map<String, dynamic> userData =
      jsonDecode(userString) as Map<String, dynamic>;
      userData['access_token'] = token;
      _user = UserModel.fromJson(userData, token);
      notifyListeners();
    } catch (e) {
      _error = 'Session expirée, veuillez vous reconnecter';
      await logout();
    }
  }

  // ---------------------------------------------------------------------
  // UPDATE USER
  // ---------------------------------------------------------------------
  Future<void> updateUser(UserModel updatedUser) async {
    _user = updatedUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', updatedUser.token);
    await prefs.setString('user', jsonEncode(updatedUser.toJson()));

    notifyListeners();
  }
}