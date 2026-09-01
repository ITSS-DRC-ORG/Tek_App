import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/screens/inventory/stock_detail_view.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';
import '../../models/product_model.dart';
import '../../models/stock_model.dart';

class StockProducts extends StatefulWidget {
  const StockProducts({super.key});

  @override
  State<StockProducts> createState() => _StockProductsState();
}

class _StockProductsState extends State<StockProducts> with SingleTickerProviderStateMixin {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  Map<int, int> _stockQuantities = {}; // produitId -> quantité totale
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  // Contrôleurs pour le formulaire
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _prixAchatCtrl = TextEditingController();
  final TextEditingController _prixVenteCtrl = TextEditingController();
  final TextEditingController _uniteCtrl = TextEditingController();
  final TextEditingController _seuilCtrl = TextEditingController();
  bool _isActif = true;
  int? _editingProductId;
  bool _isFormLoading = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
    _codeCtrl.dispose();
    _nomCtrl.dispose();
    _descriptionCtrl.dispose();
    _prixAchatCtrl.dispose();
    _prixVenteCtrl.dispose();
    _uniteCtrl.dispose();
    _seuilCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // LOAD DATA
  // ---------------------------------------------------------------------
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final products = await service.getAllProducts();
        final stocks = await service.getStocks();

        // Calculer la quantité totale par produit
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
      _showSnackBar('Erreur: ${e.toString()}', _K.danger);
    }
  }

  // ---------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------
  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = _products);
    } else {
      setState(() {
        _filteredProducts = _products.where((product) =>
          product.nom.toLowerCase().contains(query.toLowerCase()) ||
          product.code.toLowerCase().contains(query.toLowerCase()) ||
          product.description?.toLowerCase().contains(query.toLowerCase()) == true
        ).toList();
      });
    }
  }

  // ---------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------
  Future<void> _createProduct() async {
    if (_codeCtrl.text.isEmpty || _nomCtrl.text.isEmpty) {
      _showSnackBar('Code et nom du produit requis', _K.danger);
      return;
    }

    setState(() => _isFormLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      final service = AdminService(user.token);
      final newProduct = await service.createProduct(
      code: _codeCtrl.text.trim(),
      nom: _nomCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      categorieId: 1, // ✅ AJOUTER - ID de la catégorie (à remplacer par une vraie valeur)
      prixAchat: double.parse(_prixAchatCtrl.text.trim()),
      prixVente: double.parse(_prixVenteCtrl.text.trim()),
      unite: _uniteCtrl.text.trim(),
      seuilAlerte: int.tryParse(_seuilCtrl.text.trim()) ?? 10,
      actif: _isActif,
    );

      if (!mounted) return;
      
      await _animationController.reverse();
      if (!mounted) return;
      
      Navigator.pop(context);
      _showSnackBar('Produit ${newProduct.nom} créé avec succès !', _K.success);
      _loadData();
      
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', _K.danger);
    } finally {
      if (mounted) setState(() => _isFormLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------
  Future<void> _updateProduct() async {
    if (_codeCtrl.text.isEmpty || _nomCtrl.text.isEmpty) {
      _showSnackBar('Code et nom du produit requis', _K.danger);
      return;
    }

    setState(() => _isFormLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      final service = AdminService(user.token);
      final updatedProduct = await service.updateProduct(
        _editingProductId!,
        {
          'code': _codeCtrl.text.trim(),
          'nom': _nomCtrl.text.trim(),
          'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
          'prix_achat': double.parse(_prixAchatCtrl.text.trim()),
          'prix_vente': double.parse(_prixVenteCtrl.text.trim()),
          'unite': _uniteCtrl.text.trim(),
          'seuil_alerte': int.tryParse(_seuilCtrl.text.trim()) ?? 10,
          'actif': _isActif,
        },
      );

      if (!mounted) return;
      
      await _animationController.reverse();
      if (!mounted) return;
      
      Navigator.pop(context);
      _showSnackBar('Produit ${updatedProduct.nom} modifié avec succès !', _K.success);
      _loadData();
      
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', _K.danger);
    } finally {
      if (mounted) setState(() => _isFormLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------
  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_K.radiusXl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _K.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, color: _K.danger, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Confirmer la suppression'),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer le produit "${product.nom}" ?\nCette action est irréversible.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: _K.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _K.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_K.radiusSm),
              ),
            ),
            child: const Text('Supprimer'),
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
        _showSnackBar('Produit "${product.nom}" supprimé avec succès', _K.success);
        _loadData();
      } else {
        _showSnackBar('Erreur lors de la suppression', _K.danger);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', _K.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // SHOW DIALOG
  // ---------------------------------------------------------------------
  void _showProductDialog({Product? product}) {
    final isEditing = product != null;
    
    if (isEditing) {
      _codeCtrl.text = product.code;
      _nomCtrl.text = product.nom;
      _descriptionCtrl.text = product.description ?? '';
      _prixAchatCtrl.text = product.prixAchat.toString();
      _prixVenteCtrl.text = product.prixVente.toString();
      _uniteCtrl.text = product.unite;
      _seuilCtrl.text = product.seuilAlerte.toString();
      _isActif = product.actif;
      _editingProductId = product.id;
    } else {
      _codeCtrl.clear();
      _nomCtrl.clear();
      _descriptionCtrl.clear();
      _prixAchatCtrl.clear();
      _prixVenteCtrl.clear();
      _uniteCtrl.clear();
      _seuilCtrl.text = '10';
      _isActif = true;
      _editingProductId = null;
    }
    _isFormLoading = false;

    final isWide = MediaQuery.of(context).size.width >= 900;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        _animationController.reset();
        _animationController.forward();
        
        return WillPopScope(
          onWillPop: () async {
            await _animationController.reverse();
            return true;
          },
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Dialog(
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  width: isWide ? 600 : double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                    maxWidth: 600,
                  ),
                  decoration: BoxDecoration(
                    color: _K.surface,
                    borderRadius: BorderRadius.circular(_K.radiusXl),
                    border: Border.all(color: _K.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(_K.radiusXl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_K.primary, _K.primary.withOpacity(0.8)],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(_K.radiusSm),
                                    ),
                                    child: Icon(
                                      isEditing ? Icons.edit_rounded : Icons.inventory_2_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isEditing ? 'Modifier le Produit' : 'Nouveau Produit',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          isEditing ? 'Modifiez les informations du produit' : 'Remplissez les informations ci-dessous',
                                          style: const TextStyle(
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
                                      onPressed: () async {
                                        await _animationController.reverse();
                                        if (mounted) Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Formulaire
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('Informations générales', Icons.info_rounded),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _codeCtrl,
                                      hint: 'Code produit *',
                                      icon: Icons.code_rounded,
                                      isRequired: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _nomCtrl,
                                      hint: 'Nom du produit *',
                                      icon: Icons.label_rounded,
                                      isRequired: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _descriptionCtrl,
                                      hint: 'Description',
                                      icon: Icons.description_rounded,
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 20),

                                    _buildSectionTitle('Prix et unité', Icons.attach_money_rounded),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _prixAchatCtrl,
                                            hint: "Prix d'achat",
                                            icon: Icons.shopping_cart_rounded,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _prixVenteCtrl,
                                            hint: 'Prix de vente *',
                                            icon: Icons.sell_rounded,
                                            isRequired: true,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _uniteCtrl,
                                            hint: 'Unité *',
                                            icon: Icons.scale_rounded,
                                            isRequired: true,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _seuilCtrl,
                                            hint: 'Seuil alerte',
                                            icon: Icons.warning_rounded,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    _buildSectionTitle('Statut', Icons.toggle_on_rounded),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _K.surfaceAlt,
                                        borderRadius: BorderRadius.circular(_K.radiusSm),
                                      ),
                                      child: SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                          'Produit actif',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _K.textPrimary,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _isActif ? 'Le produit est disponible' : 'Le produit est désactivé',
                                          style: const TextStyle(fontSize: 12, color: _K.textMuted),
                                        ),
                                        value: _isActif,
                                        activeColor: _K.success,
                                        inactiveThumbColor: _K.danger,
                                        activeTrackColor: _K.success.withOpacity(0.3),
                                        inactiveTrackColor: _K.danger.withOpacity(0.2),
                                        onChanged: (value) => setState(() => _isActif = value),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Footer
                            Container(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: _K.border, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isFormLoading ? null : () async {
                                        await _animationController.reverse();
                                        if (mounted) Navigator.pop(context);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: const BorderSide(color: _K.border),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(_K.radiusSm),
                                        ),
                                      ),
                                      child: const Text(
                                        'Annuler',
                                        style: TextStyle(color: _K.textMuted),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _isFormLoading ? null : (isEditing ? _updateProduct : _createProduct),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _K.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(_K.radiusSm),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isFormLoading
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
                                                Icon(isEditing ? Icons.save_rounded : Icons.check_rounded, size: 20),
                                                const SizedBox(width: 8),
                                                Text(isEditing ? 'Modifier' : 'Créer'),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _animationController.reset();
    });
  }

  // ---------------------------------------------------------------------
  // WIDGETS D'AIDE
  // ---------------------------------------------------------------------
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_K.radiusSm)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _K.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _K.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: _K.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: _K.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _K.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: _K.textMuted, size: 20),
        suffixIcon: isRequired
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.star_rounded,
                  color: _K.danger,
                  size: 12,
                ),
              )
            : null,
        filled: true,
        fillColor: _K.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_K.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_K.radiusSm),
          borderSide: const BorderSide(color: _K.primary, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _K.surface,
        borderRadius: BorderRadius.circular(_K.radius),
        border: Border.all(color: _K.border),
        boxShadow: [_K.cardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide)
              _buildDesktopHeader()
            else
              _buildMobileHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _K.primary))
                  : _filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : isWide
                          ? _buildDesktopTable()
                          : _buildMobileList(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HEADERS
  // ---------------------------------------------------------------------
  Widget _buildDesktopHeader() {
    return Row(
      children: [
        const Text(
          'Catalogue Produits',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _K.textPrimary,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 250,
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filterProducts,
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              hintStyle: const TextStyle(color: _K.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: _K.textMuted, size: 20),
              filled: true,
              fillColor: _K.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_K.radiusSm),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _showProductDialog,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nouveau Produit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _K.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_K.radiusSm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catalogue Produits',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _K.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filterProducts,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: const TextStyle(color: _K.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: _K.textMuted, size: 20),
                  filled: true,
                  fillColor: _K.surfaceAlt,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_K.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _showProductDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _K.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_K.radiusSm),
                ),
              ),
              child: const Icon(Icons.add_rounded, size: 24),
            ),
          ],
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
        headingRowColor: MaterialStateProperty.all(_K.surfaceAlt),
        horizontalMargin: 20,
        columnSpacing: 15,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 56,
        columns: const [
          DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Prix Vente', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Unité', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _filteredProducts.map((product) {
          final isEven = _filteredProducts.indexOf(product).isEven;
          final stockTotal = _stockQuantities[product.id] ?? 0;
          final isAlerte = stockTotal < product.seuilAlerte;
          
          return DataRow(
            color: MaterialStateProperty.all(isEven ? _K.surface : _K.bg.withOpacity(0.4)),
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _K.accentSoft,
                    borderRadius: BorderRadius.circular(_K.radiusXs),
                  ),
                  child: Text(
                    product.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _K.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  product.nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _K.textPrimary,
                  ),
                ),
              ),
            DataCell(
  Text(
    '${product.prixVente} \$',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      color: _K.success,
    ),
  ),
),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _K.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(_K.radiusXl),
                  ),
                  child: Text(
                    product.unite,
                    style: const TextStyle(
                      color: _K.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StockDetailView(productId: product.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAlerte 
                          ? _K.danger.withOpacity(0.1) 
                          : _K.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_K.radiusXl),
                      border: Border.all(
                        color: isAlerte 
                            ? _K.danger.withOpacity(0.3) 
                            : _K.success.withOpacity(0.3),
                      ),
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
                          '$stockTotal',
                          style: TextStyle(
                            color: isAlerte ? _K.danger : _K.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline_rounded,
                          color: isAlerte ? _K.danger : _K.success,
                          size: 14,
                        ),
                      ],
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
                      icon: const Icon(Icons.edit_rounded, color: _K.info, size: 18),
                      onPressed: () => _showProductDialog(product: product),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, color: _K.danger, size: 18),
                      onPressed: () => _deleteProduct(product),
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
      padding: const EdgeInsets.all(8),
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const Divider(color: _K.border, height: 1),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final stockTotal = _stockQuantities[product.id] ?? 0;
        final isAlerte = stockTotal < product.seuilAlerte;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_K.radiusSm),
            side: const BorderSide(color: _K.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _K.accentSoft,
                borderRadius: BorderRadius.circular(_K.radiusSm),
              ),
              child: Center(
                child: Text(
                  product.code.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: _K.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            title: Text(
              product.nom,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _K.textPrimary,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product.code} • ${product.unite}',
                  style: const TextStyle(color: _K.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                   Text(
  '${product.prixVente} \$',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: _K.success,
    fontSize: 14,
  ),
),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StockDetailView(productId: product.id),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAlerte 
                              ? _K.danger.withOpacity(0.1) 
                              : _K.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(_K.radiusXl),
                          border: Border.all(
                            color: isAlerte 
                                ? _K.danger.withOpacity(0.3) 
                                : _K.success.withOpacity(0.3),
                          ),
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
                            const SizedBox(width: 4),
                            Text(
                              '$stockTotal',
                              style: TextStyle(
                                color: isAlerte ? _K.danger : _K.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusBadge(product.actif),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: _K.info, size: 20),
                  onPressed: () => _showProductDialog(product: product),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: _K.danger, size: 20),
                  onPressed: () => _deleteProduct(product),
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
    final color = actif ? _K.success : _K.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_K.radiusXl),
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
            size: 64,
            color: _K.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isEmpty ? 'Aucun produit enregistré' : 'Aucun résultat trouvé',
            style: const TextStyle(color: _K.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _searchCtrl.text.isEmpty ? 'Ajoutez votre premier produit' : 'Essayez un autre terme de recherche',
            style: const TextStyle(color: _K.textMuted, fontSize: 13),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
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
}

