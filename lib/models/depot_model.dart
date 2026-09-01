/// Modèle représentant un dépôt/magasin
class Depot {
  final int id;
  final String nom;
  final String type;
  final String? adresse;
  final bool estMagasin;
  final bool aCaisse;
  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;

  Depot({
    required this.id,
    required this.nom,
    required this.type,
    this.adresse,
    required this.estMagasin,
    required this.aCaisse,
    required this.actif,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée une instance de Depot à partir d'un JSON
  factory Depot.fromJson(Map<String, dynamic> json) {
    return Depot(
      id: json['id'] as int,
      nom: json['nom'] as String,
      type: json['type'] as String,
      adresse: json['adresse'] as String?,
      estMagasin: json['est_magasin'] as bool? ?? false,
      aCaisse: json['a_caisse'] as bool? ?? false,
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convertit une instance de Depot en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'adresse': adresse,
      'est_magasin': estMagasin,
      'a_caisse': aCaisse,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crée une copie de l'instance avec des champs modifiés
  Depot copyWith({
    int? id,
    String? nom,
    String? type,
    String? adresse,
    bool? estMagasin,
    bool? aCaisse,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Depot(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      adresse: adresse ?? this.adresse,
      estMagasin: estMagasin ?? this.estMagasin,
      aCaisse: aCaisse ?? this.aCaisse,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Depot(id: $id, nom: $nom, type: $type, estMagasin: $estMagasin)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Depot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Extension pour les types de dépôt
extension DepotTypeExtension on String {
  bool get isGrandDepot => this == 'grand_depot';
  bool get isPetitDepot => this == 'petit_depot';
  bool get isTroisiemeDepot => this == 'troisieme_depot';
  
  String get label {
    switch (this) {
      case 'grand_depot':
        return 'Grand Dépôt';
      case 'petit_depot':
        return 'Petit Dépôt';
      case 'troisieme_depot':
        return 'Troisième Dépôt';
      default:
        return this;
    }
  }
}