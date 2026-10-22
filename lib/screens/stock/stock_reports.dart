import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';
import '../../models/stock_model.dart';
import '../../models/product_model.dart';
import '../../models/depot_model.dart';
import '../cashier/print/receipt_printer.dart';

class StockReports extends StatefulWidget {
  const StockReports({super.key});

  @override
  State<StockReports> createState() => _StockReportsState();
}

class _StockReportsState extends State<StockReports>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _selectedReport = 'Aucun';
  dynamic _reportData;

  List<Stock> _stocks = [];
  List<Product> _products = [];
  List<Depot> _depots = [];
  List<Stock> _alertes = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isStockStateLoading = false;
  bool _isMouvementsLoading = false;
  bool _isAlertesLoading = false;
  bool _isAnalyseLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final stocks = await service.getStocks();
        final products = await service.getAllProducts();
        final depots = await service.getDepots();
        final alertes = await service.getStockAlertes();

        setState(() {
          _stocks = stocks;
          _products = products;
          _depots = depots;
          _alertes = alertes;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
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
  // HELPERS
  // ---------------------------------------------------------------------------
  Product? _findProduct(int produitId) {
    try {
      return _products.firstWhere((p) => p.id == produitId);
    } catch (_) {
      return null;
    }
  }

  Depot? _findDepot(int depotId) {
    try {
      return _depots.firstWhere((d) => d.id == depotId);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // GÉNÉRATION DES RAPPORTS (Logique Intacte)
  // ---------------------------------------------------------------------------
  void _generateStockReport() async {
    setState(() {
      _isStockStateLoading = true;
      _reportData = null;
      _selectedReport = 'État des stocks';
    });

    await Future.delayed(const Duration(milliseconds: 260));

    final Map<int, Map<String, dynamic>> depotStats = {};
    for (var stock in _stocks) {
      final depot = _findDepot(stock.depotId);
      if (depot == null) continue;

      depotStats.putIfAbsent(
        stock.depotId,
            () => {
          'depot': depot,
          'total_unites': 0,
          'nb_produits': 0,
          'valeur_vente': 0.0,
          'valeur_achat': 0.0,
          'en_alerte': 0,
          'produits': <Map<String, dynamic>>[],
        },
      );

      final product = _findProduct(stock.produitId);
      final entry = depotStats[stock.depotId]!;

      entry['total_unites'] += stock.quantite;
      entry['nb_produits'] += 1;
      entry['valeur_vente'] += stock.quantite * (product?.prixVente ?? 0);
      entry['valeur_achat'] += stock.quantite * (product?.prixAchat ?? 0);

      if (stock.quantite <= stock.quantiteMinimale) {
        entry['en_alerte'] += 1;
      }

      (entry['produits'] as List).add({
        'stock': stock,
        'produit': product,
      });
    }

    setState(() {
      _reportData = depotStats;
      _isStockStateLoading = false;
    });
  }

  void _generateMouvementsReport() async {
    setState(() {
      _isMouvementsLoading = true;
      _reportData = null;
      _selectedReport = 'Mouvements';
    });

    await Future.delayed(const Duration(milliseconds: 260));

    final Map<int, Map<String, dynamic>> parDepot = {};
    for (final s in _stocks) {
      final depot = _findDepot(s.depotId);
      if (depot == null) continue;

      parDepot.putIfAbsent(
        s.depotId,
            () => {'depot': depot, 'total': 0, 'alerte': 0, 'ok': 0},
      );
      parDepot[s.depotId]!['total'] += 1;
      if (s.quantite <= s.quantiteMinimale) {
        parDepot[s.depotId]!['alerte'] += 1;
      } else {
        parDepot[s.depotId]!['ok'] += 1;
      }
    }

    final totalStock = _stocks.fold<int>(0, (sum, s) => sum + s.quantite);
    final alertes =
        _stocks.where((s) => s.quantite <= s.quantiteMinimale).length;
    final ok = _stocks.length - alertes;

    setState(() {
      _reportData = {
        'total_unites': totalStock,
        'nb_lignes': _stocks.length,
        'alertes': alertes,
        'ok': ok,
        'par_depot': parDepot,
      };
      _isMouvementsLoading = false;
    });
  }

  void _generateAlertesReport() async {
    setState(() {
      _isAlertesLoading = true;
      _reportData = null;
      _selectedReport = 'Alertes';
    });

    await Future.delayed(const Duration(milliseconds: 260));

    final alertes = _stocks
        .where((s) => s.quantite <= s.quantiteMinimale)
        .toList()
      ..sort((a, b) => (b.quantiteMinimale - b.quantite)
          .compareTo(a.quantiteMinimale - a.quantite));

    setState(() {
      _reportData = alertes;
      _isAlertesLoading = false;
    });
  }

  void _generateAnalyseReport() async {
    setState(() {
      _isAnalyseLoading = true;
      _reportData = null;
      _selectedReport = 'Analyse';
    });

    await Future.delayed(const Duration(milliseconds: 260));

    final Map<int, Map<String, dynamic>> parProduit = {};
    for (final s in _stocks) {
      parProduit.putIfAbsent(
        s.produitId,
            () => {
          'produit': _findProduct(s.produitId),
          'total': 0,
          'valeur_vente': 0.0,
          'valeur_achat': 0.0,
        },
      );

      final product = _findProduct(s.produitId);
      parProduit[s.produitId]!['total'] += s.quantite;
      parProduit[s.produitId]!['valeur_vente'] +=
          s.quantite * (product?.prixVente ?? 0);
      parProduit[s.produitId]!['valeur_achat'] +=
          s.quantite * (product?.prixAchat ?? 0);
    }

    final sorted = parProduit.values.toList()
      ..sort((a, b) =>
          (b['valeur_vente'] as double).compareTo(a['valeur_vente'] as double));
    final topParValeur = sorted.take(10).toList();

    final sortedQte = parProduit.values.toList()
      ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    final topParQuantite = sortedQte.take(5).toList();

    final totalValeurVente = parProduit.values.fold<double>(
        0, (s, v) => s + (v['valeur_vente'] as double));
    final totalValeurAchat = parProduit.values.fold<double>(
        0, (s, v) => s + (v['valeur_achat'] as double));

    setState(() {
      _reportData = {
        'top_par_valeur': topParValeur,
        'top_par_quantite': topParQuantite,
        'nb_produits': parProduit.length,
        'valeur_vente': totalValeurVente,
        'valeur_achat': totalValeurAchat,
        'marge_potentielle': totalValeurVente - totalValeurAchat,
      };
      _isAnalyseLoading = false;
    });
  }

  // ---------------------------------------------------------------------------
  // EXPORT PDF
  // ---------------------------------------------------------------------------
  Future<void> _exportPDF() async {
    if (_reportData == null || _selectedReport == 'Aucun') {
      _showSnackBar('Veuillez d\'abord générer un rapport', const Color(0xFFD97706));
      return;
    }
    try {
      _showSnackBar('Génération du rapport PDF en cours...', const Color(0xFF0067C0));
      final pdfData = _preparePDFData();
      await ReceiptPrinter.printReport(
        title: 'Rapport $_selectedReport',
        data: pdfData,
        filename:
        'rapport_${_selectedReport.replaceAll(' ', '_').toLowerCase()}.pdf',
      );
      _showSnackBar('PDF généré avec succès', const Color(0xFF107C41));
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
  }

  Map<String, dynamic> _preparePDFData() {
    switch (_selectedReport) {
    // -------------------------------------------------------------------
    // ÉTAT DES STOCKS — un tableau par dépôt
    // -------------------------------------------------------------------
      case 'État des stocks':
        final stats = _reportData as Map<int, Map<String, dynamic>>;
        final sections = <Map<String, dynamic>>[];

        for (final entry in stats.values) {
          final depot = entry['depot'] as Depot;
          final produits = entry['produits'] as List;

          // Synthèse (paires)
          sections.add({
            'title': depot.nom,
            'subtitle':
            '${entry['nb_produits']} produits • ${entry['en_alerte']} en alerte',
            'items': [
              {'label': 'Unités totales', 'value': '${entry['total_unites']}'},
              {
                'label': 'Valeur vente',
                'value': '\$${(entry['valeur_vente'] as double).toStringAsFixed(0)}'
              },
              {
                'label': 'Valeur achat',
                'value': '\$${(entry['valeur_achat'] as double).toStringAsFixed(0)}'
              },
            ],
          });

          // Tableau détaillé (lignes / colonnes)
          final rows = <List<String>>[];
          for (final p in produits) {
            final stock = p['stock'] as Stock;
            final produit = p['produit'] as Product?;
            final valeur = stock.quantite * (produit?.prixVente ?? 0);
            rows.add([
              produit?.nom ?? 'Article #${stock.produitId}',
              '${stock.quantite}',
              '\$${(produit?.prixVente ?? 0).toStringAsFixed(0)}',
              '\$${valeur.toStringAsFixed(0)}',
            ]);
          }
          if (rows.isNotEmpty) {
            sections.add({
              'title': '${depot.nom} — détail des produits',
              'table': {
                'headers': ['Produit', 'Qté', 'P.U.', 'Valeur'],
                'rows': rows,
              },
            });
          }
        }

        return {
          'title': 'État des stocks',
          'subtitle': 'Résumé détaillé par dépôt',
          'sections': sections,
        };

    // -------------------------------------------------------------------
    // MOUVEMENTS — un tableau par dépôt
    // -------------------------------------------------------------------
      case 'Mouvements':
        final data = _reportData as Map<String, dynamic>;
        final parDepot = data['par_depot'] as Map<int, Map<String, dynamic>>;

        final rows = <List<String>>[];
        for (final d in parDepot.values) {
          final depot = d['depot'] as Depot;
          rows.add([
            depot.nom,
            '${d['total']}',
            '${d['ok']}',
            '${d['alerte']}',
          ]);
        }

        return {
          'title': 'Mouvements',
          'subtitle':
          '${data['nb_lignes']} lignes • ${data['total_unites']} unités',
          'sections': [
            {
              'title': 'Synthèse',
              'items': [
                {'label': 'Unités stockées', 'value': '${data['total_unites']}'},
                {'label': 'Lignes actives', 'value': '${data['nb_lignes']}'},
                {'label': 'En alerte', 'value': '${data['alertes']}'},
              ],
            },
            if (rows.isNotEmpty)
              {
                'title': 'Répartition par dépôt',
                'table': {
                  'headers': ['Dépôt', 'Lignes', 'OK', 'Alerte'],
                  'rows': rows,
                },
              },
          ],
        };

    // -------------------------------------------------------------------
    // ALERTES — un seul tableau listant tous les produits
    // -------------------------------------------------------------------
      case 'Alertes':
        final alertes = _reportData as List<Stock>;
        final rows = <List<String>>[];
        for (final a in alertes) {
          final product = _findProduct(a.produitId);
          final depot = _findDepot(a.depotId);
          rows.add([
            product?.nom ?? 'Article #${a.produitId}',
            product?.code ?? '?',
            depot?.nom ?? '?',
            '${a.quantite}',
            '${a.quantiteMinimale}',
            '${a.quantiteMinimale - a.quantite}',
          ]);
        }

        return {
          'title': 'Alertes de stock',
          'subtitle': '${alertes.length} produit(s) sous le seuil',
          'sections': rows.isEmpty
              ? []
              : [
            {
              'title': 'Produits à réapprovisionner',
              'table': {
                'headers': [
                  'Produit',
                  'Code',
                  'Dépôt',
                  'Qté',
                  'Min',
                  'Manquant'
                ],
                'rows': rows,
              },
            },
          ],
        };

    // -------------------------------------------------------------------
    // ANALYSE — synthèse + tableau top produits
    // -------------------------------------------------------------------
      case 'Analyse':
        final data = _reportData as Map<String, dynamic>;
        final topParValeur = data['top_par_valeur'] as List;

        final rows = <List<String>>[];
        for (var i = 0; i < topParValeur.length; i++) {
          final item = topParValeur[i];
          final product = item['produit'] as Product?;
          rows.add([
            '${i + 1}',
            product?.nom ?? 'Article',
            '${item['total']}',
            '\$${(item['valeur_vente'] as double).toStringAsFixed(0)}',
          ]);
        }

        return {
          'title': 'Analyse des stocks',
          'subtitle': '${data['nb_produits']} produits référencés',
          'sections': [
            {
              'title': 'Valeur du stock',
              'items': [
                {
                  'label': 'Valeur vente',
                  'value':
                  '\$${(data['valeur_vente'] as double).toStringAsFixed(0)}'
                },
                {
                  'label': 'Valeur achat',
                  'value':
                  '\$${(data['valeur_achat'] as double).toStringAsFixed(0)}'
                },
                {
                  'label': 'Marge potentielle',
                  'value':
                  '\$${(data['marge_potentielle'] as double).toStringAsFixed(0)}'
                },
              ],
            },
            if (rows.isNotEmpty)
              {
                'title': 'Top produits par valeur',
                'table': {
                  'headers': ['#', 'Produit', 'Qté', 'Valeur'],
                  'rows': rows,
                },
              },
          ],
        };

      default:
        return {'title': 'Rapport', 'subtitle': '', 'sections': []};
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD PRINCIPAL
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Material(
      color: Colors.transparent,
      child: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0067C0),
          strokeWidth: 2.2,
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            if (isWide)
              _buildDesktopReportCards()
            else
              _buildMobileReportCards(),
            const SizedBox(height: 16),
            Expanded(child: _buildReportContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2FB),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.analytics_outlined, color: Color(0xFF0067C0), size: 19),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rapports & Statistiques Logistiques',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Analysez vos valorisations, mouvements et stocks critiques en temps réel',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (_selectedReport != 'Aucun')
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedReport,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF0067C0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _exportPDF,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('Exporter PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0067C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CARTES DE RAPPORTS AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopReportCards() {
    return Row(
      children: [
        Expanded(
          child: _buildReportCard(
            icon: Icons.inventory_2_outlined,
            title: 'État des stocks',
            subtitle: 'Détail par dépôt',
            badge: 'Inventaire',
            gradient: const [Color(0xFF004E8C), Color(0xFF0067C0), Color(0xFF2886DE)],
            waveSeed: 1.2,
            isLoading: _isStockStateLoading,
            onTap: _generateStockReport,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildReportCard(
            icon: Icons.trending_up_rounded,
            title: 'Mouvements',
            subtitle: 'Taux & répartition',
            badge: 'Logistique',
            gradient: const [Color(0xFF0A3B5C), Color(0xFF165B8C), Color(0xFF3A89C9)],
            waveSeed: 2.4,
            isLoading: _isMouvementsLoading,
            onTap: _generateMouvementsReport,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildReportCard(
            icon: Icons.warning_amber_rounded,
            title: 'Alertes',
            subtitle: 'Articles sous seuil',
            badge: 'Surveillance',
            gradient: const [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
            waveSeed: 3.6,
            isLoading: _isAlertesLoading,
            onTap: _generateAlertesReport,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildReportCard(
            icon: Icons.pie_chart_outline_rounded,
            title: 'Analyse',
            subtitle: 'Valeurs & marges',
            badge: 'Financier',
            gradient: const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF2563EB)],
            waveSeed: 4.8,
            isLoading: _isAnalyseLoading,
            onTap: _generateAnalyseReport,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileReportCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: _buildReportCard(
              icon: Icons.inventory_2_outlined,
              title: 'État des stocks',
              subtitle: 'Détail par dépôt',
              badge: 'Inventaire',
              gradient: const [Color(0xFF004E8C), Color(0xFF0067C0), Color(0xFF2886DE)],
              waveSeed: 1.2,
              isLoading: _isStockStateLoading,
              onTap: _generateStockReport,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 220,
            child: _buildReportCard(
              icon: Icons.trending_up_rounded,
              title: 'Mouvements',
              subtitle: 'Taux & répartition',
              badge: 'Logistique',
              gradient: const [Color(0xFF0A3B5C), Color(0xFF165B8C), Color(0xFF3A89C9)],
              waveSeed: 2.4,
              isLoading: _isMouvementsLoading,
              onTap: _generateMouvementsReport,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 220,
            child: _buildReportCard(
              icon: Icons.warning_amber_rounded,
              title: 'Alertes',
              subtitle: 'Articles sous seuil',
              badge: 'Surveillance',
              gradient: const [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
              waveSeed: 3.6,
              isLoading: _isAlertesLoading,
              onTap: _generateAlertesReport,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 220,
            child: _buildReportCard(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Analyse',
              subtitle: 'Valeurs & marges',
              badge: 'Financier',
              gradient: const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF2563EB)],
              waveSeed: 4.8,
              isLoading: _isAnalyseLoading,
              onTap: _generateAnalyseReport,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required List<Color> gradient,
    required double waveSeed,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedReport == title;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0067C0) : const Color(0x18000000),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0x140067C0) : const Color(0x06000000),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bannière fluide
            SizedBox(
              height: 58,
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
                      painter: ReportMetricWavePainter(waveSeed: waveSeed),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(icon, color: Colors.white, size: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 9.5,
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

            // Pied de carte
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF0067C0) : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0067C0)),
                    )
                  else
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                      size: 18,
                      color: isSelected ? const Color(0xFF0067C0) : const Color(0xFF94A3B8),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENU DU RAPPORT
  // ---------------------------------------------------------------------------
  Widget _buildReportContent() {
    if (_selectedReport == 'Aucun') return _buildEmptyState();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildReportData(),
      ),
    );
  }

  Widget _buildReportData() {
    if (_reportData == null) return _buildNoDataState();

    switch (_selectedReport) {
      case 'État des stocks':
        return _buildStockStateReport();
      case 'Mouvements':
        return _buildMouvementsReport();
      case 'Alertes':
        return _buildAlertesReport();
      case 'Analyse':
        return _buildAnalyseReport();
      default:
        return _buildNoDataState();
    }
  }

  // ---------------------------------------------------------------------------
  // RAPPORT ÉTAT DES STOCKS
  // ---------------------------------------------------------------------------
  Widget _buildStockStateReport() {
    final stats = _reportData as Map<int, Map<String, dynamic>>;
    if (stats.isEmpty) {
      return _buildNoDataState('Aucune donnée de stock disponible pour le rapport');
    }

    final totalUnites = stats.values.fold<int>(0, (s, v) => s + (v['total_unites'] as int));
    final totalValeur = stats.values.fold<double>(0, (s, v) => s + (v['valeur_vente'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x12000000)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.warehouse_outlined, color: Color(0xFF0067C0), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vue d\'ensemble consolidée',
                      style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '$totalUnites unités en stock • ${totalValeur.toStringAsFixed(0)} \$ de valorisation',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...stats.values.map((entry) {
          final depot = entry['depot'] as Depot;
          final produits = (entry['produits'] as List);
          final enAlerte = entry['en_alerte'] as int;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: ExpansionTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: Icon(
                depot.estMagasin ? Icons.storefront_outlined : Icons.warehouse_outlined,
                color: const Color(0xFF0067C0),
                size: 20,
              ),
              title: Text(
                depot.nom,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                '${entry['nb_produits']} référence(s) • $enAlerte en alerte',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 11.5,
                  color: enAlerte > 0 ? const Color(0xFFB45309) : const Color(0xFF64748B),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStatItem('Unités', '${entry['total_unites']}', const Color(0xFF0F172A)),
                          const SizedBox(width: 8),
                          _buildStatItem('Valeur Vente', '${(entry['valeur_vente'] as double).toStringAsFixed(0)} \$', const Color(0xFF0067C0)),
                          const SizedBox(width: 8),
                          _buildStatItem('Valeur Achat', '${(entry['valeur_achat'] as double).toStringAsFixed(0)} \$', const Color(0xFF64748B)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, thickness: 1, color: Color(0x10000000)),
                      const SizedBox(height: 6),
                      ...produits.map((p) {
                        final stock = p['stock'] as Stock;
                        final produit = p['produit'] as Product?;
                        final alerte = stock.quantite <= stock.quantiteMinimale;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: alerte ? const Color(0xFFB45309) : const Color(0xFF107C41),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  produit?.nom ?? 'Article #${stock.produitId}',
                                  style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                              ),
                              Text(
                                '${stock.quantite} ${produit?.unite ?? 'u'}',
                                style: TextStyle(
                                  fontFamily: kAppFontFamily,
                                  color: alerte ? const Color(0xFFB45309) : const Color(0xFF107C41),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMouvementsReport() {
    final data = _reportData as Map<String, dynamic>;
    final parDepot = data['par_depot'] as Map<int, Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatCard(title: 'Unités Stockées', value: '${data['total_unites']}', icon: Icons.inventory_2_outlined),
            const SizedBox(width: 8),
            _buildStatCard(title: 'Lignes Actives', value: '${data['nb_lignes']}', icon: Icons.list_alt_rounded),
            const SizedBox(width: 8),
            _buildStatCard(title: 'En Alerte', value: '${data['alertes']}', icon: Icons.warning_amber_rounded, isAlert: true),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Répartition de conformité par dépôt',
          style: TextStyle(fontFamily: kAppFontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        ...parDepot.values.map((d) {
          final depot = d['depot'] as Depot;
          final alerte = d['alerte'] as int;
          final ok = d['ok'] as int;
          final total = d['total'] as int;
          final pctOk = total > 0 ? (ok / total * 100) : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x10000000)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(depot.estMagasin ? Icons.storefront_outlined : Icons.warehouse_outlined, color: const Color(0xFF0067C0), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        depot.nom,
                        style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Text(
                      alerte > 0 ? '$alerte alerte(s)' : 'Stock conforme',
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        color: alerte > 0 ? const Color(0xFFB45309) : const Color(0xFF107C41),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pctOk / 100,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      alerte > 0 ? const Color(0xFFB45309) : const Color(0xFF107C41),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAlertesReport() {
    final alertes = _reportData as List<Stock>;
    if (alertes.isEmpty) {
      return _buildNoDataState('Aucune alerte de stock à signaler.');
    }

    final totalManquant = alertes.fold<int>(0, (s, a) => s + (a.quantiteMinimale - a.quantite));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x20B45309)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${alertes.length} article(s) à réapprovisionner • Déficit cumulé : $totalManquant unités',
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...alertes.map((alerte) {
          final product = _findProduct(alerte.produitId);
          final depot = _findDepot(alerte.depotId);
          final manquant = alerte.quantiteMinimale - alerte.quantite;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x10000000)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.nom ?? 'Article #${alerte.produitId}',
                        style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${product?.code ?? '?'} • ${depot?.nom ?? 'Dépôt inconnu'}',
                        style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Actuel : ${alerte.quantite} (Min : ${alerte.quantiteMinimale})',
                  style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '-$manquant ${product?.unite ?? ''}',
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      color: Color(0xFFC42B1C),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAnalyseReport() {
    final data = _reportData as Map<String, dynamic>;
    final topParValeur = data['top_par_valeur'] as List;
    final topParQuantite = data['top_par_quantite'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x12000000)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF0067C0), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Valorisation marchande totale', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF64748B))),
                    Text(
                      '${(data['valeur_vente'] as double).toStringAsFixed(0)} \$',
                      style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Coût d\'achat : ${(data['valeur_achat'] as double).toStringAsFixed(0)} \$ • Marge brute prévisionnelle : ${(data['marge_potentielle'] as double).toStringAsFixed(0)} \$',
                      style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF107C41), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Top 10 des références par valeur',
          style: TextStyle(fontFamily: kAppFontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        ...topParValeur.map((item) {
          final product = item['produit'] as Product?;
          final rank = topParValeur.indexOf(item) + 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x0C000000)),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2FB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, color: Color(0xFF0067C0), fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    product?.nom ?? 'Article',
                    style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
                  ),
                ),
                Text(
                  '${(item['valeur_vente'] as double).toStringAsFixed(0)} \$',
                  style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, color: Color(0xFF0067C0), fontSize: 13),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS D'ÉTAT
  // ---------------------------------------------------------------------------
  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x10000000)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, color: color, fontSize: 13)),
            Text(label, style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    bool isAlert = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x10000000)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isAlert ? const Color(0xFFB45309) : const Color(0xFF0067C0), size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isAlert ? const Color(0xFFB45309) : const Color(0xFF0F172A),
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.analytics_outlined, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 14),
            Text(
              'Sélectionnez un rapport logistique',
              style: TextStyle(fontFamily: kAppFontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            SizedBox(height: 4),
            Text(
              'Cliquez sur l\'une des 4 cartes d\'analyse ci-dessus pour générer les données en direct.',
              style: TextStyle(fontFamily: kAppFontFamily, fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState([String message = 'Aucune donnée disponible']) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, size: 36, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES DE RAPPORTS
// ---------------------------------------------------------------------------
class ReportMetricWavePainter extends CustomPainter {
  final double waveSeed;

  ReportMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant ReportMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}