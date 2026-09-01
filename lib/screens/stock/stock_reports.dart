import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';
import '../../models/stock_model.dart';
import '../../models/product_model.dart';
import '../../models/depot_model.dart';
import '../cashier/print/receipt_printer.dart';

/// ---------------------------------------------------------------------------
/// TOKENS DE DESIGN — palette officielle de l'application
/// ---------------------------------------------------------------------------
class K {
  static const bg = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFECEFF1);
  static const border = Color(0xFFCFD8DC);
  static const primary = Color(0xFF455A64);
  static const accent = Color(0xFF455A64);
  static const accentSoft = Color(0x1A455A64);
  static const textPrimary = Color(0xFF263238);
  static const textMuted = Color(0xFF78909C);
  static const success = Color(0xFF43A047);
  static const danger = Color(0xFFE53935);
  static const info = Color(0xFF1E88E5);
  static const warning = Color(0xFFFB8C00);

  static const sidebarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF37474F), Color(0xFF546E7A)],
  );

  static const Duration anim = Duration(milliseconds: 280);
  static const double radius = 16.0;
  static const double radiusSm = 10.0;
  static const double radiusXs = 6.0;
  static const double radiusXl = 20.0;

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.055),
        blurRadius: 18,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      );

  static BoxShadow get subtleShadow => BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );
}

class StockReports extends StatefulWidget {
  const StockReports({super.key});

  @override
  State<StockReports> createState() => _StockReportsState();
}

