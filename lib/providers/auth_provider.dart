import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/user_model.dart';
import '../../api/auth_service.dart';
import '../../api/admin_service.dart';

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
  // LOGIN - Version corrigée avec redirection
  // ---------------------------------------------------------------------
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(username, password);
      
      print('📦 Response dans AuthProvider: $response');

      if (response == null) {
        _error = 'Erreur de connexion au serveur';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Vérifier que le token existe
      if (response['access_token'] == null) {
        _error = 'Identifiants incorrects';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ✅ Extraire le token et créer l'utilisateur
      final String token = response['access_token'] as String;
      print('✅ Token reçu: $token');
      
      // ✅ Créer l'utilisateur depuis la réponse
      _user = UserModel.fromJson(response, token);
      print('✅ Utilisateur créé: ${_user?.username}');
      
      // ✅ Sauvegarder les données
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      
      // Sauvegarder l'utilisateur
      if (response.containsKey('user') && response['user'] != null) {
        final userData = response['user'] as Map<String, dynamic>;
        await prefs.setString('user', jsonEncode(userData));
      } else {
        await prefs.setString('user', jsonEncode(response));
      }
      
      _isLoading = false;
      notifyListeners();
      
      print('✅ Connexion réussie pour: ${_user?.username}');
      return true;

    } catch (e) {
      print('❌ Erreur dans login: $e');
      _error = e.toString();
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
    
    if (token != null && userString != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userString) as Map<String, dynamic>;
        userData['access_token'] = token;
        _user = UserModel.fromJson(userData, token);
        print('✅ Utilisateur chargé depuis le storage: ${_user?.username}');
        notifyListeners();
      } catch (e) {
        print('❌ Erreur chargement: $e');
        await logout();
      }
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