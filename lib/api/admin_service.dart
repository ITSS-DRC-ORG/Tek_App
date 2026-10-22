import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tek_app/models/stock_model.dart';
import 'package:tek_app/screens/stock/stock_transfers.dart';
import '../models/transfert_model.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/depot_model.dart';
import '../utils/config.dart';

class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);
  
  @override
  String toString() => message;
}

class AdminService {
  final String token;

  AdminService(this.token);


/// Valide une facture avec un mode de paiement spécifique
Future<Map<String, dynamic>> validateInvoiceWithMode(
  int saleId, {
  String modePaiement = 'especes',
}) async {
  try {
    print('✅ Validation de la facture #$saleId avec mode: $modePaiement');
    
    final body = {
      'mode_paiement': modePaiement,
    };
    
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/ventes/$saleId/paiement'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': json.decode(response.body),
      };
    } else {
      return {
        'success': false,
        'message': 'Erreur: ${response.body}',
      };
    }
  } catch (e) {
    print('❌ Exception dans validateInvoiceWithMode: $e');
    return {
      'success': false,
      'message': e.toString(),
    };
  }
}

/// Valide une facture (admin uniquement) - enregistre le paiement
Future<Map<String, dynamic>> validateInvoice(int saleId) async {
  try {
    print('✅ Validation de la facture #$saleId');
    
    // ✅ Ajouter le mode_paiement requis
    final body = {
      'mode_paiement': 'especes', // ou 'carte', 'mobile_money', etc.
    };
    
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/ventes/$saleId/paiement'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': json.decode(response.body),
      };
    } else if (response.statusCode == 403) {
      return {
        'success': false,
        'message': 'Accès réservé aux administrateurs',
      };
    } else if (response.statusCode == 422) {
      return {
        'success': false,
        'message': 'Données manquantes: ${response.body}',
      };
    } else {
      return {
        'success': false,
        'message': 'Erreur lors de la validation: ${response.body}',
      };
    }
  } catch (e) {
    print('❌ Exception dans validateInvoice: $e');
    return {
      'success': false,
      'message': e.toString(),
    };
  }
}

/// Marque une vente comme livrée
Future<Map<String, dynamic>> deliverSale(int saleId) async {
  try {
    print('🚚 Livraison de la vente #$saleId');
    
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/ventes/$saleId/livrer'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': json.decode(response.body),
      };
    } else {
      return {
        'success': false,
        'message': 'Erreur lors de la livraison',
      };
    }
  } catch (e) {
    print('❌ Exception dans deliverSale: $e');
    return {
      'success': false,
      'message': e.toString(),
    };
  }
}

/// Récupère les top produits
Future<List<Map<String, dynamic>>> getTopProducts({
  String periode = 'mois',
  int limit = 5,
}) async {
  try {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/dashboard/top-produits?periode=$periode&limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((p) => p as Map<String, dynamic>).toList();
    } else {
      throw Exception('Erreur lors de la récupération des top produits');
    }
  } catch (e) {
    print('❌ Exception dans getTopProducts: $e');
    rethrow;
  }
}

/// Récupère la comparaison des ventes
Future<Map<String, dynamic>> getSalesComparison() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/dashboard/comparaison'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors de la récupération de la comparaison');
    }
  } catch (e) {
    print('❌ Exception dans getSalesComparison: $e');
    rethrow;
  }
}

// ---------------------------------------------------------------------
// DASHBOARD STATS
// ---------------------------------------------------------------------

/// Récupère les statistiques du tableau de bord
Future<Map<String, dynamic>> getDashboardStats() async {
  try {
    print('📊 Récupération des statistiques du tableau de bord...');
    
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/dashboard/stats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Statistiques récupérées avec succès');
      return data as Map<String, dynamic>;
    } else {
      print('❌ Erreur: ${response.statusCode}');
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  } catch (e) {
    print('❌ Exception dans getDashboardStats: $e');
    rethrow;
  }
}

