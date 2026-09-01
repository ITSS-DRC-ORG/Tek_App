import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import 'package:tek_app/screens/cashier/print/receipt_printer.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';
import '../../models/product_model.dart';
import '../../models/depot_model.dart';

class CashierNewSale extends StatefulWidget {
  const CashierNewSale({super.key});

  @override
  State<CashierNewSale> createState() => _CashierNewSaleState();
}

class _CashierNewSaleState extends State<CashierNewSale>
    with SingleTickerProviderStateMixin {
  // Données
  List<Product> _products = [];
  List<Depot> _depots = [];
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _stocks = []; // ✅ Ajout des stocks
  List<SaleLine> _saleLines = [];

  // Sélections
  int? _selectedClientId;
  int? _selectedDepotId;
  String _selectedModeLivraison = 'retrait_magasin';
  double _remise = 0.0;
  String _notes = '';

  // États
  bool _isLoading = true;
  bool _isSubmitting = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _remiseCtrl = TextEditingController(text: '0');
  final TextEditingController _notesCtrl = TextEditingController();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _remiseCtrl.dispose();
    _notesCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final products = await service.getAllProducts();
        final depots = await service.getDepots();
        final clients = await service.getClients();
        final stocks = await service.getStocks(); // ✅ Récupérer les stocks


        setState(() {
          _products = products;
          _depots = depots;
          _clients = clients.map((c) => c as Map<String, dynamic>).toList();
          _stocks = stocks.map((s) => s.toJson()).toList(); // ✅ Stocker les stocks

          if (_depots.isNotEmpty) {
            _selectedDepotId = _depots.first.id;
          }
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
    }
  }

   // ---------------------------------------------------------------------
  // RÉCUPÉRER LE STOCK D'UN PRODUIT DANS UN DÉPÔT
  // ---------------------------------------------------------------------
  int _getProductStock(int productId, int depotId) {
    final stock = _stocks.firstWhere(
      (s) => s['produit_id'] == productId && s['depot_id'] == depotId,
      orElse: () => {'quantite': 0},
    );
    return stock['quantite'] as int? ?? 0;
  }


  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle_rounded
                  : color == Colors.orange
                      ? Icons.warning_rounded
                      : Icons.error_outline_rounded,
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
  // GESTION PANIER
  // ---------------------------------------------------------------------
  void _addProduct(Product product) {
    final existingIndex =
        _saleLines.indexWhere((line) => line.productId == product.id);

    if (existingIndex != -1) {
      setState(() {
        _saleLines[existingIndex] = _saleLines[existingIndex].copyWith(
          quantity: _saleLines[existingIndex].quantity + 1,
        );
      });
    } else {
      setState(() {
        _saleLines.add(SaleLine(
          productId: product.id,
          productName: product.nom,
          productCode: product.code,
          unitPrice: product.prixVente,
          quantity: 1,
          total: product.prixVente,
        ));
      });
    }
    _showSnackBar('✅ ${product.nom} ajouté au panier', Colors.green);
  }

  void _removeProduct(int index) {
    setState(() {
      _saleLines.removeAt(index);
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeProduct(index);
      return;
    }
    setState(() {
      final line = _saleLines[index];
      _saleLines[index] = line.copyWith(
        quantity: newQuantity,
        total: line.unitPrice * newQuantity,
      );
    });
  }

  // ---------------------------------------------------------------------
  // CALCULS
  // ---------------------------------------------------------------------
  double get _subtotal {
    return _saleLines.fold(0, (sum, line) => sum + line.total);
  }

  double get _remiseValue {
    final value = double.tryParse(_remiseCtrl.text) ?? 0;
    return value.clamp(0, 100);
  }

  double get _remiseAmount {
    return _subtotal * (_remiseValue / 100);
  }

  double get _total {
    return _subtotal - _remiseAmount;
  }

  // ---------------------------------------------------------------------
  // ENREGISTREMENT
  // ---------------------------------------------------------------------
 Future<void> _saveSale() async {
  // ✅ Vérifications
  if (_selectedClientId == null) {
    _showSnackBar('Veuillez sélectionner un client', Colors.orange);
    return;
  }
  if (_selectedDepotId == null) {
    _showSnackBar('Veuillez sélectionner un dépôt', Colors.orange);
    return;
  }
  if (_saleLines.isEmpty) {
    _showSnackBar('Ajoutez au moins un produit', Colors.orange);
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      _showSnackBar('Utilisateur non connecté', Colors.red);
      return;
    }

    final service = AdminService(user.token);

    // Préparer les lignes pour l'API
    final lignes = _saleLines
        .map((line) => {
              'produit_id': line.productId,
              'quantite': line.quantity,
              'prix_unitaire': line.unitPrice,
            })
        .toList();

    // Créer la vente
    final result = await service.createSale(
      clientId: _selectedClientId!,
      depotSourceId: _selectedDepotId!,
      dateVente: DateTime.now().toIso8601String().split('T').first,
      lignes: lignes,
      remise: _remiseValue,
      modeLivraison: _selectedModeLivraison,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
    );

    final numeroFacture = result['numero_facture'] as String? ?? 'N/A';

    // ✅ Récupérer les données client et dépôt
    final client = _clients.firstWhere(
      (c) => c['id'] == _selectedClientId,
      orElse: () => {'nom': 'Client inconnu'},
    );
    final clientName = client['nom'] as String? ?? 'Client inconnu';
    
    final depot = _depots.firstWhere(
      (d) => d.id == _selectedDepotId,
      orElse: () => Depot(
        id: 0,
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
    final depotName = depot.nom;

    // ✅ PRÉPARER LES LIGNES POUR L'IMPRESSION (printLines)
    final printLines = _saleLines.map((line) => {
      'produit_nom': line.productName,
      'quantite': line.quantity,
      'prix_unitaire': line.unitPrice,
    }).toList();

    // ✅ Afficher le dialogue d'impression
    _showPrintDialog(
      saleData: {
        'numero_facture': numeroFacture,
        'mode_livraison': _selectedModeLivraison,
      },
      lignes: printLines,
      clientName: clientName,
      depotName: depotName,
      subtotal: _subtotal,
      remise: _remiseAmount,
      total: _total,
      numeroFacture: numeroFacture,
    );

    // ✅ Réinitialiser le panier
    setState(() {
      _saleLines.clear();
      _selectedClientId = null;
      _remiseCtrl.text = '0';
      _notesCtrl.clear();
      _searchCtrl.clear();
    });

  } catch (e) {
    _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
  } finally {
    setState(() => _isSubmitting = false);
  }
}

 // ---------------------------------------------------------------------
// DIALOGUE D'IMPRESSION - Version corrigée
// ---------------------------------------------------------------------

void _showPrintDialog({
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
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(K.radiusXl),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: K.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: K.success),
          ),
          const SizedBox(width: 12),
          const Text(
            'Vente enregistrée !',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: K.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Souhaitez-vous imprimer le reçu ?',
            style: TextStyle(fontSize: 14, height: 1.5, color: K.textPrimary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: K.surfaceAlt,
              borderRadius: BorderRadius.circular(K.radiusSm),
              border: Border.all(color: K.border),
            ),
            child: _buildReceiptPreview(
              numeroFacture: numeroFacture,
              clientName: clientName,
              depotName: depotName,
              lignes: lignes,
              subtotal: subtotal,
              remise: remise,
              total: total,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context); // Retour à la page précédente
          },
          child: const Text('Ignorer', style: TextStyle(color: K.textMuted)),
        ),
      // Dans _showPrintDialog
ElevatedButton.icon(
  onPressed: () async {
    Navigator.pop(context);
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
      _showSnackBar('✅ Reçu imprimé avec succès', Colors.green);
    } catch (e) {
      _showSnackBar('✅ Vente enregistrée, reçu disponible', K.info);
    }
    if (context.mounted) {
      Navigator.pop(context);
    }
  },
  icon: const Icon(Icons.print_rounded),
  label: const Text('Imprimer'),
  style: ElevatedButton.styleFrom(
    backgroundColor: K.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(K.radiusSm),
    ),
  ),
),
      ],
    ),
  );
}

 // ---------------------------------------------------------------------
