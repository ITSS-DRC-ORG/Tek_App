/// Énumération des rôles utilisateur
enum UserRole {
  admin,
  caissier,
  gestionnaire,
  vendeur,
}

/// Extension pour les rôles utilisateur
extension UserRoleExtension on UserRole {
  /// Retourne le libellé du rôle en français
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.caissier:
        return 'Caissier';
      case UserRole.gestionnaire:
        return 'Gestionnaire';
      case UserRole.vendeur:
        return 'Vendeur';
    }
  }

  /// Retourne la couleur associée au rôle
  int get color {
    switch (this) {
      case UserRole.admin:
        return 0xFFE53935; // Rouge
      case UserRole.caissier:
        return 0xFF43A047; // Vert
      case UserRole.gestionnaire:
        return 0xFF8E24AA; // Violet
      case UserRole.vendeur:
        return 0xFF1E88E5; // Bleu
    }
  }

  /// Convertit le rôle en chaîne pour l'API
  String get apiValue {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.caissier:
        return 'caissier';
      case UserRole.gestionnaire:
        return 'gestionnaire';
      case UserRole.vendeur:
        return 'vendeur';
    }
  }

  /// Parse un rôle depuis une chaîne
  static UserRole parse(String role) {
    final r = role.toLowerCase().trim();
    switch (r) {
      case 'admin':
        return UserRole.admin;
      case 'caissier':
        return UserRole.caissier;
      case 'gestionnaire':
      // Compatibilité avec l'ancienne API
      case 'magasinier':
      case 'gestionnaire_depot':
        return UserRole.gestionnaire;
      case 'vendeur':
        return UserRole.vendeur;
      default:
        return UserRole.vendeur;
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
    final data = json.containsKey('user')
        ? (json['user'] as Map<String, dynamic>)
        : json;

    final tokenValue = token ?? json['access_token'] as String? ?? '';

    return UserModel(
      id: data['id'] as int? ?? 0,
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      role: UserRoleExtension.parse(data['role'] as String? ?? 'vendeur'),
      depotId: data['depot_id'] as int?,
      depotNom: data['depot_nom'] as String?,
      actif: data['actif'] as bool? ?? true,
      token: tokenValue,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
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

  /// Nom complet
  String get fullName => '$prenom $nom'.trim();

  /// Initiales
  String get initials {
    final first = prenom.isNotEmpty ? prenom[0] : '';
    final last = nom.isNotEmpty ? nom[0] : '';
    return '$first$last'.toUpperCase();
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isCaissier => role == UserRole.caissier;
  bool get isGestionnaire => role == UserRole.gestionnaire;
  bool get isVendeur => role == UserRole.vendeur;

  /// Vérifie si l'utilisateur a accès à une section
  bool canAccess(String section) {
    switch (role) {
      case UserRole.admin:
        return true;
      case UserRole.caissier:
        return ['ventes', 'caisse', 'clients'].contains(section);
      case UserRole.gestionnaire:
        return [
          'stocks',
          'produits',
          'transferts',
          'achats',
          'ravitaillement'
        ].contains(section);
      case UserRole.vendeur:
        return ['ventes', 'clients'].contains(section);
    }
  }

  @override
  String toString() =>
      'UserModel(id: $id, username: $username, role: ${role.label})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}