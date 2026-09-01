import 'package:flutter/material.dart';

/// Modèle représentant le stock d'un produit dans un dépôt
class Stock {
  final int id;
  final int produitId;
  final int depotId;
  final int quantite;
  final int quantiteMinimale;
  final int quantiteMaximale;
  final bool enAlerte;
  final String? produitNom;
  final String? produitCode;
  final String? depotNom;
  final DateTime createdAt;
  final DateTime updatedAt;

  Stock({
    required this.id,
    required this.produitId,
    required this.depotId,
    required this.quantite,
    required this.quantiteMinimale,
    required this.quantiteMaximale,
    required this.enAlerte,
    this.produitNom,
    this.produitCode,
    this.depotNom,
    required this.createdAt,
    required this.updatedAt,
  });

 // Dans stock_model.dart - Assurez-vous que fromJson est correct

factory Stock.fromJson(Map<String, dynamic> json) {
  print('📥 Parsing Stock from JSON: $json');
  
  return Stock(
    id: json['id'] as int? ?? 0,
    produitId: json['produit_id'] as int? ?? 0,
    depotId: json['depot_id'] as int? ?? 0,
    quantite: json['quantite'] as int? ?? 0,
    quantiteMinimale: json['quantite_minimale'] as int? ?? 10,
    quantiteMaximale: json['quantite_maximale'] as int? ?? 500,
    enAlerte: json['en_alerte'] as bool? ?? false,
    produitNom: json['produit_nom'] as String?,
    produitCode: json['produit_code'] as String?,
    depotNom: json['depot_nom'] as String?,
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
      'produit_id': produitId,
      'depot_id': depotId,
      'quantite': quantite,
      'quantite_minimale': quantiteMinimale,
      'quantite_maximale': quantiteMaximale,
      'en_alerte': enAlerte,
      'produit_nom': produitNom,
      'produit_code': produitCode,
      'depot_nom': depotNom,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Stock copyWith({
    int? id,
    int? produitId,
    int? depotId,
    int? quantite,
    int? quantiteMinimale,
    int? quantiteMaximale,
    bool? enAlerte,
    String? produitNom,
    String? produitCode,
    String? depotNom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Stock(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      depotId: depotId ?? this.depotId,
      quantite: quantite ?? this.quantite,
      quantiteMinimale: quantiteMinimale ?? this.quantiteMinimale,
      quantiteMaximale: quantiteMaximale ?? this.quantiteMaximale,
      enAlerte: enAlerte ?? this.enAlerte,
      produitNom: produitNom ?? this.produitNom,
      produitCode: produitCode ?? this.produitCode,
      depotNom: depotNom ?? this.depotNom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Stock(produitId: $produitId, depotId: $depotId, quantite: $quantite)';
}

/// Modèle pour l'historique des mouvements de stock
class StockMouvement {
  final int id;
  final int produitId;
  final int depotId;
  final int ancienneQuantite;
  final int nouvelleQuantite;
  final String typeMouvement;
  final int? referenceId;
  final String? referenceType;
  final DateTime dateMouvement;
  final int createdBy;

  StockMouvement({
    required this.id,
    required this.produitId,
    required this.depotId,
    required this.ancienneQuantite,
    required this.nouvelleQuantite,
    required this.typeMouvement,
    this.referenceId,
    this.referenceType,
    required this.dateMouvement,
    required this.createdBy,
  });

  factory StockMouvement.fromJson(Map<String, dynamic> json) {
    return StockMouvement(
      id: json['id'] as int,
      produitId: json['produit_id'] as int,
      depotId: json['depot_id'] as int,
      ancienneQuantite: json['ancienne_quantite'] as int,
      nouvelleQuantite: json['nouvelle_quantite'] as int,
      typeMouvement: json['type_mouvement'] as String,
      referenceId: json['reference_id'] as int?,
      referenceType: json['reference_type'] as String?,
      dateMouvement: DateTime.parse(json['date_mouvement'] as String),
      createdBy: json['created_by'] as int,
    );
  }

  String get typeLabel {
    switch (typeMouvement) {
      case 'entree':
        return 'Entrée';
      case 'sortie':
        return 'Sortie';
      case 'ajustement':
        return 'Ajustement';
      default:
        return typeMouvement;
    }
  }

  Color get typeColor {
    switch (typeMouvement) {
      case 'entree':
        return Colors.green;
      case 'sortie':
        return Colors.red;
      case 'ajustement':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}