import 'package:flutter/material.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import '../../../models/depot_model.dart';
import '../../../api/admin_service.dart';

class DepotView extends StatefulWidget {
  final AdminService service;
  const DepotView({super.key, required this.service});

  @override
  State<DepotView> createState() => _DepotViewState();
}

class _DepotViewState extends State<DepotView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Depot> _filteredDepots = [];
  List<Depot> _allDepots = [];
  bool _isLoading = false;
  
  // Contrôleurs pour le formulaire
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _adresseCtrl = TextEditingController();
  String _selectedType = 'petit_depot';
  bool _estMagasin = false;
  bool _aCaisse = false;
  bool _isActif = true;
  int? _editingDepotId;

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
      setState(() {
        _filteredDepots = _allDepots.where((depot) =>
          depot.nom.toLowerCase().contains(query.toLowerCase()) ||
          depot.type.toLowerCase().contains(query.toLowerCase())
        ).toList();
      });
    }
  }

  // ---------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------
  Future<void> _createDepot() async {
    if (_nomCtrl.text.isEmpty) {
      _showSnackBar('Le nom du dépôt est requis', K.danger);
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
      _showSnackBar('Dépôt ${newDepot.nom} créé avec succès !', K.success);
      _refreshDepots();
      
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', K.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------
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
        _showSnackBar('Erreur lors du chargement des dépôts', K.danger);
      }
    }
  }

  // ---------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------
  Future<void> _updateDepot() async {
    if (_nomCtrl.text.isEmpty) {
      _showSnackBar('Le nom du dépôt est requis', K.danger);
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
      _showSnackBar('Dépôt ${updatedDepot.nom} modifié avec succès !', K.success);
      _refreshDepots();
      
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', K.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------
  Future<void> _deleteDepot(Depot depot) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.radiusXl)),
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
            const Text('Confirmer la suppression'),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer le dépôt "${depot.nom}" ?\nCette action est irréversible.',
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

    setState(() => _isLoading = true);

    try {
      final success = await widget.service.deleteDepot(depot.id);
      
      if (!mounted) return;
      
      if (success) {
        _showSnackBar('Dépôt "${depot.nom}" supprimé avec succès', K.success);
        _refreshDepots();
      } else {
        _showSnackBar('Erreur lors de la suppression', K.danger);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', K.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // SHOW DIALOG (Create/Update)
  // ---------------------------------------------------------------------
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
                  width: isWide ? 500 : double.infinity,
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
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(K.radiusXl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header avec gradient
                            Container(
                              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [K.primary, K.primary.withOpacity(0.8)],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(K.radiusSm),
                                    ),
                                    child: Icon(
                                      isEditing ? Icons.edit_rounded : Icons.warehouse_rounded,
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
                                          isEditing ? 'Modifier le Dépôt' : 'Nouveau Dépôt',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          isEditing ? 'Modifiez les informations du dépôt' : 'Créez un nouveau dépôt ou magasin',
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
                            
                            // Formulaire scrollable
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('Informations du dépôt', Icons.info_outline_rounded),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _nomCtrl,
                                      hint: 'Nom du dépôt *',
                                      icon: Icons.storefront_rounded,
                                      isRequired: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _adresseCtrl,
                                      hint: 'Adresse (optionnel)',
                                      icon: Icons.location_on_rounded,
                                    ),
                                    const SizedBox(height: 20),

                                    _buildSectionTitle('Type de dépôt', Icons.category_rounded),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _selectedType,
                                      decoration: _buildDropdownDecoration('Type de dépôt', Icons.category_rounded),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'grand_depot',
                                          child: Row(
                                            children: [
                                              Icon(Icons.business_center_rounded, color: K.primary, size: 18),
                                              SizedBox(width: 10),
                                              Text('Grand Dépôt'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'petit_depot',
                                          child: Row(
                                            children: [
                                              Icon(Icons.store_rounded, color: K.info, size: 18),
                                              SizedBox(width: 10),
                                              Text('Petit Dépôt'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'troisieme_depot',
                                          child: Row(
                                            children: [
                                              Icon(Icons.warehouse_rounded, color: Colors.orange, size: 18),
                                              SizedBox(width: 10),
                                              Text('Troisième Dépôt'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) setState(() => _selectedType = value);
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    _buildSectionTitle('Configuration', Icons.settings_rounded),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: K.surfaceAlt,
                                        borderRadius: BorderRadius.circular(K.radiusSm),
                                      ),
                                      child: Column(
                                        children: [
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text(
                                              'Est un magasin',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: K.textPrimary,
                                                fontSize: 14,
                                              ),
                                            ),
                                            subtitle: Text(
                                              _estMagasin ? 'Ce dépôt est un magasin' : 'Ce dépôt est un entrepôt',
                                              style: const TextStyle(fontSize: 12, color: K.textMuted),
                                            ),
                                            value: _estMagasin,
                                            activeColor: K.info,
                                            inactiveThumbColor: K.textMuted,
                                            activeTrackColor: K.info.withOpacity(0.3),
                                            onChanged: (value) => setState(() => _estMagasin = value),
                                          ),
                                          const Divider(height: 20),
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text(
                                              'Possède une caisse',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: K.textPrimary,
                                                fontSize: 14,
                                              ),
                                            ),
                                            subtitle: Text(
                                              _aCaisse ? 'Ce dépôt peut effectuer des ventes' : 'Ce dépôt ne possède pas de caisse',
                                              style: const TextStyle(fontSize: 12, color: K.textMuted),
                                            ),
                                            value: _aCaisse,
                                            activeColor: K.success,
                                            inactiveThumbColor: K.textMuted,
                                            activeTrackColor: K.success.withOpacity(0.3),
                                            onChanged: (value) => setState(() => _aCaisse = value),
                                          ),
                                          const Divider(height: 20),
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text(
                                              'Dépôt actif',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: K.textPrimary,
                                                fontSize: 14,
                                              ),
                                            ),
                                            subtitle: Text(
                                              _isActif ? 'Le dépôt est disponible' : 'Le dépôt est désactivé',
                                              style: const TextStyle(fontSize: 12, color: K.textMuted),
                                            ),
                                            value: _isActif,
                                            activeColor: K.success,
                                            inactiveThumbColor: K.danger,
                                            activeTrackColor: K.success.withOpacity(0.3),
                                            onChanged: (value) => setState(() => _isActif = value),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Footer avec boutons
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
                                      onPressed: _isLoading ? null : () async {
                                        await _animationController.reverse();
                                        if (mounted) Navigator.pop(context);
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
                                      onPressed: _isLoading ? null : (isEditing ? _updateDepot : _createDepot),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: K.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(K.radiusSm),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
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
                                                Icon(isEditing ? Icons.save_rounded : Icons.add_rounded, size: 20),
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
              color == K.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.radiusSm)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: K.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: K.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: K.primary.withOpacity(0.2),
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
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: K.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: K.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: K.textMuted, size: 20),
        suffixIcon: isRequired
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.star_rounded,
                  color: K.danger,
                  size: 12,
                ),
              )
            : null,
        filled: true,
        fillColor: K.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusSm),
          borderSide: const BorderSide(color: K.primary, width: 1.5),
        ),
      ),
    );
  }

  InputDecoration _buildDropdownDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: K.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: K.textMuted, size: 20),
      filled: true,
      fillColor: K.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(K.radiusSm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(K.radiusSm),
        borderSide: const BorderSide(color: K.primary, width: 1.5),
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'grand_depot': return K.primary;
      case 'petit_depot': return K.info;
      case 'troisieme_depot': return Colors.orange;
      default: return K.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return FutureBuilder<List<Depot>>(
      future: widget.service.getDepots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: K.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: K.danger),
                const SizedBox(height: 12),
                Text(
                  "Erreur: ${snapshot.error}",
                  style: const TextStyle(color: K.danger, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshDepots,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: K.primary,
                    foregroundColor: Colors.white,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide)
              _buildDesktopHeader()
            else
              _buildMobileHeader(),
            const SizedBox(height: 25),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: K.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: K.border),
                  boxShadow: [K.cardShadow],
                ),
                child: _filteredDepots.isEmpty
                    ? _buildEmptyState()
                    : isWide
                        ? _buildDesktopTable()
                        : _buildMobileList(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // HEADERS
  // ---------------------------------------------------------------------
  Widget _buildDesktopHeader() {
    final activeDepots = _allDepots.where((d) => d.actif).length;
    final magasins = _allDepots.where((d) => d.estMagasin).length;
    
    return Row(
      children: [
        StatChip(
          icon: Icons.warehouse_rounded, 
          label: 'Dépôts', 
          value: '${_allDepots.length}', 
          color: K.primary
        ),
        const SizedBox(width: 12),
        StatChip(
          icon: Icons.store_rounded, 
          label: 'Magasins', 
          value: '$magasins',
          color: K.info
        ),
        const SizedBox(width: 12),
        StatChip(
          icon: Icons.check_circle_rounded, 
          label: 'Actifs', 
          value: '$activeDepots',
          color: K.success
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showDepotDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nouveau Dépôt'),
          style: ElevatedButton.styleFrom(
            backgroundColor: K.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final activeDepots = _allDepots.where((d) => d.actif).length;
    final magasins = _allDepots.where((d) => d.estMagasin).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              StatChip(
                icon: Icons.warehouse_rounded, 
                label: 'Total', 
                value: '${_allDepots.length}', 
                color: K.primary
              ),
              const SizedBox(width: 10),
              StatChip(
                icon: Icons.store_rounded, 
                label: 'Magasins', 
                value: '$magasins',
                color: K.info
              ),
              const SizedBox(width: 10),
              StatChip(
                icon: Icons.check_circle_rounded, 
                label: 'Actifs', 
                value: '$activeDepots',
                color: K.success
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          onChanged: _filterDepots,
          decoration: InputDecoration(
            hintText: 'Rechercher un dépôt...',
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDepotDialog(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Nouveau Dépôt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: K.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  final columnLabels = [
    'ID',
    'Nom',
    'Type',
    'Adresse',
    'Magasin',
    'Caisse',
    'Statut',
    'Actions',
  ];

  return SingleChildScrollView(
    child: DataTable(
      headingRowColor: MaterialStateProperty.all(K.surfaceAlt),
      horizontalMargin: 20,
      columnSpacing: 20,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 56,
      columns: columnLabels.map((label) {
        return DataColumn(
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
      rows: _filteredDepots.map((depot) {
        final isEven = _filteredDepots.indexOf(depot).isEven;
        return DataRow(
          color: MaterialStateProperty.all(isEven ? K.surface : K.bg.withOpacity(0.4)),
          cells: [
            DataCell(Text('#${depot.id}', style: const TextStyle(color: K.textMuted, fontSize: 12))),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    depot.estMagasin ? Icons.store_rounded : Icons.warehouse_rounded,
                    color: K.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(depot.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            DataCell(_buildTypeBadge(depot.type)),
            DataCell(
              Text(
                depot.adresse ?? '-',
                style: const TextStyle(color: K.textMuted, fontSize: 13),
              ),
            ),
            DataCell(
              Icon(
                depot.estMagasin ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: depot.estMagasin ? K.success : K.textMuted,
                size: 18,
              ),
            ),
            DataCell(
              Icon(
                depot.aCaisse ? Icons.point_of_sale_rounded : Icons.cancel_rounded,
                color: depot.aCaisse ? K.info : K.textMuted,
                size: 18,
              ),
            ),
            DataCell(_buildStatusBadge(depot.actif)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: K.info, size: 18),
                    onPressed: () => _showDepotDialog(depot: depot),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: K.danger, size: 18),
                    onPressed: () => _deleteDepot(depot),
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
      itemCount: _filteredDepots.length,
      separatorBuilder: (_, __) => const Divider(color: K.border, height: 1),
      itemBuilder: (context, index) {
        final depot = _filteredDepots[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: K.accentSoft,
              borderRadius: BorderRadius.circular(K.radiusSm),
            ),
            child: Icon(
              depot.estMagasin ? Icons.store_rounded : Icons.warehouse_rounded,
              color: K.primary,
              size: 24,
            ),
          ),
          title: Text(
            depot.nom,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeBadge(depot.type),
              const SizedBox(height: 4),
              if (depot.adresse != null)
                Text(
                  depot.adresse!,
                  style: const TextStyle(color: K.textMuted, fontSize: 12),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildFeatureChip(
                    icon: Icons.store_rounded,
                    label: 'Magasin',
                    active: depot.estMagasin,
                  ),
                  const SizedBox(width: 4),
                  _buildFeatureChip(
                    icon: Icons.point_of_sale_rounded,
                    label: 'Caisse',
                    active: depot.aCaisse,
                  ),
                  const SizedBox(width: 4),
                  _buildStatusBadge(depot.actif),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: K.info, size: 20),
                onPressed: () => _showDepotDialog(depot: depot),
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: K.danger, size: 20),
                onPressed: () => _deleteDepot(depot),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // BADGES
  // ---------------------------------------------------------------------
  Widget _buildTypeBadge(String type) {
    final color = _getTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getTypeLabel(type).toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(bool actif) {
    final color = actif ? K.success : K.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          actif ? 'Actif' : 'Inactif',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    final color = active ? K.success : K.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? K.success.withOpacity(0.1) : K.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? K.success.withOpacity(0.3) : K.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // ÉTATS
  // ---------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchCtrl.text.isEmpty ? Icons.warehouse_outlined : Icons.search_off_rounded,
            size: 48,
            color: K.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            _searchCtrl.text.isEmpty ? 'Aucun dépôt enregistré' : 'Aucun résultat trouvé',
            style: const TextStyle(color: K.textMuted, fontSize: 14),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                _filterDepots('');
              },
              child: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }
}