import 'package:flutter/material.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import '../../../models/product_model.dart';
import '../../../api/admin_service.dart';

class AddProductDialog extends StatefulWidget {
  final AdminService service;
  final Product? product;
  const AddProductDialog({
    super.key,
    required this.service,
    this.product,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _prixAchatCtrl = TextEditingController();
  final TextEditingController _prixVenteCtrl = TextEditingController();
  final TextEditingController _uniteCtrl = TextEditingController();
  final TextEditingController _seuilCtrl = TextEditingController();
  bool _isActif = true;
  bool _isLoading = false;

  // ✅ Ajouter le contrôleur pour la catégorie
  int? _selectedCategorieId;
  List<dynamic> _categories = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    // Remplir les champs si en mode édition
    if (widget.product != null) {
      final p = widget.product!;
      _codeCtrl.text = p.code;
      _nomCtrl.text = p.nom;
      _descriptionCtrl.text = p.description ?? '';
      _prixAchatCtrl.text = p.prixAchat.toString();
      _prixVenteCtrl.text = p.prixVente.toString();
      _uniteCtrl.text = p.unite;
      _seuilCtrl.text = p.seuilAlerte.toString();
      _isActif = p.actif;
      _selectedCategorieId = p.categorieId;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nomCtrl.dispose();
    _descriptionCtrl.dispose();
    _prixAchatCtrl.dispose();
    _prixVenteCtrl.dispose();
    _uniteCtrl.dispose();
    _seuilCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // CHARGER LES CATÉGORIES
  // ---------------------------------------------------------------------
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await widget.service.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        if (_categories.isNotEmpty && _selectedCategorieId == null) {
          _selectedCategorieId = _categories.first['id'] as int?;
        }
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  // ---------------------------------------------------------------------
  // SAUVEGARDER
  // ---------------------------------------------------------------------
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Vérifier que la catégorie est sélectionnée
    if (_selectedCategorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.product != null;
      
      if (isEditing) {
        // ✅ Mise à jour
        await widget.service.updateProduct(
          widget.product!.id,
          {
            'code': _codeCtrl.text.trim(),
            'nom': _nomCtrl.text.trim(),
            'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
            'categorie_id': _selectedCategorieId,
            'prix_achat': double.parse(_prixAchatCtrl.text.trim()),
            'prix_vente': double.parse(_prixVenteCtrl.text.trim()),
            'unite': _uniteCtrl.text.trim(),
            'seuil_alerte': int.tryParse(_seuilCtrl.text.trim()) ?? 10,
            'actif': _isActif,
          },
        );
      } else {
        // ✅ Création avec categorieId
        await widget.service.createProduct(
          code: _codeCtrl.text.trim(),
          nom: _nomCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
          categorieId: _selectedCategorieId!,
          prixAchat: double.parse(_prixAchatCtrl.text.trim()),
          prixVente: double.parse(_prixVenteCtrl.text.trim()),
          unite: _uniteCtrl.text.trim(),
          seuilAlerte: int.tryParse(_seuilCtrl.text.trim()) ?? 10,
          actif: _isActif,
        );
      }

      if (!context.mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: K.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_rounded : Icons.add_rounded,
                      color: K.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Modifier le produit' : 'Nouveau produit',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: K.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField(_codeCtrl, 'Code *', Icons.code_rounded, true),
                      const SizedBox(height: 12),
                      _buildTextField(_nomCtrl, 'Nom *', Icons.label_rounded, true),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionCtrl, 'Description', Icons.description_rounded, false, maxLines: 2),
                      const SizedBox(height: 12),
                      
                      // ✅ Sélecteur de catégorie
                      _buildCategorySelector(),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _prixAchatCtrl,
                              "Prix d'achat *",
                              Icons.shopping_cart_rounded,
                              true,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              _prixVenteCtrl,
                              'Prix de vente *',
                              Icons.sell_rounded,
                              true,
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
                              _uniteCtrl,
                              'Unité *',
                              Icons.scale_rounded,
                              true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              _seuilCtrl,
                              'Seuil alerte',
                              Icons.warning_rounded,
                              false,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Produit actif',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: K.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          _isActif ? 'Le produit est disponible' : 'Le produit est désactivé',
                          style: const TextStyle(fontSize: 12, color: K.textMuted),
                        ),
                        value: _isActif,
                        activeColor: K.success,
                        onChanged: (value) => setState(() => _isActif = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: K.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(isEditing ? 'Modifier' : 'Créer'),
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

  // ---------------------------------------------------------------------
  // SÉLECTEUR DE CATÉGORIE
  // ---------------------------------------------------------------------
  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: K.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedCategorieId,
        isExpanded: true,
        hint: const Text('Catégorie *'),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.category_rounded, color: K.textMuted),
        ),
        items: _categories.map((category) {
          return DropdownMenuItem(
            value: category['id'] as int,
            child: Text(category['nom'] as String),
          );
        }).toList(),
        validator: (value) => value == null ? 'Veuillez sélectionner une catégorie' : null,
        onChanged: (value) {
          setState(() {
            _selectedCategorieId = value;
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CHAMP TEXTE
  // ---------------------------------------------------------------------
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool required, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: K.textMuted),
        suffixIcon: required
            ? const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.star_rounded, color: Colors.red, size: 12),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: K.primary, width: 1.5),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }
}