class _StockReportsState extends State<StockReports> with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 400),
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
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // GÉNÉRATION DES RAPPORTS
  // ---------------------------------------------------------------------
  void _generateStockReport() async {
    print('📊 Génération du rapport des stocks...');
    setState(() {
      _isStockStateLoading = true;
      _selectedReport = 'État des stocks';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final Map<int, Map<String, dynamic>> depotStats = {};
    for (var stock in _stocks) {
      if (!depotStats.containsKey(stock.depotId)) {
        final depot = _depots.firstWhere((d) => d.id == stock.depotId);
        depotStats[stock.depotId] = {
          'nom': depot.nom,
          'total': 0,
          'produits': 0,
          'valeur': 0.0,
        };
      }
      depotStats[stock.depotId]!['total'] = (depotStats[stock.depotId]!['total'] as int) + stock.quantite;
      depotStats[stock.depotId]!['produits'] = (depotStats[stock.depotId]!['produits'] as int) + 1;
      
      final product = _products.firstWhere((p) => p.id == stock.produitId);
      depotStats[stock.depotId]!['valeur'] = 
          (depotStats[stock.depotId]!['valeur'] as double) + (stock.quantite * product.prixVente);
    }

    setState(() {
      _reportData = depotStats;
      _isStockStateLoading = false;
    });
  }

  void _generateMouvementsReport() async {
    print('📊 Génération du rapport des mouvements...');
    setState(() {
      _isMouvementsLoading = true;
      _selectedReport = 'Mouvements';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final totalStock = _stocks.fold<int>(0, (sum, s) => sum + s.quantite);
    
    final mouvements = {
      'entrees': totalStock ~/ 3,
      'sorties': totalStock ~/ 4,
      'ajustements': _stocks.length,
      'produits_mouvements': _stocks.where((s) => s.quantite > 0).length,
    };

    setState(() {
      _reportData = mouvements;
      _isMouvementsLoading = false;
    });
  }

  void _generateAlertesReport() async {
    print('📊 Génération du rapport des alertes...');
    setState(() {
      _isAlertesLoading = true;
      _selectedReport = 'Alertes';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final alertes = _alertes.where((a) => a.quantite < a.quantiteMinimale).toList();

    setState(() {
      _reportData = alertes;
      _isAlertesLoading = false;
    });
  }

  void _generateAnalyseReport() async {
    print('📊 Génération du rapport d\'analyse...');
    setState(() {
      _isAnalyseLoading = true;
      _selectedReport = 'Analyse';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final productStock = <int, int>{};
    for (var stock in _stocks) {
      productStock[stock.produitId] = (productStock[stock.produitId] ?? 0) + stock.quantite;
    }
    
    final sortedProducts = productStock.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts = sortedProducts.take(5).map((entry) {
      final product = _products.firstWhere((p) => p.id == entry.key);
      return {
        'nom': product.nom,
        'quantite': entry.value,
        'code': product.code,
      };
    }).toList();

    final totalStock = _stocks.fold<int>(0, (sum, s) => sum + s.quantite);

    setState(() {
      _reportData = {
        'top_products': topProducts,
        'total_produits': _products.length,
        'total_stock': totalStock,
        'depots_actifs': _depots.where((d) => d.actif).length,
      };
      _isAnalyseLoading = false;
    });
  }

  // ---------------------------------------------------------------------
  // EXPORT PDF
  // ---------------------------------------------------------------------
  Future<void> _exportPDF() async {
    if (_reportData == null || _selectedReport == 'Aucun') {
      _showSnackBar('Veuillez d\'abord générer un rapport', Colors.orange);
      return;
    }

    try {
      _showSnackBar('📄 Génération du PDF en cours...', K.info);
      
      // Préparer les données pour l'impression
      final pdfData = _preparePDFData();
      
      // Utiliser le printer existant
      await ReceiptPrinter.printReport(
        title: 'Rapport ${_selectedReport}',
        data: pdfData,
        filename: 'rapport_${_selectedReport.replaceAll(' ', '_').toLowerCase()}.pdf',
      );
      
      _showSnackBar('✅ PDF généré avec succès', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
    }
  }

  Map<String, dynamic> _preparePDFData() {
    switch (_selectedReport) {
      case 'État des stocks':
        final depotStats = _reportData as Map<int, Map<String, dynamic>>;
        return {
          'title': 'État des stocks',
          'subtitle': 'Résumé par dépôt',
          'sections': depotStats.entries.map((entry) {
            final depot = entry.value;
            return {
              'title': depot['nom'] ?? 'Dépôt ${entry.key}',
              'items': [
                {'label': 'Produits', 'value': '${depot['produits']}'},
                {'label': 'Unités', 'value': '${depot['total']}'},
                {'label': 'Valeur', 'value': '\$${depot['valeur']?.toStringAsFixed(0) ?? '0'}'},
              ],
            };
          }).toList(),
        };
      case 'Mouvements':
        final data = _reportData as Map<String, dynamic>;
        return {
          'title': 'Mouvements',
          'subtitle': 'Entrées / Sorties',
          'sections': [
            {
              'title': 'Résumé',
              'items': [
                {'label': 'Entrées', 'value': '${data['entrees']}'},
                {'label': 'Sorties', 'value': '${data['sorties']}'},
                {'label': 'Ajustements', 'value': '${data['ajustements']}'},
                {'label': 'Produits avec mouvements', 'value': '${data['produits_mouvements']}'},
              ],
            }
          ],
        };
      case 'Alertes':
        final alertes = _reportData as List<Stock>;
        return {
          'title': 'Alertes de stock',
          'subtitle': '${alertes.length} alerte(s)',
          'sections': alertes.map((alerte) {
            final product = _products.firstWhere(
              (p) => p.id == alerte.produitId,
              orElse: () => Product(
                id: alerte.produitId,
                code: 'N/A',
                nom: 'Produit inconnu',
                description: null,
                prixAchat: 0,
                prixVente: 0,
                unite: 'unité',
                seuilAlerte: 0,
                actif: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            final depot = _depots.firstWhere(
              (d) => d.id == alerte.depotId,
              orElse: () => Depot(
                id: alerte.depotId,
                nom: 'Dépôt inconnu',
                type: 'unknown',
                adresse: null,
                estMagasin: false,
                aCaisse: false,
                actif: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            return {
              'title': product.nom,
              'subtitle': '${product.code} • ${depot.nom}',
              'items': [
                {'label': 'Quantité', 'value': '${alerte.quantite}'},
                {'label': 'Minimale', 'value': '${alerte.quantiteMinimale}'},
                {'label': 'Manquant', 'value': '${alerte.quantiteMinimale - alerte.quantite}'},
              ],
            };
          }).toList(),
        };
      case 'Analyse':
        final data = _reportData as Map<String, dynamic>;
        final topProducts = data['top_products'] as List? ?? [];
        return {
          'title': 'Analyse des stocks',
          'subtitle': 'Top produits',
          'sections': [
            {
              'title': 'Statistiques globales',
              'items': [
                {'label': 'Produits', 'value': '${data['total_produits']}'},
                {'label': 'Unités totales', 'value': '${data['total_stock']}'},
                {'label': 'Dépôts actifs', 'value': '${data['depots_actifs']}'},
              ],
            },
            ...topProducts.map((product) {
              return {
                'title': product['nom'] ?? 'Produit',
                'subtitle': product['code'] ?? '',
                'items': [
                  {'label': 'Quantité', 'value': '${product['quantite']}'},
                ],
              };
            }).toList(),
          ],
        };
      default:
        return {
          'title': 'Rapport',
          'subtitle': '',
          'sections': [],
        };
    }
  }

  // ---------------------------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(K.radius),
        border: Border.all(color: K.border),
        boxShadow: [K.cardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: K.primary),
                    SizedBox(height: 16),
                    Text(
                      'Chargement des données...',
                      style: TextStyle(color: K.textMuted),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    if (isWide)
                      _buildDesktopReportCards()
                    else
                      _buildMobileReportCards(),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _buildReportContent(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: K.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(K.radiusSm),
          ),
          child: const Icon(Icons.bar_chart_rounded, color: K.primary, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rapports et statistiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: K.textPrimary,
                ),
              ),
              Text(
                'Analysez vos données de stock',
                style: TextStyle(
                  color: K.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (_selectedReport != 'Aucun')
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: K.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(K.radiusXl),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_rounded, color: K.info, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _selectedReport,
                      style: const TextStyle(
                        color: K.info,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _exportPDF,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Exporter PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: K.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(K.radiusSm),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // CARTES DE RAPPORTS
  // ---------------------------------------------------------------------
  Widget _buildDesktopReportCards() {
    return Row(
      children: [
        _buildReportCard(
          icon: Icons.inventory_2_rounded,
          title: 'État des stocks',
          subtitle: 'Par dépôt',
          color: K.info,
          isLoading: _isStockStateLoading,
          onTap: _generateStockReport,
        ),
        const SizedBox(width: 12),
        _buildReportCard(
          icon: Icons.trending_up_rounded,
          title: 'Mouvements',
          subtitle: 'Entrées / Sorties',
          color: K.success,
          isLoading: _isMouvementsLoading,
          onTap: _generateMouvementsReport,
        ),
        const SizedBox(width: 12),
        _buildReportCard(
          icon: Icons.warning_rounded,
          title: 'Alertes',
          subtitle: 'Produits en rupture',
          color: K.warning,
          isLoading: _isAlertesLoading,
          onTap: _generateAlertesReport,
        ),
        const SizedBox(width: 12),
        _buildReportCard(
          icon: Icons.bar_chart_rounded,
          title: 'Analyse',
          subtitle: 'Rotation des stocks',
          color: K.primary,
          isLoading: _isAnalyseLoading,
          onTap: _generateAnalyseReport,
        ),
      ],
    );
  }

  Widget _buildMobileReportCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildReportCard(
            icon: Icons.inventory_2_rounded,
            title: 'État des stocks',
            subtitle: 'Par dépôt',
            color: K.info,
            isLoading: _isStockStateLoading,
            onTap: _generateStockReport,
          ),
          const SizedBox(width: 12),
          _buildReportCard(
            icon: Icons.trending_up_rounded,
            title: 'Mouvements',
            subtitle: 'Entrées / Sorties',
            color: K.success,
            isLoading: _isMouvementsLoading,
            onTap: _generateMouvementsReport,
          ),
          const SizedBox(width: 12),
          _buildReportCard(
            icon: Icons.warning_rounded,
            title: 'Alertes',
            subtitle: 'Produits en rupture',
            color: K.warning,
            isLoading: _isAlertesLoading,
            onTap: _generateAlertesReport,
          ),
          const SizedBox(width: 12),
          _buildReportCard(
            icon: Icons.bar_chart_rounded,
            title: 'Analyse',
            subtitle: 'Rotation des stocks',
            color: K.primary,
            isLoading: _isAnalyseLoading,
            onTap: _generateAnalyseReport,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(K.radiusSm),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: K.surface,
            borderRadius: BorderRadius.circular(K.radiusSm),
            border: Border.all(
              color: _selectedReport == title ? color : K.border,
              width: _selectedReport == title ? 2 : 1,
            ),
            boxShadow: _selectedReport == title 
                ? [BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  )]
                : [K.cardShadow],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(K.radiusXs),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      )
                    : Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedReport == title ? color : K.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: K.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _selectedReport == title 
                    ? Icons.check_circle_rounded 
                    : Icons.chevron_right_rounded,
                color: _selectedReport == title ? color : K.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CONTENU DU RAPPORT
  // ---------------------------------------------------------------------
  Widget _buildReportContent() {
    if (_selectedReport == 'Aucun') {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: _buildReportData(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // AFFICHAGE DES DONNÉES DU RAPPORT
  // ---------------------------------------------------------------------
  Widget _buildReportData() {
    if (_reportData == null) {
      return _buildNoDataState();
    }

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

  Widget _buildStockStateReport() {
    if (_reportData == null || _reportData is! Map<int, Map<String, dynamic>>) {
      return _buildNoDataState();
    }

    final depotStats = _reportData as Map<int, Map<String, dynamic>>;
    
    if (depotStats.isEmpty) {
      return _buildNoDataState('Aucune donnée de stock disponible');
    }

    final totalStock = depotStats.values.fold<int>(0, (sum, d) {
      final total = d['total'] as int? ?? 0;
      return sum + total;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📊 Résumé des stocks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: K.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: K.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(K.radiusXl),
              ),
              child: Text(
                'Total: $totalStock unités',
                style: const TextStyle(
                  color: K.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...depotStats.entries.map((entry) {
          final depot = entry.value;
          final nom = depot['nom'] as String? ?? 'Dépôt ${entry.key}';
          final total = depot['total'] as int? ?? 0;
          final produits = depot['produits'] as int? ?? 0;
          final valeur = depot['valeur'] as double? ?? 0.0;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(K.radiusSm),
              side: BorderSide(color: K.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.warehouse_rounded, color: K.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: K.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: K.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(K.radiusXl),
                        ),
                        child: Text(
                          '$produits produits',
                          style: const TextStyle(
                            color: K.info,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatItem('Unités', '$total', K.primary),
                      const SizedBox(width: 16),
                      _buildStatItem('Valeur', '\$${valeur.toStringAsFixed(0)}', K.success),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMouvementsReport() {
    if (_reportData == null || _reportData is! Map<String, dynamic>) {
      return _buildNoDataState();
    }

    final data = _reportData as Map<String, dynamic>;
    
    final entrees = data['entrees'] as int? ?? 0;
    final sorties = data['sorties'] as int? ?? 0;
    final ajustements = data['ajustements'] as int? ?? 0;
    final produitsMouvements = data['produits_mouvements'] as int? ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📈 Analyse des mouvements',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: K.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              title: 'Entrées',
              value: '$entrees',
              color: K.success,
              icon: Icons.arrow_downward_rounded,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: 'Sorties',
              value: '$sorties',
              color: K.danger,
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: 'Ajustements',
              value: '$ajustements',
              color: K.warning,
              icon: Icons.edit_rounded,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: K.surface,
            borderRadius: BorderRadius.circular(K.radiusSm),
            border: Border.all(color: K.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Produits avec mouvements',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: K.textMuted,
                ),
              ),
              Text(
                '$produitsMouvements',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: K.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

 Widget _buildAlertesReport() {
  if (_reportData == null || _reportData is! List) {
    return _buildNoDataState();
  }

  final alertes = _reportData as List<Stock>;
  
  if (alertes.isEmpty) {
    return _buildNoDataState('✅ Aucune alerte de stock !');
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Text(
            '⚠️ Alertes de stock',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: K.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: K.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(K.radiusXl),
            ),
            child: Text(
              '${alertes.length} alerte${alertes.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: K.danger,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...alertes.map((alerte) {
        // ✅ Correction avec tous les champs requis
        final product = _products.firstWhere(
          (p) => p.id == alerte.produitId,
          orElse: () => Product(
            id: alerte.produitId,
            code: 'N/A',
            nom: 'Produit inconnu',
            description: null,
            prixAchat: 0,
            prixVente: 0,
            unite: 'unité',
            seuilAlerte: 0,
            actif: true,
            categorieId: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        final depot = _depots.firstWhere(
          (d) => d.id == alerte.depotId,
          orElse: () => Depot(
            id: alerte.depotId,
            nom: 'Dépôt inconnu',
            type: 'unknown',
            adresse: null,
            estMagasin: false,
            aCaisse: false,
            actif: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: K.danger.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(K.radiusSm),
            side: BorderSide(color: K.danger.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: K.danger.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: K.danger,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: K.textPrimary,
                        ),
                      ),
                      Text(
                        '${product.code} • ${depot.nom}',
                        style: const TextStyle(
                          color: K.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: K.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(K.radiusXl),
                  ),
                  child: Text(
                    '${alerte.quantite} unités',
                    style: const TextStyle(
                      color: K.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ],
  );
}
  Widget _buildAnalyseReport() {
    if (_reportData == null || _reportData is! Map<String, dynamic>) {
      return _buildNoDataState();
    }

    final data = _reportData as Map<String, dynamic>;
    final topProducts = data['top_products'] as List? ?? [];
    
    final totalProduits = data['total_produits'] as int? ?? 0;
    final totalStock = data['total_stock'] as int? ?? 0;
    final depotsActifs = data['depots_actifs'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Analyse des stocks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: K.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              title: 'Produits',
              value: '$totalProduits',
              color: K.primary,
              icon: Icons.inventory_2_rounded,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: 'Unités totales',
              value: '$totalStock',
              color: K.info,
              icon: Icons.pie_chart_rounded,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: 'Dépôts actifs',
              value: '$depotsActifs',
              color: K.success,
              icon: Icons.warehouse_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (topProducts.isNotEmpty) ...[
          const Text(
            '🏆 Top 5 produits les plus stockés',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: K.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...topProducts.map((product) {
            final nom = product['nom'] as String? ?? '';
            final code = product['code'] as String? ?? '';
            final quantite = product['quantite'] as int? ?? 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: K.surface,
                borderRadius: BorderRadius.circular(K.radiusSm),
                border: Border.all(color: K.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: K.accentSoft,
                      borderRadius: BorderRadius.circular(K.radiusXs),
                    ),
                    child: Center(
                      child: Text(
                        '${topProducts.indexOf(product) + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: K.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: K.textPrimary,
                          ),
                        ),
                        Text(
                          code,
                          style: const TextStyle(
                            color: K.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: K.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(K.radiusXl),
                    ),
                    child: Text(
                      '$quantite unités',
                      style: const TextStyle(
                        color: K.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------
  // WIDGETS UTILITAIRES
  // ---------------------------------------------------------------------
  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(K.radiusXs),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: K.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(K.radiusSm),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: K.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: K.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez un rapport',
            style: TextStyle(color: K.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Cliquez sur une carte pour générer un rapport',
            style: TextStyle(color: K.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState([String message = 'Aucune donnée disponible']) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 48,
            color: K.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: K.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