// APERÇU DU REÇU - Version corrigée
// ---------------------------------------------------------------------

Widget _buildReceiptPreview({
  required String numeroFacture,
  required String clientName,
  required String depotName,
  required List<Map<String, dynamic>> lignes, // ✅ Utiliser 'lignes' ici
  required double subtotal,
  required double remise,
  required double total,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: K.primary, size: 16),
          const SizedBox(width: 8),
          const Text(
            '🧾 Aperçu du reçu',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: K.textPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _buildReceiptLine('Facture', numeroFacture),
      _buildReceiptLine('Client', clientName),
      _buildReceiptLine('Dépôt', depotName),
      const Divider(height: 16),
      ...lignes.take(3).map((line) {
        final nom = line['produit_nom'] as String? ?? 'Produit';
        final qte = line['quantite'] as int? ?? 0;
        final prix = line['prix_unitaire'] as double? ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$qte x ${nom.length > 15 ? '${nom.substring(0, 15)}...' : nom}',
                style: const TextStyle(fontSize: 12, color: K.textPrimary),
              ),
              Text(
                '${(qte * prix).toStringAsFixed(0)} FC',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }),
      if (lignes.length > 3)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '... et ${lignes.length - 3} autre(s) produit(s)',
            style: const TextStyle(fontSize: 11, color: K.textMuted, fontStyle: FontStyle.italic),
          ),
        ),
      const Divider(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: K.textPrimary,
            ),
          ),
          Text(
            '$total FC',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: K.success,
            ),
          ),
        ],
      ),
      if (remise > 0)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Remise',
              style: TextStyle(fontSize: 12, color: K.textMuted),
            ),
            Text(
              '-$remise FC',
              style: const TextStyle(fontSize: 12, color: K.danger),
            ),
          ],
        ),
    ],
  );
}

