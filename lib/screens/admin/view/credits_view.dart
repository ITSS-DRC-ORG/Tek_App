import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../api/admin_service.dart';

class CreditsView extends StatefulWidget {
  const CreditsView({super.key});

  @override
  State<CreditsView> createState() => _CreditsViewState();
}

class _CreditsViewState extends State<CreditsView> {
  bool _isLoading = true;
  List<dynamic> _credits = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  double _parseNum(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;
      final data = await AdminService(user.token).getCredits();
      setState(() {
        _credits = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Erreur lors du chargement : $e', const Color(0xFFC42B1C));
    }
  }

  List<dynamic> get _filteredCredits {
    final query = _searchCtrl.text.toLowerCase().trim();
    if (query.isEmpty) return _credits;
    return _credits.where((c) {
      final client = (c['client_nom'] ?? '').toString().toLowerCase();
      final facture = (c['numero_facture'] ?? '').toString().toLowerCase();
      return client.contains(query) || facture.contains(query);
    }).toList();
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              c == const Color(0xFF107C41)
                  ? Icons.check_circle_rounded
                  : c == const Color(0xFFD97706)
                  ? Icons.info_outline_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOGUE D'ENCAISSEMENT DU CRÉDIT (WINDOWS 11 FLUENT 2)
  // ---------------------------------------------------------------------------
  Future<void> _encaisser(dynamic credit) async {
    final formKey = GlobalKey<FormState>();
    final resteDu = _parseNum(credit['montant_restant']);
    final totalTtc = _parseNum(credit['total_ttc']);
    final montantPaye = _parseNum(credit['montant_paye']);
    final clientNom = (credit['client_nom'] ?? 'Client non spécifié').toString();
    final numeroFacture = (credit['numero_facture'] ?? '—').toString();

    final montantCtrl = TextEditingController(
      text: resteDu.toStringAsFixed(2),
    );
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 20, 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF0067C0),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Encaisser un règlement de crédit',
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Facture N° $numeroFacture • $clientNom',
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  splashRadius: 16,
                  icon: const Icon(Icons.close_rounded, size: 19),
                  color: const Color(0xFF64748B),
                  onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, thickness: 1, color: Color(0x14000000)),
                    const SizedBox(height: 16),

                    // Synthèse de la créance
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Montant total facture :', '${totalTtc.toStringAsFixed(2)} \$'),
                          const SizedBox(height: 4),
                          _buildDetailRow('Déjà réglé par le client :', '${montantPaye.toStringAsFixed(2)} \$', color: const Color(0xFF107C41)),
                          const Divider(height: 12, thickness: 1, color: Color(0x12000000)),
                          _buildDetailRow(
                            'Reste à recouvrer :',
                            '${resteDu.toStringAsFixed(2)} \$',
                            isBold: true,
                            color: const Color(0xFFC42B1C),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ de saisie
                    _buildDialogFieldLabel("MONTANT DU VERSEMENT (\$)", isRequired: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: montantCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: _buildDialogInputDecoration(
                        hint: '0.00',
                        icon: Icons.attach_money_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Le montant est obligatoire';
                        final val = double.tryParse(v.trim());
                        if (val == null || val <= 0) return 'Montant invalide';
                        if (val > resteDu) {
                          return 'Le versement ne peut excéder le reste dû (${resteDu.toStringAsFixed(2)} \$)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Raccourcis de paiement rapide
                    Row(
                      children: [
                        const Text(
                          'Raccourcis : ',
                          style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              montantCtrl.text = resteDu.toStringAsFixed(2);
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F2FB),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0x300067C0)),
                            ),
                            child: const Text(
                              'Solder la totalité (100%)',
                              style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0067C0)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              montantCtrl.text = (resteDu / 2).toStringAsFixed(2);
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0x3064748B)),
                            ),
                            child: const Text(
                              '50% du reste',
                              style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Annuler', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 13)),
              ),
              ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                  if (!formKey.currentState!.validate()) return;
                  final montant = double.tryParse(montantCtrl.text.trim()) ?? 0;
                  setDialogState(() => isSaving = true);
                  try {
                    final user = Provider.of<AuthProvider>(context, listen: false).user;
                    if (user == null) return;
                    await AdminService(user.token).payerVente(credit['vente_id'], montant);
                    if (!mounted) return;
                    Navigator.of(dialogCtx).pop();
                    _snack('Règlement enregistré avec succès', const Color(0xFF107C41));
                    await _load();
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    if (!mounted) return;
                    _snack('Erreur lors de l\'enregistrement : $e', const Color(0xFFC42B1C));
                  }
                },
                icon: isSaving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_rounded, size: 16),
                label: isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text(
                  'Valider l\'encaissement',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0067C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );

    montantCtrl.dispose();
  }

  Widget _buildDetailRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildCreditsMetricsRow() {
    final totalReste = _credits.fold<double>(0.0, (acc, c) => acc + _parseNum(c['montant_restant']));
    final totalPaye = _credits.fold<double>(0.0, (acc, c) => acc + _parseNum(c['montant_paye']));
    final totalVolume = _credits.fold<double>(0.0, (acc, c) => acc + _parseNum(c['total_ttc']));
    final totalDossiers = _credits.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 860;

        final cards = [
          _buildWaveMetricCard(
            title: "RESTE À RECOUVRER",
            value: "${totalReste.toStringAsFixed(2)} \$",
            subtitle: "Créances clients en cours",
            badge: "À Recouvrer",
            icon: Icons.money_off_csred_rounded,
            gradient: const [
              Color(0xFF8B1E1E),
              Color(0xFFC42B1C),
              Color(0xFFE53935),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "MONTANTS RÉGLÉS",
            value: "${totalPaye.toStringAsFixed(2)} \$",
            subtitle: "Paiements déjà perçus",
            badge: "Encaissé",
            icon: Icons.check_circle_rounded,
            gradient: const [
              Color(0xFF0A5C36),
              Color(0xFF107C41),
              Color(0xFF2E945D),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "VOLUME TOTAL ENGAGÉ",
            value: "${totalVolume.toStringAsFixed(2)} \$",
            subtitle: "Montant total facturé",
            badge: "Volume Global",
            icon: Icons.account_balance_wallet_rounded,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 3.6,
          ),
          _buildWaveMetricCard(
            title: "DOSSIERS EN CRÉDIT",
            value: "$totalDossiers",
            subtitle: "Factures non soldées",
            badge: "Créances",
            icon: Icons.receipt_long_outlined,
            gradient: const [
              Color(0xFF1E293B),
              Color(0xFF334155),
              Color(0xFF475569),
            ],
            waveSeed: 4.8,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
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
            const SizedBox(width: 14),
            Expanded(child: cards[3]),
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
                    painter: CreditMetricWavePainter(waveSeed: waveSeed),
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
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
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
  // 2. BARRE D'ACTIONS & RECHERCHE
  // ---------------------------------------------------------------------------
  Widget _buildActionBar(bool isWide, int count) {
    return Row(
      children: [
        SizedBox(
          width: isWide ? 310 : 200,
          height: 38,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher client, N° facture...',
              hintStyle: const TextStyle(fontFamily: kAppFontFamily, color: Color(0xFFA0AEC0), fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                splashRadius: 14,
                icon: const Icon(Icons.clear_rounded, size: 15, color: Color(0xFF6B7280)),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
              )
                  : null,
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x18000000))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x18000000))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5)),
            ),
          ),
        ),

        if (isWide) ...[
          const SizedBox(width: 14),
          Text(
            "$count dossier(s) de crédit répertorié(s)",
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ],

        const Spacer(),

        // Bouton Rafraîchir
        SizedBox(
          height: 38,
          child: OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0x20000000)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
  // 3. TABLEAU DESKTOP HAUTE LISIBILITÉ
  // ---------------------------------------------------------------------------
  Widget _buildDesktopDataTable(List<dynamic> filtered) {
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
                dataRowMaxHeight: 56,
                horizontalMargin: 20,
                columnSpacing: 28,
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text("RÉFÉRENCE FACTURE", style: _headerStyle)),
                  DataColumn(label: Text("CLIENT DÉBITEUR", style: _headerStyle)),
                  DataColumn(label: Text("DATE DE CRÉATION", style: _headerStyle)),
                  DataColumn(label: Text("TOTAL VENTE", style: _headerStyle)),
                  DataColumn(label: Text("DÉJÀ VERSÉ", style: _headerStyle)),
                  DataColumn(label: Text("RESTE DÛ", style: _headerStyle)),
                  DataColumn(label: Text("ACTION", style: _headerStyle)),
                ],
                rows: filtered.map((c) {
                  final facture = (c['numero_facture'] ?? '—').toString();
                  final client = (c['client_nom'] ?? 'Client non spécifié').toString();
                  final date = (c['date_vente'] ?? '—').toString();
                  final total = _parseNum(c['total_ttc']);
                  final paye = _parseNum(c['montant_paye']);
                  final reste = _parseNum(c['montant_restant']);

                  return DataRow(
                    cells: [
                      // Facture
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F2FB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF0067C0), size: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              facture,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Client Débiteur
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: const Color(0xFFFEF3C7),
                              child: Text(
                                client.isNotEmpty ? client[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              client,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Date
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Total TTC
                      DataCell(
                        Text(
                          '${total.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),

                      // Déjà Versé
                      DataCell(
                        Text(
                          '${paye.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: Color(0xFF107C41),
                          ),
                        ),
                      ),

                      // Reste Dû
                      DataCell(
                        Text(
                          '${reste.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xFFC42B1C),
                          ),
                        ),
                      ),

                      // Action Encaisser
                      DataCell(
                        ElevatedButton.icon(
                          onPressed: () => _encaisser(c),
                          icon: const Icon(Icons.payments_outlined, size: 14),
                          label: const Text('Encaisser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0067C0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            textStyle: const TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
  // 4. LISTE MOBILE DE SECOURS
  // ---------------------------------------------------------------------------
  Widget _buildMobileList(List<dynamic> filtered) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final c = filtered[index];
        final facture = (c['numero_facture'] ?? '—').toString();
        final client = (c['client_nom'] ?? 'Client non spécifié').toString();
        final date = (c['date_vente'] ?? '—').toString();
        final paye = _parseNum(c['montant_paye']);
        final reste = _parseNum(c['montant_restant']);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Facture $facture',
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Reste : ${reste.toStringAsFixed(2)} \$',
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFFC42B1C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Client : $client • Date : $date',
                style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Déjà versé : ${paye.toStringAsFixed(2)} \$',
                    style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11.5, color: Color(0xFF107C41), fontWeight: FontWeight.w600),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _encaisser(c),
                    icon: const Icon(Icons.payments_outlined, size: 14),
                    label: const Text('Encaisser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0067C0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
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
  // BUILD PRINCIPAL
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;
    final filtered = _filteredCredits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Indicateurs Synthétiques avec Ondes Fluides
        _buildCreditsMetricsRow(),
        const SizedBox(height: 18),

        // 2. Barre d'outils et recherche
        _buildActionBar(isWide, filtered.length),
        const SizedBox(height: 14),

        // 3. Tableau de données Desktop / Liste mobile
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
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0067C0),
                strokeWidth: 2.2,
              ),
            )
                : filtered.isEmpty
                ? _buildEmptyState()
                : isWide
                ? _buildDesktopDataTable(filtered)
                : _buildMobileList(filtered),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS POUR MODALES FLUENT 2
  // ---------------------------------------------------------------------------
  Widget _buildDialogFieldLabel(String label, {bool isRequired = false}) {
    return Row(
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
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(color: Color(0xFFC42B1C), fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  InputDecoration _buildDialogInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
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
    );
  }

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
              child: const Icon(Icons.check_circle_outline_rounded, size: 32, color: Color(0xFF107C41)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isEmpty ? 'Aucun crédit client en cours' : 'Aucun dossier correspondant',
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
                  ? 'Toutes les factures ont été soldées ou aucun encaissement différé n\'est actif.'
                  : 'Modifiez vos termes de recherche.',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES CRÉDITS (WINDOWS BLOOM)
// ---------------------------------------------------------------------------
class CreditMetricWavePainter extends CustomPainter {
  final double waveSeed;

  CreditMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant CreditMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}