/// Récupère l'évolution des ventes
Future<List<Map<String, dynamic>>> getSalesEvolution({int jours = 7}) async {
  try {
    print('📈 Récupération de l\'évolution des ventes sur $jours jours...');
    
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/dashboard/evolution-ventes?jours=$jours'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('✅ Évolution des ventes récupérée');
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Erreur lors de la récupération de l\'évolution des ventes');
    }
  } catch (e) {
    print('❌ Exception dans getSalesEvolution: $e');
    rethrow;
  }
}

/// Récupère les activités récentes
Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 20}) async {
  try {
    print('📋 Récupération des activités récentes...');
    
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/dashboard/activite-recente?limit=$limit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('✅ ${data.length} activités récentes récupérées');
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      print('❌ Erreur: ${response.statusCode}');
      throw Exception('Erreur lors de la récupération des activités récentes');
    }
  } catch (e) {
    print('❌ Exception dans getRecentActivities: $e');
    rethrow;
  }
}

/// Récupère les prévisions et alertes
Future<List<Map<String, dynamic>>> getPrevisions() async {
  try {
    print('🔮 Récupération des prévisions...');
    
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/dashboard/previsions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('✅ ${data.length} prévisions récupérées');
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Erreur lors de la récupération des prévisions');
    }
  } catch (e) {
    print('❌ Exception dans getPrevisions: $e');
    rethrow;
  }
}

// ---------------------------------------------------------------------
// VENTES
// ---------------------------------------------------------------------

// Dans admin_service.dart - Modifier la méthode getSales

Future<List<Map<String, dynamic>>> getSales({
  String? statut,
  int? clientId,
  String? dateDebut,
  String? dateFin,
}) async {
  try {
    print('🛒 Récupération des ventes...');
    
    final Map<String, String> queryParams = {};
    if (statut != null && statut.isNotEmpty) queryParams['statut'] = statut;
    if (clientId != null) queryParams['client_id'] = clientId.toString();
    if (dateDebut != null && dateDebut.isNotEmpty) queryParams['date_debut'] = dateDebut;
    if (dateFin != null && dateFin.isNotEmpty) queryParams['date_fin'] = dateFin;
    
    print('🔍 Filtres: $queryParams');
    
    final uri = Uri.parse('${AppConfig.baseUrl}/ventes/')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('✅ ${data.length} ventes récupérées');
      return data.map((s) => s as Map<String, dynamic>).toList();
    } else {
      print('❌ Erreur: ${response.statusCode}');
      throw Exception('Erreur lors de la récupération des ventes');
    }
  } catch (e) {
    print('❌ Exception dans getSales: $e');
    rethrow;
  }
}

