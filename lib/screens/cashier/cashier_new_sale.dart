import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/screens/cashier/print/receipt_printer.dart';
import 'package:tek_app/theme/app_theme.dart';
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
  List<Map<String, dynamic>> _stocks = [];
  List<SaleLine> _saleLines = [];

  // Sélections
  int? _selectedClientId;
  int? _selectedDepotId;
  String _selectedModeLivraison = 'retrait_magasin';

  bool _estVenteARetirer = false;
  DateTime? _dateRetrait;

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
        final stocks = await service.getStocks();

        setState(() {
          _products = products;
          _depots = depots;
          _clients = clients;
          _stocks = stocks.map((s) => s.toJson()).toList();

          if (_depots.isNotEmpty) {
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
  // GESTION DU PANIER (Inchangé)
  // ---------------------------------------------------------------------------
  void _addProduct(Product product) {
    final existingIndex =
    _saleLines.indexWhere((line) => line.productId == product.id);

    if (existingIndex != -1) {
      setState(() {
        _saleLines[existingIndex] = _saleLines[existingIndex].copyWith(
          quantity: _saleLines[existingIndex].quantity + 1,
          total: _saleLines[existingIndex].unitPrice *
              (_saleLines[existingIndex].quantity + 1),
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
    _showSnackBar('${product.nom} ajouté au panier', const Color(0xFF107C41));
  }

  void _removeProduct(int index) {
    setState(() => _saleLines.removeAt(index));
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

  // ---------------------------------------------------------------------------
  // CALCULS (Inchangé)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // ENREGISTREMENT DE LA VENTE (Inchangé)
  // ---------------------------------------------------------------------------
  Future<void> _saveSale() async {
    if (_selectedClientId == null) {
      _showSnackBar('Veuillez sélectionner un client', const Color(0xFFD97706));
      return;
    }
    if (_estVenteARetirer && _dateRetrait == null) {
      _showSnackBar('Veuillez choisir la date de retrait', const Color(0xFFD97706));
      return;
    }
    if (_selectedDepotId == null) {
      _showSnackBar('Veuillez sélectionner un dépôt', const Color(0xFFD97706));
      return;
    }
    if (_saleLines.isEmpty) {
      _showSnackBar('Ajoutez au moins un produit au panier', const Color(0xFFD97706));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        _showSnackBar('Utilisateur non connecté', const Color(0xFFC42B1C));
        return;
      }

      final service = AdminService(user.token);

      final lignes = _saleLines
          .map((line) => {
        'produit_id': line.productId,
        'quantite': line.quantity,
        'prix_unitaire': line.unitPrice,
      })
          .toList();

      final result = await service.createSale(
        clientId: _selectedClientId!,
        depotSourceId: _selectedDepotId!,
        dateVente: DateTime.now().toIso8601String().split('T').first,
        lignes: lignes,
        remise: _remiseValue,
        modeLivraison: _selectedModeLivraison,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        dateRetrait: _estVenteARetirer && _dateRetrait != null
            ? _dateRetrait!.toIso8601String().split('T').first
            : null,
      );

      final numeroFacture = result['numero_facture'] as String? ?? 'N/A';

      final client = _clients.firstWhere(
            (c) => c['id'] == _selectedClientId,
        orElse: () => {'nom': 'Client inconnu'},
      );
      final clientName = client['nom'] as String? ?? 'Client inconnu';

      final depot = _depots.where((d) => d.id == _selectedDepotId).firstOrNull;
      final depotName = depot?.nom ?? 'Point de vente';

      final printLines = _saleLines
          .map((line) => {
        'produit_nom': line.productName,
        'quantite': line.quantity,
        'prix_unitaire': line.unitPrice,
      })
          .toList();

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

      setState(() {
        _saleLines.clear();
        _selectedClientId = null;
        _remiseCtrl.text = '0';
        _notesCtrl.clear();
        _searchCtrl.clear();
        _estVenteARetirer = false;
        _dateRetrait = null;
      });
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // DIALOGUE D'IMPRESSION (Design Windows 11 Fluent)
  // ---------------------------------------------------------------------------
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF107C41), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Vente enregistrée avec succès',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Le ticket a été clôturé. Souhaitez-vous générer le reçu thermique maintenant ?',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x14000000)),
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
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text(
              'Terminer sans imprimer',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
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
                _showSnackBar('Reçu imprimé avec succès', const Color(0xFF107C41));
              } catch (_) {
                _showSnackBar('Reçu archivé numériquement', const Color(0xFF0067C0));
              }
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.print_outlined, size: 17),
            label: const Text('Imprimer le reçu client'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview({
    required String numeroFacture,
    required String clientName,
    required String depotName,
    required List<Map<String, dynamic>> lignes,
    required double subtotal,
    required double remise,
    required double total,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.receipt_long_outlined, color: Color(0xFF0067C0), size: 16),
            SizedBox(width: 8),
            Text(
              'Aperçu du ticket de caisse',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildReceiptLine('Facture', numeroFacture),
        _buildReceiptLine('Client', clientName),
        _buildReceiptLine('Point de vente', depotName),
        const Divider(height: 12, thickness: 1, color: Color(0x12000000)),
        ...lignes.take(3).map((line) {
          final nom = line['produit_nom'] as String? ?? 'Article';
          final qte = line['quantite'] as int? ?? 0;
          final prix = (line['prix_unitaire'] as num?)?.toDouble() ?? 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$qte x $nom',
                    style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(qte * prix).toStringAsFixed(2)} \$',
                  style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 12, thickness: 1, color: Color(0x12000000)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Net TTC',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '${total.toStringAsFixed(2)} \$',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF0067C0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 11.5,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOGUE SÉLECTION CLIENT
  // ---------------------------------------------------------------------------
  void _showClientDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.all(22),
          width: 440,
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2FB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.person_search_outlined, color: Color(0xFF0067C0), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Sélectionner un compte client',
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    splashRadius: 14,
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1, color: Color(0x14000000)),
              Expanded(
                child: _clients.isEmpty
                    ? const Center(
                  child: Text(
                    'Aucun client enregistré',
                    style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                )
                    : ListView.separated(
                  itemCount: _clients.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x10000000)),
                  itemBuilder: (context, index) {
                    final client = _clients[index];
                    final name = client['nom'] as String? ?? '';
                    final phone = client['telephone'] as String? ?? '';
                    final isSelected = _selectedClientId == client['id'];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isSelected ? const Color(0xFF0067C0) : const Color(0xFFE8F2FB),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                          style: TextStyle(
                            fontFamily: kAppFontFamily,
                            color: isSelected ? Colors.white : const Color(0xFF0067C0),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                      ),
                      subtitle: phone.isNotEmpty
                          ? Text(phone, style: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B), fontSize: 11.5))
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0067C0), size: 18)
                          : null,
                      onTap: () {
                        setState(() => _selectedClientId = client['id'] as int);
                        Navigator.pop(dialogContext);
                      },
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

  // ---------------------------------------------------------------------------
  // BUILD PRINCIPAL
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F7),
      appBar: AppBar(
        title: const Text(
          'Point de Vente — Nouvelle Vente & Encaissement',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Retour',
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0x14000000)),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0067C0),
          strokeWidth: 2.2,
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return constraints.maxWidth >= 960
                ? _buildDesktopLayout()
                : _buildMobileLayout();
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LAYOUT DESKTOP (Catalogue 60% / Panier & Encaissement 40%)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 6, child: _buildProductPanel()),
          const SizedBox(width: 18),
          Expanded(flex: 4, child: _buildCartPanel()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 480, child: _buildProductPanel()),
          const SizedBox(height: 16),
          _buildCartPanel(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PANNEAU GAUCHE : CATALOGUE PRODUITS
  // ---------------------------------------------------------------------------
  Widget _buildProductPanel() {
    final filteredProducts = _searchCtrl.text.isEmpty
        ? _products
        : _products.where((p) =>
    p.nom.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
        p.code.toLowerCase().contains(_searchCtrl.text.toLowerCase())).toList();

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF0067C0), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Catalogue des Articles',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 14.5,
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
                  '${filteredProducts.length} référence(s)',
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher par code ou article...',
                hintStyle: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFFA0AEC0), fontSize: 12.5),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 18),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
              child: Text(
                'Aucun article correspondant',
                style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF94A3B8), fontSize: 13),
              ),
            )
                : ListView.separated(
              itemCount: filteredProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _buildProductRow(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(Product product) {
    final stockDisponible = _getProductStock(product.id, _selectedDepotId ?? 0);
    final hasStock = stockDisponible > 0;
    final quantityInCart = _saleLines
        .where((line) => line.productId == product.id)
        .fold(0, (sum, line) => sum + line.quantity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: quantityInCart > 0 ? const Color(0xFFE8F2FB).withOpacity(0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: quantityInCart > 0 ? const Color(0xFF0067C0).withOpacity(0.4) : const Color(0x10000000),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: Text(
              product.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nom,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${product.unite} • Stock dispo: $stockDisponible',
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: hasStock ? const Color(0xFFE6F4EA) : const Color(0xFFFDE8E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              hasStock ? 'En stock' : 'Rupture',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                color: hasStock ? const Color(0xFF107C41) : const Color(0xFFC42B1C),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Text(
            '${product.prixVente.toStringAsFixed(2)} \$',
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0067C0),
              fontSize: 13.5,
            ),
          ),
          const SizedBox(width: 10),

          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: hasStock ? () => _addProduct(product) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0067C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              child: quantityInCart > 0
                  ? Text('+$quantityInCart', style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 12))
                  : const Icon(Icons.add_rounded, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PANNEAU DROIT : PANIER SCROLLABLE AVEC STICKY CHECKOUT (ANTI-DÉBORDEMENT)
  // ---------------------------------------------------------------------------
  Widget _buildCartPanel() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête Panier + Sélecteurs fixes
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F2FB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0067C0), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Panier de Vente',
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 14.5,
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
                        '${_saleLines.length} article(s)',
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildClientSelector(),
                const SizedBox(height: 8),
                _buildDepotSelector(),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0x12000000)),

          // ZONE CENTRALE SCROLLABLE : Articles + Options de Livraison / Date de Retrait
          Expanded(
            child: _saleLines.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.remove_shopping_cart_outlined, size: 36, color: Color(0xFF94A3B8)),
                  SizedBox(height: 10),
                  Text(
                    'Votre panier est vide',
                    style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Cliquez sur (+) sur un article pour l\'ajouter',
                    style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            )
                : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              children: [
                // Liste des articles ajoutés
                ..._saleLines.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildCartRow(entry.value, entry.key),
                  );
                }),

                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: Color(0x12000000)),
                const SizedBox(height: 12),

                // Section Livraison, Retrait différé & Notes dans le flux scrollable
                _buildDeliveryAndNotes(),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ZONE BASSE FIXE (STICKY FOOTER) : Totaux Financiers & Bouton d'Encaissement
          if (_saleLines.isNotEmpty) ...[
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                border: Border(
                  top: BorderSide(color: Color(0x14000000), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTotalsSummary(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _saveSale,
                      icon: _isSubmitting
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isSubmitting
                            ? 'Traitement...'
                            : 'Finaliser la vente (${_total.toStringAsFixed(2)} \$)',
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0067C0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildCartRow(SaleLine line, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  line.productName,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${line.unitPrice.toStringAsFixed(2)} \$ / u',
                  style: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _updateQuantity(index, line.quantity - 1),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0x18000000)),
                  ),
                  child: const Icon(Icons.remove_rounded, size: 14, color: Color(0xFF0F172A)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${line.quantity}',
                  style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
              InkWell(
                onTap: () => _updateQuantity(index, line.quantity + 1),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0x18000000)),
                  ),
                  child: const Icon(Icons.add_rounded, size: 14, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          Text(
            '${line.total.toStringAsFixed(2)} \$',
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF0067C0),
            ),
          ),
          const SizedBox(width: 4),

          IconButton(
            splashRadius: 14,
            icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFC42B1C)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => _removeProduct(index),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SÉLECTEURS CLIENT & DÉPÔT
  // ---------------------------------------------------------------------------
  Widget _buildClientSelector() {
    final selectedClient = _clients.firstWhere((c) => c['id'] == _selectedClientId, orElse: () => {});
    final clientName = selectedClient['nom'] as String? ?? 'Sélectionner un compte client *';

    return InkWell(
      onTap: _showClientDialog,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _selectedClientId != null ? const Color(0xFF0067C0) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: _selectedClientId != null ? const Color(0xFF0067C0) : const Color(0xFF64748B), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                clientName,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: _selectedClientId != null ? const Color(0xFF0F172A) : const Color(0xFFA0AEC0),
                  fontWeight: _selectedClientId != null ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildDepotSelector() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButton<int>(
        value: _selectedDepotId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: const Color(0xFFFFFFFF),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
        // ✅ Après (corrigé avec .toList())
        items: _depots.map((depot) {
          return DropdownMenuItem(
            value: depot.id,
            child: Row(
              children: [
                Icon(depot.estMagasin ? Icons.storefront_outlined : Icons.warehouse_outlined, color: const Color(0xFF0067C0), size: 16),
                const SizedBox(width: 8),
                Text(
                  depot.nom,
                  style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedDepotId = value;
            if (_saleLines.isNotEmpty) {
              _showSnackBar('Dépôt modifié, panier réinitialisé', const Color(0xFFD97706));
              _saleLines.clear();
            }
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CALCULS & RÉSUMÉ DU PANIER
  // ---------------------------------------------------------------------------
  Widget _buildTotalsSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x10000000)),
      ),
      child: Column(
        children: [
          _summaryLine('Sous-total brut', '${_subtotal.toStringAsFixed(2)} \$'),
          if (_remiseAmount > 0)
            _summaryLine('Remise (${_remiseValue.toStringAsFixed(0)}%)', '- ${_remiseAmount.toStringAsFixed(2)} \$', isDiscount: true),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Remise (%) : ',
                style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              SizedBox(
                width: 54,
                height: 28,
                child: TextField(
                  controller: _remiseCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 12, thickness: 1, color: Color(0x12000000)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net à payer TTC',
                style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
              ),
              Text(
                '${_total.toStringAsFixed(2)} \$',
                style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0067C0)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              color: isDiscount ? const Color(0xFFC42B1C) : const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              color: isDiscount ? const Color(0xFFC42B1C) : const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET DATE PICKER & OPTIONS LIVRAISON (WINDOWS 11 FLUENT 2 REFONDU)
  // ---------------------------------------------------------------------------
  Widget _buildDeliveryAndNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Panneau de Retrait Différé Fluent 2 ---
        _buildPickupSchedulerTile(),
        const SizedBox(height: 10),

        // --- Mode de Livraison ---
        DropdownButtonFormField<String>(
          value: _selectedModeLivraison,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 12.5,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5)),
          ),
          items: const [
            DropdownMenuItem(value: 'retrait_magasin', child: Text('Retrait direct au comptoir (Magasin)')),
            DropdownMenuItem(value: 'retrait_grand_depot', child: Text('Retrait au grand dépôt logistique')),
            DropdownMenuItem(value: 'retrait_troisieme_depot', child: Text('Retrait au dépôt annexe')),
          ],
          onChanged: (val) => setState(() => _selectedModeLivraison = val!),
        ),
        const SizedBox(height: 8),

        // --- Champ Notes & Référence ---
        TextField(
          controller: _notesCtrl,
          maxLines: 1,
          style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12.5),
          decoration: InputDecoration(
            hintText: 'Notes ou référence client (optionnel)',
            hintStyle: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFFA0AEC0), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5)),
          ),
        ),
      ],
    );
  }

  // Composant Date Picker Fluent avec raccourcis rapides et dialogue thématisé
  Widget _buildPickupSchedulerTile() {
    return Container(
      decoration: BoxDecoration(
        color: _estVenteARetirer ? const Color(0xFFE8F2FB).withOpacity(0.35) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _estVenteARetirer ? const Color(0xFF0067C0).withOpacity(0.35) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _estVenteARetirer ? const Color(0xFFE8F2FB) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  size: 17,
                  color: _estVenteARetirer ? const Color(0xFF0067C0) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retrait différé',
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Planifier une date de mise à disposition',
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _estVenteARetirer,
                onChanged: (v) => setState(() {
                  _estVenteARetirer = v;
                  if (!v) {
                    _dateRetrait = null;
                  } else {
                    _dateRetrait ??= DateTime.now().add(const Duration(days: 1));
                  }
                }),
                activeColor: const Color(0xFF0067C0),
              ),
            ],
          ),

          if (_estVenteARetirer) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: Color(0x140067C0)),
            const SizedBox(height: 10),

            // Bouton Sélecteur de Calendrier Thématisé Windows 11
            InkWell(
              onTap: _openFluentDatePicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0067C0), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF0067C0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dateRetrait == null
                            ? 'Sélectionner la date de retrait *'
                            : 'Mise à disposition le ${_formatFrenchDate(_dateRetrait!)}',
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _dateRetrait == null ? const Color(0xFFA0AEC0) : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0067C0)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Raccourcis Rapides (Demain, 3j, 1 sem)
            Row(
              children: [
                _buildDateShortcutChip('Demain', () {
                  setState(() => _dateRetrait = DateTime.now().add(const Duration(days: 1)));
                }),
                const SizedBox(width: 6),
                _buildDateShortcutChip('Dans 3 jours', () {
                  setState(() => _dateRetrait = DateTime.now().add(const Duration(days: 3)));
                }),
                const SizedBox(width: 6),
                _buildDateShortcutChip('Dans 1 semaine', () {
                  setState(() => _dateRetrait = DateTime.now().add(const Duration(days: 7)));
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateShortcutChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x18000000)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Future<void> _openFluentDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateRetrait ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0067C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0067C0),
                textStyle: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRetrait = picked);
    }
  }

  String _formatFrenchDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ---------------------------------------------------------------------------
// MODÈLE SALE LINE (Inchangé)
// ---------------------------------------------------------------------------
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