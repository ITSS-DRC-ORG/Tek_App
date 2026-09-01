/// Énumération des rôles utilisateur
enum UserRole {
  admin,
  vendeur,
  caissier,
  magasinier,
  gestionnaire_depot,
}

/// Extension pour les rôles utilisateur
extension UserRoleExtension on UserRole {
  /// Retourne le libellé du rôle en français
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.vendeur:
        return 'Vendeur';
      case UserRole.caissier:
        return 'Caissier';
      case UserRole.magasinier:
        return 'Magasinier';
      case UserRole.gestionnaire_depot:
        return 'Gestionnaire de dépôt';
    }
  }

  /// Retourne la couleur associée au rôle
  int get color {
    switch (this) {
      case UserRole.admin:
        return 0xFFE53935; // Rouge
      case UserRole.vendeur:
        return 0xFF1E88E5; // Bleu
      case UserRole.caissier:
        return 0xFF43A047; // Vert
      case UserRole.magasinier:
        return 0xFFFB8C00; // Orange
      case UserRole.gestionnaire_depot:
        return 0xFF8E24AA; // Violet
    }
  }

  /// Convertit le rôle en chaîne pour l'API
  String get apiValue {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.vendeur:
        return 'vendeur';
      case UserRole.caissier:
        return 'caissier';
      case UserRole.magasinier:
        return 'magasinier';
      case UserRole.gestionnaire_depot:
        return 'gestionnaire_depot';
    }
  }
}

/// Modèle représentant un utilisateur
class UserModel {
  final int id;
  final String username;
  final String email;
  final String nom;
  final String prenom;
  final UserRole role;
  final int? depotId;
  final String? depotNom;
  final bool actif;
  final String token;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.role,
    this.depotId,
    this.depotNom,
    required this.actif,
    required this.token,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée une instance de UserModel à partir d'un JSON
  factory UserModel.fromJson(Map<String, dynamic> json, [String? token]) {
    // Si le JSON contient un champ 'user', on l'extrait
    final data = json.containsKey('user') ? json['user'] : json;
    final tokenValue = token ?? json['access_token'] as String? ?? '';

    return UserModel(
      id: data['id'] as int,
      username: data['username'] as String,
      email: data['email'] as String,
      nom: data['nom'] as String,
      prenom: data['prenom'] as String? ?? '',
      role: _parseRole(data['role'] as String? ?? 'vendeur'),
      depotId: data['depot_id'] as int?,
      depotNom: data['depot_nom'] as String?,
      actif: data['actif'] as bool? ?? true,
      token: tokenValue,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at'] as String) 
          : DateTime.now(),
      updatedAt: data['updated_at'] != null 
          ? DateTime.parse(data['updated_at'] as String) 
          : DateTime.now(),
    );
  }

  /// Parse le rôle depuis une chaîne
  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'vendeur':
        return UserRole.vendeur;
      case 'caissier':
        return UserRole.caissier;
      case 'magasinier':
        return UserRole.magasinier;
      case 'gestionnaire_depot':
        return UserRole.gestionnaire_depot;
      default:
        return UserRole.vendeur;
    }
  }

  /// Convertit une instance de UserModel en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'role': role.apiValue,
      'depot_id': depotId,
      'depot_nom': depotNom,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crée une copie de l'instance avec des champs modifiés
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? nom,
    String? prenom,
    UserRole? role,
    int? depotId,
    String? depotNom,
    bool? actif,
    String? token,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      role: role ?? this.role,
      depotId: depotId ?? this.depotId,
      depotNom: depotNom ?? this.depotNom,
      actif: actif ?? this.actif,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Retourne le nom complet de l'utilisateur
  String get fullName => '$prenom $nom'.trim();

  /// Retourne les initiales de l'utilisateur
  String get initials {
    final first = prenom.isNotEmpty ? prenom[0] : '';
    final last = nom.isNotEmpty ? nom[0] : '';
    return '$first$last'.toUpperCase();
  }

  /// Vérifie si l'utilisateur est un administrateur
  bool get isAdmin => role == UserRole.admin;

  /// Vérifie si l'utilisateur est un vendeur
  bool get isVendeur => role == UserRole.vendeur;

  /// Vérifie si l'utilisateur est un caissier
  bool get isCaissier => role == UserRole.caissier;

  /// Vérifie si l'utilisateur est un magasinier
  bool get isMagasinier => role == UserRole.magasinier;

  /// Vérifie si l'utilisateur est un gestionnaire de dépôt
  bool get isGestionnaireDepot => role == UserRole.gestionnaire_depot;

  /// Vérifie si l'utilisateur a accès à une section
  bool canAccess(String section) {
    switch (role) {
      case UserRole.admin:
        return true; // Admin a accès à tout
      case UserRole.vendeur:
        return section == 'ventes' || section == 'clients';
      case UserRole.caissier:
        return section == 'ventes' || section == 'caisse' || section == 'clients';
      case UserRole.magasinier:
        return section == 'stocks' || section == 'produits' || section == 'transferts';
      case UserRole.gestionnaire_depot:
        return section == 'stocks' || section == 'produits' || 
               section == 'transferts' || section == 'achats';
    }
  }

  @override
  String toString() => 'UserModel(id: $id, username: $username, role: ${role.label})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}