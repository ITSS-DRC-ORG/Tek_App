import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tek_app/screens/admin/view/add_product_dialog.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../../models/product_model.dart';
import '../../../api/admin_service.dart';

class ProductView extends StatefulWidget {
  final AdminService service;
  const ProductView({super.key, required this.service});

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await widget.service.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = _products);
    } else {
      final lower = query.toLowerCase();
      setState(() {
        _filteredProducts = _products
            .where((p) =>
        p.nom.toLowerCase().contains(lower) ||
            p.code.toLowerCase().contains(lower))
            .toList();
      });
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
  // SUPPRESSION (Modale Windows 11)
  // ---------------------------------------------------------------------------
  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFC42B1C),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirmer la suppression',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "${product.nom}" (${product.code}) ?\nCette opération retirera définitivement l\'article du catalogue.',
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF5F6368),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4A4A4A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC42B1C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Supprimer le produit',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await widget.service.deleteProduct(product.id);
      if (success) {
        _showSnackBar('Produit "${product.nom}" supprimé avec succès', const Color(0xFF107C41));
        _loadProducts();
      } else {
        _showSnackBar('Impossible de supprimer le produit', const Color(0xFFC42B1C));
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
  }

  Future<void> _editProduct(Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddProductDialog(service: widget.service, product: product),
    );
    if (result == true) _loadProducts();
  }

  Future<void> _addProduct() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddProductDialog(service: widget.service),
    );
    if (result == true) _loadProducts();
  }

  // ---------------------------------------------------------------------------
  // BUILD PRINCIPAL
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Les 3 Cartes Métriques avec Motifs Ondes Fluides
        _buildStockMetricsRow(),
        const SizedBox(height: 18),

        // 2. Barre d'outils (Recherche & Nouveau Produit)
        _buildActionBar(isWide),
        const SizedBox(height: 14),

        // 3. Tableau de données principal
        Expanded(
          child: _isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0067C0),
              strokeWidth: 2.2,
            ),
          )
              : Container(
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
            child: _filteredProducts.isEmpty
                ? _buildEmptyState()
                : isWide
                ? _buildFullDataTable()
                : _buildMobileDataRows(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (STYLE RÉFÉRENCE)
  // ---------------------------------------------------------------------------
  Widget _buildStockMetricsRow() {
    final total = _products.length;
    final actifs = _products.where((p) => p.actif).length;
    final alertes = _products.where((p) => p.seuilAlerte > 0).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 740;

        final cards = [
          _buildWaveMetricCard(
            title: "TOTAL ARTICLES",
            value: "$total",
            subtitle: "Références enregistrées",
            badge: "Catalogue",
            icon: Icons.inventory_2_outlined,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "DISPONIBLES EN VENTE",
            value: "$actifs",
            subtitle: "Articles actifs en caisse",
            badge: "En Vente",
            icon: Icons.check_circle_outline_rounded,
            gradient: const [
              Color(0xFF0A3B5C),
              Color(0xFF165B8C),
              Color(0xFF3A89C9),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "SEUILS D'ALERTE",
            value: "$alertes",
            subtitle: "Sous surveillance active",
            badge: "Surveillance",
            icon: Icons.notifications_active_outlined,
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

  // Composant Carte avec Bannière Vectorielle Fluide Windows 11
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
          // Bannière supérieure avec ondulations vectorielles
          SizedBox(
            height: 64,
            child: Stack(
              children: [
                // Dégradé de base
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                ),
                // Ondes vectorielles fluides
                Positioned.fill(
                  child: CustomPaint(
                    painter: MetricWavePainter(waveSeed: waveSeed),
                  ),
                ),
                // Contenu sur l'onde : Icône & Tag
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

          // Pied de carte blanc avec Métrique & Libellés
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
  // 2. BARRE D'ACTIONS (Recherche, Décompte & Bouton Principal)
  // ---------------------------------------------------------------------------
  Widget _buildActionBar(bool isWide) {
    return Row(
      children: [
        // Champ de recherche Fluent
        Expanded(
          flex: isWide ? 0 : 1,
          child: SizedBox(
            width: isWide ? 310 : null,
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filterProducts,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1F1F1F),
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher par code ou désignation...',
                hintStyle: const TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFF9CA3AF),
                  fontSize: 12.5,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6B7280),
                  size: 18,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  splashRadius: 14,
                  icon: const Icon(Icons.clear_rounded, size: 15, color: Color(0xFF6B7280)),
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
                  borderSide: const BorderSide(color: Color(0x18000000), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x18000000), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5),
                ),
              ),
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
              color: Color(0xFF6B7280),
            ),
          ),
        ],

        const Spacer(),

        // Bouton Nouveau Produit
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: _addProduct,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: Text(isWide ? "Nouveau Produit" : "Ajouter"),
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
  // 3. TABLEAU DE DONNÉES DESKTOP
  // ---------------------------------------------------------------------------
  Widget _buildFullDataTable() {
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
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
                horizontalMargin: 20,
                columnSpacing: 24,
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text("CODE ARTICLE", style: _headerStyle)),
                  DataColumn(label: Text("DÉSIGNATION", style: _headerStyle)),
                  DataColumn(label: Text("PRIX ACHAT", style: _headerStyle)),
                  DataColumn(label: Text("PRIX VENTE", style: _headerStyle)),
                  DataColumn(label: Text("UNITÉ", style: _headerStyle)),
                  DataColumn(label: Text("SEUIL ALERTE", style: _headerStyle)),
                  DataColumn(label: Text("STATUT", style: _headerStyle)),
                  DataColumn(label: Text("ACTIONS", style: _headerStyle)),
                ],
                rows: _filteredProducts.map((p) {
                  return DataRow(
                    cells: [
                      // 1. Code Article
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0x10000000)),
                          ),
                          child: Text(
                            p.code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      // 2. Nom du produit
                      DataCell(
                        Text(
                          p.nom,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // 3. Prix Achat
                      DataCell(
                        Text(
                          '${p.prixAchat.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // 4. Prix Vente
                      DataCell(
                        Text(
                          '${p.prixVente.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0067C0),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // 5. Unité
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p.unite,
                            style: const TextStyle(
                              fontFamily: kAppFontFamily,
                              color: Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // 6. Seuil Alerte
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 13,
                              color: p.seuilAlerte > 0
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${p.seuilAlerte}',
                              style: TextStyle(
                                fontFamily: kAppFontFamily,
                                fontWeight: FontWeight.w400,
                                color: p.seuilAlerte > 0
                                    ? const Color(0xFF1F1F1F)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 7. Statut
                      DataCell(_buildStatusBadge(p.actif)),

                      // 8. Actions
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF0067C0),
                                size: 17,
                              ),
                              splashRadius: 14,
                              tooltip: 'Modifier',
                              onPressed: () => _editProduct(p),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFC42B1C),
                                size: 17,
                              ),
                              splashRadius: 14,
                              tooltip: 'Supprimer',
                              onPressed: () => _deleteProduct(p),
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
  // 4. AFFICHAGE MOBILE CONDENSÉ
  // ---------------------------------------------------------------------------
  Widget _buildMobileDataRows() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final p = _filteredProducts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.nom,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${p.unite} • Seuil: ${p.seuilAlerte}',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.prixVente.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Color(0xFF0067C0),
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildStatusBadge(p.actif),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF0067C0), size: 18),
                    onPressed: () => _editProduct(p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC42B1C), size: 18),
                    onPressed: () => _deleteProduct(p),
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
  // PASTILLE DE STATUT (Actif / Inactif)
  // ---------------------------------------------------------------------------
  Widget _buildStatusBadge(bool actif) {
    final color = actif ? const Color(0xFF107C41) : const Color(0xFFC42B1C);
    final bgColor = actif ? const Color(0xFFE6F4EA) : const Color(0xFFFDE8E8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            actif ? 'Actif' : 'Inactif',
            style: TextStyle(
              fontFamily: kAppFontFamily,
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Aucun article enregistré'
                  : 'Aucun résultat trouvé',
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
                  : 'Modifiez les critères ou effacez le terme de recherche.',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'Effacer le filtre',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES DE MÉTRIQUES
// ---------------------------------------------------------------------------
class MetricWavePainter extends CustomPainter {
  final double waveSeed;

  MetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant MetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}