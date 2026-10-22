import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/api/admin_service.dart';
import 'package:tek_app/providers/auth_provider.dart';
import 'package:tek_app/screens/cashier/cashier_sales.dart';
import 'package:tek_app/theme/app_theme.dart';

class InvoiceValidationView extends StatefulWidget {
  const InvoiceValidationView({super.key});

  @override
  State<InvoiceValidationView> createState() => _InvoiceValidationViewState();
}

class _InvoiceValidationViewState extends State<InvoiceValidationView> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  List<Map<String, dynamic>> _pendingInvoices = [];

  @override
  void initState() {
    super.initState();
    _loadPendingInvoices();
  }

  Future<void> _loadPendingInvoices() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final sales = await service.getSales(statut: 'en_cours');
        setState(() {
          _pendingInvoices =
              sales.map((s) => s as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    }
  }

  double get _cumulativeTotal {
    return _pendingInvoices.fold<double>(0.0, (sum, inv) {
      final t = double.tryParse(inv['total_ttc']?.toString() ?? '0') ?? 0;
      return sum + t;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Indicateurs Synthétiques avec Ondes Fluides
          _buildCashierMetricsRow(),
          const SizedBox(height: 18),

          // 2. Barre de titre et action
          _buildActionBar(isWide),
          const SizedBox(height: 14),

          // 3. Tableau de données principal
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0067C0),
                strokeWidth: 2.2,
              ),
            )
                : Container(
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
              child: _pendingInvoices.isEmpty
                  ? _buildEmptyState()
                  : isWide
                  ? _buildDesktopDataTable()
                  : _buildMobileDataRows(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildCashierMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 740;

        final cards = [
          _buildWaveMetricCard(
            title: "FACTURES EN ATTENTE",
            value: "${_pendingInvoices.length}",
            subtitle: "Règlements à percevoir",
            badge: "À Traiter",
            icon: Icons.receipt_long_outlined,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "TOTAL À ENCAISSER",
            value: "${_cumulativeTotal.toStringAsFixed(0)} \$",
            subtitle: "Montant cumulé TTC",
            badge: "Encaissement",
            icon: Icons.payments_outlined,
            gradient: const [
              Color(0xFF0A3B5C),
              Color(0xFF165B8C),
              Color(0xFF3A89C9),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "MODE AUTORISÉ",
            value: "Espèces",
            subtitle: "Devise : CASH (USD)",
            badge: "Guichet",
            icon: Icons.point_of_sale_outlined,
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
          // Bannière supérieure avec ondulations vectorielles
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
                    painter: InvoiceMetricWavePainter(waveSeed: waveSeed),
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

          // Pied de carte blanc avec Métrique & Libellés
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validation des Encaissements',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Confirmez la réception des règlements au comptoir pour valider la vente',
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

        SizedBox(
          height: 38,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _loadPendingInvoices,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0x20000000)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TABLEAU DE DONNÉES DESKTOP
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
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
                horizontalMargin: 20,
                columnSpacing: 26,
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text("N° FACTURE", style: _headerStyle)),
                  DataColumn(label: Text("DATE ÉMISSION", style: _headerStyle)),
                  DataColumn(label: Text("CLIENT", style: _headerStyle)),
                  DataColumn(label: Text("MONTANT TTC", style: _headerStyle)),
                  DataColumn(label: Text("STATUT", style: _headerStyle)),
                  DataColumn(label: Text("ACTIONS", style: _headerStyle)),
                ],
                rows: _pendingInvoices.map((invoice) {
                  final total = double.tryParse(invoice['total_ttc']?.toString() ?? '0') ?? 0;
                  final client = invoice['client_nom'] as String? ?? 'Client de passage';
                  final numero = invoice['numero_facture'] as String? ?? '—';
                  final date = invoice['created_at'] as String? ?? '';
                  final formattedDate = _formatDate(date);

                  return DataRow(
                    cells: [
                      // N° Facture
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0x10000000)),
                          ),
                          child: Text(
                            numero,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      // Date
                      DataCell(
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ),

                      // Client
                      DataCell(
                        Text(
                          client,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Montant TTC
                      DataCell(
                        Text(
                          '${total.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0067C0),
                            fontSize: 13.5,
                          ),
                        ),
                      ),

                      // Statut
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFB45309)),
                              SizedBox(width: 4),
                              Text(
                                'EN COURS',
                                style: TextStyle(
                                  fontFamily: kAppFontFamily,
                                  color: Color(0xFFB45309),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Actions
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Bouton Voir
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CashierSales(initialFilter: 'en_cours'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined, size: 14),
                              label: const Text('Voir'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(color: Color(0x20000000)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                textStyle: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Bouton Encaisser
                            ElevatedButton.icon(
                              onPressed: _isActionLoading
                                  ? null
                                  : () async => await _validateInvoiceWithModePicker(invoice),
                              icon: _isActionLoading
                                  ? const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : const Icon(Icons.check_rounded, size: 15),
                              label: Text(_isActionLoading ? '...' : 'Encaisser'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0067C0),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                textStyle: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
  // 4. LIGNES MOBILE
  // ---------------------------------------------------------------------------
  Widget _buildMobileDataRows() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingInvoices.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final invoice = _pendingInvoices[index];
        final total = double.tryParse(invoice['total_ttc']?.toString() ?? '0') ?? 0;
        final client = invoice['client_nom'] as String? ?? 'Client';
        final numero = invoice['numero_facture'] as String? ?? '';
        final date = invoice['created_at'] as String? ?? '';
        final formattedDate = _formatDate(date);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    numero,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF0067C0),
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(2)} \$',
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0067C0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                client,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CashierSales(initialFilter: 'en_cours'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0x20000000)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Détails'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isActionLoading
                        ? null
                        : () async => await _validateInvoiceWithModePicker(invoice),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0067C0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Encaisser'),
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
  // DIALOGUE D'ENCAISSEMENT (Design Windows 11)
  // ---------------------------------------------------------------------------
  Future<void> _validateInvoiceWithModePicker(Map<String, dynamic> invoice) async {
    final total = double.tryParse(invoice['total_ttc']?.toString() ?? '0') ?? 0;
    final client = invoice['client_nom'] as String? ?? 'Client';
    final numero = invoice['numero_facture'] as String? ?? '';

    final confirmed = await showDialog<bool>(
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
                color: const Color(0xFFE8F2FB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.payments_outlined, color: Color(0xFF0067C0), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Encaisser en espèces',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmez la réception du règlement au comptoir pour finaliser la facture $numero.',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF5F6368),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogInfoRow('Client', client),
                  const SizedBox(height: 6),
                  _buildDialogInfoRow('Montant net', '${total.toStringAsFixed(2)} \$'),
                  const SizedBox(height: 6),
                  _buildDialogInfoRow('Mode de règlement', 'CASH (USD)'),
                ],
              ),
            ),
          ],
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
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Valider le paiement',
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

    if (confirmed == true) {
      await _validateInvoiceWithMode(invoice);
    }
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label : ',
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            fontSize: 12.5,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _validateInvoiceWithMode(Map<String, dynamic> invoice) async {
    setState(() => _isActionLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        _showSnackBar('Utilisateur non connecté', const Color(0xFFC42B1C));
        return;
      }

      final service = AdminService(user.token);
      final result = await service.validateInvoiceWithMode(
        invoice['id'] as int,
        modePaiement: 'cash',
      );

      if (result['success'] == true) {
        _showSnackBar('Facture encaissée avec succès', const Color(0xFF107C41));
        _loadPendingInvoices();
      } else {
        _showSnackBar(result['message'] ?? 'Erreur de validation', const Color(0xFFC42B1C));
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return date.isNotEmpty && date.length >= 10 ? date.substring(0, 10) : date;
    }
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
              child: const Icon(Icons.check_circle_outline_rounded, size: 32, color: Color(0xFF107C41)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Toutes les factures sont encaissées !',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Aucun règlement en attente de validation pour le moment.',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadPendingInvoices,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Actualiser le statut'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0067C0),
                side: const BorderSide(color: Color(0xFF0067C0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES DE VALIDATION FACTURES
// ---------------------------------------------------------------------------
class InvoiceMetricWavePainter extends CustomPainter {
  final double waveSeed;

  InvoiceMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant InvoiceMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}