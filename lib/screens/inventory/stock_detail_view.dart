import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _StockDetailViewState extends State<StockDetailView> with SingleTickerProviderStateMixin {
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
    if (!_isRefreshing) setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final product = await service.getProduct(widget.productId);
        final depots = await service.getDepots();
        final allStocks = await service.getStocks();
        final productStocks = allStocks.where((s) => s.produitId == widget.productId).toList();

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
      _showSnackBar('Erreur: ${e.toString()}', _K.danger);
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
              color == _K.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // EXPORT / IMPRESSION
  // ---------------------------------------------------------------------
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exporter le rapport',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _K.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choisissez le format d\'exportation',
              style: TextStyle(color: _K.textMuted),
            ),
            const SizedBox(height: 20),
            _buildExportOption(
              icon: Icons.picture_as_pdf_rounded,
              title: 'PDF',
              subtitle: 'Exporter en format PDF',
              color: _K.danger,
            ),
            const Divider(height: 1),
            _buildExportOption(
              icon: Icons.table_chart_rounded,
              title: 'Excel',
              subtitle: 'Exporter en format Excel',
              color: _K.success,
            ),
            const Divider(height: 1),
            _buildExportOption(
              icon: Icons.print_rounded,
              title: 'Imprimer',
              subtitle: 'Imprimer le rapport directement',
              color: _K.primary,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: _K.textMuted),
      onTap: () {
        Navigator.pop(context);
        _showSnackBar('Export $title en cours...', _K.info);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: _K.bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const _LoadingState()
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: _K.primary,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(isWide ? 24 : 16),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _K.surface,
      elevation: 0,
      centerTitle: false,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _K.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _K.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _product?.nom ?? 'Détail du stock',
            style: const TextStyle(
              color: _K.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          if (_product != null)
            Text(
              'Code: ${_product!.code}',
              style: const TextStyle(
                color: _K.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _K.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.print_rounded, color: _K.primary),
            onPressed: _showExportOptions,
            tooltip: 'Exporter / Imprimer',
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _K.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _K.primary),
            onPressed: _refreshData,
            tooltip: 'Rafraîchir',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // CONTENU PRINCIPAL
  // ---------------------------------------------------------------------
  Widget _buildContent() {
    if (_product == null) {
      return const Center(
        child: Text('Produit non trouvé', style: TextStyle(color: _K.textMuted)),
      );
    }

    final totalStock = _stocks.fold(0, (sum, s) => sum + s.quantite);
    final isAlerte = totalStock < (_product?.seuilAlerte ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte d'information du produit
        _buildProductCard(totalStock, isAlerte),
        const SizedBox(height: 20),

        // En-tête des stocks
        _buildStockHeader(),
        const SizedBox(height: 16),

        // Liste des stocks par dépôt
        if (_stocks.isEmpty)
          _buildEmptyStock()
        else
          ..._stocks.map((stock) => _buildStockCard(stock)),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // CARTE PRODUIT
  // ---------------------------------------------------------------------
  Widget _buildProductCard(int totalStock, bool isAlerte) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _K.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _K.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _K.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _product!.code.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: _K.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product!.nom,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _K.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInfoChip(
                            label: _product!.code,
                            color: _K.primary,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            label: _product!.unite,
                            color: _K.info,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(isAlerte),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildStatItem(
                  label: 'Prix vente',
                  value: '${_product!.prixVente} \$',
                  color: _K.success,
                ),
                _buildStatItem(
                  label: "Prix d'achat",
                  value: '${_product!.prixAchat} \$',
                  color: _K.info,
                ),
                _buildStatItem(
                  label: 'Seuil alerte',
                  value: '${_product!.seuilAlerte}',
                  color: _K.warning,
                ),
                _buildStatItem(
                  label: 'Stock total',
                  value: '$totalStock',
                  color: isAlerte ? _K.danger : _K.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isAlerte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAlerte ? _K.danger.withOpacity(0.1) : _K.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isAlerte ? _K.danger : _K.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAlerte ? 'Stock bas' : 'Stock OK',
            style: TextStyle(
              color: isAlerte ? _K.danger : _K.success,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _K.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: _K.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // EN-TÊTE STOCKS
  // ---------------------------------------------------------------------
  Widget _buildStockHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          const Text(
            '📦 Répartition par dépôt',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _K.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _K.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_stocks.length} dépôt${_stocks.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: _K.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CARTE DE STOCK PAR DÉPÔT
  // ---------------------------------------------------------------------
  Widget _buildStockCard(Stock stock) {
    final depot = _depots.firstWhere(
      (d) => d.id == stock.depotId,
      orElse: () => Depot(
        id: stock.depotId,
        nom: stock.depotNom ?? 'Dépôt ${stock.depotId}',
        type: 'unknown',
        adresse: null,
        estMagasin: false,
        aCaisse: false,
        actif: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final isAlerte = stock.quantite < stock.quantiteMinimale;
    final pourcentage = stock.quantiteMaximale > 0
        ? (stock.quantite / stock.quantiteMaximale * 100).clamp(0, 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _K.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlerte ? _K.danger.withOpacity(0.3) : _K.border.withOpacity(0.4),
          width: isAlerte ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du dépôt
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _K.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    depot.estMagasin ? Icons.store_rounded : Icons.warehouse_rounded,
                    color: _K.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        depot.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: _K.textPrimary,
                        ),
                      ),
                      Text(
                        depot.estMagasin ? 'Magasin' : 'Entrepôt',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _K.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(isAlerte),
              ],
            ),
            const SizedBox(height: 14),

            // Barre de progression
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pourcentage / 100,
                      backgroundColor: _K.surfaceAlt,
                      color: isAlerte ? _K.danger : _K.success,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _K.surfaceAlt,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${pourcentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _K.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quantité
            Row(
              children: [
                _buildQuantityItem(
                  label: 'Min',
                  value: stock.quantiteMinimale,
                  color: _K.warning,
                ),
                const SizedBox(width: 16),
                _buildQuantityItem(
                  label: 'Actuel',
                  value: stock.quantite,
                  color: isAlerte ? _K.danger : _K.success,
                  isBold: true,
                  isBig: true,
                ),
                const SizedBox(width: 16),
                _buildQuantityItem(
                  label: 'Max',
                  value: stock.quantiteMaximale,
                  color: _K.info,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityItem({
    required String label,
    required int value,
    required Color color,
    bool isBold = false,
    bool isBig = false,
  }) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: _K.textMuted,
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: isBig ? 18 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isAlerte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAlerte ? _K.danger.withOpacity(0.1) : _K.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isAlerte ? _K.danger : _K.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAlerte ? 'Alerte' : 'OK',
            style: TextStyle(
              color: isAlerte ? _K.danger : _K.success,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------
  Widget _buildEmptyStock() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _K.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _K.border.withOpacity(0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_rounded, size: 56, color: _K.textMuted),
            SizedBox(height: 12),
            Text(
              'Aucun stock disponible',
              style: TextStyle(
                color: _K.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Ce produit n\'est pas encore en stock dans aucun dépôt',
              style: TextStyle(
                color: _K.textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// LOADING STATE
// ---------------------------------------------------------------------
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _K.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                color: _K.primary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chargement du stock...',
            style: TextStyle(
              color: _K.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// TOKENS DE DESIGN
// ---------------------------------------------------------------------
class _K {
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
        spreadRadius: 0,
        offset: const Offset(0, 2),
      );
}