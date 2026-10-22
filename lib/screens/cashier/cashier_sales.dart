import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import 'package:tek_app/screens/cashier/cashier_new_sale.dart';
import 'package:tek_app/screens/cashier/print/receipt_printer.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && widget.initialFilter!.isNotEmpty) {
      _selectedFilter = _normalizeFilter(widget.initialFilter!);
    }
    _loadSales();
  }

  String _normalizeFilter(String input) {
    switch (input) {
      case 'en_cours':
        return 'en_cours';
      case 'payee':
        return 'payee';
      case 'livree':
        return 'livree';
      case 'annulee':
        return 'annulee';
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
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredSales = _sales.where((sale) {
        final client = (sale['client_nom'] as String? ?? '').toLowerCase();
        final numero = (sale['numero_facture'] as String? ?? '').toLowerCase();
        final matchesSearch = client.contains(query) || numero.contains(query);

        final statut = sale['statut'] as String? ?? 'en_cours';
        final matchesFilter = _selectedFilter == 'Toutes' || statut == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF107C41)
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
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
  // VALIDATION D'ENCAISSEMENT
  // ---------------------------------------------------------------------------
  Future<void> _validateInvoice(Map<String, dynamic> sale) async {
    final total = double.tryParse(sale['total_ttc']?.toString() ?? '0') ?? 0;
    final client = sale['client_nom'] ?? 'Client de passage';
    final numero = sale['numero_facture'] ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22),
        actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2FB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.payments_outlined, color: Color(0xFF0067C0), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Encaisser la facture',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmez-vous la perception du règlement en espèces pour le ticket $numero ?',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogInfoRow('Client', client),
                  const SizedBox(height: 4),
                  _buildDialogInfoRow('Montant net', '${total.toStringAsFixed(2)} \$'),
                  const SizedBox(height: 4),
                  _buildDialogInfoRow('Mode de paiement', 'CASH (USD)'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Encaisser le ticket',
              style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        _showSnackBar('Utilisateur non connecté', const Color(0xFFC42B1C));
        return;
      }

      final service = AdminService(user.token);
      final result = await service.validateInvoiceWithMode(
        sale['id'] as int,
        modePaiement: 'cash',
      );

      if (result['success'] == true) {
        _showSnackBar('Facture encaissée avec succès', const Color(0xFF107C41));
        _loadSales();
      } else {
        _showSnackBar('Erreur: ${result['message'] ?? 'Impossible d\'encaisser'}', const Color(0xFFC42B1C));
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label : ',
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            fontSize: 12.5,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RÉIMPRESSION THERMIQUE
  // ---------------------------------------------------------------------------
  Future<void> _reprintReceipt(Map<String, dynamic> sale) async {
    try {
      final numeroFacture = sale['numero_facture'] as String? ?? '';
      final clientName = sale['client_nom'] as String? ?? 'Client';
      final depotName = sale['depot_source_nom'] as String? ?? 'Dépôt';
      final lignes = sale['lignes'] as List? ?? [];

      double subtotal = 0;
      final printLines = lignes.map((line) {
        final qte = line['quantite'] as int? ?? 0;
        final prix = (line['prix_unitaire'] as num?)?.toDouble() ?? 0.0;
        subtotal += qte * prix;
        return {
          'produit_nom': line['produit_nom'] ?? 'Produit',
          'quantite': qte,
          'prix_unitaire': prix,
        };
      }).toList();

      final remise = double.tryParse(sale['remise']?.toString() ?? '0') ?? 0;
      final total = double.tryParse(sale['total_ttc']?.toString() ?? '0') ?? 0;

      _showReprintDialog(
        saleData: {
          'numero_facture': numeroFacture,
          'mode_livraison': sale['mode_livraison'] ?? 'retrait_magasin',
        },
        lignes: printLines,
        clientName: clientName,
        depotName: depotName,
        subtotal: subtotal,
        remise: remise,
        total: total,
        numeroFacture: numeroFacture,
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
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22),
        actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2FB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.print_outlined, color: Color(0xFF0067C0), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Réimpression du reçu',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aperçu du ticket à réémettre vers l\'imprimante de caisse :',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 12.5,
                color: Color(0xFF64748B),
              ),
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
                _showSnackBar('Reçu réimprimé avec succès', const Color(0xFF107C41));
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
          final qte = line['quantite'] as int? ?? 0;
          final prix = (line['prix_unitaire'] as num?)?.toDouble() ?? 0.0;
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
            const Text(
              'Total Net TTC',
              style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            Text(
              '${total.toStringAsFixed(2)} \$',
              style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0067C0)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
              // 1. Indicateurs Synthétiques avec Ondes Fluides
              _buildSalesMetricsRow(),
              const SizedBox(height: 18),

              // 2. Barre d'outils (Recherche, Filtres, Nouvelle Vente)
              _buildActionBar(isWide),
              const SizedBox(height: 14),

              // 3. Tableau de données Desktop
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x18000000), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0067C0),
                      strokeWidth: 2.2,
                    ),
                  )
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
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildSalesMetricsRow() {
    final total = _sales.length;
    final enCours = _sales.where((s) => (s['statut'] ?? '') == 'en_cours').length;
    final cumulTTC = _sales.fold<double>(0.0, (sum, s) {
      return sum + (double.tryParse(s['total_ttc']?.toString() ?? '0') ?? 0);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 740;

        final cards = [
          _buildWaveMetricCard(
            title: "TOTAL FACTURES",
            value: "$total",
            subtitle: "Transactions au comptoir",
            badge: "Activité",
            icon: Icons.receipt_long_outlined,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "EN COURS D'ENCAISSEMENT",
            value: "$enCours",
            subtitle: "Règlements à valider",
            badge: "À Traiter",
            icon: Icons.hourglass_empty_rounded,
            gradient: const [
              Color(0xFF0A3B5C),
              Color(0xFF165B8C),
              Color(0xFF3A89C9),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "VOLUME GLOBAL TTC",
            value: "${cumulTTC.toStringAsFixed(0)} \$",
            subtitle: "Chiffre d'affaires facturé",
            badge: "Trésorerie",
            icon: Icons.payments_outlined,
            gradient: const [
              Color(0xFF1E293B),
              Color(0xFF334155),
              Color(0xFF475569),
            ],
            waveSeed: 3.6,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[1],
              const SizedBox(height: 12),
              cards[2],
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
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
                Positioned.fill(
                  child: CustomPaint(
                    painter: SalesMetricWavePainter(waveSeed: waveSeed),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icon, color: Colors.white, size: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF94A3B8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.more_horiz_rounded,
                  size: 16,
                  color: Color(0xFFCBD5E1),
                ),
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
    final filters = ['Toutes', 'en_cours', 'payee', 'livree', 'annulee'];
    final labels = ['Toutes', 'En cours', 'Payées', 'Livrées', 'Annulées'];

    return Row(
      children: [
        // Recherche
        SizedBox(
          width: isWide ? 280 : 180,
          height: 38,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _filterSales(),
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher client, numéro...',
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

        const SizedBox(width: 12),

        // Filtres
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

        const SizedBox(width: 12),

        // Bouton Nouvelle Vente
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CashierNewSale(),
                ),
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
                dataRowMaxHeight: 52,
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
                  final total = double.tryParse(sale['total_ttc']?.toString() ?? '0') ?? 0;
                  final client = sale['client_nom'] as String? ?? 'Client de passage';
                  final numero = sale['numero_facture'] as String? ?? '';
                  final date = sale['created_at'] as String? ?? '';
                  final canValidate = status == 'en_cours';

                  String formattedDate = '';
                  try {
                    final dateTime = DateTime.parse(date);
                    formattedDate = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à '
                        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
                        Text(
                          client,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Montant
                      DataCell(
                        Text(
                          '${total.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0067C0),
                            fontSize: 13.5,
                          ),
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
  // 4. LISTE MOBILE
  // ---------------------------------------------------------------------------
  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredSales.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final sale = _filteredSales[index];
        final status = sale['statut'] as String? ?? 'en_cours';
        final total = double.tryParse(sale['total_ttc']?.toString() ?? '0') ?? 0;
        final client = sale['client_nom'] as String? ?? 'Client';
        final numero = sale['numero_facture'] as String? ?? '';
        final canValidate = status == 'en_cours';

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
                  Text(
                    '${total.toStringAsFixed(2)} \$',
                    style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0067C0)),
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
  // BADGE STATUT SOBRE
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
      case 'annulee':
        color = const Color(0xFFC42B1C);
        bgColor = const Color(0xFFFDE8E8);
        label = 'Annulée';
        break;
      default:
        color = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        label = 'En cours';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: kAppFontFamily,
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
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
              _searchCtrl.text.isEmpty ? 'Aucune vente enregistrée' : 'Aucune transaction trouvée',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Cliquez sur "Nouvelle Vente" pour générer votre premier ticket.'
                  : 'Modifiez vos critères ou votre terme de recherche.',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  _searchCtrl.clear();
                  _filterSales();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0067C0),
                  side: const BorderSide(color: Color(0xFF0067C0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Effacer la recherche', style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES DE VENTES
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
        colors: [
          Colors.white.withOpacity(0.20),
          Colors.white.withOpacity(0.02),
        ],
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
  bool shouldRepaint(covariant SalesMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}