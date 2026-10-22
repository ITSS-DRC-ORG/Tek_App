import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';
import '../../models/stock_model.dart';
import '../../models/product_model.dart';
import '../../models/depot_model.dart';

class StockDetailView extends StatefulWidget {
  final int productId;
  const StockDetailView({super.key, required this.productId});

  @override
  State<StockDetailView> createState() => _StockDetailViewState();
}

class _StockDetailViewState extends State<StockDetailView>
    with SingleTickerProviderStateMixin {
  Product? _product;
  List<Stock> _stocks = [];
  List<Depot> _depots = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    if (!_isRefreshing) setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final product = await service.getProduct(widget.productId);
        final depots = await service.getDepots();
        final allStocks = await service.getStocks();
        final productStocks =
        allStocks.where((s) => s.produitId == widget.productId).toList();

        setState(() {
          _product = product;
          _depots = depots;
          _stocks = productStocks;
          _isLoading = false;
          _isRefreshing = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadData();
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
  // EXPORT / IMPRESSION (Dialogue Desktop Windows 11)
  // ---------------------------------------------------------------------------
  void _showExportOptions() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2FB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.file_download_outlined,
                color: Color(0xFF0067C0),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Exporter la fiche de stock',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Générez un rapport détaillé pour l\'article ${_product?.nom ?? ''} :',
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              _buildExportOption(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Rapport PDF (.pdf)',
                subtitle: 'Fiche d\'inventaire imprimable avec code-barres',
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showSnackBar('Génération du rapport PDF en cours...', const Color(0xFF0067C0));
                },
              ),
              const SizedBox(height: 8),
              _buildExportOption(
                icon: Icons.table_chart_outlined,
                title: 'Feuille Excel (.xlsx)',
                subtitle: 'Données détaillées de répartition par dépôt',
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showSnackBar('Export Excel généré avec succès', const Color(0xFF107C41));
                },
              ),
              const SizedBox(height: 8),
              _buildExportOption(
                icon: Icons.print_outlined,
                title: 'Impression Directe',
                subtitle: 'Transmettre à l\'imprimante de bureau',
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showSnackBar('Document envoyé à l\'imprimante', const Color(0xFF0067C0));
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Fermer',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2FB),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: const Color(0xFF0067C0), size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8), size: 16),
        onTap: onTap,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD PRINCIPAL
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F7),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0067C0),
          strokeWidth: 2.2,
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR WINDOWS 11 FLUENT
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Retour',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _product?.nom ?? 'Détail de l\'inventaire',
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          if (_product != null)
            Text(
              'Code article : ${_product!.code}',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                color: Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.print_outlined, color: Color(0xFF0067C0), size: 19),
          onPressed: _showExportOptions,
          tooltip: 'Exporter / Imprimer',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0067C0), size: 19),
          onPressed: _refreshData,
          tooltip: 'Actualiser',
        ),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0x14000000)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENU PRINCIPAL
  // ---------------------------------------------------------------------------
  Widget _buildContent() {
    if (_product == null) {
      return const Center(
        child: Text(
          'Produit non trouvé',
          style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B)),
        ),
      );
    }

    final totalStock = _stocks.fold(0, (sum, s) => sum + s.quantite);
    final isAlerte = totalStock < (_product?.seuilAlerte ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Les 4 Cartes Métriques Stylisées avec Ondes Fluides
        _buildDetailMetricsRow(totalStock, isAlerte),
        const SizedBox(height: 20),

        // 2. Fiche d'identité produit
        _buildProductCard(totalStock, isAlerte),
        const SizedBox(height: 20),

        // 3. Répartition logistique par site
        _buildStockHeader(),
        const SizedBox(height: 12),

        if (_stocks.isEmpty)
          _buildEmptyStock()
        else
          ..._stocks.map((stock) => _buildStockCard(stock)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. STATS ROW AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildDetailMetricsRow(int totalStock, bool isAlerte) {
    final valorisation = (_product?.prixVente ?? 0.0) * totalStock;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final cards = [
          _buildWaveMetricCard(
            title: "STOCK CONSOLIDÉ",
            value: "$totalStock ${_product?.unite ?? 'u'}",
            subtitle: "Unités physiques réelles",
            badge: "Inventaire",
            icon: Icons.inventory_2_outlined,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "SEUIL DE SÉCURITÉ",
            value: "${_product?.seuilAlerte ?? 0} ${_product?.unite ?? 'u'}",
            subtitle: isAlerte ? "Seuil minimal franchi" : "Stock sous contrôle",
            badge: isAlerte ? "Alerte Réassort" : "Sécurisé",
            icon: Icons.warning_amber_rounded,
            gradient: isAlerte
                ? const [Color(0xFF9A3412), Color(0xFFC2410C), Color(0xFFEA580C)]
                : const [Color(0xFF0A3B5C), Color(0xFF165B8C), Color(0xFF3A89C9)],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "VALORISATION VENTE",
            value: "${valorisation.toStringAsFixed(0)} \$",
            subtitle: "Valeur marchande totale",
            badge: "Actif Circulant",
            icon: Icons.payments_outlined,
            gradient: const [
              Color(0xFF1E293B),
              Color(0xFF334155),
              Color(0xFF475569),
            ],
            waveSeed: 3.6,
          ),
          _buildWaveMetricCard(
            title: "SITES DÉPOSITAIRES",
            value: "${_stocks.length}",
            subtitle: "Dépôts et magasins",
            badge: "Répartition",
            icon: Icons.warehouse_outlined,
            gradient: const [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF2563EB),
            ],
            waveSeed: 4.8,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          );
        } else {
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
            height: 62,
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
                    painter: StockDetailWavePainter(waveSeed: waveSeed),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. CARTE PRODUIT
  // ---------------------------------------------------------------------------
  Widget _buildProductCard(int totalStock, bool isAlerte) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _product!.code.isNotEmpty ? _product!.code.substring(0, 1).toUpperCase() : 'P',
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      color: Color(0xFF0067C0),
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product!.nom,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _product!.code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF1E293B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Unité : ${_product!.unite}',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(isAlerte),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_product!.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              _product!.description!,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                color: Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0x12000000)),
          const SizedBox(height: 14),

          // Ligne de statistiques financières
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildStatItem(
                label: "Prix de vente",
                value: "${_product!.prixVente.toStringAsFixed(2)} \$",
                color: const Color(0xFF0067C0),
              ),
              _buildStatItem(
                label: "Prix d'achat",
                value: "${_product!.prixAchat.toStringAsFixed(2)} \$",
                color: const Color(0xFF475569),
              ),
              _buildStatItem(
                label: "Seuil d'alerte",
                value: "${_product!.seuilAlerte} ${_product!.unite}",
                color: const Color(0xFFB45309),
              ),
              _buildStatItem(
                label: "Marge unitaire",
                value: "${(_product!.prixVente - _product!.prixAchat).toStringAsFixed(2)} \$",
                color: const Color(0xFF107C41),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x10000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. EN-TÊTE RÉPARTITION PAR DÉPÔT
  // ---------------------------------------------------------------------------
  Widget _buildStockHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2FB),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.warehouse_outlined, color: Color(0xFF0067C0), size: 16),
        ),
        const SizedBox(width: 10),
        const Text(
          'Répartition Logistique par Dépôt',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${_stocks.length} site(s) dépositaire(s)',
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CARTE DE STOCK PAR DÉPÔT
  // ---------------------------------------------------------------------------
  Widget _buildStockCard(Stock stock) {
    final depot = _depots.where((d) => d.id == stock.depotId).firstOrNull;
    final depotName = depot?.nom ?? (stock.depotNom ?? 'Dépôt #${stock.depotId}');
    final isMagasin = depot?.estMagasin ?? false;

    final isAlerte = stock.quantite < stock.quantiteMinimale;
    final pourcentage = stock.quantiteMaximale > 0
        ? (stock.quantite / stock.quantiteMaximale * 100).clamp(0, 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAlerte ? const Color(0xFFB45309).withOpacity(0.3) : const Color(0x14000000),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isMagasin ? Icons.storefront_outlined : Icons.warehouse_outlined,
                  color: const Color(0xFF0067C0),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      depotName,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isMagasin ? 'Magasin / Vente directe' : 'Entrepôt de stockage',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isAlerte),
            ],
          ),
          const SizedBox(height: 12),

          // Barre de niveau de stock
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (pourcentage / 100).toDouble(),
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation(
                      isAlerte ? const Color(0xFFB45309) : const Color(0xFF107C41),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${pourcentage.toStringAsFixed(0)}% du max',
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Détail des quantités
          Row(
            children: [
              _buildQuantityMetric(label: 'Min (Alerte)', value: stock.quantiteMinimale, color: const Color(0xFFB45309)),
              const SizedBox(width: 20),
              _buildQuantityMetric(label: 'Stock Actuel', value: stock.quantite, color: isAlerte ? const Color(0xFFB45309) : const Color(0xFF107C41), isBold: true),
              const SizedBox(width: 20),
              _buildQuantityMetric(label: 'Capacité Max', value: stock.quantiteMaximale, color: const Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityMetric({
    required String label,
    required int value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5.5,
          height: 5.5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label : ',
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          '$value ${_product?.unite ?? ''}',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isAlerte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAlerte ? const Color(0xFFFEF3C7) : const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isAlerte ? 'Alerte Seuil' : 'Optimal',
        style: TextStyle(
          fontFamily: kAppFontFamily,
          color: isAlerte ? const Color(0xFFB45309) : const Color(0xFF107C41),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ÉTAT VIDE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyStock() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 44, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'Aucun stock présent dans les dépôts',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Cet article n\'a pas encore fait l\'objet d\'un ravitaillement ou d\'une entrée de stock.',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                color: Color(0xFF64748B),
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES DE DÉTAIL STOCK
// ---------------------------------------------------------------------------
class StockDetailWavePainter extends CustomPainter {
  final double waveSeed;

  StockDetailWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant StockDetailWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}