import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import 'package:tek_app/screens/cashier/cashier_new_sale.dart';
import 'package:tek_app/screens/cashier/print/receipt_printer.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

class CashierSales extends StatefulWidget {
  final String? initialFilter;
  const CashierSales({super.key, this.initialFilter});

  @override
  State<CashierSales> createState() => _CashierSalesState();
}

class _CashierSalesState extends State<CashierSales> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _filteredSales = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _selectedFilter = widget.initialFilter!;
    }
    _loadSales();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final sales = await service.getSales();
        
        final sortedSales = sales.map((s) => s as Map<String, dynamic>).toList();
        sortedSales.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] as String? ?? '');
          final dateB = DateTime.tryParse(b['created_at'] as String? ?? '');
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        setState(() {
          _sales = sortedSales;
          _filteredSales = sortedSales;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
    }
  }

  void _filterSales() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredSales = _sales.where((sale) {
        final client = (sale['client_nom'] as String? ?? '').toLowerCase();
        final numero = (sale['numero_facture'] as String? ?? '').toLowerCase();
        final matchesSearch = client.contains(query) || numero.contains(query);
        
        final statut = sale['statut'] as String? ?? 'en_cours';
        final matchesFilter = _selectedFilter == 'Toutes' || statut == _selectedFilter;
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

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
  // VALIDATION DE LA FACTURE
  // ---------------------------------------------------------------------
  Future<void> _validateInvoice(Map<String, dynamic> sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
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
              'Valider la facture',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous valider la facture ${sale['numero_facture'] ?? ''} ?',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: K.surfaceAlt,
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Client', sale['client_nom'] ?? ''),
                  _buildInfoRow('Montant', '\$${double.tryParse(sale['total_ttc']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'}'),
                  _buildInfoRow('Date', sale['created_at']?.toString().substring(0, 10) ?? ''),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: K.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: K.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        _showSnackBar('Utilisateur non connecté', Colors.red);
        return;
      }

      final service = AdminService(user.token);
      final result = await service.validateInvoice(sale['id'] as int);

      if (result['success'] == true) {
        _showSnackBar('✅ Facture validée avec succès', Colors.green);
        _loadSales();
      } else {
        _showSnackBar('❌ Erreur: ${result['message'] ?? 'Impossible de valider'}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: K.textMuted,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: K.textPrimary,
                fontSize: 12,
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
  // RÉIMPRESSION DU REÇU
  // ---------------------------------------------------------------------
  Future<void> _reprintReceipt(Map<String, dynamic> sale) async {
    try {
      final numeroFacture = sale['numero_facture'] as String? ?? '';
      final clientName = sale['client_nom'] as String? ?? 'Client';
      final depotName = sale['depot_source_nom'] as String? ?? 'Dépôt';
      final lignes = sale['lignes'] as List? ?? [];
      
      double subtotal = 0;
      final printLines = lignes.map((line) {
        final qte = line['quantite'] as int? ?? 0;
        final prix = line['prix_unitaire'] as double? ?? 0;
        final total = qte * prix;
        subtotal += total;
        
        return {
          'produit_nom': line['produit_nom'] ?? 'Produit',
          'quantite': qte,
          'prix_unitaire': prix,
        };
      }).toList();
      
      final remise = double.tryParse(sale['remise']?.toString() ?? '0') ?? 0;
      final total = double.tryParse(sale['total_ttc']?.toString() ?? '0') ?? 0;

      _showReprintDialog(
        saleData: {
          'numero_facture': numeroFacture,
          'mode_livraison': sale['mode_livraison'] ?? 'retrait_magasin',
        },
        lignes: printLines,
        clientName: clientName,
        depotName: depotName,
        subtotal: subtotal,
        remise: remise,
        total: total,
        numeroFacture: numeroFacture,
      );
      
    } catch (e) {
      _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
    }
  }

  void _showReprintDialog({
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
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: K.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.print_rounded, color: K.info),
            ),
            const SizedBox(width: 12),
            const Text(
              'Réimpression du reçu',
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
              'Voulez-vous réimprimer ce reçu ?',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: K.textMuted)),
          ),
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
                _showSnackBar('✅ Reçu réimprimé avec succès', Colors.green);
              } catch (e) {
                _showSnackBar('❌ Erreur d\'impression: ${e.toString()}', Colors.red);
              }
            },
            icon: const Icon(Icons.print_rounded),
            label: const Text('Réimprimer'),
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
                  '\$${(qte * prix).toStringAsFixed(0)}',
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
              '\$${total.toStringAsFixed(0)}',
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
                '-\$${remise.toStringAsFixed(0)}',
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
  // CARTE DE VENTE
  // ---------------------------------------------------------------------
  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final status = sale['statut'] as String? ?? 'en_cours';
    final total = double.tryParse(sale['total_ttc']?.toString() ?? '0') ?? 0;
    final client = sale['client_nom'] as String? ?? 'Client';
    final numero = sale['numero_facture'] as String? ?? '';
    final date = sale['created_at'] as String? ?? '';
    final isAdmin = Provider.of<AuthProvider>(context).user?.role == UserRole.admin;
    final canValidate = status == 'en_cours' && isAdmin;

    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'payee':
        statusColor = K.success;
        statusLabel = 'Payée';
        break;
      case 'livree':
        statusColor = K.info;
        statusLabel = 'Livrée';
        break;
      case 'annulee':
        statusColor = K.danger;
        statusLabel = 'Annulée';
        break;
      default:
        statusColor = K.warning;
        statusLabel = 'En cours';
    }

    String formattedDate = '';
    try {
      final dateTime = DateTime.parse(date);
      formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      formattedDate = date;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(
          color: canValidate ? K.success.withOpacity(0.3) : K.border,
          width: canValidate ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(K.radiusSm),
            ),
            child: Icon(
              status == 'payee'
                  ? Icons.check_circle_rounded
                  : status == 'livree'
                      ? Icons.local_shipping_rounded
                      : Icons.pending_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: K.textPrimary,
                  ),
                ),
                Text(
                  numero,
                  style: const TextStyle(
                    fontSize: 12,
                    color: K.textMuted,
                  ),
                ),
                if (formattedDate.isNotEmpty)
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 10,
                      color: K.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: K.success,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canValidate)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: Tooltip(
                        message: 'Valider la facture',
                        child: IconButton(
                          icon: _isActionLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: K.success,
                                  ),
                                )
                              : const Icon(Icons.check_circle_rounded, color: K.success, size: 18),
                          onPressed: _isActionLoading ? null : () => _validateInvoice(sale),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.print_rounded, size: 16),
                    onPressed: () => _reprintReceipt(sale),
                    tooltip: 'Réimprimer le reçu',
                    color: K.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(K.radiusXl),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
          _filterSales();
        });
      },
      backgroundColor: K.surfaceAlt,
      selectedColor: K.accentSoft,
      labelStyle: TextStyle(
        color: isSelected ? K.primary : K.textMuted,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(K.radiusSm),
        side: BorderSide(
          color: isSelected ? K.primary : K.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Ventes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: K.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => _filterSales(),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par client ou facture...',
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
                                  _filterSales();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (isWide) ...[
                  _buildFilterChip('Toutes', 'Toutes'),
                  const SizedBox(width: 8),
                  _buildFilterChip('En cours', 'en_cours'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Payée', 'payee'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Livrée', 'livree'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Annulée', 'annulee'),
                ],
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CashierNewSale(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nouvelle Vente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: K.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(K.radiusSm),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isWide)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Toutes', 'Toutes'),
                    const SizedBox(width: 8),
                    _buildFilterChip('En cours', 'en_cours'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Payée', 'payee'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Livrée', 'livree'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Annulée', 'annulee'),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: K.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(K.radiusXl),
              ),
              child: Text(
                '${_filteredSales.length} vente${_filteredSales.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: K.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: K.primary))
                  : _filteredSales.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: _filteredSales.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final sale = _filteredSales[index];
                            return _buildSaleCard(sale);
                          },
                        ),
            ),
          ],
        ),
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
            _searchCtrl.text.isEmpty ? Icons.shopping_cart_rounded : Icons.search_off_rounded,
            size: 64,
            color: K.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isEmpty
                ? 'Aucune vente enregistrée'
                : 'Aucun résultat trouvé',
            style: const TextStyle(color: K.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _searchCtrl.text.isEmpty
                ? 'Créez votre première vente'
                : 'Essayez un autre terme de recherche',
            style: const TextStyle(color: K.textMuted, fontSize: 13),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                _filterSales();
              },
              child: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }
}