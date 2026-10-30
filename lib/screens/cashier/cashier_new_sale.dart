import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Contrôleurs de quantité par produit (clé = productId)
  final Map<int, TextEditingController> _qtyControllers = {};

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
  final TextEditingController _clientLibreCtrl = TextEditingController();
  final TextEditingController _montantPayeCtrl = TextEditingController(text: '0');

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
    _clientLibreCtrl.dispose();
    _montantPayeCtrl.dispose();
    for (final ctrl in _qtyControllers.values) {
      ctrl.dispose();
    }
    _qtyControllers.clear();
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
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
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
  // GESTION DU PANIER
  // ---------------------------------------------------------------------------
  void _addProduct(Product product) {
    final existingIndex = _saleLines.indexWhere((line) => line.productId == product.id);

    if (existingIndex != -1) {
      setState(() {
        _saleLines[existingIndex] = _saleLines[existingIndex].copyWith(
          quantity: _saleLines[existingIndex].quantity + 1,
          total: _saleLines[existingIndex].unitPrice * (_saleLines[existingIndex].quantity + 1),
        );
      });
      _syncQtyController(product.id);
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
      _qtyControllers[product.id] = TextEditingController(text: '1');
    }
    _showSnackBar('${product.nom} ajouté', const Color(0xFF107C41));
  }

  void _removeProduct(int index) {
    final productId = _saleLines[index].productId;
    _qtyControllers[productId]?.dispose();
    _qtyControllers.remove(productId);
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
    _syncQtyController(_saleLines[index].productId);
  }

  void _syncQtyController(int productId) {
    final line = _saleLines.firstWhere(
          (l) => l.productId == productId,
      orElse: () => SaleLine(
        productId: productId,
        productName: '',
        productCode: '',
        unitPrice: 0,
        quantity: 0,
        total: 0,
      ),
    );
    if (line.quantity <= 0) return;
    final ctrl = _qtyControllers[productId];
    if (ctrl != null && ctrl.text != '${line.quantity}') {
      ctrl.text = '${line.quantity}';
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }
  }

  void _clearSaleLines() {
    for (final ctrl in _qtyControllers.values) {
      ctrl.dispose();
    }
    _qtyControllers.clear();
    _saleLines.clear();
  }

  // ---------------------------------------------------------------------------
  // CALCULS
  // ---------------------------------------------------------------------------
  double get _subtotal => _saleLines.fold(0, (sum, line) => sum + line.total);

  double get _remiseValue {
    final value = double.tryParse(_remiseCtrl.text) ?? 0;
    return value.clamp(0, _subtotal);
  }

  double get _remiseAmount => _remiseValue;
  double get _total => _subtotal - _remiseAmount;

  double get _montantPaye {
    final v = double.tryParse(_montantPayeCtrl.text) ?? 0;
    return v.clamp(0, _total);
  }

  double get _resteAPayer => _total - _montantPaye;

  // ---------------------------------------------------------------------------
  // ENREGISTREMENT DE LA VENTE
  // ---------------------------------------------------------------------------
  Future<void> _saveSale() async {
    if (_estVenteARetirer && _selectedClientId == null) {
      _showSnackBar('Sélectionnez un client enregistré pour un retrait', const Color(0xFFD97706));
      return;
    }
    if (_estVenteARetirer && _dateRetrait == null) {
      _showSnackBar('Choisissez la date de retrait', const Color(0xFFD97706));
      return;
    }
    if (_selectedDepotId == null) {
      _showSnackBar('Sélectionnez un dépôt', const Color(0xFFD97706));
      return;
    }
    if (_saleLines.isEmpty) {
      _showSnackBar('Le panier est vide', const Color(0xFFD97706));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        _showSnackBar('Session expirée', const Color(0xFFC42B1C));
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
        clientId: _selectedClientId,
        clientNomLibre: _selectedClientId == null && _clientLibreCtrl.text.trim().isNotEmpty
            ? _clientLibreCtrl.text.trim()
            : null,
        depotSourceId: _selectedDepotId!,
        dateVente: DateTime.now().toIso8601String().split('T').first,
        lignes: lignes,
        remise: _remiseValue,
        remiseType: 'montant',
        modeLivraison: _selectedModeLivraison,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        dateRetrait: _estVenteARetirer && _dateRetrait != null
            ? _dateRetrait!.toIso8601String().split('T').first
            : null,
        montantPayeInitial: _montantPaye,
      );

      final numeroFacture = result['numero_facture'] as String? ?? 'N/A';
      final clientNomLibreResult = result['client_nom_libre'] as String?;

      String clientName;
      if (_selectedClientId != null) {
        final client = _clients.firstWhere(
              (c) => c['id'] == _selectedClientId,
          orElse: () => {'nom': 'Client inconnu'},
        );
        clientName = client['nom'] as String? ?? 'Client inconnu';
      } else {
        clientName = clientNomLibreResult ??
            (_clientLibreCtrl.text.trim().isNotEmpty
                ? _clientLibreCtrl.text.trim()
                : 'Client comptoir');
      }

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
          'montant_paye': _montantPaye,
          'reste_a_payer': _resteAPayer,
        },
        lignes: printLines,
        clientName: clientName,
        depotName: depotName,
        subtotal: _subtotal,
        remise: _remiseAmount,
        total: _total,
        numeroFacture: numeroFacture,
        montantPaye: _montantPaye,
        resteAPayer: _resteAPayer,
      );

      setState(() {
        _clearSaleLines();
        _selectedClientId = null;
        _remiseCtrl.text = '0';
        _notesCtrl.clear();
        _searchCtrl.clear();
        _estVenteARetirer = false;
        _dateRetrait = null;
        _clientLibreCtrl.clear();
        _montantPayeCtrl.text = '0';
      });
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // DIALOGUE D'IMPRESSION
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
    required double montantPaye,
    required double resteAPayer,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF107C41), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Vente clôturée avec succès',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 15,
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
              'Ticket enregistré. Souhaitez-vous imprimer le reçu client ?',
              style: TextStyle(fontFamily: kAppFontFamily, fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
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
                montantPaye: montantPaye,
                resteAPayer: resteAPayer,
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
            child: const Text('Fermer', style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B))),
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
                _showSnackBar('Ticket envoyé à l\'imprimante', const Color(0xFF107C41));
              } catch (_) {
                _showSnackBar('Reçu archivé', const Color(0xFF0067C0));
              }
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Imprimer reçu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 12.5),
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
    required double montantPaye,
    required double resteAPayer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReceiptLine('Facture', numeroFacture),
        _buildReceiptLine('Client', clientName),
        _buildReceiptLine('Dépôt', depotName),
        const Divider(height: 10, thickness: 1, color: Color(0x12000000)),
        ...lignes.take(3).map((line) {
          final nom = line['produit_nom'] as String? ?? 'Article';
          final qte = line['quantite'] as int? ?? 0;
          final prix = (line['prix_unitaire'] as num?)?.toDouble() ?? 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$qte x $nom',
                    style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(qte * prix).toStringAsFixed(2)} \$',
                  style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 10, thickness: 1, color: Color(0x12000000)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Net TTC', style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
            Text('${total.toStringAsFixed(2)} \$', style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0067C0))),
          ],
        ),
        if (resteAPayer > 0) ...[
          const SizedBox(height: 4),
          _buildReceiptLine('Payé', '\$${montantPaye.toStringAsFixed(2)}'),
          _buildReceiptLine('Reste à payer', '\$${resteAPayer.toStringAsFixed(2)}', isWarning: true),
        ],
      ],
    );
  }

  Widget _buildReceiptLine(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 11,
              color: isWarning ? const Color(0xFFD97706) : const Color(0xFF64748B),
              fontWeight: isWarning ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 11.5,
                color: isWarning ? const Color(0xFFD97706) : const Color(0xFF0F172A),
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
          padding: const EdgeInsets.all(18),
          width: 420,
          height: 460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2FB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.person_search_outlined, color: Color(0xFF0067C0), size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Sélectionner un compte client',
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 14.5,
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
              const Divider(height: 16, thickness: 1, color: Color(0x14000000)),
              Expanded(
                child: _clients.isEmpty
                    ? const Center(
                  child: Text(
                    'Aucun client enregistré',
                    style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF94A3B8), fontSize: 12.5),
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
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      leading: CircleAvatar(
                        radius: 13,
                        backgroundColor: isSelected ? const Color(0xFF0067C0) : const Color(0xFFE8F2FB),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                          style: TextStyle(
                            fontFamily: kAppFontFamily,
                            color: isSelected ? Colors.white : const Color(0xFF0067C0),
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          fontSize: 12.5,
                        ),
                      ),
                      subtitle: phone.isNotEmpty
                          ? Text(phone, style: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B), fontSize: 11))
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0067C0), size: 17)
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
          'Point de Vente — Caisse & Facturation',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15.5,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
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

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 55, child: _buildProductPanel()),
          const SizedBox(width: 12),
          Expanded(flex: 45, child: _buildCartPanel()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(height: 400, child: _buildProductPanel()),
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x18000000), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Color(0xFF0067C0), size: 17),
              const SizedBox(width: 8),
              const Text(
                'Catalogue Articles',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '${filteredProducts.length} référence(s)',
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 32,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Rechercher par code ou article...',
                hintStyle: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFFA0AEC0), fontSize: 11.5),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 16),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.4)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
              child: Text(
                'Aucun article trouvé',
                style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF94A3B8), fontSize: 12),
              ),
            )
                : ListView.separated(
              itemCount: filteredProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: quantityInCart > 0 ? const Color(0xFFE8F2FB).withOpacity(0.4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: quantityInCart > 0 ? const Color(0xFF0067C0).withOpacity(0.35) : const Color(0x10000000),
        ),
      ),
      child: Row(
        children: [
          Text(
            product.code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nom,
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
                  '${product.unite} • Stock: $stockDisponible',
                  style: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B), fontSize: 10.5),
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
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),

          SizedBox(
            height: 28,
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
                  ? Text('+$quantityInCart', style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 11))
                  : const Icon(Icons.add_rounded, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PANNEAU DROIT : PANIER AÉRÉ & RESPIRANT
  // ---------------------------------------------------------------------------
  Widget _buildCartPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x18000000), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. EN-TÊTE COMPACT (Client & Dépôt côte-à-côte sur 1 seule ligne)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0067C0), size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Panier',
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_saleLines.length} art.',
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          color: Color(0xFF64748B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Ligne unique regroupant Client et Dépôt
                Row(
                  children: [
                    Expanded(child: _buildClientSelector()),
                    const SizedBox(width: 6),
                    Expanded(child: _buildDepotSelector()),
                  ],
                ),

                if (_selectedClientId == null && !_estVenteARetirer) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 30,
                    child: TextField(
                      controller: _clientLibreCtrl,
                      style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5),
                      decoration: InputDecoration(
                        hintText: 'Nom client au comptoir (optionnel)',
                        hintStyle: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFFA0AEC0), fontSize: 11),
                        prefixIcon: const Icon(Icons.edit_note_rounded, size: 15, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.4)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0x12000000)),

          // 2. ZONE CENTRALE : GRANDE LISTE DES PRODUITS VISIBLE EN TOUT TEMPS
          Expanded(
            child: _saleLines.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.remove_shopping_cart_outlined, size: 32, color: Color(0xFF94A3B8)),
                  SizedBox(height: 6),
                  Text(
                    'Panier vide',
                    style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ],
              ),
            )
                : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: [
                // Liste principale des articles
                ..._saleLines.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildCartRow(entry.value, entry.key),
                  );
                }),

                const SizedBox(height: 6),

                // Section Livraison repliable
                _buildCollapsibleDeliverySection(),
              ],
            ),
          ),

          // 3. PIED DE CAISSE (STICKY FOOTER) ULTRA-COMPACT ET AÉRÉ
          if (_saleLines.isNotEmpty) ...[
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                border: Border(top: BorderSide(color: Color(0x14000000), width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTotalsSummary(),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _saveSale,
                      icon: _isSubmitting
                          ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                          : const Icon(Icons.check_rounded, size: 17),
                      label: Text(
                        _isSubmitting
                            ? 'Traitement...'
                            : 'Valider l\'encaissement (${_total.toStringAsFixed(2)} \$)',
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0067C0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

  // ---------------------------------------------------------------------------
  // LIGNE DE PRODUIT DU PANIER (ALIGNEMENT STRICTEMENT CENTRÉ)
  // ---------------------------------------------------------------------------
  Widget _buildCartRow(SaleLine line, int index) {
    final qtyCtrl = _qtyControllers[line.productId];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x10000000)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.productName,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${line.unitPrice.toStringAsFixed(2)} \$ / u',
                  style: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B), fontSize: 10.5),
                ),
              ],
            ),
          ),

          // Boutons - / champ quantité / + (Alignement vertical parfait)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => _updateQuantity(index, line.quantity - 1),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Icon(Icons.remove_rounded, size: 13, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 4),

              SizedBox(
                width: 46,
                height: 26,
                child: TextField(
                  key: ValueKey('qty_${line.productId}'),
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center, // 👈 Centre verticalement le texte
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.4), // 👈 Bleu primaire au focus
                    ),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value) ?? 0;
                    if (parsed > 0) {
                      setState(() {
                        final current = _saleLines[index];
                        _saleLines[index] = current.copyWith(
                          quantity: parsed,
                          total: current.unitPrice * parsed,
                        );
                      });
                    }
                  },
                  onSubmitted: (value) {
                    final parsed = int.tryParse(value) ?? 0;
                    if (parsed <= 0) {
                      _removeProduct(index);
                    } else {
                      _updateQuantity(index, parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),

              InkWell(
                onTap: () => _updateQuantity(index, line.quantity + 1),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Icon(Icons.add_rounded, size: 13, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          SizedBox(
            width: 60,
            child: Text(
              '${line.total.toStringAsFixed(2)} \$',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: Color(0xFF0067C0),
              ),
            ),
          ),

          IconButton(
            splashRadius: 12,
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFC42B1C)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => _removeProduct(index),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSelector() {
    final selectedClient = _clients.firstWhere((c) => c['id'] == _selectedClientId, orElse: () => {});
    final clientName = selectedClient['nom'] as String? ?? 'Client *';

    return InkWell(
      onTap: _showClientDialog,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _selectedClientId != null ? const Color(0xFF0067C0) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: _selectedClientId != null ? const Color(0xFF0067C0) : const Color(0xFF64748B), size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                clientName,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: _selectedClientId != null ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  fontWeight: _selectedClientId != null ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDepotSelector() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButton<int>(
        value: _selectedDepotId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: Colors.white, // 👈 Fond blanc du menu déroulant
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 16),
        items: _depots.map((depot) {
          return DropdownMenuItem(
            value: depot.id,
            child: Row(
              children: [
                Icon(depot.estMagasin ? Icons.storefront_outlined : Icons.warehouse_outlined, color: const Color(0xFF0067C0), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    depot.nom,
                    style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedDepotId = value;
            if (_saleLines.isNotEmpty) {
              _showSnackBar('Dépôt modifié, panier vidé', const Color(0xFFD97706));
              _clearSaleLines();
            }
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PIED DE TOTAUX COMPACT ET LISIBLE
  // ---------------------------------------------------------------------------
  Widget _buildTotalsSummary() {
    final aUnCredit = _resteAPayer > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Ligne 1 : Sous-total & Saisies rapides sur la même ligne
          Row(
            children: [
              Text(
                'Brut: ${_subtotal.toStringAsFixed(2)} \$',
                style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
              ),
              const Spacer(),

              // Saisie Remise
              const Text('Remise: ', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11, color: Color(0xFF64748B))),
              SizedBox(
                width: 52,
                height: 24,
                child: TextField(
                  controller: _remiseCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFC42B1C)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.4)), // 👈 Bleu focus
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Saisie Montant Payé
              const Text('Payé: ', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11, color: Color(0xFF64748B))),
              SizedBox(
                width: 58,
                height: 24,
                child: TextField(
                  controller: _montantPayeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF107C41)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.4)), // 👈 Bleu focus
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 10, thickness: 1, color: Color(0x10000000)),

          // Ligne 2 : Total Net & Reste dû
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Net: ', style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A))),
                  Text(
                    '${_total.toStringAsFixed(2)} \$',
                    style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0067C0)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: aUnCredit ? const Color(0xFFFEF3C7) : const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  aUnCredit ? 'Reste: ${_resteAPayer.toStringAsFixed(2)} \$' : 'Soldé',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: aUnCredit ? const Color(0xFFC42B1C) : const Color(0xFF107C41),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION LIVRAISON & NOTES REPLIABLE (ACCORDÉON)
  // ---------------------------------------------------------------------------
  Widget _buildCollapsibleDeliverySection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          leading: const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF64748B)),
          title: Text(
            _estVenteARetirer ? 'Retrait différé activé' : 'Options de livraison & Notes',
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          children: [
            _buildPickupSchedulerTile(),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedModeLivraison,
              dropdownColor: Colors.white, // 👈 Fond blanc du menu déroulant
              style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.4)), // 👈 Bleu focus
              ),
              items: const [
                DropdownMenuItem(value: 'retrait_magasin', child: Text('Retrait magasin (Comptoir)')),
                DropdownMenuItem(value: 'retrait_grand_depot', child: Text('Grand dépôt logistique')),
                DropdownMenuItem(value: 'retrait_troisieme_depot', child: Text('Dépôt annexe')),
              ],
              onChanged: (val) => setState(() => _selectedModeLivraison = val!),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: TextField(
                controller: _notesCtrl,
                style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5),
                decoration: InputDecoration(
                  hintText: 'Notes ou référence client...',
                  hintStyle: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFFA0AEC0), fontSize: 11),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.4)), // 👈 Bleu focus
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupSchedulerTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _estVenteARetirer ? const Color(0xFFE8F2FB) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _estVenteARetirer ? const Color(0xFF0067C0) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF0067C0)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Retrait programmé ultérieur', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              // 👈 Switch stylisé actif & inactif
              Switch(
                value: _estVenteARetirer,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: const Color(0xFF0067C0),
                activeTrackColor: const Color(0xFFE8F2FB),
                inactiveThumbColor: const Color(0xFF94A3B8),
                inactiveTrackColor: const Color(0xFFE2E8F0),
                trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                onChanged: (v) => setState(() {
                  _estVenteARetirer = v;
                  if (!v) {
                    _dateRetrait = null;
                  } else {
                    _dateRetrait ??= DateTime.now().add(const Duration(days: 1));
                  }
                }),
              ),
            ],
          ),
          if (_estVenteARetirer) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: _openFluentDatePicker,
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF0067C0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF0067C0)),
                    const SizedBox(width: 6),
                    Text(
                      _dateRetrait == null ? 'Choisir date *' : 'Prévu le ${_formatFrenchDate(_dateRetrait!)}',
                      style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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

  // 👈 Date picker restauré avec le thème Windows 11 Fluent 2
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
// MODÈLE SALE LINE
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