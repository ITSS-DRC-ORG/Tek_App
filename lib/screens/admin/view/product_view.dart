import 'package:flutter/material.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import 'package:tek_app/screens/admin/view/add_product_dialog.dart';
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
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = _products);
    } else {
      setState(() {
        _filteredProducts = _products.where((p) =>
          p.nom.toLowerCase().contains(query.toLowerCase()) ||
          p.code.toLowerCase().contains(query.toLowerCase())
        ).toList();
      });
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
  // DELETE
  // ---------------------------------------------------------------------
  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: K.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, color: K.danger, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirmer la suppression',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer le produit "${product.nom}" ?\nCette action est irréversible.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: K.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: K.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await widget.service.deleteProduct(product.id);
      if (success) {
        _showSnackBar('✅ Produit "${product.nom}" supprimé avec succès', Colors.green);
        _loadProducts();
      } else {
        _showSnackBar('❌ Erreur lors de la suppression', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
    }
  }

  // ---------------------------------------------------------------------
  // UPDATE - Ouvre le dialogue en mode édition
  // ---------------------------------------------------------------------
  Future<void> _editProduct(Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddProductDialog(
        service: widget.service,
        product: product,
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  // ---------------------------------------------------------------------
  // CREATE - Ouvre le dialogue en mode création
  // ---------------------------------------------------------------------
  Future<void> _addProduct() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddProductDialog(
        service: widget.service,
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Column(
      children: [
        if (isWide)
          _buildDesktopHeader()
        else
          _buildMobileHeader(),
        const SizedBox(height: 20),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: K.primary))
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: K.border),
                  ),
                  child: _filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : isWide
                          ? _buildDesktopTable()
                          : _buildMobileList(),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // HEADERS
  // ---------------------------------------------------------------------
  Widget _buildDesktopHeader() {
    return Row(
      children: [
        StatChip(
          icon: Icons.inventory_2_rounded,
          label: "Total Produits",
          value: "${_products.length}",
          color: K.info,
        ),
        const SizedBox(width: 12),
        StatChip(
          icon: Icons.check_circle_rounded,
          label: "Actifs",
          value: "${_products.where((p) => p.actif).length}",
          color: K.success,
        ),
        const Spacer(),
        SizedBox(
          width: 200,
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filterProducts,
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              hintStyle: const TextStyle(color: K.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: K.textMuted, size: 20),
              filled: true,
              fillColor: K.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(K.radiusSm),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _addProduct,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text("Nouveau Produit"),
          style: ElevatedButton.styleFrom(
            backgroundColor: K.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(K.radiusSm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Row(
          children: [
            StatChip(
              icon: Icons.inventory_2_rounded,
              label: "Total",
              value: "${_products.length}",
              color: K.info,
            ),
            const SizedBox(width: 8),
            StatChip(
              icon: Icons.check_circle_rounded,
              label: "Actifs",
              value: "${_products.where((p) => p.actif).length}",
              color: K.success,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _addProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: K.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(K.radiusSm),
                ),
              ),
              child: const Icon(Icons.add_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchCtrl,
          onChanged: _filterProducts,
          decoration: InputDecoration(
            hintText: 'Rechercher un produit...',
            hintStyle: const TextStyle(color: K.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: K.textMuted, size: 20),
            filled: true,
            fillColor: K.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(K.radiusSm),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // TABLE DESKTOP
  // ---------------------------------------------------------------------
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(K.surfaceAlt),
        horizontalMargin: 20,
        columnSpacing: 30,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 52,
        columns: const [
          DataColumn(label: Text("Code", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Désignation", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Prix Achat", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Prix Vente", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Unité", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Seuil", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Statut", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _filteredProducts.map((p) {
          final isEven = _filteredProducts.indexOf(p).isEven;
          return DataRow(
            color: MaterialStateProperty.all(
              isEven ? Colors.white : K.surfaceAlt.withOpacity(0.5),
            ),
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: K.accentSoft,
                    borderRadius: BorderRadius.circular(K.radiusXl),
                  ),
                  child: Text(
                    p.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: K.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  p.nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: K.textPrimary,
                  ),
                ),
              ),
              DataCell(
                // ✅ Correction 1: Utiliser \$
                Text(
                  '${p.prixAchat} \$',
                  style: const TextStyle(color: K.textMuted),
                ),
              ),
              DataCell(
                // ✅ Correction 1: Utiliser \$
                Text(
                  '${p.prixVente} \$',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: K.success,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: K.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(K.radiusXl),
                  ),
                  child: Text(
                    p.unite,
                    style: const TextStyle(
                      color: K.info,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${p.seuilAlerte}',
                  style: const TextStyle(color: K.textMuted),
                ),
              ),
              DataCell(_buildStatusBadge(p.actif)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: K.info, size: 18),
                      onPressed: () => _editProduct(p),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, color: K.danger, size: 18),
                      onPressed: () => _deleteProduct(p),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LISTE MOBILE
  // ---------------------------------------------------------------------
  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const Divider(color: K.border, height: 1),
      itemBuilder: (context, index) {
        final p = _filteredProducts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(K.radiusSm),
            side: BorderSide(color: K.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: K.accentSoft,
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
              child: Center(
                child: Text(
                  p.code.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: K.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              p.nom,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: K.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.code} • ${p.unite}',
                  style: const TextStyle(color: K.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // ✅ Correction 1: Utiliser \$
                    Text(
                      '${p.prixVente} \$',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: K.success,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(p.actif),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: K.info, size: 20),
                  onPressed: () => _editProduct(p),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: K.danger, size: 20),
                  onPressed: () => _deleteProduct(p),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // BADGES
  // ---------------------------------------------------------------------
  Widget _buildStatusBadge(bool actif) {
    final color = actif ? K.success : K.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(K.radiusXl),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            actif ? 'Actif' : 'Inactif',
            style: TextStyle(
              color: color,
              fontSize: 10,
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
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchCtrl.text.isEmpty ? Icons.inventory_2_rounded : Icons.search_off_rounded,
            size: 48,
            color: K.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            _searchCtrl.text.isEmpty ? 'Aucun produit enregistré' : 'Aucun résultat trouvé',
            style: const TextStyle(color: K.textMuted, fontSize: 14),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                _filterProducts('');
              },
              child: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }
}