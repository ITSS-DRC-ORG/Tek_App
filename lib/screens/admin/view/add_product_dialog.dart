import 'package:flutter/material.dart';
import 'package:tek_app/theme/app_theme.dart';
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

  int? _selectedCategorieId;
  List<dynamic> _categories = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();

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

  // ---------------------------------------------------------------------------
  // CHARGER LES CATÉGORIES (Inchangé)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // SAUVEGARDER LE PRODUIT (Inchangé)
  // ---------------------------------------------------------------------------
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner une catégorie',
            style: TextStyle(fontFamily: kAppFontFamily),
          ),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.product != null;

      if (isEditing) {
        await widget.service.updateProduct(
          widget.product!.id,
          {
            'code': _codeCtrl.text.trim(),
            'nom': _nomCtrl.text.trim(),
            'description': _descriptionCtrl.text.trim().isEmpty
                ? null
                : _descriptionCtrl.text.trim(),
            'categorie_id': _selectedCategorieId,
            'prix_achat': double.parse(_prixAchatCtrl.text.trim()),
            'prix_vente': double.parse(_prixVenteCtrl.text.trim()),
            'unite': _uniteCtrl.text.trim(),
            'seuil_alerte': int.tryParse(_seuilCtrl.text.trim()) ?? 10,
            'actif': _isActif,
          },
        );
      } else {
        await widget.service.createProduct(
          code: _codeCtrl.text.trim(),
          nom: _nomCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
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
          content: Text(
            'Erreur: ${e.toString()}',
            style: const TextStyle(fontFamily: kAppFontFamily),
          ),
          backgroundColor: const Color(0xFFC42B1C),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // INTERFACE UTILISATEUR
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x18000000), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 28,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // EN-TÊTE DU DIALOGUE WINDOWS 11
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F2FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_box_outlined,
                        color: const Color(0xFF0067C0),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Modifier le produit'
                              : 'Ajouter un nouveau produit',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Mettez à jour les caractéristiques de l\'article'
                              : 'Renseignez les données d\'inventaire et de tarification',
                          style: const TextStyle(
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0x14000000)),

              // CORPS DU FORMULAIRE SCROLLABLE
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LIGNE 1 : CODE (flex: 4) & NOM (flex: 6)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildInputField(
                                controller: _codeCtrl,
                                label: 'Code article',
                                hint: 'ex: PRD-001',
                                icon: Icons.qr_code_rounded,
                                isRequired: true,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 6,
                              child: _buildInputField(
                                controller: _nomCtrl,
                                label: 'Nom du produit',
                                hint: 'Désignation de l\'article',
                                icon: Icons.label_outline_rounded,
                                isRequired: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // LIGNE 2 : SÉLECTEUR DE CATÉGORIE
                        _buildCategorySection(),
                        const SizedBox(height: 16),

                        // LIGNE 3 : PRIX D'ACHAT & PRIX DE VENTE (50 / 50)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _prixAchatCtrl,
                                label: 'Prix d\'achat (\$)',
                                hint: '0.00',
                                icon: Icons.arrow_downward_rounded,
                                isRequired: true,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildInputField(
                                controller: _prixVenteCtrl,
                                label: 'Prix de vente (\$)',
                                hint: '0.00',
                                icon: Icons.arrow_upward_rounded,
                                isRequired: true,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // LIGNE 4 : UNITÉ & SEUIL D'ALERTE (50 / 50)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _uniteCtrl,
                                label: 'Unité de mesure',
                                hint: 'ex: Pièce, Kg, Paquet',
                                icon: Icons.straighten_rounded,
                                isRequired: true,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildInputField(
                                controller: _seuilCtrl,
                                label: 'Seuil d\'alerte stock',
                                hint: 'ex: 10',
                                icon: Icons.notifications_active_outlined,
                                isRequired: false,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // LIGNE 5 : DESCRIPTION
                        _buildInputField(
                          controller: _descriptionCtrl,
                          label: 'Description détaillée',
                          hint: 'Détails, spécifications ou références complémentaires...',
                          icon: Icons.notes_rounded,
                          isRequired: false,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 18),

                        // LIGNE 6 : CARTE DE STATUT ACTIF / INACTIF
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x14000000)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _isActif
                                      ? const Color(0xFFE8F2FB)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _isActif
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.remove_circle_outline_rounded,
                                  color: _isActif
                                      ? const Color(0xFF0067C0)
                                      : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Disponibilité commerciale',
                                      style: TextStyle(
                                        fontFamily: kAppFontFamily,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      _isActif
                                          ? 'Actif et visible pour les encaissements en caisse'
                                          : 'Masqué en caisse et suspendu du catalogue',
                                      style: const TextStyle(
                                        fontFamily: kAppFontFamily,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isActif,
                                activeColor: const Color(0xFF0067C0),
                                onChanged: (val) =>
                                    setState(() => _isActif = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0x14000000)),

              // PIED DU DIALOGUE AVEC LES ACTIONS
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed:
                      _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0x20000000)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0067C0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                          : Text(
                        isEditing
                            ? 'Enregistrer les modifications'
                            : 'Créer le produit',
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
  }

  // ---------------------------------------------------------------------------
  // COMPOSANT CHAMP DE SAISIE AVEC LABEL SUPÉRIEUR
  // ---------------------------------------------------------------------------
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isRequired,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
                letterSpacing: 0.6,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFC42B1C),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: kAppFontFamily,
              color: Color(0xFFA0AEC0),
              fontSize: 12.5,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 11,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF0067C0),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC42B1C), width: 1.2),
            ),
          ),
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
              : null,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // COMPOSANT SÉLECTEUR DE CATÉGORIE
  // ---------------------------------------------------------------------------
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'CATÉGORIE',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
                letterSpacing: 0.6,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: Color(0xFFC42B1C),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isLoadingCategories) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Color(0xFF0067C0),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _selectedCategorieId,
          isExpanded: true,
          dropdownColor: const Color(0xFFFFFFFF),
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
          decoration: InputDecoration(
            hintText: 'Sélectionnez une catégorie',
            hintStyle: const TextStyle(
              fontFamily: kAppFontFamily,
              color: Color(0xFFA0AEC0),
              fontSize: 12.5,
            ),
            prefixIcon: const Icon(
              Icons.category_outlined,
              color: Color(0xFF64748B),
              size: 18,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 11,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF0067C0),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC42B1C), width: 1.2),
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<int>(
              value: category['id'] as int,
              child: Text(
                category['nom'] as String,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
            );
          }).toList(),
          validator: (value) =>
          value == null ? 'Veuillez sélectionner une catégorie' : null,
          onChanged: (value) => setState(() => _selectedCategorieId = value),
        ),
      ],
    );
  }
}