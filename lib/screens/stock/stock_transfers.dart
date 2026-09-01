import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';
import '../../models/depot_model.dart';
import '../../models/product_model.dart';
import '../../models/stock_model.dart';

class StockTransfers extends StatefulWidget {
  const StockTransfers({super.key});

  @override
  State<StockTransfers> createState() => _StockTransfersState();
}

class _StockTransfersState extends State<StockTransfers> with SingleTickerProviderStateMixin {
  // Données
  List<Transfert> _transferts = [];
  List<Depot> _depots = [];
  List<Product> _products = [];
  List<Stock> _stocks = [];
  List<Transfert> _filteredTransferts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _selectedFilter = 'Tous';
  final TextEditingController _searchCtrl = TextEditingController();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Rôle utilisateur
  bool _isAdmin = false;

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
    print('📦 Chargement des transferts...');
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        
        // ✅ Vérifier si l'utilisateur est admin
        _isAdmin = user.role == UserRole.admin;
        
        final depots = await service.getDepots();
        final products = await service.getAllProducts();
        final stocks = await service.getStocks();
        final transferts = await service.getTransferts();

        setState(() {
          _depots = depots;
          _products = products;
          _stocks = stocks;
          _transferts = transferts;
          _filteredTransferts = transferts;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  // ---------------------------------------------------------------------
  // VALIDATION TRANSFERT (Réservée aux admins)
  // ---------------------------------------------------------------------
  Future<void> _validerTransfert(Transfert transfert) async {
    // ✅ Vérifier si l'utilisateur est admin
    if (!_isAdmin) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        'Seuls les administrateurs peuvent valider les transferts.\n\nVous n\'avez pas les droits nécessaires pour effectuer cette action.',
        Icons.lock_rounded,
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      'Valider le transfert',
      'Êtes-vous sûr de vouloir valider ce transfert ?',
      'Valider',
      K.success,
    );
    if (!confirm) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      final service = AdminService(user.token);
      await service.validerTransfert(transfert.id);
      _showSnackBar('✅ Transfert #${transfert.numeroBon} validé avec succès', Colors.green);
      _refreshData();
    } on PermissionException catch (e) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        '${e.message}\n\nSeuls les administrateurs peuvent valider les transferts.',
        Icons.lock_rounded,
      );
    } catch (e) {
      _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _effectuerTransfert(Transfert transfert) async {
    // ✅ Vérifier si l'utilisateur est admin
    if (!_isAdmin) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        'Seuls les administrateurs peuvent effectuer les transferts.\n\nVous n\'avez pas les droits nécessaires pour effectuer cette action.',
        Icons.lock_rounded,
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      'Effectuer le transfert',
      'Êtes-vous sûr de vouloir effectuer ce transfert ?\nLes stocks seront déduits du dépôt source.',
      'Effectuer',
      K.success,
    );
    if (!confirm) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      final service = AdminService(user.token);
      await service.effectuerTransfert(transfert.id);
      _showSnackBar('✅ Transfert #${transfert.numeroBon} effectué avec succès', Colors.green);
      _refreshData();
    } on PermissionException catch (e) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        '${e.message}\n\nSeuls les administrateurs peuvent effectuer les transferts.',
        Icons.lock_rounded,
      );
    } catch (e) {
      _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _annulerTransfert(Transfert transfert) async {
    // ✅ Vérifier si l'utilisateur est admin
    if (!_isAdmin) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        'Seuls les administrateurs peuvent annuler les transferts.\n\nVous n\'avez pas les droits nécessaires pour effectuer cette action.',
        Icons.lock_rounded,
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      'Annuler le transfert',
      'Êtes-vous sûr de vouloir annuler ce transfert ?',
      'Annuler',
      K.danger,
    );
    if (!confirm) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      final service = AdminService(user.token);
      await service.annulerTransfert(transfert.id);
      _showSnackBar('✅ Transfert #${transfert.numeroBon} annulé avec succès', Colors.orange);
      _refreshData();
    } on PermissionException catch (e) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        '${e.message}\n\nSeuls les administrateurs peuvent annuler les transferts.',
        Icons.lock_rounded,
      );
    } catch (e) {
      _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------
  // DIALOG PERMISSION
  // ---------------------------------------------------------------------
  void _showPermissionErrorDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: K.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: K.warning,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: K.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: K.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: K.warning.withOpacity(0.05),
                borderRadius: BorderRadius.circular(K.radiusSm),
                border: Border.all(color: K.warning.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: K.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Contactez un administrateur pour obtenir les droits nécessaires.',
                      style: TextStyle(
                        fontSize: 12,
                        color: K.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: K.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: K.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // FILTRES
  // ---------------------------------------------------------------------
  void _filterTransferts(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Tous') {
        _filteredTransferts = _transferts;
      } else {
        _filteredTransferts = _transferts.where((t) => t.statut == filter).toList();
      }
    });
  }

  // ---------------------------------------------------------------------
  // SHOW SNACKBAR
  // ---------------------------------------------------------------------
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle_rounded : Icons.error_outline_rounded,
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
  // SHOW CONFIRM DIALOG
  // ---------------------------------------------------------------------
  Future<bool> _showConfirmDialog(String title, String message, String action, Color color) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.radiusXl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                title.contains('Valider') ? Icons.check_circle_rounded :
                title.contains('Effectuer') ? Icons.play_arrow_rounded :
                Icons.warning_rounded,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: K.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
            ),
            child: Text(action),
          ),
        ],
      ),
    ) ?? false;
  }

  // ---------------------------------------------------------------------
  // CRÉER TRANSFERT
  // ---------------------------------------------------------------------
  void _showCreateTransferDialog() {
    // ✅ Vérifier si l'utilisateur peut créer un transfert
    if (!_isAdmin) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        'Seuls les administrateurs peuvent créer des transferts.\n\nVous n\'avez pas les droits nécessaires pour effectuer cette action.',
        Icons.lock_rounded,
      );
      return;
    }

    // ... reste du code de création de transfert inchangé
    final List<TransfertLigne> lignes = [];
    int? selectedDepotSource;
    int? selectedDepotDestination;
    String selectedMotif = 'Réapprovisionnement';
    bool isSubmitting = false;

    final TextEditingController motifCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width >= 700 ? 700 : double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 700,
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
                    // Header
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
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(K.radiusSm),
                            ),
                            child: const Icon(
                              Icons.swap_horiz_rounded,
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
                                  'Nouveau Transfert',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Transférer des produits entre dépôts',
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
                              onPressed: isSubmitting ? null : () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contenu
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDepotSelectorModal(
                              'Dépôt source',
                              'Veuillez sélectionner le dépôt source',
                              selectedDepotSource,
                              _depots,
                              (value) => setStateModal(() => selectedDepotSource = value),
                            ),
                            const SizedBox(height: 16),

                            _buildDepotSelectorModal(
                              'Dépôt destination',
                              'Veuillez sélectionner le dépôt de destination',
                              selectedDepotDestination,
                              _depots.where((d) => d.id != selectedDepotSource).toList(),
                              (value) => setStateModal(() => selectedDepotDestination = value),
                            ),
                            const SizedBox(height: 16),

                            _buildMotifSelector(
                              motifCtrl,
                              selectedMotif,
                              (value) => setStateModal(() {
                                selectedMotif = value;
                                motifCtrl.text = value;
                              }),
                            ),
                            const SizedBox(height: 16),

                            _buildLignesTransfert(
                              lignes,
                              selectedDepotSource,
                              _products,
                              _stocks,
                              setStateModal,
                            ),
                            const SizedBox(height: 16),

                            if (lignes.isNotEmpty)
                              _buildTransfertResume(lignes, _products),
                          ],
                        ),
                      ),
                    ),

                    // Footer
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
                              onPressed: isSubmitting ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: K.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(K.radiusSm),
                                ),
                              ),
                              child: const Text('Annuler', style: TextStyle(color: K.textMuted)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isSubmitting || lignes.isEmpty || selectedDepotSource == null || selectedDepotDestination == null
                                  ? null
                                  : () async {
                                      setStateModal(() => isSubmitting = true);
                                      try {
                                        final user = Provider.of<AuthProvider>(context, listen: false).user;
                                        if (user == null) return;

                                        final service = AdminService(user.token);
                                        final transfert = await service.createTransfert(
                                          depotSourceId: selectedDepotSource!,
                                          depotDestinationId: selectedDepotDestination!,
                                          motif: motifCtrl.text.isNotEmpty ? motifCtrl.text : selectedMotif,
                                          lignes: lignes,
                                        );

                                        _showSnackBar('Transfert #${transfert.numeroBon} créé avec succès', Colors.green);
                                        Navigator.pop(context);
                                        _refreshData();
                                      } catch (e) {
                                        _showSnackBar('Erreur: ${e.toString()}', Colors.red);
                                      } finally {
                                        setStateModal(() => isSubmitting = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: K.primary,
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
                                        const Text('Créer le transfert'),
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
    );
  }

  // ---------------------------------------------------------------------
  // WIDGETS MODALE
  // ---------------------------------------------------------------------
  Widget _buildDepotSelectorModal(
    String label,
    String hint,
    int? selectedValue,
    List<Depot> depots,
    Function(int?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Icon(
                label.contains('source') ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: K.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
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
              value: selectedValue,
              isExpanded: true,
              hint: Text(hint, style: const TextStyle(color: K.textMuted, fontSize: 13)),
              underline: Container(),
              dropdownColor: K.surface,
              items: depots.map((depot) {
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
                      Text(depot.nom, style: const TextStyle(color: K.textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: K.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(K.radiusXl),
                        ),
                        child: Text(
                          depot.estMagasin ? 'Magasin' : 'Entrepôt',
                          style: const TextStyle(fontSize: 9, color: K.info, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => onChanged(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotifSelector(
    TextEditingController controller,
    String selectedValue,
    Function(String) onChanged,
  ) {
    final motifs = ['Réapprovisionnement', 'Régularisation', 'Vente', 'Retour fournisseur', 'Autre'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_rounded, color: K.primary, size: 16),
              SizedBox(width: 8),
              Text(
                'Motif du transfert',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: K.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: motifs.map((motif) {
              final isSelected = selectedValue == motif;
              return ChoiceChip(
                label: Text(motif, style: TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onChanged(motif);
                  }
                },
                selectedColor: K.primary.withOpacity(0.2),
                backgroundColor: K.surface,
                labelStyle: TextStyle(
                  color: isSelected ? K.primary : K.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(K.radiusXl),
                  side: BorderSide(color: isSelected ? K.primary : K.border),
                ),
              );
            }).toList(),
          ),
          if (selectedValue == 'Autre') ...[
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Précisez le motif...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(K.radiusSm),
                  borderSide: BorderSide(color: K.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => onChanged(value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLignesTransfert(
    List<TransfertLigne> lignes,
    int? selectedDepotSource,
    List<Product> products,
    List<Stock> stocks,
    StateSetter setStateModal,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              const Icon(Icons.add_rounded, color: K.primary, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Produits à transférer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: K.textPrimary,
                ),
              ),
              const Spacer(),
              if (selectedDepotSource != null)
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddProductToTransferDialog(
                      lignes,
                      selectedDepotSource,
                      products,
                      stocks,
                      setStateModal,
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Ajouter un produit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: K.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(K.radiusSm),
                    ),
                    elevation: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (lignes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Aucun produit ajouté',
                  style: TextStyle(color: K.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lignes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ligne = lignes[index];
                final product = products.firstWhere((p) => p.id == ligne.produitId);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
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
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    product.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: K.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${product.code} • Qté: ${ligne.quantite} ${product.unite}',
                    style: const TextStyle(color: K.textMuted, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded, color: K.danger),
                    onPressed: () {
                      setStateModal(() {
                        lignes.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddProductToTransferDialog(
    List<TransfertLigne> lignes,
    int depotSourceId,
    List<Product> products,
    List<Stock> stocks,
    StateSetter setStateModal,
  ) {
    int? selectedProductId;
    int quantity = 1;
    final TextEditingController quantityCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final availableProducts = products.where((p) {
            final stock = stocks.firstWhere(
              (s) => s.produitId == p.id && s.depotId == depotSourceId,
              orElse: () => Stock(
                id: 0,
                produitId: p.id,
                depotId: depotSourceId,
                quantite: 0,
                quantiteMinimale: 0,
                quantiteMaximale: 0,
                enAlerte: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            return stock.quantite > 0;
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.radiusXl)),
            title: const Text('Ajouter un produit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: selectedProductId,
                  isExpanded: true,
                  hint: const Text('Sélectionner un produit'),
                  items: availableProducts.map((p) {
                    final stock = stocks.firstWhere(
                      (s) => s.produitId == p.id && s.depotId == depotSourceId,
                    );
                    return DropdownMenuItem(
                      value: p.id,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${p.nom} (Stock: ${stock.quantite} ${p.unite})',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setStateDialog(() => selectedProductId = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantité',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0) {
                            quantity = parsed;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: selectedProductId == null
                    ? null
                    : () {
                        setStateModal(() {
                          lignes.add(TransfertLigne(
                            produitId: selectedProductId!,
                            quantite: quantity,
                          ));
                        });
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: K.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransfertResume(List<TransfertLigne> lignes, List<Product> products) {
    final totalItems = lignes.fold(0, (sum, l) => sum + l.quantite);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: K.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.success.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Résumé :',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: K.success,
            ),
          ),
          Text(
            '${lignes.length} produit(s) • $totalItems unités',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: K.success,
            ),
          ),
        ],
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
                      'Chargement des transferts...',
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
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _filteredTransferts.isEmpty
                          ? _buildEmptyState()
                          : isWide
                              ? _buildDesktopList()
                              : _buildMobileList(),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: K.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(K.radiusSm),
          ),
          child: const Icon(Icons.swap_horiz_rounded, color: K.primary, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transferts entre dépôts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: K.textPrimary,
                ),
              ),
              Text(
                'Gérez les mouvements de stock entre dépôts',
                style: TextStyle(
                  color: K.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showCreateTransferDialog,
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('Nouveau Transfert'),
          style: ElevatedButton.styleFrom(
            backgroundColor: K.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(K.radiusSm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = ['Tous', 'en_attente', 'valide', 'effectue', 'annule'];
    final labels = ['Tous', 'En attente', 'Validés', 'Effectués', 'Annulés'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...List.generate(filters.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(labels[index], _selectedFilter == filters[index], filters[index]),
            );
          }),
          const SizedBox(width: 8),
          _buildDateRangePicker(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, String filterValue) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _filterTransferts(filterValue),
      backgroundColor: K.surfaceAlt,
      selectedColor: K.accentSoft,
      labelStyle: TextStyle(
        color: selected ? K.primary : K.textMuted,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(K.radiusSm),
        side: BorderSide(
          color: selected ? K.primary : K.border,
          width: selected ? 1.5 : 1,
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: K.border),
        borderRadius: BorderRadius.circular(K.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, color: K.textMuted, size: 16),
          const SizedBox(width: 8),
          const Text(
            'Sélectionner une période',
            style: TextStyle(color: K.textMuted, fontSize: 12),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_drop_down_rounded, color: K.textMuted),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LISTES
  // ---------------------------------------------------------------------
  Widget _buildDesktopList() {
    return ListView.separated(
      itemCount: _filteredTransferts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final transfert = _filteredTransferts[index];
        return _buildTransfertCard(transfert);
      },
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      itemCount: _filteredTransferts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final transfert = _filteredTransferts[index];
        return _buildTransfertCard(transfert);
      },
    );
  }

  // ---------------------------------------------------------------------
  // CARTE TRANSFERT
  // ---------------------------------------------------------------------
  Widget _buildTransfertCard(Transfert transfert) {
    final statusColor = _getStatusColor(transfert.statut);
    final statusLabel = _getStatusLabel(transfert.statut);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(K.radiusSm),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(K.radiusSm),
                  ),
                  child: Icon(
                    _getStatusIcon(transfert.statut),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfert.numeroBon,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: K.textPrimary,
                        ),
                      ),
                      Text(
                        '${transfert.depotSourceNom} → ${transfert.depotDestinationNom}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: K.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(K.radiusXl),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.calendar_today_rounded,
                  label: transfert.dateTransfert,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.description_rounded,
                  label: transfert.motif,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.inventory_2_rounded,
                  label: '${transfert.lignes.length} produits',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ✅ Afficher les boutons uniquement si admin
                if (_isAdmin) ...[
                  if (transfert.statut == 'en_attente') ...[
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : () => _validerTransfert(transfert),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: K.success,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Valider'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: K.success),
                        foregroundColor: K.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : () => _annulerTransfert(transfert),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: K.danger,
                              ),
                            )
                          : const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: K.danger),
                        foregroundColor: K.danger,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                  if (transfert.statut == 'valide') ...[
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : () => _effectuerTransfert(transfert),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: K.success,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Effectuer'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: K.success),
                        foregroundColor: K.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : () => _annulerTransfert(transfert),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: K.danger,
                              ),
                            )
                          : const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: K.danger),
                        foregroundColor: K.danger,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ],
                // ✅ Badge de statut
                if (transfert.statut == 'effectue') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: K.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(K.radiusXl),
                    ),
                    child: const Text(
                      '✅ Terminé',
                      style: TextStyle(
                        color: K.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                if (transfert.statut == 'annule') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: K.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(K.radiusXl),
                    ),
                    child: const Text(
                      '❌ Annulé',
                      style: TextStyle(
                        color: K.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: K.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: K.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // UTILITAIRES
  // ---------------------------------------------------------------------
  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return K.warning;
      case 'valide':
        return K.info;
      case 'effectue':
        return K.success;
      case 'annule':
        return K.danger;
      default:
        return K.textMuted;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'valide':
        return 'Validé';
      case 'effectue':
        return 'Effectué';
      case 'annule':
        return 'Annulé';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'en_attente':
        return Icons.hourglass_empty_rounded;
      case 'valide':
        return Icons.check_circle_rounded;
      case 'effectue':
        return Icons.check_circle_rounded;
      case 'annule':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            size: 64,
            color: K.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter != 'Tous' ? 'Aucun transfert avec ce statut' : 'Aucun transfert enregistré',
            style: const TextStyle(color: K.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter != 'Tous' ? 'Essayez un autre filtre' : 'Créez votre premier transfert',
            style: const TextStyle(color: K.textMuted, fontSize: 13),
          ),
          if (_selectedFilter != 'Tous') ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _filterTransferts('Tous'),
              child: const Text('Voir tous les transferts'),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// MODÈLES
// ---------------------------------------------------------------------
class Transfert {
  final int id;
  final String numeroBon;
  final int depotSourceId;
  final String depotSourceNom;
  final int depotDestinationId;
  final String depotDestinationNom;
  final String dateTransfert;
  final String motif;
  final String statut;
  final List<TransfertLigne> lignes;
  final String? dateValidation;
  final String? dateEffectue;
  final int? validePar;
  final int createdBy;

  Transfert({
    required this.id,
    required this.numeroBon,
    required this.depotSourceId,
    required this.depotSourceNom,
    required this.depotDestinationId,
    required this.depotDestinationNom,
    required this.dateTransfert,
    required this.motif,
    required this.statut,
    required this.lignes,
    this.dateValidation,
    this.dateEffectue,
    this.validePar,
    required this.createdBy,
  });

  factory Transfert.fromJson(Map<String, dynamic> json) {
    final lignes = (json['lignes'] as List? ?? [])
        .map((l) => TransfertLigne.fromJson(l))
        .toList();

    return Transfert(
      id: json['id'] as int,
      numeroBon: json['numero_bon'] as String,
      depotSourceId: json['depot_source_id'] as int,
      depotSourceNom: json['depot_source_nom'] as String,
      depotDestinationId: json['depot_destination_id'] as int,
      depotDestinationNom: json['depot_destination_nom'] as String,
      dateTransfert: json['date_transfert'] as String,
      motif: json['motif'] as String,
      statut: json['statut'] as String,
      lignes: lignes,
      dateValidation: json['date_validation'] as String?,
      dateEffectue: json['date_effectue'] as String?,
      validePar: json['valide_par'] as int?,
      createdBy: json['created_by'] as int,
    );
  }
}

class TransfertLigne {
  final int produitId;
  final int quantite;
  final String? produitNom;
  final String? produitCode;

  TransfertLigne({
    required this.produitId,
    required this.quantite,
    this.produitNom,
    this.produitCode,
  });

  factory TransfertLigne.fromJson(Map<String, dynamic> json) {
    return TransfertLigne(
      produitId: json['produit_id'] as int,
      quantite: json['quantite'] as int,
      produitNom: json['produit_nom'] as String?,
      produitCode: json['produit_code'] as String?,
    );
  }
}

// ---------------------------------------------------------------------
// TOKENS DE DESIGN
// ---------------------------------------------------------------------
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