Widget _buildReceiptLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: K.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: K.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

  // ---------------------------------------------------------------------
  // DIALOGS
  // ---------------------------------------------------------------------
  void _showClientDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.radiusXl),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 400,
          height: 450,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: K.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_rounded, color: K.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sélectionner un client',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: K.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: K.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: _clients.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_rounded,
                                size: 48, color: K.textMuted),
                            SizedBox(height: 12),
                            Text('Aucun client disponible',
                                style: TextStyle(color: K.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _clients.length,
                        itemBuilder: (context, index) {
                          final client = _clients[index];
                          final name = client['nom'] as String? ?? '';
                          final phone = client['telephone'] as String? ?? '';
                          final isSelected = _selectedClientId == client['id'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? K.primary.withOpacity(0.05)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(K.radiusSm),
                              border: Border.all(
                                color:
                                    isSelected ? K.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isSelected ? K.primary : K.accentSoft,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color:
                                        isSelected ? Colors.white : K.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected ? K.primary : K.textPrimary,
                                ),
                              ),
                              subtitle: phone.isNotEmpty ? Text(phone) : null,
                              trailing: isSelected
                                  ? Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: K.success,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedClientId = client['id'] as int;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: K.primary))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return _buildDesktopLayout();
                  } else {
                    return _buildMobileLayout();
                  }
                },
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Nouvelle Vente',
        style: TextStyle(
          color: K.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: K.surface,
      elevation: 0,
      foregroundColor: K.textPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Retour',
      ),
      actions: [
        if (_saleLines.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _saveSale,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isSubmitting ? 'Enregistrement...' : 'Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: K.success,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(K.radiusSm),
                ),
                elevation: 0,
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // LAYOUT DESKTOP
  // ---------------------------------------------------------------------
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildProductPanel(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // LAYOUT MOBILE
  // ---------------------------------------------------------------------
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProductPanel(),
          const SizedBox(height: 16),
          _buildCartPanel(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PANEL PRODUITS
  // ---------------------------------------------------------------------
 Widget _buildProductPanel() {
  final filteredProducts = _searchCtrl.text.isEmpty
      ? _products
      : _products
          .where((p) =>
              p.nom.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
              p.code.toLowerCase().contains(_searchCtrl.text.toLowerCase()))
          .toList();

  // ✅ Vérifier si des produits ont du stock
  final hasAvailableProducts = filteredProducts.any((p) {
    final stock = _getProductStock(p.id, _selectedDepotId ?? 0);
    return stock > 0;
  });

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: K.surface,
      borderRadius: BorderRadius.circular(K.radius),
      border: Border.all(color: K.border),
      boxShadow: [K.cardShadow],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: K.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: K.primary),
            ),
            const SizedBox(width: 12),
            const Text(
              'Catalogue produits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: K.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: K.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(K.radiusXl),
              ),
              child: Text(
                '${filteredProducts.length} produits',
                style: const TextStyle(
                  color: K.info,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
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
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        // ✅ Afficher un message si aucun produit disponible
        if (_selectedDepotId != null && !hasAvailableProducts && filteredProducts.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: K.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(K.radiusSm),
              border: Border.all(color: K.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_rounded, color: K.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aucun produit disponible en stock dans ce dépôt',
                    style: const TextStyle(
                      color: K.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: filteredProducts.isEmpty
              ? _buildEmptyProductState()
              : ListView.separated(
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductTile(product);
                  },
                ),
        ),
      ],
    ),
  );
}
  Widget _buildEmptyProductState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchCtrl.text.isEmpty
                ? Icons.inventory_2_rounded
                : Icons.search_off_rounded,
            size: 48,
            color: K.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            _searchCtrl.text.isEmpty
                ? 'Aucun produit disponible'
                : 'Aucun résultat trouvé',
            style: const TextStyle(color: K.textMuted, fontSize: 14),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {});
              },
              child: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }

  // Remplacer _buildProductTile par cette version améliorée

