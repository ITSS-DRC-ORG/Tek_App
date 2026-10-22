class Transfert {
  final int id;
  final String numeroBon;
  final int depotSourceId;
  final String depotSourceNom;
  final int depotDestinationId;
  final String depotDestinationNom;
  final String dateTransfert;
  final String motif;
  final String statut;
  final List<TransfertLigne> lignes;
  final String? dateValidation;
  final String? dateEffectue;
  final int? validePar;
  final int createdBy;

  Transfert({
    required this.id,
    required this.numeroBon,
    required this.depotSourceId,
    required this.depotSourceNom,
    required this.depotDestinationId,
    required this.depotDestinationNom,
    required this.dateTransfert,
    required this.motif,
    required this.statut,
    required this.lignes,
    this.dateValidation,
    this.dateEffectue,
    this.validePar,
    required this.createdBy,
  });

  factory Transfert.fromJson(Map<String, dynamic> json) {
    final lignes = (json['lignes'] as List? ?? [])
        .map((l) => TransfertLigne.fromJson(l as Map<String, dynamic>))
        .toList();

    return Transfert(
      id: json['id'] as int? ?? 0,
      numeroBon: json['numero_bon'] as String? ?? '',
      depotSourceId: json['depot_source_id'] as int? ?? 0,
      depotSourceNom: json['depot_source_nom'] as String? ?? '',
      depotDestinationId: json['depot_destination_id'] as int? ?? 0,
      depotDestinationNom: json['depot_destination_nom'] as String? ?? '',
      dateTransfert: json['date_transfert'] as String? ??
          DateTime.now().toIso8601String().split('T').first,
      motif: json['motif'] as String? ?? '',
      statut: json['statut'] as String? ?? 'en_attente',
      lignes: lignes,
      dateValidation: json['date_validation'] as String?,
      dateEffectue: json['date_effectue'] as String?,
      validePar: json['valide_par'] as int?,
      createdBy: json['created_by'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_bon': numeroBon,
      'depot_source_id': depotSourceId,
      'depot_source_nom': depotSourceNom,
      'depot_destination_id': depotDestinationId,
      'depot_destination_nom': depotDestinationNom,
      'date_transfert': dateTransfert,
      'motif': motif,
      'statut': statut,
      'lignes': lignes.map((l) => l.toJson()).toList(),
      'date_validation': dateValidation,
      'date_effectue': dateEffectue,
      'valide_par': validePar,
      'created_by': createdBy,
    };
  }
}

class TransfertLigne {
  final int produitId;
  final int quantite;
  final String? produitNom;
  final String? produitCode;

  TransfertLigne({
    required this.produitId,
    required this.quantite,
    this.produitNom,
    this.produitCode,
  });

  factory TransfertLigne.fromJson(Map<String, dynamic> json) {
    return TransfertLigne(
      produitId: json['produit_id'] as int? ?? 0,
      quantite: json['quantite'] as int? ?? 0,
      produitNom: json['produit_nom'] as String?,
      produitCode: json['produit_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produit_id': produitId,
      'quantite': quantite,
      'produit_nom': produitNom,
      'produit_code': produitCode,
    };
  }
}