/// Récupère une vente par son ID
Future<Map<String, dynamic>> getSale(int id) async {
  try {
    print('🛒 Récupération de la vente #$id...');
    
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/ventes/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Vente #$id récupérée');
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors de la récupération de la vente');
    }
  } catch (e) {
    print('❌ Exception dans getSale: $e');
    rethrow;
  }
}

  Future<List<dynamic>> getVentesARecuperer({String statut = 'en_attente'}) async {
    final r = await http.get(
      Uri.parse('${AppConfig.baseUrl}/ventes/a-recuperer?statut=$statut'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (r.statusCode == 200) return json.decode(r.body);
    throw Exception('Erreur chargement stocks à récupérer (${r.statusCode})');
  }

  Future<dynamic> validerSortie(int venteId) async {
    final r = await http.post(
      Uri.parse('${AppConfig.baseUrl}/ventes/$venteId/valider-sortie'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (r.statusCode == 200) return json.decode(r.body);
    throw Exception('Erreur validation sortie (${r.statusCode})');
  }

  Future<dynamic> annulerRetrait(int venteId) async {
    final r = await http.post(
      Uri.parse('${AppConfig.baseUrl}/ventes/$venteId/annuler-retrait'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (r.statusCode == 200) return json.decode(r.body);
    throw Exception('Erreur annulation retrait (${r.statusCode})');
  }
// Dans admin_service.dart

/// Crée une nouvelle vente
  Future<Map<String, dynamic>> createSale({
    required int clientId,
    required int depotSourceId,
    required String dateVente,
    required List<Map<String, dynamic>> lignes,
    double remise = 0.0,
    String modeLivraison = 'retrait_magasin',
    String? notes,
    String? dateRetrait,   // NOUVEAU : null = vente immédiate
  }) async {
    try {
      print('🛒 Création d\'une nouvelle vente...');
      print('👤 Client: $clientId, Dépôt: $depotSourceId');
      print('📦 ${lignes.length} produits');

      final body = <String, dynamic>{
        'client_id': clientId,
        'depot_source_id': depotSourceId,
        'date_vente': dateVente,
        'remise': remise,
        'remise_type': 'pourcentage',
        'mode_livraison': modeLivraison,
        'notes': notes,
        'lignes': lignes,
        'type_vente': dateRetrait != null ? 'a_retirer' : 'normale',
        if (dateRetrait != null) 'date_retrait': dateRetrait,
      };

      print('📤 Body: ${jsonEncode(body)}');

      final url = '${AppConfig.baseUrl}/ventes/';
      print('📍 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      // Gestion 307
      if (response.statusCode == 307) {
        final location = response.headers['location'];
        print('🔄 Redirection vers: $location');
        if (location != null) {
          final redirectResponse = await http.post(
            Uri.parse(location),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          );
          print('📡 Redirect Status: ${redirectResponse.statusCode}');
          print('📡 Redirect Response: ${redirectResponse.body}');
          if (redirectResponse.statusCode == 200 || redirectResponse.statusCode == 201) {
            final data = json.decode(redirectResponse.body);
            print('✅ Vente créée avec succès');
            return data as Map<String, dynamic>;
          } else {
            throw Exception('Erreur lors de la création de la vente: ${redirectResponse.body}');
          }
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Vente créée avec succès');
        return data as Map<String, dynamic>;
      } else {
        throw Exception('Erreur lors de la création de la vente: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception dans createSale: $e');
      rethrow;
    }
  }
/// Enregistre un paiement pour une vente
Future<Map<String, dynamic>> paySale(int id) async {
  try {
    print('💳 Enregistrement du paiement pour la vente #$id...');
    
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/ventes/$id/paiement'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      print('✅ Paiement enregistré avec succès');
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors du paiement de la vente: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception dans paySale: $e');
    rethrow;
  }
}

/// Annule une vente
Future<Map<String, dynamic>> cancelSale(int id) async {
  try {
    print('❌ Annulation de la vente #$id...');
    
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/ventes/$id/annuler'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('success') && data['success'] == false) {
        throw Exception(data['error'] ?? 'Erreur lors de l\'annulation');
      }
      print('✅ Vente #$id annulée avec succès');
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors de l\'annulation de la vente: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception dans cancelSale: $e');
    rethrow;
  }
}

// ---------------------------------------------------------------------
// STATISTIQUES DES VENTES
// ---------------------------------------------------------------------

/// Récupère les statistiques journalières des ventes
Future<Map<String, dynamic>> getSalesStatsJournalieres({String? date}) async {
  try {
    print('📊 Récupération des statistiques journalières...');
    
    final uri = date != null
        ? Uri.parse('${AppConfig.baseUrl}/ventes/stats/journalieres?date=$date')
        : Uri.parse('${AppConfig.baseUrl}/ventes/stats/journalieres');
    
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Statistiques journalières récupérées');
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  } catch (e) {
    print('❌ Exception dans getSalesStatsJournalieres: $e');
    rethrow;
  }
}

/// Valide un transfert
Future<Transfert> validerTransfert(int id) async {
  try {
    print('📤 Validation du transfert #$id');
    
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/transferts/$id/valider'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    // ✅ Gestion des erreurs de permission
    if (response.statusCode == 403) {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] as String? ?? 'Accès non autorisé';
      print('❌ Permission refusée: $errorMessage');
      throw PermissionException(errorMessage);
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = json.decode(response.body);
        return Transfert.fromJson(data);
      } catch (e) {
        print('❌ Erreur de parsing: $e');
        if (response.body.isEmpty || response.body == '{}') {
          print('⚠️ Réponse vide, retour du transfert non parsé');
          return await getTransfert(id);
        }
        rethrow;
      }
    } else {
      print('❌ Erreur API: ${response.statusCode} - ${response.body}');
      throw Exception('Erreur lors de la validation du transfert: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception dans validerTransfert: $e');
    rethrow;
  }
}

/// Effectue un transfert
Future<Transfert> effectuerTransfert(int id) async {
  try {
    print('📤 Effectuation du transfert #$id');
    
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/transferts/$id/effectuer'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    // ✅ Gestion des erreurs de permission
    if (response.statusCode == 403) {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] as String? ?? 'Accès non autorisé';
      print('❌ Permission refusée: $errorMessage');
      throw PermissionException(errorMessage);
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = json.decode(response.body);
        return Transfert.fromJson(data);
      } catch (e) {
        print('❌ Erreur de parsing: $e');
        if (response.body.isEmpty || response.body == '{}') {
          print('⚠️ Réponse vide, retour du transfert non parsé');
          return await getTransfert(id);
        }
        rethrow;
      }
    } else {
      throw Exception('Erreur lors de l\'effectuation du transfert: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception dans effectuerTransfert: $e');
    rethrow;
  }
}

/// Annule un transfert
Future<Transfert> annulerTransfert(int id) async {
  try {
    print('📤 Annulation du transfert #$id');
    
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/transferts/$id/annuler'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    // ✅ Gestion des erreurs de permission
    if (response.statusCode == 403) {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] as String? ?? 'Accès non autorisé';
      print('❌ Permission refusée: $errorMessage');
      throw PermissionException(errorMessage);
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('success') && data['success'] == false) {
          throw Exception(data['error'] ?? 'Erreur lors de l\'annulation');
        }
        return Transfert.fromJson(data);
      } catch (e) {
        print('❌ Erreur de parsing: $e');
        if (response.body.isEmpty || response.body == '{}') {
          print('⚠️ Réponse vide, retour du transfert non parsé');
          return await getTransfert(id);
        }
        rethrow;
      }
    } else {
      throw Exception('Erreur lors de l\'annulation du transfert: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception dans annulerTransfert: $e');
    rethrow;
  }
}

/// Crée un nouveau transfert
Future<Transfert> createTransfert({
  required int depotSourceId,
  required int depotDestinationId,
  required String motif,
  required List<TransfertLigne> lignes,
}) async {
  try {
    print('📤 Création d\'un nouveau transfert...');
    print('🏢 Source: $depotSourceId, Destination: $depotDestinationId');
    print('📝 Motif: $motif');
    print('📦 ${lignes.length} produits');

    if (lignes.isEmpty) {
      throw Exception('Ajoutez au moins un produit au transfert');
    }
    if (depotSourceId == depotDestinationId) {
      throw Exception('Les dépôts source et destination doivent être différents');
    }

    final body = {
      'depot_source_id': depotSourceId,
      'depot_destination_id': depotDestinationId,
      'date_transfert': DateTime.now().toIso8601String().split('T').first,
      'motif': motif,
      'lignes': lignes.map((l) => {
        'produit_id': l.produitId,
        'quantite': l.quantite,
      }).toList(),
    };

    print('📤 Body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/transferts/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response Body: ${response.body}');

    // ✅ Gestion des erreurs de permission
    if (response.statusCode == 403) {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] as String? ?? 'Accès non autorisé';
      print('❌ Permission refusée: $errorMessage');
      throw PermissionException(errorMessage);
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return Transfert.fromJson(data);
        } else {
          throw Exception('Format de réponse inattendu');
        }
      } catch (e) {
        print('❌ Erreur de parsing: $e');
        rethrow;
      }
    } else if (response.statusCode == 422) {
      final errorData = json.decode(response.body);
      print('❌ Erreur de validation: $errorData');
      throw Exception('Erreur de validation: $errorData');
    } else {
      throw Exception('Erreur lors de la création du transfert: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception dans createTransfert: $e');
    rethrow;
  }
}

/// Récupère un transfert par son ID
Future<Transfert> getTransfert(int id) async {
  try {
    print('📤 Récupération du transfert #$id');
    
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/transferts/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      return Transfert.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la récupération du transfert');
    }
  } catch (e) {
    print('❌ Exception dans getTransfert: $e');
    rethrow;
  }
}

