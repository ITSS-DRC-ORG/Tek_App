import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/screens/cashier/cashier_new_sale.dart';
import 'package:tek_app/screens/cashier/print/receipt_printer.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

// Helper global : parse une valeur (String, num, null) en double
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class CashierSales extends StatefulWidget {
  final String? initialFilter;
  const CashierSales({super.key, this.initialFilter});

  @override
  State<CashierSales> createState() => _CashierSalesState();
}

class _CashierSalesState extends State<CashierSales> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _filteredSales = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'Toutes';

  // Gestion des dates
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && widget.initialFilter!.isNotEmpty) {
      _selectedFilter = _normalizeFilter(widget.initialFilter!);
    }
    _loadSales();
  }

  bool get _canEncaisser {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user?.role == UserRole.vendeur ||
        user?.role == UserRole.caissier ||
        user?.role == UserRole.admin;
  }

  String _normalizeFilter(String input) {
    switch (input) {
      case 'en_cours':
        return 'en_cours';
      case 'payee':
        return 'payee';
      case 'livree':
        return 'livree';
      default:
        return 'Toutes';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final sales = await service.getSales();

        final sortedSales = sales.map((s) => s as Map<String, dynamic>).toList();
        sortedSales.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] as String? ?? '');
          final dateB = DateTime.tryParse(b['created_at'] as String? ?? '');
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        setState(() {
          _sales = sortedSales;
          _isLoading = false;
        });
        _filterSales();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
  }

  void _filterSales() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredSales = _sales.where((sale) {
        // 1. Filtre Texte
        final client = (sale['client_nom'] as String? ?? sale['client_nom_libre'] as String? ?? '').toLowerCase();
        final numero = (sale['numero_facture'] as String? ?? '').toLowerCase();
        final matchesSearch = client.contains(query) || numero.contains(query);

        // 2. Filtre Statut
        final statut = sale['statut'] as String? ?? 'en_cours';
        final matchesFilter = _selectedFilter == 'Toutes' || statut == _selectedFilter;

        // 3. Filtre Date
        bool matchesDate = true;
        if (_dateDebut != null || _dateFin != null) {
          final createdAtStr = sale['created_at'] as String?;
          if (createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null) {
              final saleDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

              final startDate = _dateDebut != null ? DateTime(_dateDebut!.year, _dateDebut!.month, _dateDebut!.day) : DateTime(2000);
              final endDate = _dateFin != null ? DateTime(_dateFin!.year, _dateFin!.month, _dateFin!.day) : DateTime(2100);

              matchesDate = (saleDate.isAtSameMomentAs(startDate) || saleDate.isAfter(startDate)) &&
                  (saleDate.isAtSameMomentAs(endDate) || saleDate.isBefore(endDate));
            } else {
              matchesDate = false;
            }
          } else {
            matchesDate = false;
          }
        }

        return matchesSearch && matchesFilter && matchesDate;
      }).toList();
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF107C41) ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GESTION DES FILTRES DE DATE
  // ---------------------------------------------------------------------------
  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0067C0),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0067C0),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _dateDebut = picked;
        _dateFin = picked;
      });
      _filterSales();
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateDebut != null && _dateFin != null ? DateTimeRange(start: _dateDebut!, end: _dateFin!) : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0067C0),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0067C0),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _dateDebut = picked.start;
        _dateFin = picked.end;
      });
      _filterSales();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _dateDebut = null;
      _dateFin = null;
    });
    _filterSales();
  }

  // ---------------------------------------------------------------------------
  // VALIDATION D'ENCAISSEMENT (WINDOWS 11 FLUENT 2)
  // ---------------------------------------------------------------------------
  Future<void> _validateInvoice(Map<String, dynamic> sale) async {
    final total = _toDouble(sale['total_ttc']);
    final paye = _toDouble(sale['montant_paye']);
    final restant = _toDouble(sale['montant_restant']);
    final client = sale['client_nom'] ?? sale['client_nom_libre'] ?? 'Client de passage';
    final numero = sale['numero_facture'] ?? '';

    final montantCtrl = TextEditingController(text: restant.toStringAsFixed(2));

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final montantSaisi = double.tryParse(montantCtrl.text) ?? 0;
          final nouveauRestant = (restant - montantSaisi).clamp(0, double.infinity);
          final valide = montantSaisi > 0 && montantSaisi <= restant;

          return AlertDialog(
            backgroundColor: const Color(0xFFFFFFFF),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 22),
            actionsPadding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payments_outlined, color: Color(0xFF0067C0), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Encaisser le règlement',
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Validation de la perception en espèces au comptoir',
                        style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  splashRadius: 16,
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(dialogContext, false),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, thickness: 1, color: Color(0x14000000)),
                  const SizedBox(height: 14),

                  // Synthèse de la créance
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDialogInfoRow('Ticket de vente', 'Facture N° $numero'),
                        const SizedBox(height: 4),
                        _buildDialogInfoRow('Client facturé', client),
                        const SizedBox(height: 4),
                        _buildDialogInfoRow('Montant total TTC', '${total.toStringAsFixed(2)} \$'),
                        const SizedBox(height: 4),
                        _buildDialogInfoRow('Déjà versé', '${paye.toStringAsFixed(2)} \$', color: const Color(0xFF107C41)),
                        const Divider(height: 12, thickness: 1, color: Color(0x12000000)),
                        _buildDialogInfoRow('Reste dû actuel', '${restant.toStringAsFixed(2)} \$', highlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'MONTANT PERÇU (\$ USD) *',
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: montantCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attach_money_rounded, size: 18, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          montantCtrl.text = restant.toStringAsFixed(2);
                          setDialogState(() {});
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2FB),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0x300067C0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.done_all_rounded, size: 13, color: Color(0xFF0067C0)),
                              SizedBox(width: 4),
                              Text('Solder tout (100%)', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0067C0))),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (montantSaisi > 0)
                        Text(
                          'Reste après opération : ${nouveauRestant.toStringAsFixed(2)} \$',
                          style: TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: nouveauRestant > 0 ? const Color(0xFFB45309) : const Color(0xFF107C41),
                          ),
                        ),
                    ],
                  ),
                  if (!valide && montantSaisi > 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Le montant doit être compris entre 0.01 et le reste dû.',
                        style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11, color: Color(0xFFC42B1C), fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Annuler', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 13)),
              ),
              ElevatedButton.icon(
                onPressed: valide ? () => Navigator.pop(dialogContext, true) : null,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(
                  valide ? 'Valider ${montantSaisi.toStringAsFixed(2)} \$' : 'Valider l\'encaissement',
                  style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0067C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (confirm != true) return;

    final montant = double.tryParse(montantCtrl.text) ?? 0;
    if (montant <= 0 || montant > restant) {
      _showSnackBar('Montant saisi invalide', const Color(0xFFD97706));
      return;
    }

    setState(() => _isActionLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        _showSnackBar('Utilisateur non connecté', const Color(0xFFC42B1C));
        return;
      }

      final service = AdminService(user.token);
      final result = await service.validateInvoiceWithMode(sale['id'] as int, modePaiement: 'cash', montant: montant);

      if (result['success'] == true) {
        _showSnackBar('Encaissement de ${montant.toStringAsFixed(2)} \$ validé', const Color(0xFF107C41));
        await _loadSales();
      } else {
        _showSnackBar('Erreur: ${result['message'] ?? 'Impossible d\'encaisser'}', const Color(0xFFC42B1C));
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Widget _buildDialogInfoRow(String label, String value, {bool highlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label :',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? const Color(0xFFC42B1C) : const Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
            color: color ?? (highlight ? const Color(0xFFC42B1C) : const Color(0xFF0F172A)),
            fontSize: highlight ? 13 : 12,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RÉIMPRESSION THERMIQUE (FORMAT POS 80MM)
  // ---------------------------------------------------------------------------
  Future<void> _reprintReceipt(Map<String, dynamic> sale) async {
    try {
      final numeroFacture = sale['numero_facture'] as String? ?? '';
      final clientName = sale['client_nom'] ?? sale['client_nom_libre'] as String? ?? 'Client';
      final depotName = sale['depot_source_nom'] as String? ?? 'Dépôt Principal';
      final lignes = sale['lignes'] as List? ?? [];

      double subtotal = 0;
      final printLines = lignes.map((line) {
        final qte = (line['quantite'] is int) ? line['quantite'] as int : int.tryParse(line['quantite']?.toString() ?? '0') ?? 0;
        final prix = _toDouble(line['prix_unitaire']);
        subtotal += qte * prix;
        return {'produit_nom': line['produit_nom'] ?? 'Produit', 'quantite': qte, 'prix_unitaire': prix};
      }).toList();

      final remise = _toDouble(sale['remise']);
      final total = _toDouble(sale['total_ttc']);
      final montantPaye = _toDouble(sale['montant_paye']);
      final montantRestant = _toDouble(sale['montant_restant']);

      _showReprintDialog(
        saleData: {
          'numero_facture': numeroFacture,
          'mode_livraison': sale['mode_livraison'] ?? 'retrait_magasin',
          'montant_paye': montantPaye,
          'reste_a_payer': montantRestant,
        },
        lignes: printLines,
        clientName: clientName,
        depotName: depotName,
        subtotal: subtotal,
        remise: remise,
        total: total,
        numeroFacture: numeroFacture,
        montantPaye: montantPaye,
        montantRestant: montantRestant,
      );
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
  }

  void _showReprintDialog({
    required Map<String, dynamic> saleData,
    required List<Map<String, dynamic>> lignes,
    required String clientName,
    required String depotName,
    required double subtotal,
    required double remise,
    required double total,
    required String numeroFacture,
    required double montantPaye,
    required double montantRestant,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22),
        actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: const Color(0xFFE8F2FB), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.print_outlined, color: Color(0xFF0067C0), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Réimpression du reçu client',
              style: TextStyle(fontFamily: kAppFontFamily, fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aperçu du ticket format thermique POS 80 mm :',
              style: TextStyle(fontFamily: kAppFontFamily, fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: _buildReceiptPreview(
                numeroFacture: numeroFacture,
                clientName: clientName,
                depotName: depotName,
                lignes: lignes,
                total: total,
                remise: remise,
                montantPaye: montantPaye,
                montantRestant: montantRestant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer', style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ReceiptPrinter.printReceipt(
                  sale: saleData,
                  lines: lignes,
                  clientName: clientName,
                  depotName: depotName,
                  subtotal: subtotal,
                  remise: remise,
                  total: total,
                  numeroFacture: numeroFacture,
                );
                _showSnackBar('Reçu transmis à l\'imprimante', const Color(0xFF107C41));
              } catch (e) {
                _showSnackBar('Erreur d\'impression: ${e.toString()}', const Color(0xFFC42B1C));
              }
            },
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Lancer l\'impression'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview({
    required String numeroFacture,
    required String clientName,
    required String depotName,
    required List<Map<String, dynamic>> lignes,
    required double total,
    required double remise,
    required double montantPaye,
    required double montantRestant,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReceiptLine('Facture', numeroFacture),
        _buildReceiptLine('Client', clientName),
        _buildReceiptLine('Point de vente', depotName),
        const Divider(height: 12, thickness: 1, color: Color(0x12000000)),
        ...lignes.take(3).map((line) {
          final nom = line['produit_nom'] as String? ?? 'Produit';
          final qte = (line['quantite'] is int) ? line['quantite'] as int : int.tryParse(line['quantite']?.toString() ?? '0') ?? 0;
          final prix = _toDouble(line['prix_unitaire']);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$qte x $nom',
                    style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(qte * prix).toStringAsFixed(2)} \$',
                  style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 12, thickness: 1, color: Color(0x12000000)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Net TTC', style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
            Text('${total.toStringAsFixed(2)} \$', style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0067C0))),
          ],
        ),
        if (montantPaye > 0 || montantRestant > 0) ...[
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 1, color: Color(0x12000000)),
          const SizedBox(height: 4),
          _buildReceiptLine('Payé', '\$${montantPaye.toStringAsFixed(2)}'),
          if (montantRestant > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(
                children: [
                  const Text('Reste à payer : ', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFFB45309), fontWeight: FontWeight.w700)),
                  Expanded(child: Text('\$${montantRestant.toStringAsFixed(2)}', style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12.5, color: Color(0xFFB45309), fontWeight: FontWeight.w700))),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildReceiptLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text('$label : ', style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD PRINCIPAL
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F7),
      body: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSalesMetricsRow(), // <-- 4 Cartes statistiques réactives aux filtres
              const SizedBox(height: 18),
              _buildActionBar(isWide),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x18000000), width: 1),
                    boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 3))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0067C0), strokeWidth: 2.2))
                      : _filteredSales.isEmpty
                      ? _buildEmptyState()
                      : isWide
                      ? _buildDesktopDataTable()
                      : _buildMobileList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES (4 CARTES BLOOM RÉACTIVES)
  // ---------------------------------------------------------------------------
  Widget _buildSalesMetricsRow() {
    final total = _filteredSales.length;
    final enCours = _filteredSales.where((s) => (s['statut'] ?? '') == 'en_cours').length;
    final encaissees = _filteredSales.where((s) {
      final statut = s['statut'] as String? ?? '';
      return statut == 'payee' || statut == 'livree';
    }).length;
    final totalRestantDu = _filteredSales.fold<double>(0.0, (acc, s) => acc + _toDouble(s['montant_restant']));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 860;

        final cards = [
          _buildWaveMetricCard(
            title: "TOTAL FACTURES",
            value: "$total",
            subtitle: "Dossiers sélectionnés",
            badge: "Activité",
            icon: Icons.receipt_long_outlined,
            gradient: const [Color(0xFF004E8C), Color(0xFF0067C0), Color(0xFF2886DE)],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "EN COURS",
            value: "$enCours",
            subtitle: "Règlements à clôturer",
            badge: "À Traiter",
            icon: Icons.hourglass_empty_rounded,
            gradient: const [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "ENCAISSÉES",
            value: "$encaissees",
            subtitle: "Tickets soldés & validés",
            badge: "Comptant",
            icon: Icons.check_circle_outline_rounded,
            gradient: const [Color(0xFF0A5C36), Color(0xFF107C41), Color(0xFF2E945D)],
            waveSeed: 3.6,
          ),
          _buildWaveMetricCard(
            title: "RESTE DÛ (CRÉANCES)",
            value: "${totalRestantDu.toStringAsFixed(0)} \$",
            subtitle: "Reliquats à percevoir",
            badge: "À Recouvrer",
            icon: Icons.money_off_csred_rounded,
            gradient: const [Color(0xFF8B1E1E), Color(0xFFC42B1C), Color(0xFFE53935)],
            waveSeed: 4.8,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
            const SizedBox(width: 14),
            Expanded(child: cards[2]),
            const SizedBox(width: 14),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _buildWaveMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required String badge,
    required IconData icon,
    required List<Color> gradient,
    required double waveSeed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 64,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                ),
                Positioned.fill(child: CustomPaint(painter: SalesMetricWavePainter(waveSeed: waveSeed))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(6)),
                        child: Icon(icon, color: Colors.white, size: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(4)),
                        child: Text(badge, style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.6)),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(value, style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(subtitle, style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. BARRE D'ACTIONS & FILTRES
  // ---------------------------------------------------------------------------
  Widget _buildActionBar(bool isWide) {
    final filters = ['Toutes', 'en_cours', 'payee', 'livree'];
    final labels = ['Toutes', 'En cours', 'Payées', 'Livrées'];

    String dateLabel = 'Filtrer par date';
    if (_dateDebut != null && _dateFin != null) {
      if (_dateDebut!.isAtSameMomentAs(_dateFin!)) {
        dateLabel = '${_dateDebut!.day.toString().padLeft(2, '0')}/${_dateDebut!.month.toString().padLeft(2, '0')}/${_dateDebut!.year}';
      } else {
        dateLabel = 'Du ${_dateDebut!.day.toString().padLeft(2, '0')}/${_dateDebut!.month.toString().padLeft(2, '0')} au ${_dateFin!.day.toString().padLeft(2, '0')}/${_dateFin!.month.toString().padLeft(2, '0')}';
      }
    }

    return Row(
      children: [
        // Recherche textuelle
        SizedBox(
          width: isWide ? 250 : 160,
          height: 38,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _filterSales(),
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher ticket, client...',
              hintStyle: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFFA0AEC0), fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                splashRadius: 14,
                icon: const Icon(Icons.clear_rounded, size: 15, color: Color(0xFF6B7280)),
                onPressed: () {
                  _searchCtrl.clear();
                  _filterSales();
                },
              )
                  : null,
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x18000000))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x18000000))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Sélecteur de date propre avec menu contextuel ancré
        SizedBox(
          height: 38,
          child: _dateDebut == null
              ? Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Filtrer par date',
              onSelected: (val) async {
                if (val == 'aujourdhui') {
                  final today = DateTime.now();
                  setState(() {
                    _dateDebut = today;
                    _dateFin = today;
                  });
                  _filterSales();
                } else if (val == 'date_unique') {
                  await _pickSingleDate();
                } else if (val == 'plage') {
                  await _pickDateRange();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'aujourdhui',
                  child: Row(
                    children: [
                      Icon(Icons.today_rounded, size: 16, color: Color(0xFF0067C0)),
                      SizedBox(width: 10),
                      Text('Aujourd\'hui', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'date_unique',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                      SizedBox(width: 10),
                      Text('Choisir un jour précis...', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x18000000)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Text('Date', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
          )
              : Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0067C0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 4),
                  child: Text(
                    dateLabel,
                    style: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF0067C0), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 15, color: Color(0xFF0067C0)),
                  onPressed: _clearDateFilter,
                  splashRadius: 14,
                  tooltip: 'Effacer filtre date',
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Filtres par statut en chips
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(filters.length, (index) {
                final isSelected = _selectedFilter == filters[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(labels[index]),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filters[index];
                        _filterSales();
                      });
                    },
                    selectedColor: const Color(0xFFE8F2FB),
                    backgroundColor: const Color(0xFFFFFFFF),
                    labelStyle: TextStyle(
                      fontFamily: kAppFontFamily,
                      color: isSelected ? const Color(0xFF0067C0) : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? const Color(0xFF0067C0) : const Color(0x18000000)),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Bouton Rafraîchir
        SizedBox(
          height: 38,
          width: 38,
          child: OutlinedButton(
            onPressed: _loadSales,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0x18000000)),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Icon(Icons.refresh_rounded, size: 17),
          ),
        ),

        const SizedBox(width: 8),

        // Bouton Nouvelle Vente
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CashierNewSale()),
              ).then((_) => _loadSales());
            },
            icon: const Icon(Icons.add_rounded, size: 17),
            label: Text(isWide ? "Nouvelle Vente" : "Vendre"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TABLEAU DESKTOP HAUTE LISIBILITÉ
  // ---------------------------------------------------------------------------
  Widget _buildDesktopDataTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingRowHeight: 42,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 56,
                horizontalMargin: 20,
                columnSpacing: 24,
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text("N° FACTURE", style: _headerStyle)),
                  DataColumn(label: Text("DATE & HEURE", style: _headerStyle)),
                  DataColumn(label: Text("CLIENT", style: _headerStyle)),
                  DataColumn(label: Text("TOTAL NET TTC", style: _headerStyle)),
                  DataColumn(label: Text("STATUT", style: _headerStyle)),
                  DataColumn(label: Text("ACTIONS", style: _headerStyle)),
                ],
                rows: _filteredSales.map((sale) {
                  final status = sale['statut'] as String? ?? 'en_cours';
                  final total = _toDouble(sale['total_ttc']);
                  final restant = _toDouble(sale['montant_restant']);
                  final client = sale['client_nom'] as String? ?? sale['client_nom_libre'] as String? ?? 'Client de passage';
                  final numero = sale['numero_facture'] as String? ?? '';
                  final date = sale['created_at'] as String? ?? '';
                  final canValidate = _canEncaisser && (status == 'en_cours') && restant > 0;

                  String formattedDate = '';
                  try {
                    final dateTime = DateTime.parse(date);
                    formattedDate = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                  } catch (_) {
                    formattedDate = date;
                  }

                  return DataRow(
                    cells: [
                      // N° Facture
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0x10000000)),
                          ),
                          child: Text(
                            numero,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      // Date & Heure
                      DataCell(
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ),

                      // Client
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: const Color(0xFFE8F2FB),
                              child: Text(
                                client.isNotEmpty ? client[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  color: Color(0xFF0067C0),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              client,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Montant total & reliquat restant
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${total.toStringAsFixed(2)} \$',
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0067C0),
                                fontSize: 13.5,
                              ),
                            ),
                            if (restant > 0)
                              Text(
                                'Reste : ${restant.toStringAsFixed(2)} \$',
                                style: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC42B1C),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Statut
                      DataCell(_buildStatusBadge(status)),

                      // Actions
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canValidate) ...[
                              ElevatedButton(
                                onPressed: _isActionLoading ? null : () => _validateInvoice(sale),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0067C0),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  textStyle: const TextStyle(
                                    fontFamily: kAppFontFamily,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Text('Encaisser'),
                              ),
                              const SizedBox(width: 8),
                            ],
                            IconButton(
                              icon: const Icon(Icons.print_outlined, size: 17, color: Color(0xFF0067C0)),
                              splashRadius: 14,
                              tooltip: 'Réimprimer le reçu client',
                              onPressed: () => _reprintReceipt(sale),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
    letterSpacing: 0.6,
  );

  // ---------------------------------------------------------------------------
  // 4. LISTE MOBILE DE SECOURS
  // ---------------------------------------------------------------------------
  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredSales.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final sale = _filteredSales[index];
        final status = sale['statut'] as String? ?? 'en_cours';
        final total = _toDouble(sale['total_ttc']);
        final restant = _toDouble(sale['montant_restant']);
        final client = sale['client_nom'] as String? ?? 'Client';
        final numero = sale['numero_facture'] as String? ?? '';
        final canValidate = _canEncaisser && (status == 'en_cours') && restant > 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    numero,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0067C0)),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    client,
                    style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${total.toStringAsFixed(2)} \$',
                        style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0067C0)),
                      ),
                      if (restant > 0)
                        Text(
                          'Reste: ${restant.toStringAsFixed(2)} \$',
                          style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFC42B1C)),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canValidate) ...[
                    ElevatedButton(
                      onPressed: _isActionLoading ? null : () => _validateInvoice(sale),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0067C0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Encaisser', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => _reprintReceipt(sale),
                    icon: const Icon(Icons.print_outlined, size: 15),
                    label: const Text('Reçu'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0x20000000)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BADGES DE STATUT
  // ---------------------------------------------------------------------------
  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    String label;

    switch (status) {
      case 'payee':
        color = const Color(0xFF107C41);
        bgColor = const Color(0xFFE6F4EA);
        label = 'Payée';
        break;
      case 'livree':
        color = const Color(0xFF0067C0);
        bgColor = const Color(0xFFE8F2FB);
        label = 'Livrée';
        break;
      default:
        color = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        label = 'En cours';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label,
        style: TextStyle(fontFamily: kAppFontFamily, color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ÉTAT VIDE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.shopping_cart_outlined, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isEmpty && _dateDebut == null ? 'Aucune vente enregistrée' : 'Aucune transaction trouvée',
              style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              _searchCtrl.text.isEmpty && _dateDebut == null ? 'Cliquez sur "Nouvelle Vente" pour générer votre premier ticket.' : 'Modifiez vos critères ou votre terme de recherche.',
              style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12.5, fontWeight: FontWeight.w400, color: Color(0xFF64748B)),
            ),
            if (_searchCtrl.text.isNotEmpty || _dateDebut != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  _searchCtrl.clear();
                  _clearDateFilter();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0067C0),
                  side: const BorderSide(color: Color(0xFF0067C0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Effacer les filtres', style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DE CAISSE (WINDOWS BLOOM)
// ---------------------------------------------------------------------------
class SalesMetricWavePainter extends CustomPainter {
  final double waveSeed;

  SalesMetricWavePainter({required this.waveSeed});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.20), Colors.white.withOpacity(0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.85);
    path.cubicTo(
      size.width * 0.28,
      size.height * (0.35 + 0.12 * math.sin(waveSeed)),
      size.width * 0.60,
      size.height * (0.95 - 0.12 * math.cos(waveSeed)),
      size.width,
      size.height * 0.40,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, fillPaint);

    final ridgePath = Path();
    ridgePath.moveTo(0, size.height * 0.85);
    ridgePath.cubicTo(
      size.width * 0.28,
      size.height * (0.35 + 0.12 * math.sin(waveSeed)),
      size.width * 0.60,
      size.height * (0.95 - 0.12 * math.cos(waveSeed)),
      size.width,
      size.height * 0.40,
    );
    canvas.drawPath(ridgePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant SalesMetricWavePainter oldDelegate) => oldDelegate.waveSeed != waveSeed;
}