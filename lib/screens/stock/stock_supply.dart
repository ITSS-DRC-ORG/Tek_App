import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';
import '../../models/product_model.dart';
import '../../models/depot_model.dart';
import '../../models/stock_model.dart';

class StockSupply extends StatefulWidget {
  const StockSupply({super.key});

  @override
  State<StockSupply> createState() => _StockSupplyState();
}

class _StockSupplyState extends State<StockSupply>
    with SingleTickerProviderStateMixin {
  // Données
  List<Depot> _depots = [];
  List<Product> _products = [];
  List<Stock> _stocks = [];
  List<Product> _filteredProducts = [];
  int? _selectedDepotId;
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  // Animation
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

        final depots = await service.getDepots();
        final products = await service.getAllProducts();
        final stocks = await service.getStocks();

        setState(() {
          _depots = depots;
          _products = products;
          _filteredProducts = products;
          _stocks = stocks;
          if (_depots.isNotEmpty && _selectedDepotId == null) {
            _selectedDepotId = _depots.first.id;
          }
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  // ---------------------------------------------------------------------------
  // FILTRES
  // ---------------------------------------------------------------------------
  void _filterProducts() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.nom.toLowerCase().contains(query) ||
            product.code.toLowerCase().contains(query);
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // RAVITAILLEMENT AVEC MODALE WINDOWS 11 FLUENT
  // ---------------------------------------------------------------------------
  void _showSupplyModal(Product product) {
    final TextEditingController quantityCtrl = TextEditingController(text: '1');
    int selectedQuantity = 1;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 520,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
                maxWidth: 520,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x18000000), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // En-tête Fluent sobre
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2FB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_shipping_outlined,
                            color: Color(0xFF0067C0),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ravitaillement de Stock',
                              style: TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Entrée de marchandises dans l\'entrepôt sélectionné',
                              style: TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          splashRadius: 16,
                          icon: const Icon(Icons.close_rounded, size: 19),
                          color: const Color(0xFF64748B),
                          onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, thickness: 1, color: Color(0x14000000)),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductInfo(product),
                          const SizedBox(height: 18),
                          _buildDepotSelectorModal(setStateModal),
                          const SizedBox(height: 18),
                          _buildQuantitySelector(
                            quantityCtrl,
                            selectedQuantity,
                            setStateModal,
                                (value) => selectedQuantity = value,
                          ),
                          const SizedBox(height: 18),
                          _buildStockSummary(product, selectedQuantity),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1, thickness: 1, color: Color(0x14000000)),

                  // Pied de dialogue avec boutons d'actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0x20000000)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                            final quantity = int.tryParse(quantityCtrl.text) ?? 1;

                            if (_selectedDepotId == null) {
                              _showSnackBar('Veuillez sélectionner un dépôt', const Color(0xFFD97706));
                              return;
                            }

                            if (quantity <= 0) {
                              _showSnackBar('La quantité doit être supérieure à 0', const Color(0xFFD97706));
                              return;
                            }

                            setStateModal(() => isSubmitting = true);

                            try {
                              await _supplyProduct(product, _selectedDepotId!, quantity);
                              if (!context.mounted) return;
                              Navigator.pop(dialogContext);
                            } catch (_) {
                              // Géré dans _supplyProduct
                            } finally {
                              if (mounted) setStateModal(() => isSubmitting = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0067C0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                              : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Valider le ravitaillement',
                                style: TextStyle(
                                  fontFamily: kAppFontFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS DE LA MODALE
  // ---------------------------------------------------------------------------
  Widget _buildProductInfo(Product product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                product.code.isNotEmpty ? product.code.substring(0, 1).toUpperCase() : 'P',
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFF0067C0),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
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
                  product.nom,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF1E293B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Unité : ${product.unite}',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${product.prixVente.toStringAsFixed(2)} \$',
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0067C0),
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepotSelectorModal(StateSetter setStateModal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DÉPÔT DE DESTINATION',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButton<int>(
            value: _selectedDepotId,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFFFFFFFF),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
            items: _depots.map((depot) {
              return DropdownMenuItem(
                value: depot.id,
                child: Row(
                  children: [
                    Icon(
                      depot.estMagasin ? Icons.storefront_outlined : Icons.warehouse_outlined,
                      color: const Color(0xFF0067C0),
                      size: 17,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      depot.nom,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setStateModal(() => _selectedDepotId = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(
      TextEditingController quantityCtrl,
      int selectedQuantity,
      StateSetter setStateModal,
      Function(int) onQuantityChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUANTITÉ À AJOUTER',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildQuantityStepBtn('-', () {
              if (selectedQuantity > 1) {
                final newValue = selectedQuantity - 1;
                quantityCtrl.text = newValue.toString();
                onQuantityChanged(newValue);
                setStateModal(() {});
              }
            }),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: quantityCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) {
                    final int? parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      onQuantityChanged(parsed);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildQuantityStepBtn('+', () {
              final newValue = selectedQuantity + 1;
              quantityCtrl.text = newValue.toString();
              onQuantityChanged(newValue);
              setStateModal(() {});
            }),
          ],
        ),
        const SizedBox(height: 10),
        // Pastilles de quantités rapides
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [5, 10, 25, 50, 100].map((q) {
            return _buildQuickPill(q, () {
              quantityCtrl.text = q.toString();
              onQuantityChanged(q);
              setStateModal(() {});
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantityStepBtn(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 40,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPill(int value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x10000000)),
        ),
        child: Text(
          '+$value',
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildStockSummary(Product product, int selectedQuantity) {
    final currentStock = _getCurrentStock(product.id);
    final newStock = currentStock + selectedQuantity;
    final isLowStock = newStock < product.seuilAlerte;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Stock actuel',
                  value: '$currentStock',
                  color: currentStock < product.seuilAlerte
                      ? const Color(0xFFD97706)
                      : const Color(0xFF1E293B),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF94A3B8)),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Entrée prévue',
                  value: '+$selectedQuantity',
                  color: const Color(0xFF0067C0),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF94A3B8)),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Nouveau stock',
                  value: '$newStock',
                  color: isLowStock
                      ? const Color(0xFFD97706)
                      : const Color(0xFF107C41),
                ),
              ),
            ],
          ),
          if (isLowStock) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce volume reste inférieur au seuil minimal requis (${product.seuilAlerte})',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        color: Color(0xFFB45309),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  int _getCurrentStock(int productId) {
    return _stocks
        .where((s) => s.produitId == productId && s.depotId == _selectedDepotId)
        .fold(0, (sum, s) => sum + s.quantite);
  }

  Future<void> _supplyProduct(Product product, int depotId, int quantity) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        _showSnackBar('Utilisateur non connecté', const Color(0xFFC42B1C));
        return;
      }

      final service = AdminService(user.token);

      final existingStock = _stocks.firstWhere(
            (s) => s.produitId == product.id && s.depotId == depotId,
        orElse: () {
          return Stock(
            id: 0,
            produitId: product.id,
            depotId: depotId,
            quantite: 0,
            quantiteMinimale: product.seuilAlerte,
            quantiteMaximale: 500,
            enAlerte: false,
            produitNom: product.nom,
            produitCode: product.code,
            depotNom: _depots.firstWhere((d) => d.id == depotId).nom,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        },
      );

      final newQuantity = existingStock.quantite + quantity;

      await service.ajusterStock(
        produitId: product.id,
        depotId: depotId,
        quantite: newQuantity,
        quantiteMinimale: existingStock.quantiteMinimale,
        quantiteMaximale: existingStock.quantiteMaximale,
      );

      _showSnackBar(
        '$quantity ${product.unite}(s) de "${product.nom}" approvisionné(s)',
        const Color(0xFF107C41),
      );

      await _refreshData();
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
      rethrow;
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
                  : color == const Color(0xFFD97706)
                  ? Icons.warning_rounded
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
            // 1. Indicateurs Synthétiques avec Ondes Fluides
            _buildSupplyMetricsRow(),
            const SizedBox(height: 18),

            // 2. Barre d'outils (Sélection Dépôt & Recherche)
            _buildToolbar(isWide),
            const SizedBox(height: 14),

            // 3. Tableau de Ravitaillement
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
                child: _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : isWide
                    ? _buildDesktopDataTable()
                    : _buildMobileDataRows(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildSupplyMetricsRow() {
    final totalProducts = _products.length;
    String activeDepotName = 'Sélectionner';
    for (final d in _depots) {
      if (d.id == _selectedDepotId) {
        activeDepotName = d.nom;
        break;
      }
    }
    if (activeDepotName == 'Sélectionner' && _depots.isNotEmpty) {
      activeDepotName = _depots.first.nom;
    }
    final lowStockCount = _products.where((p) {
      final stock = _getCurrentStock(p.id);
      return stock < p.seuilAlerte;
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 740;

        final cards = [
          _buildWaveMetricCard(
            title: "TOTAL CATALOGUE",
            value: "$totalProducts",
            subtitle: "Articles référencés",
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
            title: "DÉPÔT EN COURS",
            value: activeDepotName,
            subtitle: "Site d'affectation actif",
            badge: "Cible",
            icon: Icons.warehouse_outlined,
            gradient: const [
              Color(0xFF0A3B5C),
              Color(0xFF165B8C),
              Color(0xFF3A89C9),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "SOUS LE SEUIL",
            value: "$lowStockCount",
            subtitle: "Articles à réapprovisionner",
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
          // Bannière supérieure fluide
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
                    painter: SupplyMetricWavePainter(waveSeed: waveSeed),
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

          // Pied de carte blanc
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
  // 2. BARRE D'OUTILS
  // ---------------------------------------------------------------------------
  Widget _buildToolbar(bool isWide) {
    return Row(
      children: [
        // Sélecteur de Dépôt Cible
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x18000000), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warehouse_outlined, size: 17, color: Color(0xFF0067C0)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedDepotId,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFFFFFFFF),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                items: _depots.map((depot) {
                  return DropdownMenuItem(
                    value: depot.id,
                    child: Text(
                      depot.nom,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDepotId = value);
                },
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Recherche d'article
        Expanded(
          flex: isWide ? 0 : 1,
          child: SizedBox(
            width: isWide ? 280 : null,
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _filterProducts(),
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1F1F1F),
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher un article...',
                hintStyle: const TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFF9CA3AF),
                  fontSize: 12.5,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  splashRadius: 14,
                  icon: const Icon(Icons.clear_rounded, size: 15, color: Color(0xFF6B7280)),
                  onPressed: () {
                    _searchCtrl.clear();
                    _filterProducts();
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
            "${_filteredProducts.length} article(s)",
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ],

        const Spacer(),

        // Bouton Rafraîchir
        SizedBox(
          height: 38,
          child: OutlinedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0x20000000)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
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
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
                horizontalMargin: 20,
                columnSpacing: 26,
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text("CODE", style: _headerStyle)),
                  DataColumn(label: Text("DÉSIGNATION", style: _headerStyle)),
                  DataColumn(label: Text("UNITÉ", style: _headerStyle)),
                  DataColumn(label: Text("STOCK EN DÉPÔT", style: _headerStyle)),
                  DataColumn(label: Text("SEUIL MINIMAL", style: _headerStyle)),
                  DataColumn(label: Text("PRIX VENTE", style: _headerStyle)),
                  DataColumn(label: Text("ACTION", style: _headerStyle)),
                ],
                rows: _filteredProducts.map((product) {
                  final currentStock = _getCurrentStock(product.id);
                  final isLowStock = currentStock < product.seuilAlerte;

                  return DataRow(
                    cells: [
                      // Code Article
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

                      // Nom
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

                      // Unité
                      DataCell(
                        Text(
                          product.unite,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ),

                      // Stock en Dépôt + Statut
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$currentStock',
                              style: TextStyle(
                                fontFamily: kAppFontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: currentStock == 0
                                    ? const Color(0xFFC42B1C)
                                    : isLowStock
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF107C41),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStockStatusBadge(currentStock, product.seuilAlerte),
                          ],
                        ),
                      ),

                      // Seuil
                      DataCell(
                        Text(
                          '${product.seuilAlerte}',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ),

                      // Prix Vente
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

                      // Bouton Ravitailler
                      DataCell(
                        ElevatedButton.icon(
                          onPressed: () => _showSupplyModal(product),
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text('Ravitailler'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0067C0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            textStyle: const TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

  Widget _buildStockStatusBadge(int currentStock, int seuil) {
    Color color;
    Color bgColor;
    String label;

    if (currentStock == 0) {
      color = const Color(0xFFC42B1C);
      bgColor = const Color(0xFFFDE8E8);
      label = 'Rupture';
    } else if (currentStock < seuil) {
      color = const Color(0xFFB45309);
      bgColor = const Color(0xFFFEF3C7);
      label = 'Stock bas';
    } else {
      color = const Color(0xFF107C41);
      bgColor = const Color(0xFFE6F4EA);
      label = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: kAppFontFamily,
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. LIGNES MOBILE
  // ---------------------------------------------------------------------------
  Widget _buildMobileDataRows() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final currentStock = _getCurrentStock(product.id);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nom,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.code} • Stock: $currentStock ${product.unite}',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showSupplyModal(product),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('Ravitailler'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0067C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        );
      },
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
              child: const Icon(Icons.inventory_2_outlined, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Aucun article disponible pour ravitaillement'
                  : 'Aucun résultat correspondant',
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
                  ? 'Créez d\'abord des produits dans le catalogue.'
                  : 'Modifiez vos termes de recherche.',
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
                  _filterProducts();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0067C0),
                  side: const BorderSide(color: Color(0xFF0067C0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Effacer la recherche'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES DE RAVITAILLEMENT
// ---------------------------------------------------------------------------
class SupplyMetricWavePainter extends CustomPainter {
  final double waveSeed;

  SupplyMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant SupplyMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}