// Dans admin_service.dart

/// Récupère tous les transferts
Future<List<Transfert>> getTransferts() async {
  try {
    print('📤 Récupération des transferts...');
    
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/transferts/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body);
        print('✅ ${data.length} transferts récupérés');
        
        if (data.isEmpty) {
          print('ℹ️ Aucun transfert trouvé');
          return [];
        }
        
        final transferts = data.map((t) {
          try {
            return Transfert.fromJson(t as Map<String, dynamic>);
          } catch (e) {
            print('⚠️ Erreur de parsing pour un transfert: $e');
            print('⚠️ Data: $t');
            return null;
          }
        }).whereType<Transfert>().toList();
        
        print('✅ ${transferts.length} transferts parsés avec succès');
        return transferts;
        
      } catch (e) {
        print('❌ Erreur de parsing JSON: $e');
        throw Exception('Erreur de parsing des données: $e');
      }
    } else if (response.statusCode == 401) {
      print('❌ Token expiré ou invalide');
      throw Exception('Session expirée, veuillez vous reconnecter');
    } else if (response.statusCode == 404) {
      print('ℹ️ Aucun transfert trouvé');
      return [];
    } else {
      print('❌ Erreur API: ${response.statusCode}');
      throw Exception('Erreur lors de la récupération des transferts: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Exception dans getTransferts: $e');
    rethrow;
  }
}