Widget _buildProductTile(Product product) {
  final isInCart = _saleLines.any((line) => line.productId == product.id);
  final quantityInCart = _saleLines
      .where((line) => line.productId == product.id)
      .fold(0, (sum, line) => sum + line.quantity);
  
  // ✅ Récupérer le stock disponible
  final stockDisponible = _getProductStock(product.id, _selectedDepotId ?? 0);
  final hasStock = stockDisponible > 0;
  final canAdd = hasStock || isInCart; // ✅ Permet d'ajouter si déjà dans le panier

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isInCart
            ? [K.success.withOpacity(0.05), K.success.withOpacity(0.01)]
            : hasStock
                ? [K.surface, K.surfaceAlt]
                : [K.surface, K.surfaceAlt.withOpacity(0.5)],
      ),
      borderRadius: BorderRadius.circular(K.radiusSm),
      border: Border.all(
        color: isInCart
            ? K.success.withOpacity(0.4)
            : hasStock
                ? K.border
                : K.danger.withOpacity(0.2),
        width: isInCart ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isInCart ? K.success.withOpacity(0.1) : Colors.transparent,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasStock || isInCart ? () => _addProduct(product) : null,
        borderRadius: BorderRadius.circular(K.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Code produit en badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isInCart
                        ? [K.success, K.success.withOpacity(0.7)]
                        : hasStock
                            ? [K.primary, K.primary.withOpacity(0.7)]
                            : [K.textMuted, K.textMuted.withOpacity(0.5)],
                  ),
                  borderRadius: BorderRadius.circular(K.radiusSm),
                ),
                child: Center(
                  child: Text(
                    product.code.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Informations produit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nom,
                      style: TextStyle(
                        fontWeight: isInCart ? FontWeight.w700 : FontWeight.w600,
                        color: isInCart ? K.success : hasStock ? K.textPrimary : K.textMuted,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: K.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(K.radiusXl),
                          ),
                          child: Text(
                            product.code,
                            style: const TextStyle(
                              color: K.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: K.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(K.radiusXl),
                          ),
                          child: Text(
                            product.unite,
                            style: const TextStyle(
                              color: K.info,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // ✅ Badge de stock
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasStock 
                                ? K.success.withOpacity(0.1) 
                                : K.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(K.radiusXl),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasStock ? Icons.check_circle_rounded : Icons.warning_rounded,
                                color: hasStock ? K.success : K.danger,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                hasStock ? 'Stock: $stockDisponible' : 'Rupture',
                                style: TextStyle(
                                  color: hasStock ? K.success : K.danger,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isInCart)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: K.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(K.radiusXl),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shopping_cart_rounded, size: 10, color: K.success),
                                const SizedBox(width: 2),
                                Text(
                                  '$quantityInCart',
                                  style: const TextStyle(
                                    color: K.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Prix et bouton
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product.prixVente} FC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isInCart ? K.success : hasStock ? K.primary : K.textMuted,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isInCart)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: K.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(K.radiusXl),
                        border: Border.all(color: K.success.withOpacity(0.3)),
                      ),
                      child: Text(
                        '+$quantityInCart',
                        style: const TextStyle(
                          color: K.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else if (!hasStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: K.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(K.radiusXl),
                      ),
                      child: const Text(
                        'Indisponible',
                        style: TextStyle(
                          color: K.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  // ---------------------------------------------------------------------
  // PANEL PANIER
  // ---------------------------------------------------------------------
  Widget _buildCartPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(K.radius),
        border: Border.all(color: K.border),
        boxShadow: [K.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: K.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(K.radiusSm),
                ),
                child:
                    const Icon(Icons.shopping_cart_rounded, color: K.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Panier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: K.textPrimary,
                  ),
                ),
              ),
              if (_saleLines.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: K.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(K.radiusXl),
                  ),
                  child: Text(
                    '${_saleLines.length} produits',
                    style: const TextStyle(
                      color: K.info,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 20),

          // Client et dépôt
          _buildClientSelector(),
          const SizedBox(height: 12),
          _buildDepotSelector(),
          const SizedBox(height: 12),

          // Liste des produits
          Expanded(
            child: _saleLines.isEmpty
                ? _buildEmptyCartState()
                : ListView.separated(
                    itemCount: _saleLines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final line = _saleLines[index];
                      return _buildCartItem(line, index);
                    },
                  ),
          ),

          // Résumé et actions
          if (_saleLines.isNotEmpty) ...[
            const Divider(height: 20),
            _buildSummary(),
            const SizedBox(height: 12),
            _buildModeLivraison(),
            const SizedBox(height: 12),
            _buildNotes(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: K.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(K.radiusSm),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Finaliser la vente',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCartState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_rounded, size: 48, color: K.textMuted),
          SizedBox(height: 12),
          Text('Panier vide',
              style: TextStyle(color: K.textMuted, fontSize: 14)),
          SizedBox(height: 4),
          Text('Ajoutez des produits depuis le catalogue',
              style: TextStyle(color: K.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SÉLECTEURS
  // ---------------------------------------------------------------------
  Widget _buildClientSelector() {
    final selectedClient = _clients.firstWhere(
      (c) => c['id'] == _selectedClientId,
      orElse: () => {},
    );
    final clientName =
        selectedClient['nom'] as String? ?? 'Sélectionner un client';

    return InkWell(
      onTap: _showClientDialog,
      borderRadius: BorderRadius.circular(K.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: K.surfaceAlt,
          borderRadius: BorderRadius.circular(K.radiusSm),
          border: Border.all(
            color: _selectedClientId != null ? K.success : K.border,
            width: _selectedClientId != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_rounded,
              color: _selectedClientId != null ? K.success : K.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                clientName,
                style: TextStyle(
                  color:
                      _selectedClientId != null ? K.textPrimary : K.textMuted,
                  fontWeight: _selectedClientId != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              _selectedClientId != null
                  ? Icons.check_circle_rounded
                  : Icons.arrow_drop_down_rounded,
              color: _selectedClientId != null ? K.success : K.textMuted,
            ),
          ],
        ),
      ),
    );
  }

 // Dans _buildDepotSelector
Widget _buildDepotSelector() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: K.surfaceAlt,
      borderRadius: BorderRadius.circular(K.radiusSm),
      border: Border.all(color: K.border),
    ),
    child: DropdownButton<int>(
      value: _selectedDepotId,
      isExpanded: true,
      hint: const Text('Sélectionner un dépôt'),
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
              Text(depot.nom),
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
        setState(() {
          _selectedDepotId = value;
          // ✅ Vider le panier quand le dépôt change
          if (_saleLines.isNotEmpty) {
            _showSnackBar('⚠️ Dépôt changé, panier vidé', Colors.orange);
            _saleLines.clear();
          }
        });
      },
    ),
  );
}
  // ---------------------------------------------------------------------
  // CARTE PANIER
  // ---------------------------------------------------------------------
  Widget _buildCartItem(SaleLine line, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: K.accentSoft,
              borderRadius: BorderRadius.circular(K.radiusSm),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: K.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: K.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${line.unitPrice} FC',
                  style: const TextStyle(
                    fontSize: 11,
                    color: K.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                onPressed: () => _updateQuantity(index, line.quantity - 1),
                style: IconButton.styleFrom(
                  backgroundColor: K.surface,
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28),
                ),
                tooltip: 'Diminuer',
              ),
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text(
                  '${line.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: K.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                onPressed: () => _updateQuantity(index, line.quantity + 1),
                style: IconButton.styleFrom(
                  backgroundColor: K.surface,
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28),
                ),
                tooltip: 'Augmenter',
              ),
              // ❌ Erreur - minimumSize n'existe pas comme paramètre dans IconButton
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                onPressed: () => _updateQuantity(index, line.quantity - 1),
                style: IconButton.styleFrom(
                  backgroundColor: K.surface,
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28), // ✅ C'est bien minimumSize
                ),
                tooltip: 'Diminuer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // RÉSUMÉ
  // ---------------------------------------------------------------------
  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
              'Sous-total', '${_subtotal.toStringAsFixed(0)} FC'),
          _buildSummaryRow(
            'Remise (${_remiseValue.toStringAsFixed(0)}%)',
            '-${_remiseAmount.toStringAsFixed(0)} FC',
            isRemise: true,
          ),
          const Divider(height: 16),
          _buildSummaryRow(
            'Total',
            '${_total.toStringAsFixed(0)} FC',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isRemise = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isRemise ? K.danger : (isTotal ? K.primary : K.textMuted),
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color:
                  isRemise ? K.danger : (isTotal ? K.primary : K.textPrimary),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeLivraison() {
    final modes = [
      {'value': 'retrait_magasin', 'label': '🏪 Retrait magasin'},
      {'value': 'livraison_domicile', 'label': '🚚 Livraison à domicile'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: DropdownButton<String>(
        value: _selectedModeLivraison,
        isExpanded: true,
        underline: Container(),
        dropdownColor: K.surface,
        items: modes.map((mode) {
          return DropdownMenuItem(
            value: mode['value'],
            child: Text(mode['label']!),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedModeLivraison = value!),
      ),
    );
  }

  Widget _buildNotes() {
    return TextField(
      controller: _notesCtrl,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: '📝 Notes (optionnel)',
        hintStyle: const TextStyle(color: K.textMuted, fontSize: 12),
        filled: true,
        fillColor: K.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusSm),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(10),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// MODÈLE SALE LINE
// ---------------------------------------------------------------------
class SaleLine {
  final int productId;
  final String productName;
  final String productCode;
  final double unitPrice;
  final int quantity;
  final double total;

  SaleLine({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unitPrice,
    required this.quantity,
    required this.total,
  });

  SaleLine copyWith({
    int? productId,
    String? productName,
    String? productCode,
    double? unitPrice,
    int? quantity,
    double? total,
  }) {
    return SaleLine(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }
}
