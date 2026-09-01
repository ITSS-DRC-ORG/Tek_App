class Product {
  final int id;
  final String code;
  final String nom;
  final String? description;
  final double prixAchat;
  final double prixVente;
  final String unite;
  final int seuilAlerte;
  final bool actif;
  final int? categorieId;
  final String? categorieNom;
  final DateTime createdAt;  // ✅ Ajouté
  final DateTime updatedAt;  // ✅ Ajouté

  Product({
    required this.id,
    required this.code,
    required this.nom,
    this.description,
    required this.prixAchat,
    required this.prixVente,
    required this.unite,
    required this.seuilAlerte,
    required this.actif,
    this.categorieId,
    this.categorieNom,
    required this.createdAt,  // ✅ Requis
    required this.updatedAt,  // ✅ Requis
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      code: json['code'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      prixAchat: double.parse(json['prix_achat'].toString()),
      prixVente: double.parse(json['prix_vente'].toString()),
      unite: json['unite'] as String? ?? 'unité',
      seuilAlerte: json['seuil_alerte'] as int? ?? 0,
      actif: json['actif'] as bool? ?? true,
      categorieId: json['categorie_id'] as int?,
      categorieNom: json['categorie_nom'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'nom': nom,
      'description': description,
      'prix_achat': prixAchat.toString(),
      'prix_vente': prixVente.toString(),
      'unite': unite,
      'seuil_alerte': seuilAlerte,
      'actif': actif,
      'categorie_id': categorieId,
      'categorie_nom': categorieNom,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? code,
    String? nom,
    String? description,
    double? prixAchat,
    double? prixVente,
    String? unite,
    int? seuilAlerte,
    bool? actif,
    int? categorieId,
    String? categorieNom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prixAchat: prixAchat ?? this.prixAchat,
      prixVente: prixVente ?? this.prixVente,
      unite: unite ?? this.unite,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      actif: actif ?? this.actif,
      categorieId: categorieId ?? this.categorieId,
      categorieNom: categorieNom ?? this.categorieNom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, code: $code, nom: $nom, prixVente: $prixVente \$, actif: $actif)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}