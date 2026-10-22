import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../../models/depot_model.dart';
import '../../../api/admin_service.dart';

class DepotView extends StatefulWidget {
  final AdminService service;
  const DepotView({super.key, required this.service});

  @override
  State<DepotView> createState() => _DepotViewState();
}

class _DepotViewState extends State<DepotView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Depot> _filteredDepots = [];
  List<Depot> _allDepots = [];
  bool _isLoading = false;

  // Contrôleurs formulaire
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _adresseCtrl = TextEditingController();
  String _selectedType = 'petit_depot';
  bool _estMagasin = false;
  bool _aCaisse = false;
  bool _isActif = true;
  int? _editingDepotId;

  // Animations
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nomCtrl.dispose();
    _adresseCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterDepots(String query) {
    if (query.isEmpty) {
      setState(() => _filteredDepots = _allDepots);
    } else {
      final q = query.toLowerCase();
      setState(() {
        _filteredDepots = _allDepots
            .where((depot) =>
        depot.nom.toLowerCase().contains(q) ||
            depot.type.toLowerCase().contains(q))
            .toList();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // CREATE (Inchangé)
  // ---------------------------------------------------------------------------
  Future<void> _createDepot() async {
    if (_nomCtrl.text.isEmpty) {
      _showSnackBar('Le nom du dépôt est requis', const Color(0xFFC42B1C));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newDepot = await widget.service.createDepot(
        nom: _nomCtrl.text.trim(),
        type: _selectedType,
        adresse: _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
        estMagasin: _estMagasin,
        aCaisse: _aCaisse,
        actif: _isActif,
      );

      if (!mounted) return;

      await _animationController.reverse();
      if (!mounted) return;

      Navigator.pop(context);
      _showSnackBar('Dépôt "${newDepot.nom}" créé avec succès !', const Color(0xFF107C41));
      _refreshDepots();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // READ (Inchangé)
  // ---------------------------------------------------------------------------
  Future<void> _refreshDepots() async {
    try {
      final depots = await widget.service.getDepots();
      if (mounted) {
        setState(() {
          _allDepots = depots;
          _filterDepots(_searchCtrl.text);
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur lors du chargement des dépôts', const Color(0xFFC42B1C));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE (Inchangé)
  // ---------------------------------------------------------------------------
  Future<void> _updateDepot() async {
    if (_nomCtrl.text.isEmpty) {
      _showSnackBar('Le nom du dépôt est requis', const Color(0xFFC42B1C));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedDepot = await widget.service.updateDepot(
        _editingDepotId!,
        nom: _nomCtrl.text.trim(),
        type: _selectedType,
        adresse: _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
        estMagasin: _estMagasin,
        aCaisse: _aCaisse,
        actif: _isActif,
      );

      if (!mounted) return;

      await _animationController.reverse();
      if (!mounted) return;

      Navigator.pop(context);
      _showSnackBar('Dépôt "${updatedDepot.nom}" modifié avec succès !', const Color(0xFF107C41));
      _refreshDepots();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE (Dialogue Windows 11)
  // ---------------------------------------------------------------------------
  Future<void> _deleteDepot(Depot depot) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
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
          'Voulez-vous vraiment supprimer le dépôt "${depot.nom}" ?\nCette opération est irréversible et dissociera les stocks qui lui sont attribués.',
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
            onPressed: () => Navigator.pop(dialogContext, false),
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
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC42B1C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Supprimer le site',
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

    setState(() => _isLoading = true);

    try {
      final success = await widget.service.deleteDepot(depot.id);

      if (!mounted) return;

      if (success) {
        _showSnackBar('Dépôt "${depot.nom}" supprimé avec succès', const Color(0xFF107C41));
        _refreshDepots();
      } else {
        _showSnackBar('Erreur lors de la suppression', const Color(0xFFC42B1C));
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // DIALOGUE CRÉATION / MODIFICATION (Design Windows 11 Fluent)
  // ---------------------------------------------------------------------------
  void _showDepotDialog({Depot? depot}) {
    final isEditing = depot != null;

    if (isEditing) {
      _nomCtrl.text = depot.nom;
      _adresseCtrl.text = depot.adresse ?? '';
      _selectedType = depot.type;
      _estMagasin = depot.estMagasin;
      _aCaisse = depot.aCaisse;
      _isActif = depot.actif;
      _editingDepotId = depot.id;
    } else {
      _nomCtrl.clear();
      _adresseCtrl.clear();
      _selectedType = 'petit_depot';
      _estMagasin = false;
      _aCaisse = false;
      _isActif = true;
      _editingDepotId = null;
    }
    _isLoading = false;

    final isWide = MediaQuery.of(context).size.width >= 900;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
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
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  width: isWide ? 560 : double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                    maxWidth: 560,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x18000000), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 28,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête du dialogue
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
                                    child: Icon(
                                      isEditing
                                          ? Icons.edit_location_alt_rounded
                                          : Icons.add_business_rounded,
                                      color: const Color(0xFF0067C0),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEditing ? 'Modifier le dépôt' : 'Nouveau dépôt',
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
                                            ? 'Mettez à jour les caractéristiques de l\'entrepôt'
                                            : 'Configurez un nouvel entrepôt ou magasin de vente',
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
                                    onPressed: () async {
                                      await _animationController.reverse();
                                      if (mounted) Navigator.pop(dialogContext);
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 1, thickness: 1, color: Color(0x14000000)),

                            // Formulaire scrollable
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormSectionHeader('INFORMATIONS GÉNÉRALES', Icons.storefront_outlined),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      controller: _nomCtrl,
                                      label: 'Nom du dépôt / magasin',
                                      hint: 'ex: Entrepôt Principal Nord',
                                      icon: Icons.business_outlined,
                                      isRequired: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _adresseCtrl,
                                      label: 'Adresse physique',
                                      hint: 'ex: Zone Industrielle, Rue 12',
                                      icon: Icons.place_outlined,
                                    ),
                                    const SizedBox(height: 20),

                                    _buildFormSectionHeader('TYPOLOGIE DE L\'INFRASTRUCTURE', Icons.category_outlined),
                                    const SizedBox(height: 10),
                                    _buildFieldHeader('TYPE DE DÉPÔT'),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: _selectedType,
                                      dropdownColor: const Color(0xFFFFFFFF),
                                      style: const TextStyle(
                                        fontFamily: kAppFontFamily,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF0F172A),
                                      ),
                                      decoration: _buildDropdownDecoration(Icons.warehouse_outlined),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'grand_depot',
                                          child: Text(
                                            'Grand Dépôt (Plateforme principale)',
                                            style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'petit_depot',
                                          child: Text(
                                            'Petit Dépôt (Stock de proximité)',
                                            style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'troisieme_depot',
                                          child: Text(
                                            'Troisième Dépôt (Annexe / Transit)',
                                            style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) setStateDialog(() => _selectedType = value);
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    _buildFormSectionHeader('CAPACITÉS & FONCTIONNALITÉS', Icons.tune_rounded),
                                    const SizedBox(height: 10),

                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0x14000000)),
                                      ),
                                      child: Column(
                                        children: [
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text(
                                              'Activité magasin',
                                              style: TextStyle(
                                                fontFamily: kAppFontFamily,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                                fontSize: 13,
                                              ),
                                            ),
                                            subtitle: const Text(
                                              'Point de vente physique ouvert aux clients',
                                              style: TextStyle(
                                                fontFamily: kAppFontFamily,
                                                fontSize: 11.5,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            value: _estMagasin,
                                            activeColor: const Color(0xFF0067C0),
                                            onChanged: (value) => setStateDialog(() => _estMagasin = value),
                                          ),
                                          const Divider(height: 12, thickness: 1, color: Color(0x10000000)),
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text(
                                              'Poste de caisse',
                                              style: TextStyle(
                                                fontFamily: kAppFontFamily,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                                fontSize: 13,
                                              ),
                                            ),
                                            subtitle: const Text(
                                              'Ce dépôt est habilité à encaisser des règlements',
                                              style: TextStyle(
                                                fontFamily: kAppFontFamily,
                                                fontSize: 11.5,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            value: _aCaisse,
                                            activeColor: const Color(0xFF0067C0),
                                            onChanged: (value) => setStateDialog(() => _aCaisse = value),
                                          ),
                                          const Divider(height: 12, thickness: 1, color: Color(0x10000000)),
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text(
                                              'Statut opérationnel',
                                              style: TextStyle(
                                                fontFamily: kAppFontFamily,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                                fontSize: 13,
                                              ),
                                            ),
                                            subtitle: const Text(
                                              'Le site est en activité et sélectionnable pour les flux',
                                              style: TextStyle(
                                                fontFamily: kAppFontFamily,
                                                fontSize: 11.5,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            value: _isActif,
                                            activeColor: const Color(0xFF0067C0),
                                            onChanged: (value) => setStateDialog(() => _isActif = value),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Divider(height: 1, thickness: 1, color: Color(0x14000000)),

                            // Footer avec boutons
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                      await _animationController.reverse();
                                      if (mounted) Navigator.pop(dialogContext);
                                    },
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
                                    onPressed: _isLoading ? null : (isEditing ? _updateDepot : _createDepot),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0067C0),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                        : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isEditing ? Icons.save_rounded : Icons.check_rounded, size: 17),
                                        const SizedBox(width: 6),
                                        Text(
                                          isEditing ? 'Enregistrer' : 'Créer le dépôt',
                                          style: const TextStyle(
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

  // ---------------------------------------------------------------------------
  // HELPERS UI
  // ---------------------------------------------------------------------------
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

  Widget _buildFormSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF0067C0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildFieldHeader(label.toUpperCase()),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Color(0xFFC42B1C), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
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
            contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
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
              borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildDropdownDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
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
        borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'grand_depot': return 'Grand Dépôt';
      case 'petit_depot': return 'Petit Dépôt';
      case 'troisieme_depot': return 'Troisième Dépôt';
      default: return type;
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD PRINCIPAL AVEC FUTUREBUILDER
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return FutureBuilder<List<Depot>>(
      future: widget.service.getDepots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0067C0), strokeWidth: 2.2),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFC42B1C)),
                const SizedBox(height: 12),
                Text(
                  "Erreur: ${snapshot.error}",
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFFC42B1C),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshDepots,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0067C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          );
        }

        _allDepots = snapshot.data ?? [];
        if (_filteredDepots.isEmpty && _searchCtrl.text.isEmpty) {
          _filteredDepots = _allDepots;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Indicateurs Synthétiques avec Ondes Fluides
            _buildDepotMetricsRow(),
            const SizedBox(height: 18),

            // 2. Barre d'actions (Bouton aligné au fond à droite)
            _buildActionBar(isWide),
            const SizedBox(height: 14),

            // 3. Tableau de données Desktop
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
                child: _filteredDepots.isEmpty
                    ? _buildEmptyState()
                    : isWide
                    ? _buildDesktopTable()
                    : _buildMobileDataRows(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildDepotMetricsRow() {
    final total = _allDepots.length;
    final magasins = _allDepots.where((d) => d.estMagasin).length;
    final actifs = _allDepots.where((d) => d.actif).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 740;

        final cards = [
          _buildWaveMetricCard(
            title: "TOTAL DÉPÔTS",
            value: "$total",
            subtitle: "Sites d'entreposage",
            badge: "Infrastructure",
            icon: Icons.warehouse_outlined,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "POINTS MAGASINS",
            value: "$magasins",
            subtitle: "Espaces vente comptoir",
            badge: "Vente Directe",
            icon: Icons.storefront_outlined,
            gradient: const [
              Color(0xFF0A3B5C),
              Color(0xFF165B8C),
              Color(0xFF3A89C9),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "DÉPÔTS ACTIFS",
            value: "$actifs",
            subtitle: "Opérationnels en direct",
            badge: "Opérationnel",
            icon: Icons.verified_outlined,
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
                    painter: DepotMetricWavePainter(waveSeed: waveSeed),
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
  // 2. BARRE D'ACTIONS
  // ---------------------------------------------------------------------------
  Widget _buildActionBar(bool isWide) {
    return Row(
      children: [
        SizedBox(
          width: isWide ? 310 : 200,
          height: 38,
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filterDepots,
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1F1F1F),
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, typologie...',
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
                  _filterDepots('');
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

        if (isWide) ...[
          const SizedBox(width: 14),
          Text(
            "${_filteredDepots.length} sur ${_allDepots.length} site(s)",
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
        ],

        const Spacer(),

        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: () => _showDepotDialog(),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: Text(isWide ? "Nouveau Dépôt" : "Ajouter"),
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
  // 3. TABLEAU DESKTOP HAUTE LISIBILITÉ
  // ---------------------------------------------------------------------------
  Widget _buildDesktopTable() {
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
                  DataColumn(label: Text("ID", style: _headerStyle)),
                  DataColumn(label: Text("NOM DU DÉPÔT", style: _headerStyle)),
                  DataColumn(label: Text("TYPE", style: _headerStyle)),
                  DataColumn(label: Text("ADRESSE", style: _headerStyle)),
                  DataColumn(label: Text("MAGASIN", style: _headerStyle)),
                  DataColumn(label: Text("CAISSE", style: _headerStyle)),
                  DataColumn(label: Text("STATUT", style: _headerStyle)),
                  DataColumn(label: Text("ACTIONS", style: _headerStyle)),
                ],
                rows: _filteredDepots.map((depot) {
                  return DataRow(
                    cells: [
                      // ID
                      DataCell(
                        Text(
                          '#${depot.id}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Nom
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              depot.estMagasin
                                  ? Icons.storefront_outlined
                                  : Icons.warehouse_outlined,
                              color: const Color(0xFF0067C0),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              depot.nom,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Type (Badge sobre)
                      DataCell(_buildTypeBadge(depot.type)),

                      // Adresse
                      DataCell(
                        Text(
                          depot.adresse ?? '—',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ),

                      // Magasin
                      DataCell(
                        Icon(
                          depot.estMagasin
                              ? Icons.check_circle_rounded
                              : Icons.remove_circle_outline_rounded,
                          color: depot.estMagasin
                              ? const Color(0xFF107C41)
                              : const Color(0xFFCBD5E1),
                          size: 18,
                        ),
                      ),

                      // Caisse
                      DataCell(
                        Icon(
                          depot.aCaisse
                              ? Icons.point_of_sale_rounded
                              : Icons.remove_circle_outline_rounded,
                          color: depot.aCaisse
                              ? const Color(0xFF0067C0)
                              : const Color(0xFFCBD5E1),
                          size: 18,
                        ),
                      ),

                      // Statut
                      DataCell(_buildStatusBadge(depot.actif)),

                      // Actions
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
                              onPressed: () => _showDepotDialog(depot: depot),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFC42B1C),
                                size: 17,
                              ),
                              splashRadius: 14,
                              tooltip: 'Supprimer',
                              onPressed: () => _deleteDepot(depot),
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
  // 4. LIGNES TABLEAU MOBILE
  // ---------------------------------------------------------------------------
  Widget _buildMobileDataRows() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredDepots.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final depot = _filteredDepots[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  depot.estMagasin ? Icons.storefront_outlined : Icons.warehouse_outlined,
                  color: const Color(0xFF0067C0),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      depot.nom,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (depot.adresse != null && depot.adresse!.isNotEmpty)
                      Text(
                        depot.adresse!,
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTypeBadge(depot.type),
                        const SizedBox(width: 8),
                        _buildStatusBadge(depot.actif),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF0067C0), size: 18),
                    onPressed: () => _showDepotDialog(depot: depot),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC42B1C), size: 18),
                    onPressed: () => _deleteDepot(depot),
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
  // BADGES (Type & Statut)
  // ---------------------------------------------------------------------------
  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x10000000)),
      ),
      child: Text(
        _getTypeLabel(type),
        style: const TextStyle(
          fontFamily: kAppFontFamily,
          color: Color(0xFF334155),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

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
          Container(width: 5.5, height: 5.5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.warehouse_outlined, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isEmpty ? 'Aucun dépôt enregistré' : 'Aucun dépôt trouvé',
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
                  ? 'Cliquez sur "Nouveau Dépôt" pour configurer votre premier site.'
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
                  _filterDepots('');
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
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES DÉPÔTS
// ---------------------------------------------------------------------------
class DepotMetricWavePainter extends CustomPainter {
  final double waveSeed;

  DepotMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant DepotMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}