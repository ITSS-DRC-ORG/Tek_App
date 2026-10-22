import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/models/transfert_model.dart';
import 'package:tek_app/theme/app_theme.dart';
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

class _StockTransfersState extends State<StockTransfers>
    with SingleTickerProviderStateMixin {
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
    _animationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD DATA
  // ---------------------------------------------------------------------------
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);

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
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  // ---------------------------------------------------------------------------
  // VALIDATION TRANSFERT (Réservée aux admins)
  // ---------------------------------------------------------------------------
  Future<void> _validerTransfert(Transfert transfert) async {
    if (!_isAdmin) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        'Seuls les administrateurs peuvent valider les transferts inter-dépôts.\n\nVotre compte ne dispose pas des privilèges suffisants.',
        Icons.lock_outline_rounded,
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      'Valider le transfert',
      'Confirmez-vous la validation de l\'ordre de transfert n° ${transfert.numeroBon} ?',
      'Valider l\'ordre',
      const Color(0xFF0067C0),
    );
    if (!confirm) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      final service = AdminService(user.token);
      await service.validerTransfert(transfert.id);
      _showSnackBar('Transfert #${transfert.numeroBon} validé avec succès', const Color(0xFF107C41));
      _refreshData();
    } on PermissionException catch (e) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        '${e.message}\n\nSeuls les administrateurs peuvent valider les transferts.',
        Icons.lock_outline_rounded,
      );
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _effectuerTransfert(Transfert transfert) async {
    if (!_isAdmin) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        'Seuls les administrateurs peuvent exécuter les transferts.\n\nVotre compte ne dispose pas des privilèges suffisants.',
        Icons.lock_outline_rounded,
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      'Effectuer le transfert',
      'Confirmez-vous l\'exécution du transfert n° ${transfert.numeroBon} ?\nLes articles seront immédiatement débités du dépôt source et crédités au dépôt cible.',
      'Exécuter le mouvement',
      const Color(0xFF107C41),
    );
    if (!confirm) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      final service = AdminService(user.token);
      await service.effectuerTransfert(transfert.id);
      _showSnackBar('Transfert #${transfert.numeroBon} exécuté avec succès', const Color(0xFF107C41));
      _refreshData();
    } on PermissionException catch (e) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        '${e.message}\n\nSeuls les administrateurs peuvent effectuer les transferts.',
        Icons.lock_outline_rounded,
      );
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _annulerTransfert(Transfert transfert) async {
    if (!_isAdmin) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        'Seuls les administrateurs peuvent annuler les transferts.',
        Icons.lock_outline_rounded,
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      'Annuler le transfert',
      'Voulez-vous vraiment annuler le bon de transfert n° ${transfert.numeroBon} ?',
      'Annuler le bon',
      const Color(0xFFC42B1C),
    );
    if (!confirm) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      final service = AdminService(user.token);
      await service.annulerTransfert(transfert.id);
      _showSnackBar('Transfert #${transfert.numeroBon} annulé', const Color(0xFFD97706));
      _refreshData();
    } on PermissionException catch (e) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        '${e.message}\n\nSeuls les administrateurs peuvent annuler les transferts.',
        Icons.lock_outline_rounded,
      );
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // DIALOG PERMISSION WINDOWS 11
  // ---------------------------------------------------------------------------
  void _showPermissionErrorDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22),
        actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: const Color(0xFFB45309), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
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
                fontFamily: kAppFontFamily,
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contactez votre direction pour étendre vos permissions de compte.',
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Compris',
              style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTRES
  // ---------------------------------------------------------------------------
  void _filterTransferts(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Tous') {
        _filteredTransferts = _transferts;
      } else {
        _filteredTransferts =
            _transferts.where((t) => t.statut == filter).toList();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // SNACKBAR
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

  // ---------------------------------------------------------------------------
  // CONFIRM DIALOG WINDOWS 11
  // ---------------------------------------------------------------------------
  Future<bool> _showConfirmDialog(
      String title, String message, String action, Color color) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22),
        actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.swap_horiz_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            color: Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              action,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  // ---------------------------------------------------------------------------
  // CRÉER TRANSFERT (Modale Windows 11 Fluent)
  // ---------------------------------------------------------------------------
  void _showCreateTransferDialog() {
    if (!_isAdmin) {
      _showPermissionErrorDialog(
        'Action non autorisée',
        'Seuls les administrateurs peuvent initier des transferts de stock.\n\nVotre compte ne dispose pas des privilèges nécessaires.',
        Icons.lock_outline_rounded,
      );
      return;
    }

    final List<TransfertLigne> lignes = [];
    int? selectedDepotSource;
    int? selectedDepotDestination;
    String selectedMotif = 'Réapprovisionnement';
    bool isSubmitting = false;

    final TextEditingController motifCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 680,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
                maxWidth: 680,
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
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // En-tête Fluent sobre
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
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Color(0xFF0067C0),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nouveau Bon de Transfert',
                              style: TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Planifiez un mouvement d\'articles entre deux sites',
                              style: TextStyle(
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
                          onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, thickness: 1, color: Color(0x14000000)),

                  // Contenu Formulaire
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDepotSelectorModal(
                                  'DÉPÔT SOURCE (DÉBIT)',
                                  'Sélectionner la source',
                                  selectedDepotSource,
                                  _depots,
                                      (value) => setStateModal(() => selectedDepotSource = value),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildDepotSelectorModal(
                                  'DÉPÔT DESTINATION (CRÉDIT)',
                                  'Sélectionner la cible',
                                  selectedDepotDestination,
                                  _depots.where((d) => d.id != selectedDepotSource).toList(),
                                      (value) => setStateModal(() => selectedDepotDestination = value),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildMotifSelector(
                            motifCtrl,
                            selectedMotif,
                                (value) => setStateModal(() {
                              selectedMotif = value;
                              motifCtrl.text = value;
                            }),
                          ),
                          const SizedBox(height: 18),
                          _buildLignesTransfert(
                            lignes,
                            selectedDepotSource,
                            _products,
                            _stocks,
                            setStateModal,
                          ),
                          const SizedBox(height: 16),
                          if (lignes.isNotEmpty) _buildTransfertResume(lignes),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1, thickness: 1, color: Color(0x14000000)),

                  // Footer Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
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
                          onPressed: isSubmitting ||
                              lignes.isEmpty ||
                              selectedDepotSource == null ||
                              selectedDepotDestination == null
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

                              _showSnackBar(
                                'Transfert #${transfert.numeroBon} enregistré avec succès',
                                const Color(0xFF107C41),
                              );
                              Navigator.pop(dialogContext);
                              _refreshData();
                            } catch (e) {
                              _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
                            } finally {
                              setStateModal(() => isSubmitting = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0067C0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                              : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Créer le transfert',
                                style: TextStyle(
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
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS MODALE
  // ---------------------------------------------------------------------------
  Widget _buildDepotSelectorModal(
      String label,
      String hint,
      int? selectedValue,
      List<Depot> depots,
      Function(int?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButton<int>(
            value: selectedValue,
            isExpanded: true,
            hint: Text(hint, style: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFFA0AEC0), fontSize: 12.5)),
            underline: const SizedBox(),
            dropdownColor: const Color(0xFFFFFFFF),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
            items: depots.map((depot) {
              return DropdownMenuItem(
                value: depot.id,
                child: Row(
                  children: [
                    Icon(
                      depot.estMagasin ? Icons.storefront_outlined : Icons.warehouse_outlined,
                      color: const Color(0xFF0067C0),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      depot.nom,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildMotifSelector(
      TextEditingController controller,
      String selectedValue,
      Function(String) onChanged,
      ) {
    final motifs = [
      'Réapprovisionnement',
      'Régularisation',
      'Vente',
      'Retour fournisseur',
      'Autre'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOTIF DU MOUVEMENT',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: motifs.map((motif) {
            final isSelected = selectedValue == motif;
            return ChoiceChip(
              label: Text(motif),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onChanged(motif);
              },
              selectedColor: const Color(0xFFE8F2FB),
              backgroundColor: const Color(0xFFF8FAFC),
              labelStyle: TextStyle(
                fontFamily: kAppFontFamily,
                color: isSelected ? const Color(0xFF0067C0) : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: isSelected ? const Color(0xFF0067C0) : const Color(0xFFE2E8F0)),
              ),
            );
          }).toList(),
        ),
        if (selectedValue == 'Autre') ...[
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Précisez le motif du transfert...',
              hintStyle: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFFA0AEC0), fontSize: 12.5),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5)),
            ),
            onChanged: (value) => onChanged(value),
          ),
        ],
      ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ARTICLES À TRANSFÉRER',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              if (selectedDepotSource != null)
                OutlinedButton.icon(
                  onPressed: () {
                    _showAddProductToTransferDialog(
                      lignes,
                      selectedDepotSource,
                      products,
                      stocks,
                      setStateModal,
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('Ajouter un article'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0067C0),
                    side: const BorderSide(color: Color(0xFF0067C0)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    textStyle: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (lignes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Aucun article ajouté au transfert',
                  style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF94A3B8), fontSize: 12.5),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lignes.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
              itemBuilder: (context, index) {
                final ligne = lignes[index];
                final product = products.where((p) => p.id == ligne.produitId).firstOrNull;
                final productName = product?.nom ?? 'Article inconnu';
                final productCode = product?.code ?? 'N/A';
                final productUnite = product?.unite ?? 'unité';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          productCode,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          productName,
                          style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Text(
                        'Qté: ${ligne.quantite} $productUnite',
                        style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0067C0)),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        splashRadius: 14,
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC42B1C), size: 18),
                        onPressed: () {
                          setStateModal(() {
                            lignes.removeAt(index);
                          });
                        },
                      ),
                    ],
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
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final availableProducts = products.where((p) {
            final stock = stocks.where((s) => s.produitId == p.id && s.depotId == depotSourceId).firstOrNull;
            return stock != null && stock.quantite > 0;
          }).toList();

          return AlertDialog(
            backgroundColor: const Color(0xFFFFFFFF),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text(
              'Ajouter un article au bon',
              style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<int>(
                  value: selectedProductId,
                  isExpanded: true,
                  hint: const Text('Sélectionner un article disponible', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 13)),
                  dropdownColor: const Color(0xFFFFFFFF),
                  items: availableProducts.map((p) {
                    final stock = stocks.firstWhere((s) => s.produitId == p.id && s.depotId == depotSourceId);
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '${p.nom} (Dispo : ${stock.quantite} ${p.unite})',
                        style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setStateDialog(() => selectedProductId = value),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: quantityCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Quantité à transférer',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      quantity = parsed;
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler', style: TextStyle(fontFamily: kAppFontFamily)),
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
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0067C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Ajouter', style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransfertResume(List<TransfertLigne> lignes) {
    final totalItems = lignes.fold(0, (sum, l) => sum + l.quantite);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'RÉCAPITULATIF :',
            style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF0067C0)),
          ),
          Text(
            '${lignes.length} référence(s) • $totalItems unités au total',
            style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0067C0)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD PRINCIPAL
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Material(
      color: Colors.transparent,
      child: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0067C0),
          strokeWidth: 2.2,
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Indicateurs Synthétiques avec Ondes Fluides
            _buildTransferMetricsRow(),
            const SizedBox(height: 18),

            // 2. Barre d'outils et Filtres
            _buildActionBar(isWide),
            const SizedBox(height: 14),

            // 3. Tableau de données principal
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
                child: _filteredTransferts.isEmpty
                    ? _buildEmptyState()
                    : isWide
                    ? _buildDesktopDataTable()
                    : _buildMobileList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildTransferMetricsRow() {
    final total = _transferts.length;
    final enAttente = _transferts.where((t) => t.statut == 'en_attente').length;
    final effectues = _transferts.where((t) => t.statut == 'effectue').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 740;

        final cards = [
          _buildWaveMetricCard(
            title: "TOTAL TRANSFERTS",
            value: "$total",
            subtitle: "Bons enregistrés",
            badge: "Mouvements",
            icon: Icons.swap_horiz_rounded,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "EN ATTENTE",
            value: "$enAttente",
            subtitle: "Ordres à valider",
            badge: "Validation",
            icon: Icons.hourglass_empty_rounded,
            gradient: const [
              Color(0xFF0A3B5C),
              Color(0xFF165B8C),
              Color(0xFF3A89C9),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "SOLDÉS & EFFECTUÉS",
            value: "$effectues",
            subtitle: "Transferts clôturés",
            badge: "Clôturés",
            icon: Icons.check_circle_outline_rounded,
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
                    painter: TransferMetricWavePainter(waveSeed: waveSeed),
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
  // 2. BARRE D'ACTIONS & FILTRES
  // ---------------------------------------------------------------------------
  Widget _buildActionBar(bool isWide) {
    final filters = ['Tous', 'en_attente', 'valide', 'effectue', 'annule'];
    final labels = ['Tous', 'En attente', 'Validés', 'Effectués', 'Annulés'];

    return Row(
      children: [
        // Pastilles de filtre
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(filters.length, (index) {
                final isSelected = _selectedFilter == filters[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(labels[index]),
                    selected: isSelected,
                    onSelected: (_) => _filterTransferts(filters[index]),
                    selectedColor: const Color(0xFFE8F2FB),
                    backgroundColor: const Color(0xFFFFFFFF),
                    labelStyle: TextStyle(
                      fontFamily: kAppFontFamily,
                      color: isSelected ? const Color(0xFF0067C0) : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? const Color(0xFF0067C0) : const Color(0x18000000)),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Bouton Nouveau Transfert
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: _showCreateTransferDialog,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: Text(isWide ? "Nouveau Transfert" : "Créer"),
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
  Widget _buildDesktopDataTable() {
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
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                horizontalMargin: 20,
                columnSpacing: 24,
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text("N° BON", style: _headerStyle)),
                  DataColumn(label: Text("MOUVEMENT DÉPÔTS", style: _headerStyle)),
                  DataColumn(label: Text("DATE", style: _headerStyle)),
                  DataColumn(label: Text("MOTIF", style: _headerStyle)),
                  DataColumn(label: Text("VOLUME", style: _headerStyle)),
                  DataColumn(label: Text("STATUT", style: _headerStyle)),
                  DataColumn(label: Text("ACTIONS", style: _headerStyle)),
                ],
                rows: _filteredTransferts.map((transfert) {
                  return DataRow(
                    cells: [
                      // N° Bon
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0x10000000)),
                          ),
                          child: Text(
                            transfert.numeroBon,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      // Trajet
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              transfert.depotSourceNom,
                              style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0067C0)),
                            ),
                            Text(
                              transfert.depotDestinationNom,
                              style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),

                      // Date
                      DataCell(
                        Text(
                          transfert.dateTransfert,
                          style: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B), fontSize: 12.5),
                        ),
                      ),

                      // Motif
                      DataCell(
                        Text(
                          transfert.motif,
                          style: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF1E293B), fontSize: 13),
                        ),
                      ),

                      // Volume
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${transfert.lignes.length} article(s)',
                            style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF475569)),
                          ),
                        ),
                      ),

                      // Statut
                      DataCell(_buildStatusBadge(transfert.statut)),

                      // Actions
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _buildTableActions(transfert),
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

  List<Widget> _buildTableActions(Transfert transfert) {
    final actions = <Widget>[];

    if (_isAdmin) {
      if (transfert.statut == 'en_attente') {
        actions.add(
          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _validerTransfert(transfert),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
            child: const Text('Valider'),
          ),
        );
        actions.add(const SizedBox(width: 6));
        actions.add(
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => _annulerTransfert(transfert),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC42B1C),
              side: const BorderSide(color: Color(0xFFC42B1C)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
            child: const Text('Annuler'),
          ),
        );
      } else if (transfert.statut == 'valide') {
        actions.add(
          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _effectuerTransfert(transfert),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF107C41),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
            child: const Text('Effectuer'),
          ),
        );
        actions.add(const SizedBox(width: 6));
        actions.add(
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => _annulerTransfert(transfert),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC42B1C),
              side: const BorderSide(color: Color(0xFFC42B1C)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
            child: const Text('Annuler'),
          ),
        );
      }
    }

    if (transfert.statut == 'effectue') {
      actions.add(
        const Text(
          'Terminé',
          style: TextStyle(fontFamily: kAppFontFamily, fontSize: 12, color: Color(0xFF107C41), fontWeight: FontWeight.w600),
        ),
      );
    }

    if (transfert.statut == 'annule') {
      actions.add(
        const Text(
          'Annulé',
          style: TextStyle(fontFamily: kAppFontFamily, fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        ),
      );
    }

    return actions;
  }

  // ---------------------------------------------------------------------------
  // 4. LISTE MOBILE
  // ---------------------------------------------------------------------------
  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredTransferts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final transfert = _filteredTransferts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transfert.numeroBon,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0067C0)),
                  ),
                  _buildStatusBadge(transfert.statut),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${transfert.depotSourceNom} → ${transfert.depotDestinationNom}',
                style: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
              ),
              Text(
                '${transfert.dateTransfert} • ${transfert.motif} • ${transfert.lignes.length} article(s)',
                style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildTableActions(transfert),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BADGE STATUT
  // ---------------------------------------------------------------------------
  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    String label;

    switch (status) {
      case 'en_attente':
        color = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        label = 'En attente';
        break;
      case 'valide':
        color = const Color(0xFF0067C0);
        bgColor = const Color(0xFFE8F2FB);
        label = 'Validé';
        break;
      case 'effectue':
        color = const Color(0xFF107C41);
        bgColor = const Color(0xFFE6F4EA);
        label = 'Effectué';
        break;
      case 'annule':
        color = const Color(0xFFC42B1C);
        bgColor = const Color(0xFFFDE8E8);
        label = 'Annulé';
        break;
      default:
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: kAppFontFamily,
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
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
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_horiz_rounded, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              _selectedFilter != 'Tous'
                  ? 'Aucun transfert avec ce statut'
                  : 'Aucun transfert enregistré',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedFilter != 'Tous'
                  ? 'Essayez de sélectionner un autre filtre.'
                  : 'Cliquez sur "Nouveau Transfert" pour initier un mouvement.',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
            if (_selectedFilter != 'Tous') ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => _filterTransferts('Tous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0067C0),
                  side: const BorderSide(color: Color(0xFF0067C0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'Voir tous les transferts',
                  style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 12),
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
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES TRANSFERTS
// ---------------------------------------------------------------------------
class TransferMetricWavePainter extends CustomPainter {
  final double waveSeed;

  TransferMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant TransferMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}