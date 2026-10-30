import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/screens/inventory/stock_detail_view.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';
import '../../models/product_model.dart';
import '../../models/stock_model.dart';
import '../admin/view/add_product_dialog.dart';

class StockProducts extends StatefulWidget {
  const StockProducts({super.key});

  @override
  State<StockProducts> createState() => _StockProductsState();
}

class _StockProductsState extends State<StockProducts>
    with SingleTickerProviderStateMixin {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  Map<int, int> _stockQuantities = {};
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD DATA
  // ---------------------------------------------------------------------------
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final products = await service.getAllProducts();
        final stocks = await service.getStocks();

        final Map<int, int> quantities = {};
        for (var stock in stocks) {
          quantities[stock.produitId] =
              (quantities[stock.produitId] ?? 0) + stock.quantite;
        }

        setState(() {
          _products = products;
          _filteredProducts = products;
          _stockQuantities = quantities;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------
  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = _products);
    } else {
      final q = query.toLowerCase();
      setState(() {
        _filteredProducts = _products
            .where((product) =>
        product.nom.toLowerCase().contains(q) ||
            product.code.toLowerCase().contains(q) ||
            product.description?.toLowerCase().contains(q) == true)
            .toList();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // SHOW ADD/EDIT DIALOG — utilise AddProductDialog
  // ---------------------------------------------------------------------------
  Future<void> _showProductDialog({Product? product}) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final service = AdminService(user.token);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AddProductDialog(
        service: service,
        product: product,
      ),
    );

    if (result == true) {
      _loadData();
      _showSnackBar(
        product == null
            ? 'Produit créé avec succès'
            : 'Produit mis à jour avec succès',
        const Color(0xFF107C41),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------
  Future<void> _deleteProduct(Product product) async {
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
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFC42B1C), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirmer la suppression',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment retirer l\'article "${product.nom}" (${product.code}) du catalogue ?\nCette opération est définitive.',
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            color: Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Annuler',
                style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC42B1C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer',
                style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      final service = AdminService(user.token);
      final success = await service.deleteProduct(product.id);

      if (!mounted) return;

      if (success) {
        _showSnackBar('Produit "${product.nom}" supprimé avec succès',
            const Color(0xFF107C41));
        _loadData();
      } else {
        _showSnackBar('Erreur lors de la suppression',
            const Color(0xFFC42B1C));
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS UI
  // ---------------------------------------------------------------------------
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
  // BUILD PRINCIPAL
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStockProductsMetricsRow(),
          const SizedBox(height: 18),
          _buildActionBar(isWide),
          const SizedBox(height: 14),
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
                  : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : isWide
                  ? _buildDesktopTable()
                  : _buildMobileList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. MÉTRIQUES
  // ---------------------------------------------------------------------------
  Widget _buildStockProductsMetricsRow() {
    final total = _products.length;
    final inStock = _products.where((p) {
      final stock = _stockQuantities[p.id] ?? 0;
      return stock >= p.seuilAlerte;
    }).length;
    final underAlert = _products.where((p) {
      final stock = _stockQuantities[p.id] ?? 0;
      return stock < p.seuilAlerte;
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 740;

        final cards = [
          _buildWaveMetricCard(
            title: "TOTAL ARTICLES",
            value: "$total",
            subtitle: "Références au catalogue",
            badge: "Catalogue",
            icon: Icons.inventory_2_outlined,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE)
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "STOCK SUFFISANT",
            value: "$inStock",
            subtitle: "Niveaux au-dessus du seuil",
            badge: "Disponibilité",
            icon: Icons.check_circle_outline_rounded,
            gradient: const [
              Color(0xFF0A3B5C),
              Color(0xFF165B8C),
              Color(0xFF3A89C9)
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "SEUILS CRITIQUES",
            value: "$underAlert",
            subtitle: "En rupture ou réassort",
            badge: "Surveillance",
            icon: Icons.notifications_active_outlined,
            gradient: const [
              Color(0xFF1E293B),
              Color(0xFF334155),
              Color(0xFF475569)
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
                    painter: StockProductMetricWavePainter(waveSeed: waveSeed),
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
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
  // 2. BARRE D'ACTIONS
  // ---------------------------------------------------------------------------
  Widget _buildActionBar(bool isWide) {
    return Row(
      children: [
        SizedBox(
          width: isWide ? 310 : 200,
          height: 38,
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filterProducts,
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher par code, nom...',
              hintStyle: const TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFFA0AEC0),
                  fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Color(0xFF6B7280), size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                splashRadius: 14,
                icon: const Icon(Icons.clear_rounded,
                    size: 15, color: Color(0xFF6B7280)),
                onPressed: () {
                  _searchCtrl.clear();
                  _filterProducts('');
                },
              )
                  : null,
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x18000000))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x18000000))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  const BorderSide(color: Color(0xFF0067C0), width: 1.5)),
            ),
          ),
        ),
        if (isWide) ...[
          const SizedBox(width: 14),
          Text(
            "${_filteredProducts.length} sur ${_products.length} référence(s)",
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ],
        const Spacer(),
        SizedBox(
          height: 38,
          child: OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0x20000000)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: () => _showProductDialog(),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: Text(isWide ? "Nouveau Produit" : "Ajouter"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
  // 3. TABLEAU DESKTOP
  // ---------------------------------------------------------------------------
  Widget _buildDesktopTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor:
                WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingRowHeight: 42,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                horizontalMargin: 20,
                columnSpacing: 24,
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text("CODE", style: _headerStyle)),
                  DataColumn(label: Text("DÉSIGNATION", style: _headerStyle)),
                  DataColumn(label: Text("PRIX DE VENTE", style: _headerStyle)),
                  DataColumn(label: Text("UNITÉ", style: _headerStyle)),
                  DataColumn(
                      label: Text("STOCK CONSOLIDÉ", style: _headerStyle)),
                  DataColumn(label: Text("STATUT", style: _headerStyle)),
                  DataColumn(label: Text("ACTIONS", style: _headerStyle)),
                ],
                rows: _filteredProducts.map((product) {
                  final stockTotal = _stockQuantities[product.id] ?? 0;
                  final isAlerte = stockTotal < product.seuilAlerte;

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0x10000000)),
                          ),
                          child: Text(
                            product.code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          product.nom,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${product.prixVente.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0067C0),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            product.unite,
                            style: const TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Tooltip(
                          message: 'Consulter la répartition par dépôt',
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StockDetailView(productId: product.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isAlerte
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFE6F4EA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isAlerte
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFF107C41),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$stockTotal',
                                    style: TextStyle(
                                      fontFamily: kAppFontFamily,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: isAlerte
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFF107C41),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: isAlerte
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF107C41),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(_buildStatusBadge(product.actif)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Color(0xFF0067C0), size: 17),
                              splashRadius: 14,
                              tooltip: 'Modifier',
                              onPressed: () =>
                                  _showProductDialog(product: product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Color(0xFFC42B1C), size: 17),
                              splashRadius: 14,
                              tooltip: 'Supprimer',
                              onPressed: () => _deleteProduct(product),
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
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) =>
      const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final stockTotal = _stockQuantities[product.id] ?? 0;
        final isAlerte = stockTotal < product.seuilAlerte;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          product.code,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${product.prixVente.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                              fontFamily: kAppFontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: Color(0xFF0067C0)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.nom,
                      style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StockDetailView(productId: product.id),
                          ),
                        );
                      },
                      child: Text(
                        'Stock: $stockTotal ${product.unite} (Seuil: ${product.seuilAlerte}) ›',
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isAlerte
                              ? const Color(0xFFB45309)
                              : const Color(0xFF107C41),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusBadge(product.actif),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Color(0xFF0067C0), size: 18),
                    onPressed: () => _showProductDialog(product: product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFC42B1C), size: 18),
                    onPressed: () => _deleteProduct(product),
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
  // BADGE STATUT
  // ---------------------------------------------------------------------------
  Widget _buildStatusBadge(bool actif) {
    final color = actif ? const Color(0xFF107C41) : const Color(0xFFC42B1C);
    final bgColor = actif ? const Color(0xFFE6F4EA) : const Color(0xFFFDE8E8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        actif ? 'Actif' : 'Inactif',
        style: TextStyle(
          fontFamily: kAppFontFamily,
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
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
              decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Aucun article enregistré'
                  : 'Aucun article trouvé',
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
                  ? 'Cliquez sur "Nouveau Produit" pour créer votre premier article.'
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
                  _filterProducts('');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0067C0),
                  side: const BorderSide(color: Color(0xFF0067C0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Effacer la recherche',
                    style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL
// ---------------------------------------------------------------------------
class StockProductMetricWavePainter extends CustomPainter {
  final double waveSeed;

  StockProductMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant StockProductMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}