/// Récupère tous les stocks (avec filtres optionnels)
Future<List<Stock>> getStocks({
  int? depotId,
  bool? enAlerte,
}) async {
  final queryParams = <String, String>{};
  if (depotId != null) queryParams['depot_id'] = depotId.toString();
  if (enAlerte != null) queryParams['en_alerte'] = enAlerte.toString();

  final uri = Uri.parse('${AppConfig.baseUrl}/stocks/')
      .replace(queryParameters: queryParams);

  final response = await http.get(
    uri,
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((s) => Stock.fromJson(s)).toList();
  } else {
    throw Exception('Erreur lors du chargement des stocks');
  }
}

/// Récupère les stocks d'un dépôt spécifique
Future<List<Stock>> getStocksByDepot(int depotId) async {
  final response = await http.get(
    Uri.parse('${AppConfig.baseUrl}/stocks/depot/$depotId'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((s) => Stock.fromJson(s)).toList();
  } else {
    throw Exception('Erreur lors du chargement des stocks du dépôt');
  }
}

/// Récupère le stock d'un produit dans un dépôt spécifique
Future<Stock> getStockByProductAndDepot(int produitId, int depotId) async {
  final response = await http.get(
    Uri.parse('${AppConfig.baseUrl}/stocks/produit/$produitId/depot/$depotId'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return Stock.fromJson(json.decode(response.body));
  } else {
    throw Exception('Erreur lors du chargement du stock');
  }
}

/// Récupère les alertes de stock
Future<List<Stock>> getStockAlertes() async {
  final response = await http.get(
    Uri.parse('${AppConfig.baseUrl}/stocks/alertes'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((s) => Stock.fromJson(s)).toList();
  } else {
    throw Exception('Erreur lors du chargement des alertes');
  }
}

// Dans admin_service.dart

// Dans admin_service.dart

/// Ajuste le stock d'un produit dans un dépôt
Future<Stock> ajusterStock({
  required int produitId,
  required int depotId,
  required int quantite,
  int? quantiteMinimale,
  int? quantiteMaximale,
}) async {
  try {
    print('📤 Ajustement stock - Produit: $produitId, Dépôt: $depotId, Quantité: $quantite');
    
    // ✅ L'API attend 'nouvelle_quantite' et non 'quantite'
    final body = {
      'produit_id': produitId,
      'depot_id': depotId,
      'nouvelle_quantite': quantite,  // ✅ Changement clé
    };
    
    // Ajouter les champs optionnels s'ils sont fournis
    if (quantiteMinimale != null) {
      body['quantite_minimale'] = quantiteMinimale;
    }
    if (quantiteMaximale != null) {
      body['quantite_maximale'] = quantiteMaximale;
    }
    
    print('📤 Body: $body');
    
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/stocks/ajuster'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📡 Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      print('✅ Stock ajusté avec succès');
      return Stock.fromJson(data);
    } else {
      print('❌ Erreur API: ${response.statusCode} - ${response.body}');
      throw Exception('Erreur lors de l\'ajustement du stock: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception dans ajusterStock: $e');
    rethrow;
  }
}

/// Récupère l'historique des mouvements d'un produit dans un dépôt
Future<List<StockMouvement>> getStockHistorique(
  int produitId,
  int depotId, {
  int limit = 20,
}) async {
  final response = await http.get(
    Uri.parse(
      '${AppConfig.baseUrl}/stocks/historique/$produitId/$depotId?limit=$limit',
    ),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((m) => StockMouvement.fromJson(m)).toList();
  } else {
    throw Exception('Erreur lors du chargement de l\'historique');
  }
}

/// Met à jour un utilisateur
Future<UserModel> updateUser(
  int id, {
  required String username,
  required String email,
  required String nom,
  required String prenom,
  required UserRole role,
  int? depotId,
  bool actif = true,
}) async {
  final response = await http.put(
    Uri.parse('${AppConfig.baseUrl}/auth/users/$id'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'username': username,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'role': role.name,
      'depot_id': depotId,
      'actif': actif,
    }),
  );

  if (response.statusCode == 200) {
    return UserModel.fromJson(json.decode(response.body), token);
  } else {
    throw Exception('Erreur lors de la mise à jour de l\'utilisateur');
  }
}

/// Supprime un utilisateur
Future<bool> deleteUser(int id) async {
  final response = await http.delete(
    Uri.parse('${AppConfig.baseUrl}/auth/users/$id'),
    headers: {'Authorization': 'Bearer $token'},
  );

  return response.statusCode == 200 || response.statusCode == 204;
}

  /// Récupère tous les utilisateurs
  Future<List<UserModel>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/auth/users'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((u) => UserModel.fromJson(u, token)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des utilisateurs");
    }
  }

  /// Récupère le profil de l'utilisateur connecté
  Future<UserModel> getMe() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body), token);
    } else {
      throw Exception("Erreur lors de la récupération du profil");
    }
  }

  /// Crée un nouvel utilisateur
  Future<UserModel> createUser({
    required String username,
    required String email,
    required String nom,
    required String prenom,
    required String password,
    required UserRole role,
    int? depotId,
    bool actif = true,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/register'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'password': password,
        'role': role.name,
        'depot_id': depotId,
        'actif': actif,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return UserModel.fromJson(json.decode(response.body), token);
    } else {
      throw Exception('Erreur lors de la création de l\'utilisateur: ${response.body}');
    }
  }

  // ---------------------------------------------------------------------
  // DÉPÔTS - CRUD COMPLET
  // ---------------------------------------------------------------------

  /// CREATE - Crée un nouveau dépôt
  Future<Depot> createDepot({
    required String nom,
    required String type,
    String? adresse,
    bool estMagasin = false,
    bool aCaisse = false,
    bool actif = true,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/depots/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nom': nom,
        'type': type,
        'adresse': adresse,
        'est_magasin': estMagasin,
        'a_caisse': aCaisse,
        'actif': actif,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Depot.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la création du dépôt: ${response.body}');
    }
  }

  /// READ - Récupère la liste de tous les dépôts
  Future<List<Depot>> getDepots() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/depots/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((d) => Depot.fromJson(d)).toList();
    } else {
      throw Exception('Erreur lors du chargement des dépôts');
    }
  }

  /// READ - Récupère un dépôt par son ID
  Future<Depot> getDepot(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/depots/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Depot.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors du chargement du dépôt');
    }
  }

  /// READ - Récupère le magasin (dépôt de type magasin)
  Future<Depot> getMagasin() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/depots/magasin'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Depot.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors du chargement du magasin');
    }
  }

  /// READ - Récupère la liste des grands dépôts
  Future<List<Depot>> getGrandsDepots() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/depots/grands-depots'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((d) => Depot.fromJson(d)).toList();
    } else {
      throw Exception('Erreur lors du chargement des grands dépôts');
    }
  }

  /// UPDATE - Met à jour un dépôt existant
  Future<Depot> updateDepot(
    int id, {
    required String nom,
    required String type,
    String? adresse,
    required bool estMagasin,
    required bool aCaisse,
    required bool actif,
  }) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/depots/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nom': nom,
        'type': type,
        'adresse': adresse,
        'est_magasin': estMagasin,
        'a_caisse': aCaisse,
        'actif': actif,
      }),
    );

    if (response.statusCode == 200) {
      return Depot.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la mise à jour du dépôt: ${response.body}');
    }
  }

  /// DELETE - Supprime un dépôt
  Future<bool> deleteDepot(int id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/depots/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ---------------------------------------------------------------------
  // PRODUITS
  // ---------------------------------------------------------------------

  /// Récupère tous les produits
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/produits/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((p) => Product.fromJson(p)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des produits");
    }
  }

  /// Récupère les produits avec filtres
  Future<List<Product>> getProducts({
    String? search,
    int? categorieId,
    bool? actif,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categorieId != null) queryParams['categorie_id'] = categorieId.toString();
    if (actif != null) queryParams['actif'] = actif.toString();

    final uri = Uri.parse('${AppConfig.baseUrl}/produits/')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((p) => Product.fromJson(p)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des produits");
    }
  }

  /// Récupère un produit par son ID
  Future<Product> getProduct(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/produits/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors du chargement du produit');
    }
  }

  /// Crée un nouveau produit
  Future<Product> createProduct({
    required String code,
    required String nom,
    String? description,
    required int categorieId,
    required double prixAchat,
    required double prixVente,
    required String unite,
    int seuilAlerte = 10,
    bool actif = true,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/produits/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'code': code,
        'nom': nom,
        'description': description,
        'categorie_id': categorieId,
        'prix_achat': prixAchat.toString(),
        'prix_vente': prixVente.toString(),
        'unite': unite,
        'seuil_alerte': seuilAlerte,
        'actif': actif,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la création du produit: ${response.body}');
    }
  }

  /// Met à jour un produit
  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/produits/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la mise à jour du produit');
    }
  }

  // ---------------------------------------------------------------------
