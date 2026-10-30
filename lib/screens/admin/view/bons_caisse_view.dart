import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../api/admin_service.dart';
import '../../cashier/print/receipt_printer.dart';

// Helper : parse une valeur (String, num, null) en double
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class BonsCaisseView extends StatefulWidget {
  const BonsCaisseView({super.key});

  @override
  State<BonsCaisseView> createState() => _BonsCaisseViewState();
}

class _BonsCaisseViewState extends State<BonsCaisseView> {
  bool _isLoading = true;
  List<dynamic> _bons = [];
  String _filtre = 'tous'; // tous | entree | sortie
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

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;
      final data = await AdminService(user.token).getBonsCaisse(
        type: _filtre == 'tous' ? null : _filtre,
      );
      setState(() {
        _bons = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Erreur lors du chargement : $e', const Color(0xFFC42B1C));
    }
  }

  List<dynamic> get _filteredBons {
    final query = _searchCtrl.text.toLowerCase().trim();
    if (query.isEmpty) return _bons;
    return _bons.where((b) {
      final num = (b['numero'] ?? '').toString().toLowerCase();
      final nom = (b['nom'] ?? '').toString().toLowerCase();
      final motif = (b['motif'] ?? '').toString().toLowerCase();
      final date = (b['date_bon'] ?? '').toString().toLowerCase();
      return num.contains(query) || nom.contains(query) || motif.contains(query) || date.contains(query);
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
  // DIALOGUE DE CRÉATION DE BON DE CAISSE (WINDOWS 11 FLUENT 2)
  // ---------------------------------------------------------------------------
  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController();
    final motifCtrl = TextEditingController();
    final montantCtrl = TextEditingController();
    String type = 'entree';
    DateTime dateBon = DateTime.now();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
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
                  Icons.receipt_long_rounded,
                  color: Color(0xFF0067C0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouveau bon de caisse',
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Émission d\'un bon d\'entrée ou de sortie avec justificatif',
                      style: TextStyle(
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
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
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
                  const SizedBox(height: 14),

                  // Sélecteur de nature du bon (Cartes cliquables)
                  _buildDialogFieldLabel("NATURE DU BON DE CAISSE", isRequired: true),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModal(() => type = 'entree'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(
                              color: type == 'entree' ? const Color(0xFFE6F4EA) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: type == 'entree' ? const Color(0xFF107C41) : const Color(0xFFE2E8F0),
                                width: type == 'entree' ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_downward_rounded, size: 16, color: type == 'entree' ? const Color(0xFF107C41) : const Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  "Bon d'Entrée (+)",
                                  style: TextStyle(
                                    fontFamily: kAppFontFamily,
                                    fontSize: 12,
                                    fontWeight: type == 'entree' ? FontWeight.w700 : FontWeight.w500,
                                    color: type == 'entree' ? const Color(0xFF107C41) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModal(() => type = 'sortie'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(
                              color: type == 'sortie' ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: type == 'sortie' ? const Color(0xFFC42B1C) : const Color(0xFFE2E8F0),
                                width: type == 'sortie' ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_upward_rounded, size: 16, color: type == 'sortie' ? const Color(0xFFC42B1C) : const Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  "Bon de Sortie (-)",
                                  style: TextStyle(
                                    fontFamily: kAppFontFamily,
                                    fontSize: 12,
                                    fontWeight: type == 'sortie' ? FontWeight.w700 : FontWeight.w500,
                                    color: type == 'sortie' ? const Color(0xFFC42B1C) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Montant
                  _buildDialogFieldLabel("MONTANT (\$ USD)", isRequired: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: montantCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13.5, fontWeight: FontWeight.w700),
                    decoration: _buildDialogInputDecoration(hint: '0.00', icon: Icons.attach_money_rounded),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Le montant est obligatoire';
                      final val = double.tryParse(v.trim());
                      if (val == null || val <= 0) return 'Montant invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Nom bénéficiaire / émetteur
                  _buildDialogFieldLabel("NOM DU BÉNÉFICIAIRE / ÉMETTEUR", isRequired: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nomCtrl,
                    style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: _buildDialogInputDecoration(hint: 'ex: Jean Dupont / Société Alpha', icon: Icons.person_outline_rounded),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
                  ),
                  const SizedBox(height: 12),

                  // Motif
                  _buildDialogFieldLabel("MOTIF / JUSTIFICATIF", isRequired: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: motifCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: _buildDialogInputDecoration(hint: 'ex: Avance sur salaire, approvisionnement urgence...', icon: Icons.notes_rounded),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Le motif est obligatoire' : null,
                  ),
                  const SizedBox(height: 12),

                  // Sélecteur de date
                  _buildDialogFieldLabel("DATE DU BON", isRequired: true),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dateBon,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF0067C0),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Color(0xFF0F172A),
                              ),
                              dialogBackgroundColor: Colors.white,
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0067C0),
                                  textStyle: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setModal(() => dateBon = picked);
                    },
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 10),
                          Text(
                            '${dateBon.day.toString().padLeft(2, '0')}/${dateBon.month.toString().padLeft(2, '0')}/${dateBon.year}',
                            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
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
                setModal(() => isSaving = true);
                try {
                  final user = Provider.of<AuthProvider>(context, listen: false).user;
                  if (user == null) return;
                  await AdminService(user.token).createBonCaisse(
                    typeBon: type,
                    montant: montant,
                    nom: nomCtrl.text.trim(),
                    motif: motifCtrl.text.trim(),
                    dateBon: '${dateBon.year}-${dateBon.month.toString().padLeft(2, '0')}-${dateBon.day.toString().padLeft(2, '0')}',
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _snack('Bon de caisse enregistré avec succès', const Color(0xFF107C41));
                  await _load();
                } catch (e) {
                  setModal(() => isSaving = false);
                  if (!mounted) return;
                  _snack('Erreur lors de l\'enregistrement : $e', const Color(0xFFC42B1C));
                }
              },
              icon: isSaving
                  ? const SizedBox.shrink()
                  : const Icon(Icons.check_rounded, size: 16),
              label: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer le bon', style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0067C0),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );

    nomCtrl.dispose();
    motifCtrl.dispose();
    montantCtrl.dispose();
  }

  Future<void> _imprimer(dynamic bon) async {
    final montant = _toDouble(bon['montant']);
    try {
      await ReceiptPrinter.printReceipt(
        sale: {
          'numero_facture': bon['numero'] ?? 'BON',
          'mode_livraison': 'retrait_magasin',
        },
        lines: [
          {
            'produit_nom': bon['motif'] ?? 'Bon de caisse',
            'quantite': 1,
            'prix_unitaire': montant,
          }
        ],
        clientName: bon['nom'] ?? '—',
        depotName: bon['depot_nom'] ?? 'Caisse Centrale',
        subtotal: montant,
        remise: 0,
        total: montant,
        numeroFacture: bon['numero'] ?? 'N/A',
        documentType: bon['type_bon'] == 'entree' ? 'BON D\'ENTREE' : 'BON DE SORTIE',
      );
      _snack('Bon envoyé à l\'imprimante', const Color(0xFF107C41));
    } catch (e) {
      _snack('Erreur d\'impression : $e', const Color(0xFFC42B1C));
    }
  }

  // ---------------------------------------------------------------------------
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildBonsMetricsRow() {
    final totalEntrees = _bons
        .where((b) => b['type_bon'] == 'entree')
        .fold<double>(0.0, (acc, b) => acc + _toDouble(b['montant']));
    final totalSorties = _bons
        .where((b) => b['type_bon'] == 'sortie')
        .fold<double>(0.0, (acc, b) => acc + _toDouble(b['montant']));
    final fluxNet = totalEntrees - totalSorties;
    final totalBons = _bons.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 860;

        final cards = [
          _buildWaveMetricCard(
            title: "BONS D'ENTRÉE",
            value: "+${totalEntrees.toStringAsFixed(2)} \$",
            subtitle: "Encaissements justifiés",
            badge: "Crédits",
            icon: Icons.arrow_downward_rounded,
            gradient: const [
              Color(0xFF0A5C36),
              Color(0xFF107C41),
              Color(0xFF2E945D),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "BONS DE SORTIE",
            value: "-${totalSorties.toStringAsFixed(2)} \$",
            subtitle: "Décaissements autorisés",
            badge: "Débits",
            icon: Icons.arrow_upward_rounded,
            gradient: const [
              Color(0xFF8B1E1E),
              Color(0xFFC42B1C),
              Color(0xFFE53935),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "FLUX NET DES BONS",
            value: "${fluxNet >= 0 ? '+' : ''}${fluxNet.toStringAsFixed(2)} \$",
            subtitle: "Balance entrées / sorties",
            badge: "Bilan Bons",
            icon: Icons.account_balance_wallet_rounded,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 3.6,
          ),
          _buildWaveMetricCard(
            title: "TOTAL BONS ÉMIS",
            value: "$totalBons",
            subtitle: "Filtre actif : $_filtre",
            badge: "Registre",
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
                    painter: BonCaisseWavePainter(waveSeed: waveSeed),
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
        // Recherche
        SizedBox(
          width: isWide ? 280 : 180,
          height: 38,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher N°, nom, motif...',
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
        const SizedBox(width: 10),

        // Filtre nature du bon
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x18000000)),
          ),
          child: DropdownButton<String>(
            value: _filtre,
            underline: const SizedBox.shrink(),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            items: const [
              DropdownMenuItem(value: 'tous', child: Text('Tous les bons')),
              DropdownMenuItem(value: 'entree', child: Text('Entrées seules')),
              DropdownMenuItem(value: 'sortie', child: Text('Sorties seules')),
            ],
            onChanged: (v) {
              setState(() => _filtre = v!);
              _load();
            },
          ),
        ),

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
        const SizedBox(width: 8),

        // Bouton Nouveau Bon
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(isWide ? 'Nouveau Bon de Caisse' : 'Créer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 13),
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
                  DataColumn(label: Text("RÉFÉRENCE BON", style: _headerStyle)),
                  DataColumn(label: Text("DATE D'ÉMISSION", style: _headerStyle)),
                  DataColumn(label: Text("NATURE", style: _headerStyle)),
                  DataColumn(label: Text("BÉNÉFICIAIRE / ÉMETTEUR", style: _headerStyle)),
                  DataColumn(label: Text("MOTIF / DESCRIPTION", style: _headerStyle)),
                  DataColumn(label: Text("MONTANT RÉEL", style: _headerStyle)),
                  DataColumn(label: Text("ACTION", style: _headerStyle)),
                ],
                rows: filtered.map((b) {
                  final numero = (b['numero'] ?? '—').toString();
                  final date = (b['date_bon'] ?? '—').toString();
                  final isEntree = b['type_bon'] == 'entree';
                  final nom = (b['nom'] ?? 'Non spécifié').toString();
                  final motif = (b['motif'] ?? '—').toString();
                  final montant = _toDouble(b['montant']);

                  return DataRow(
                    cells: [
                      // N° Bon
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
                              child: const Icon(Icons.receipt_outlined, color: Color(0xFF0067C0), size: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              numero,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
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
                            const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Nature (Badge pilule bicolore)
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isEntree ? const Color(0xFFE6F4EA) : const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isEntree ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                size: 12,
                                color: isEntree ? const Color(0xFF107C41) : const Color(0xFFC42B1C),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isEntree ? "Bon d'Entrée" : "Bon de Sortie",
                                style: TextStyle(
                                  fontFamily: kAppFontFamily,
                                  color: isEntree ? const Color(0xFF107C41) : const Color(0xFFC42B1C),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bénéficiaire / Émetteur
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: const Color(0xFFF1F5F9),
                              child: Text(
                                nom.isNotEmpty ? nom[0].toUpperCase() : 'B',
                                style: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              nom,
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

                      // Motif
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(
                            motif,
                            style: const TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Montant
                      DataCell(
                        Text(
                          '${isEntree ? '+' : '-'} ${montant.toStringAsFixed(2)} \$',
                          style: TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isEntree ? const Color(0xFF107C41) : const Color(0xFFC42B1C),
                          ),
                        ),
                      ),

                      // Actions
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.print_outlined, color: Color(0xFF0067C0), size: 18),
                          tooltip: 'Imprimer le ticket du bon',
                          splashRadius: 14,
                          onPressed: () => _imprimer(b),
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
        final b = filtered[index];
        final isEntree = b['type_bon'] == 'entree';
        final montant = _toDouble(b['montant']);
        final numero = (b['numero'] ?? '—').toString();
        final nom = (b['nom'] ?? '—').toString();
        final motif = (b['motif'] ?? '—').toString();
        final date = (b['date_bon'] ?? '—').toString();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEntree ? const Color(0xFFE6F4EA) : const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEntree ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isEntree ? const Color(0xFF107C41) : const Color(0xFFC42B1C),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$numero — $nom',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$date • $motif',
                      style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${isEntree ? '+' : '-'} ${montant.toStringAsFixed(2)} \$',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isEntree ? const Color(0xFF107C41) : const Color(0xFFC42B1C),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.print_outlined, color: Color(0xFF0067C0), size: 18),
                onPressed: () => _imprimer(b),
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
    final filtered = _filteredBons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Indicateurs Synthétiques avec Ondes Fluides
        _buildBonsMetricsRow(),
        const SizedBox(height: 18),

        // 2. Barre d'outils
        _buildActionBar(isWide, filtered.length),
        const SizedBox(height: 14),

        // 3. Tableau de données
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
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
              child: const Icon(Icons.receipt_long_outlined, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isEmpty ? 'Aucun bon de caisse enregistré' : 'Aucun bon correspondant',
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
                  ? 'Créez votre premier bon de caisse en cliquant sur "Nouveau Bon".'
                  : 'Modifiez vos critères de recherche ou réinitialisez le filtre.',
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
// PAINTER VECTORIEL : ONDES FLUIDES DES BONS DE CAISSE (WINDOWS BLOOM)
// ---------------------------------------------------------------------------
class BonCaisseWavePainter extends CustomPainter {
  final double waveSeed;

  BonCaisseWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant BonCaisseWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}