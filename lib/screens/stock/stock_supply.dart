import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';
import '../../models/product_model.dart';
import '../../models/depot_model.dart';
import '../../models/stock_model.dart';

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

class StockSupply extends StatefulWidget {
  const StockSupply({super.key});

  @override
  State<StockSupply> createState() => _StockSupplyState();
}

class _StockSupplyState extends State<StockSupply> with SingleTickerProviderStateMixin {
  // Données
  List<Depot> _depots = [];
  List<Product> _products = [];
  List<Stock> _stocks = [];
  List<Product> _filteredProducts = [];
  int? _selectedDepotId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // Animation
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
    _searchCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // LOAD DATA
  // ---------------------------------------------------------------------
  Future<void> _loadData() async {
    print('📦 Chargement des données...');
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        
        print('🔍 Récupération des dépôts...');
        final depots = await service.getDepots();
        print('✅ Dépôts récupérés: ${depots.length}');
        
        print('🔍 Récupération des produits...');
        final products = await service.getAllProducts();
        print('✅ Produits récupérés: ${products.length}');
        
        print('🔍 Récupération des stocks...');
        final stocks = await service.getStocks();
        print('✅ Stocks récupérés: ${stocks.length}');

        setState(() {
          _depots = depots;
          _products = products;
          _filteredProducts = products;
          _stocks = stocks;
          if (_depots.isNotEmpty && _selectedDepotId == null) {
            _selectedDepotId = _depots.first.id;
            print('🏢 Dépôt sélectionné par défaut: ${_depots.first.nom} (ID: ${_depots.first.id})');
          }
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _refreshData() async {
    print('🔄 Rafraîchissement des données...');
    await _loadData();
  }

  // ---------------------------------------------------------------------
  // FILTRES
  // ---------------------------------------------------------------------
  void _filterProducts() {
    final query = _searchCtrl.text.toLowerCase();
    print('🔍 Recherche: "$query"');
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = product.nom.toLowerCase().contains(query) ||
            product.code.toLowerCase().contains(query);
        return matchesSearch;
      }).toList();
      print('📊 Résultats: ${_filteredProducts.length} produits trouvés');
    });
  }

  // ---------------------------------------------------------------------
  // RAVITAILLEMENT AVEC MODALE
  // ---------------------------------------------------------------------
  void _showSupplyModal(Product product) {
    print('📦 Ouverture modale pour: ${product.nom} (ID: ${product.id})');
    
    final TextEditingController quantityCtrl = TextEditingController(text: '1');
    int selectedQuantity = 1;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width >= 600 ? 500 : double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 500,
              ),
              decoration: BoxDecoration(
                color: K.surface,
                borderRadius: BorderRadius.circular(K.radiusXl),
                border: Border.all(color: K.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(K.radiusXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [K.success, K.success.withOpacity(0.8)],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(K.radiusSm),
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ravitaillement',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Ajoutez des produits au stock',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              onPressed: isSubmitting ? null : () {
                                print('❌ Annulation du ravitaillement');
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProductInfo(product),
                            const SizedBox(height: 20),
                            _buildDepotSelectorModal(setStateModal),
                            const SizedBox(height: 20),
                            _buildQuantitySelector(
                              quantityCtrl,
                              selectedQuantity,
                              setStateModal,
                              (value) => selectedQuantity = value,
                            ),
                            const SizedBox(height: 20),
                            _buildStockSummary(product, selectedQuantity),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: K.border, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting ? null : () {
                                print('❌ Annulation du ravitaillement');
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: K.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(K.radiusSm),
                                ),
                              ),
                              child: const Text(
                                'Annuler',
                                style: TextStyle(color: K.textMuted),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : () async {
                                final quantity = int.tryParse(quantityCtrl.text) ?? 1;
                                print('🚀 Lancement du ravitaillement...');
                                print('📦 Produit: ${product.nom} (ID: ${product.id})');
                                print('🏢 Dépôt ID: $_selectedDepotId');
                                print('📊 Quantité: $quantity');

                                if (_selectedDepotId == null) {
                                  print('❌ Aucun dépôt sélectionné');
                                  _showSnackBar('Veuillez sélectionner un dépôt', Colors.orange);
                                  return;
                                }

                                if (quantity <= 0) {
                                  print('❌ Quantité invalide: $quantity');
                                  _showSnackBar('La quantité doit être supérieure à 0', Colors.orange);
                                  return;
                                }

                                setStateModal(() => isSubmitting = true);

                                try {
                                  print('📤 Appel API pour ravitailler...');
                                  await _supplyProduct(product, _selectedDepotId!, quantity);
                                  print('✅ Ravitaillement réussi !');
                                  
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                } catch (e) {
                                  print('❌ Erreur ravitaillement: $e');
                                  _showSnackBar('Erreur: ${e.toString()}', Colors.red);
                                } finally {
                                  setStateModal(() => isSubmitting = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: K.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(K.radiusSm),
                                ),
                                elevation: 0,
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_rounded, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Ravitaillement'),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).then((_) {
      print('🔚 Modale fermée');
    });
  }

  // ---------------------------------------------------------------------
  // WIDGETS DE LA MODALE
  // ---------------------------------------------------------------------
  Widget _buildProductInfo(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [K.accentSoft, K.primary.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(K.radiusSm),
            ),
            child: Center(
              child: Text(
                product.code.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: K.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: K.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: K.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(K.radiusXl),
                      ),
                      child: Text(
                        product.code,
                        style: const TextStyle(
                          color: K.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: K.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(K.radiusXl),
                      ),
                      child: Text(
                        product.unite,
                        style: const TextStyle(
                          color: K.info,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: K.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(K.radiusXl),
              border: Border.all(color: K.success.withOpacity(0.2)),
            ),
            child: Text(
              '\$${product.prixVente.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: K.success,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepotSelectorModal(StateSetter setStateModal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warehouse_rounded, color: K.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Dépôt cible',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: K.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: K.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(K.radiusXl),
                ),
                child: const Text(
                  'Obligatoire',
                  style: TextStyle(
                    color: K.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: K.surface,
              borderRadius: BorderRadius.circular(K.radiusSm),
              border: Border.all(color: K.border),
            ),
            child: DropdownButton<int>(
              value: _selectedDepotId,
              isExpanded: true,
              underline: Container(),
              dropdownColor: K.surface,
              items: _depots.map((depot) {
                return DropdownMenuItem(
                  value: depot.id,
                  child: Row(
                    children: [
                      Icon(
                        depot.estMagasin ? Icons.store_rounded : Icons.warehouse_rounded,
                        color: K.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        depot.nom,
                        style: const TextStyle(color: K.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: K.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(K.radiusXl),
                        ),
                        child: Text(
                          depot.estMagasin ? 'Magasin' : 'Entrepôt',
                          style: const TextStyle(
                            fontSize: 9,
                            color: K.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                print('🔄 Changement de dépôt: $value');
                setStateModal(() {
                  _selectedDepotId = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(
    TextEditingController quantityCtrl,
    int selectedQuantity,
    StateSetter setStateModal,
    Function(int) onQuantityChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_rounded, color: K.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Quantité à ajouter',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: K.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: K.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(K.radiusXl),
                ),
                child: const Text(
                  'En unités',
                  style: TextStyle(
                    color: K.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuantityButtonModal('-', () {
                if (selectedQuantity > 1) {
                  final newValue = selectedQuantity - 1;
                  selectedQuantity = newValue;
                  quantityCtrl.text = newValue.toString();
                  onQuantityChanged(newValue);
                  setStateModal(() {});
                  print('📉 Quantité: $selectedQuantity');
                }
              }),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: K.surface,
                    borderRadius: BorderRadius.circular(K.radiusSm),
                    border: Border.all(color: K.border),
                  ),
                  child: TextField(
                    controller: quantityCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: K.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (value) {
                      final int? parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        selectedQuantity = parsed;
                        onQuantityChanged(parsed);
                        print('📝 Quantité saisie: $selectedQuantity');
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildQuantityButtonModal('+', () {
                final newValue = selectedQuantity + 1;
                selectedQuantity = newValue;
                quantityCtrl.text = newValue.toString();
                onQuantityChanged(newValue);
                setStateModal(() {});
                print('📈 Quantité: $selectedQuantity');
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickChipModal(5, () {
                selectedQuantity = 5;
                quantityCtrl.text = '5';
                onQuantityChanged(5);
                setStateModal(() {});
                print('⚡ Quantité rapide: 5');
              }),
              _buildQuickChipModal(10, () {
                selectedQuantity = 10;
                quantityCtrl.text = '10';
                onQuantityChanged(10);
                setStateModal(() {});
                print('⚡ Quantité rapide: 10');
              }),
              _buildQuickChipModal(25, () {
                selectedQuantity = 25;
                quantityCtrl.text = '25';
                onQuantityChanged(25);
                setStateModal(() {});
                print('⚡ Quantité rapide: 25');
              }),
              _buildQuickChipModal(50, () {
                selectedQuantity = 50;
                quantityCtrl.text = '50';
                onQuantityChanged(50);
                setStateModal(() {});
                print('⚡ Quantité rapide: 50');
              }),
              _buildQuickChipModal(100, () {
                selectedQuantity = 100;
                quantityCtrl.text = '100';
                onQuantityChanged(100);
                setStateModal(() {});
                print('⚡ Quantité rapide: 100');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButtonModal(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: K.surface,
        foregroundColor: K.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(44, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.radiusSm),
          side: BorderSide(color: K.border),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuickChipModal(int value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: K.surface,
          borderRadius: BorderRadius.circular(K.radiusXs),
          border: Border.all(color: K.border),
        ),
        child: Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: K.primary,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: 'Stock actuel',
                  value: '$currentStock',
                  color: currentStock < product.seuilAlerte ? K.warning : K.success,
                  icon: Icons.inventory_2_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  label: 'À ajouter',
                  value: '+$selectedQuantity',
                  color: K.primary,
                  icon: Icons.add_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Nouveau stock',
                  value: '$newStock',
                  color: isLowStock ? K.warning : K.success,
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
          if (isLowStock) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: K.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(K.radiusSm),
                border: Border.all(color: K.warning.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: K.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Le stock reste inférieur au seuil d\'alerte (${product.seuilAlerte})',
                      style: const TextStyle(
                        color: K.warning,
                        fontSize: 12,
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

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
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
    );
  }

  int _getCurrentStock(int productId) {
    return _stocks
        .where((s) => s.produitId == productId && s.depotId == _selectedDepotId)
        .fold(0, (sum, s) => sum + s.quantite);
  }

  Future<void> _supplyProduct(Product product, int depotId, int quantity) async {
    print('📦 Ravitaillement du produit: ${product.nom}');
    print('🏢 Dépôt ID: $depotId');
    print('📊 Quantité: $quantity');
    print('📊 Stock actuel: ${_getCurrentStock(product.id)}');

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        print('❌ Utilisateur non connecté');
        _showSnackBar('Utilisateur non connecté', Colors.red);
        return;
      }

      final service = AdminService(user.token);
      print('🔧 Service Admin créé');

      print('🔍 Récupération du stock existant...');
      final existingStock = _stocks.firstWhere(
        (s) => s.produitId == product.id && s.depotId == depotId,
        orElse: () {
          print('ℹ️ Aucun stock existant, création d\'un nouveau');
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

      print('📊 Stock existant: ${existingStock.quantite}');
      final newQuantity = existingStock.quantite + quantity;
      print('📊 Nouveau stock: $newQuantity');

      print('📤 Envoi de la requête d\'ajustement...');
      try {
        final result = await service.ajusterStock(
          produitId: product.id,
          depotId: depotId,
          quantite: newQuantity,
          quantiteMinimale: existingStock.quantiteMinimale,
          quantiteMaximale: existingStock.quantiteMaximale,
        );
        print('✅ Réponse API reçue');
        print('📊 Nouveau stock: ${result.quantite}');
        
        _showSnackBar(
          '✅ ${quantity} ${product.unite}(s) de "${product.nom}" ajoutés',
          Colors.green,
        );
        
        print('🔄 Rafraîchissement des données...');
        await _refreshData();
        
      } on Exception catch (e) {
        print('❌ Erreur API: $e');
        rethrow;
      }
      
    } catch (e) {
      print('❌ Erreur dans _supplyProduct: $e');
      print('📋 Stack trace: ${StackTrace.current}');
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
      rethrow;
    }
  }

  void _showSnackBar(String message, Color color) {
    print('📢 SnackBar: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle_rounded : 
              color == Colors.orange ? Icons.warning_rounded : 
              Icons.error_outline_rounded,
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
  // WIDGETS PRINCIPAUX
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
                    const SizedBox(height: 20),
                    _buildDepotSelector(),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _filteredProducts.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              itemCount: _filteredProducts.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductTile(product);
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [K.success, K.success.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(K.radiusSm),
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ravitaillement des stocks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: K.textPrimary,
                ),
              ),
              Text(
                'Ajoutez des produits dans les dépôts',
                style: TextStyle(
                  color: K.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh_rounded, color: K.primary),
          tooltip: 'Rafraîchir',
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: K.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(K.radiusXl),
          ),
          child: Text(
            '${_filteredProducts.length} produit${_filteredProducts.length > 1 ? 's' : ''}',
            style: const TextStyle(
              color: K.info,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepotSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.warehouse_rounded, color: K.primary),
          const SizedBox(width: 12),
          const Text(
            'Dépôt :',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: K.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<int>(
              value: _selectedDepotId,
              isExpanded: true,
              underline: Container(),
              dropdownColor: K.surface,
              items: _depots.map((depot) {
                return DropdownMenuItem(
                  value: depot.id,
                  child: Row(
                    children: [
                      Icon(
                        depot.estMagasin ? Icons.store_rounded : Icons.warehouse_rounded,
                        color: K.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        depot.nom,
                        style: const TextStyle(color: K.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: K.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(K.radiusXl),
                        ),
                        child: Text(
                          depot.estMagasin ? 'Magasin' : 'Entrepôt',
                          style: const TextStyle(
                            fontSize: 9,
                            color: K.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                print('🔄 Changement de dépôt: $value');
                setState(() {
                  _selectedDepotId = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _filterProducts(),
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
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: K.textMuted, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _filterProducts();
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: K.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(K.radiusXl),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.production_quantity_limits_rounded, color: K.info, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_filteredProducts.length}',
                style: const TextStyle(
                  color: K.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductTile(Product product) {
    final currentStock = _getCurrentStock(product.id);
    final isLowStock = currentStock < product.seuilAlerte;

    print('📊 Produit: ${product.nom} - Stock: $currentStock - Seuil: ${product.seuilAlerte}');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(K.radiusSm),
        side: BorderSide(
          color: currentStock == 0
              ? K.danger.withOpacity(0.2)
              : isLowStock
                  ? K.warning.withOpacity(0.3)
                  : K.border,
          width: currentStock == 0 ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          print('👆 Clic sur produit: ${product.nom} (ID: ${product.id})');
          _showSupplyModal(product);
        },
        borderRadius: BorderRadius.circular(K.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: K.accentSoft,
                  borderRadius: BorderRadius.circular(K.radiusSm),
                ),
                child: Center(
                  child: Text(
                    product.code.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: K.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                      product.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: K.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip(product.code, K.primary),
                        const SizedBox(width: 4),
                        _buildInfoChip(product.unite, K.info),
                        const SizedBox(width: 4),
                        _buildStockStatusChip(currentStock, product.seuilAlerte),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${product.prixVente.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: K.success,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      print('🔘 Bouton Ravitailler: ${product.nom}');
                      _showSupplyModal(product);
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Ravitaillement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: K.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(K.radiusXs),
                      ),
                      minimumSize: const Size(100, 36),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(K.radiusXl),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStockStatusChip(int currentStock, int seuil) {
    Color color;
    String label;

    if (currentStock == 0) {
      color = K.danger;
      label = 'Rupture';
    } else if (currentStock < seuil) {
      color = K.warning;
      label = 'Stock bas';
    } else {
      color = K.success;
      label = 'Stock OK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(K.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchCtrl.text.isEmpty ? Icons.inventory_2_rounded : Icons.search_off_rounded,
            size: 64,
            color: K.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isEmpty ? 'Aucun produit disponible' : 'Aucun résultat trouvé',
            style: const TextStyle(color: K.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _searchCtrl.text.isEmpty 
                ? 'Ajoutez des produits pour les ravitailler' 
                : 'Essayez un autre terme de recherche',
            style: const TextStyle(color: K.textMuted, fontSize: 13),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                _filterProducts();
              },
              child: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }
}