// FINANCE / CAISSE
// ---------------------------------------------------------------------

  Future<Map<String, dynamic>> getSoldeCaisse({String? dateRef}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/caisse/solde')
        .replace(queryParameters: dateRef != null ? {'date_jour': dateRef} : null);
    final r = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode == 200) return json.decode(r.body);
    throw Exception('Erreur solde caisse (${r.statusCode})');
  }

  Future<Map<String, dynamic>> createMouvementCaisse({
    required String type, // 'entree' | 'sortie'
    required double montant,
    String? description,
    String? categorie,
  }) async {
    final body = <String, dynamic>{
      'type_mouvement': type,
      'montant': montant,
      if (description != null && description.isNotEmpty) 'description': description,
      if (categorie != null) 'categorie': categorie,
    };
    final r = await http.post(
      Uri.parse('${AppConfig.baseUrl}/caisse/mouvements'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode == 201) return json.decode(r.body);
    throw Exception('Erreur mouvement caisse: ${r.body}');
  }

  Future<List<dynamic>> getMouvementsCaisse({
    String? dateDebut,
    String? dateFin,
    String? type,
    int limit = 200,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (dateDebut != null) params['date_debut'] = dateDebut;
    if (dateFin != null) params['date_fin'] = dateFin;
    if (type != null) params['type_mouvement'] = type;
    final uri = Uri.parse('${AppConfig.baseUrl}/caisse/mouvements')
        .replace(queryParameters: params);
    final r = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode == 200) return json.decode(r.body);
    throw Exception('Erreur mouvements (${r.statusCode})');
  }

  Future<Map<String, dynamic>> getRapportJournalierCaisse({String? dateJour}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/caisse/rapport/journalier')
        .replace(queryParameters: dateJour != null ? {'date_jour': dateJour} : null);
    final r = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode == 200) return json.decode(r.body);
    throw Exception('Erreur rapport journalier');
  }

  Future<Map<String, dynamic>> getRapportMensuelCaisse({
    required int annee,
    required int mois,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/caisse/rapport/mensuel')
        .replace(queryParameters: {'annee': '$annee', 'mois': '$mois'});
    final r = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode == 200) return json.decode(r.body);
    throw Exception('Erreur rapport mensuel');
  }

  /// Supprime un produit
  Future<bool> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/produits/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ---------------------------------------------------------------------
  // CATÉGORIES
  // ---------------------------------------------------------------------

  /// Récupère toutes les catégories

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/categories/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Erreur chargement catégories: ${response.statusCode}');
    }
  }

  /// Crée une catégorie
  Future<dynamic> createCategory(String nom, String description) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/categories/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nom': nom,
        'description': description,
        'actif': true,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la création de la catégorie');
    }
  }

  // ---------------------------------------------------------------------
  // CLIENTS
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getClients() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/clients/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Erreur chargement clients: ${response.statusCode}');
    }
  }


  /// Crée un client
  Future<dynamic> createClient(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/clients/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la création du client');
    }
  }

  /// Met à jour un client
  Future<dynamic> updateClient(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/clients/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la mise à jour du client');
    }
  }

  /// Supprime un client
  Future<bool> deleteClient(int id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/clients/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ---------------------------------------------------------------------
  // FOURNISSEURS
  // ---------------------------------------------------------------------

  /// Récupère tous les fournisseurs
  Future<List<Map<String, dynamic>>> getFournisseurs() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/fournisseurs/'),  // ✅ slash ajouté
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Erreur chargement fournisseurs: ${response.statusCode}');
    }
  }

  /// Crée un fournisseur
  Future<dynamic> createFournisseur(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/fournisseurs/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la création du fournisseur');
    }
  }

  // Dans admin_service.dart

/// Met à jour le profil utilisateur
Future<UserModel> updateProfile({
  required String nom,
  required String prenom,
  required String email,
}) async {
  final response = await http.put(
    Uri.parse('${AppConfig.baseUrl}/auth/profile'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'nom': nom,
      'prenom': prenom,
      'email': email,
    }),
  );

  if (response.statusCode == 200) {
    return UserModel.fromJson(json.decode(response.body), token);
  } else {
    throw Exception('Erreur lors de la mise à jour du profil: ${response.body}');
  }
}

/// Change le mot de passe
Future<bool> changePassword({
  required String oldPassword,
  required String newPassword,
}) async {
  final response = await http.post(
    Uri.parse('${AppConfig.baseUrl}/auth/change-password'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'old_password': oldPassword,
      'new_password': newPassword,
    }),
  );

  return response.statusCode == 200;
}
}