// Dans transfert_model.dart

import 'package:tek_app/screens/stock/stock_transfers.dart';

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
    print('📥 Parsing Transfert from JSON: $json');
    
    final lignes = (json['lignes'] as List? ?? [])
        .map((l) => TransfertLigne.fromJson(l))
        .toList();

    return Transfert(
      id: json['id'] as int? ?? 0,
      numeroBon: json['numero_bon'] as String? ?? '',
      depotSourceId: json['depot_source_id'] as int? ?? 0,
      depotSourceNom: json['depot_source_nom'] as String? ?? '',
      depotDestinationId: json['depot_destination_id'] as int? ?? 0,
      depotDestinationNom: json['depot_destination_nom'] as String? ?? '',
      dateTransfert: json['date_transfert'] as String? ?? DateTime.now().toIso8601String().split('T').first,
      motif: json['motif'] as String? ?? '',
      statut: json['statut'] as String? ?? 'en_attente',
      lignes: lignes,
      dateValidation: json['date_validation'] as String?,
      dateEffectue: json['date_effectue'] as String?,
      validePar: json['valide_par'] as int?,
      createdBy: json['created_by'] as int? ?? 0,
    );
  }
}