import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../api/admin_service.dart';
import '../../cashier/print/receipt_printer.dart';

class FinanceView extends StatefulWidget {
  const FinanceView({super.key});
  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> {
  bool _isLoading = true;
  double _solde = 0;
  double _totalEntreesJour = 0;
  double _totalSortiesJour = 0;
  List<dynamic> _mouvements = [];
  String _filtreType = 'tous';
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
      final service = AdminService(user.token);
      final solde = await service.getSoldeCaisse();
      final mvs = await service.getMouvementsCaisse(
        type: _filtreType == 'tous' ? null : _filtreType,
      );
      setState(() {
        _solde = (solde['solde'] as num).toDouble();
        _totalEntreesJour = (solde['total_entrees'] as num?)?.toDouble() ?? 0;
        _totalSortiesJour = (solde['total_sorties'] as num?)?.toDouble() ?? 0;
        _mouvements = mvs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Erreur lors du chargement : $e', const Color(0xFFC42B1C));
    }
  }

  List<dynamic> get _filteredMouvements {
    final query = _searchCtrl.text.toLowerCase().trim();
    if (query.isEmpty) return _mouvements;
    return _mouvements.where((m) {
      final desc = (m['description'] ?? '').toString().toLowerCase();
      final cat = (m['categorie'] ?? '').toString().toLowerCase();
      final date = (m['date_mouvement'] ?? '').toString().toLowerCase();
      return desc.contains(query) || cat.contains(query) || date.contains(query);
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
  // DIALOGUE DE MOUVEMENT DE CAISSE (WINDOWS 11 FLUENT 2)
  // ---------------------------------------------------------------------------
  Future<void> _showMouvementDialog(String type) async {
    final formKey = GlobalKey<FormState>();
    final montantCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final isSortie = type == 'sortie';
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
                    color: isSortie ? const Color(0xFFFEE2E2) : const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSortie ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: isSortie ? const Color(0xFFC42B1C) : const Color(0xFF107C41),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSortie ? 'Sortie de caisse (Décaissement)' : 'Entrée de caisse (Encaissement)',
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSortie
                            ? 'Renseignez le montant à prélever du tiroir-caisse'
                            : 'Renseignez le montant en espèces versé dans la caisse',
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
              width: 420,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, thickness: 1, color: Color(0x14000000)),
                    const SizedBox(height: 16),

                    if (isSortie) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x40D97706)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Solde disponible en caisse : ${_solde.toStringAsFixed(2)} \$',
                                style: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    _buildDialogFieldLabel("MONTANT DU MOUVEMENT (\$)", isRequired: true),
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
                        if (v == null || v.trim().isEmpty) return 'Le montant est requis';
                        final val = double.tryParse(v.trim());
                        if (val == null || val <= 0) return 'Montant invalide';
                        if (isSortie && val > _solde) {
                          return 'Le montant dépasse le solde disponible';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildDialogFieldLabel("MOTIF / DESCRIPTION"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: _buildDialogInputDecoration(
                        hint: isSortie ? 'ex: Dépense carburant, achat fournitures...' : 'ex: Apport personnel, fond de caisse...',
                        icon: Icons.notes_rounded,
                      ),
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
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                  if (!formKey.currentState!.validate()) return;
                  final montant = double.tryParse(montantCtrl.text.trim()) ?? 0;
                  setDialogState(() => isSaving = true);
                  try {
                    final user = Provider.of<AuthProvider>(context, listen: false).user;
                    if (user == null) return;
                    await AdminService(user.token).createMouvementCaisse(
                      type: type,
                      montant: montant,
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    Navigator.of(dialogCtx).pop();
                    _snack('Mouvement de caisse validé', const Color(0xFF107C41));
                    await _load();
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    if (!mounted) return;
                    _snack('Erreur : $e', const Color(0xFFC42B1C));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSortie ? const Color(0xFFC42B1C) : const Color(0xFF107C41),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text(
                  isSortie ? 'Valider le décaissement' : 'Valider l\'encaissement',
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    montantCtrl.dispose();
    descCtrl.dispose();
  }

  // ---------------------------------------------------------------------------
  // IMPRESSION DES RAPPORTS DE CAISSE
  // ---------------------------------------------------------------------------
  Future<void> _printRapport({required bool mensuel}) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;
      final service = AdminService(user.token);
      final now = DateTime.now();

      final rapport = mensuel
          ? await service.getRapportMensuelCaisse(annee: now.year, mois: now.month)
          : await service.getRapportJournalierCaisse();

      final soldeOuverture = _parseNum(rapport['solde_ouverture']);
      final totalEntrees = _parseNum(rapport['total_entrees']);
      final totalSorties = _parseNum(rapport['total_sorties']);
      final soldeCloture = _parseNum(rapport['solde_cloture']);

      final mouvements = (rapport['mouvements'] as List?) ?? [];
      final rows = <List<String>>[];
      for (final m in mouvements) {
        final date = _formatDate(m['date_mouvement']);
        final type = m['type_mouvement'] == 'entree' ? 'Entrée' : 'Sortie';
        final montant = _parseNum(m['montant']);
        final desc = (m['description'] ?? m['categorie'] ?? '—').toString();
        rows.add([
          date,
          type,
          '${montant.toStringAsFixed(2)} \$',
          desc,
        ]);
      }

      final sections = <Map<String, dynamic>>[
        {
          'title': 'Synthèse Financière de Caisse',
          'items': [
            {'label': 'Solde d\'ouverture', 'value': '${soldeOuverture.toStringAsFixed(2)} \$'},
            {'label': 'Total des entrées', 'value': '+ ${totalEntrees.toStringAsFixed(2)} \$'},
            {'label': 'Total des sorties', 'value': '- ${totalSorties.toStringAsFixed(2)} \$'},
            {'label': 'Solde net de clôture', 'value': '${soldeCloture.toStringAsFixed(2)} \$'},
          ],
        },
      ];

      if (rows.isNotEmpty) {
        sections.add({
          'title': 'Détail des mouvements enregistrés (${rows.length})',
          'table': {
            'headers': ['Date & Heure', 'Type de flux', 'Montant', 'Motif / Description'],
            'rows': rows,
          },
        });
      } else {
        sections.add({
          'title': 'Détail des mouvements',
          'items': [
            {'label': 'Aucun mouvement enregistré sur cette période', 'value': ''},
          ],
        });
      }

      await ReceiptPrinter.printReport(
        title: mensuel
            ? 'Rapport de Caisse Mensuel — ${now.month}/${now.year}'
            : 'Rapport de Caisse Journalier — ${now.day}/${now.month}/${now.year}',
        data: {
          'subtitle': mensuel ? 'Période mensuelle Quincaillerie La Grâce' : 'Clôture journalière Quincaillerie La Grâce',
          'sections': sections,
        },
        filename: 'rapport_caisse_${mensuel ? "mensuel" : "journalier"}.pdf',
      );
      _snack('Rapport généré avec succès', const Color(0xFF107C41));
    } catch (e) {
      _snack('Erreur lors de la génération du rapport : $e', const Color(0xFFC42B1C));
    }
  }

  double _parseNum(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    try {
      final dt = DateTime.parse(s);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }

  // ---------------------------------------------------------------------------
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildFinanceMetricsRow() {
    final fluxNetJour = _totalEntreesJour - _totalSortiesJour;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 860;

        final cards = [
          _buildWaveMetricCard(
            title: "SOLDE DE CAISSE",
            value: "${_solde.toStringAsFixed(2)} \$",
            subtitle: "Trésorerie disponible",
            badge: "Actuel",
            icon: Icons.account_balance_wallet_rounded,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "ENTRÉES DU JOUR",
            value: "+${_totalEntreesJour.toStringAsFixed(2)} \$",
            subtitle: "Versements & Ventes",
            badge: "Crédit",
            icon: Icons.arrow_downward_rounded,
            gradient: const [
              Color(0xFF0A5C36),
              Color(0xFF107C41),
              Color(0xFF2E945D),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "SORTIES DU JOUR",
            value: "-${_totalSortiesJour.toStringAsFixed(2)} \$",
            subtitle: "Dépenses & Décaissements",
            badge: "Débit",
            icon: Icons.arrow_upward_rounded,
            gradient: const [
              Color(0xFF8B1E1E),
              Color(0xFFC42B1C),
              Color(0xFFE53935),
            ],
            waveSeed: 3.6,
          ),
          _buildWaveMetricCard(
            title: "FLUX NET DU JOUR",
            value: "${fluxNetJour >= 0 ? '+' : ''}${fluxNetJour.toStringAsFixed(2)} \$",
            subtitle: "${_mouvements.length} mouvement(s)",
            badge: "Bilan",
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
                    painter: FinanceMetricWavePainter(waveSeed: waveSeed),
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
  // 2. BARRE D'ACTIONS & FILTRES FLUENT 2
  // ---------------------------------------------------------------------------
  Widget _buildActionBar(bool isWide, int filteredCount) {
    return Row(
      children: [
        // Recherche
        SizedBox(
          width: isWide ? 260 : 180,
          height: 38,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher motif, date...',
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

        // Sélecteur de filtre
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x18000000)),
          ),
          child: DropdownButton<String>(
            value: _filtreType,
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
              DropdownMenuItem(value: 'tous', child: Text('Tous les flux')),
              DropdownMenuItem(value: 'entree', child: Text('Entrées seules')),
              DropdownMenuItem(value: 'sortie', child: Text('Sorties seules')),
            ],
            onChanged: (v) {
              setState(() => _filtreType = v!);
              _load();
            },
          ),
        ),

        const Spacer(),

        // Bouton Entrée
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: () => _showMouvementDialog('entree'),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(isWide ? 'Entrée Caisse' : 'Entrée'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF107C41),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Bouton Sortie
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: () => _showMouvementDialog('sortie'),
            icon: const Icon(Icons.remove_rounded, size: 16),
            label: Text(isWide ? 'Sortie Caisse' : 'Sortie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC42B1C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Rapports
        SizedBox(
          height: 38,
          child: OutlinedButton.icon(
            onPressed: () => _printRapport(mensuel: false),
            icon: const Icon(Icons.print_outlined, size: 15),
            label: const Text('Journalier'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0x20000000)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 38,
          child: OutlinedButton.icon(
            onPressed: () => _printRapport(mensuel: true),
            icon: const Icon(Icons.calendar_month_outlined, size: 15),
            label: const Text('Mensuel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0x20000000)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Actualiser
        SizedBox(
          height: 38,
          width: 38,
          child: OutlinedButton(
            onPressed: _load,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0x20000000)),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Icon(Icons.refresh_rounded, size: 17),
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
                dataRowMinHeight: 50,
                dataRowMaxHeight: 52,
                horizontalMargin: 20,
                columnSpacing: 28,
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text("DATE & HEURE", style: _headerStyle)),
                  DataColumn(label: Text("NATURE DU FLUX", style: _headerStyle)),
                  DataColumn(label: Text("MOTIF / DESCRIPTION", style: _headerStyle)),
                  DataColumn(label: Text("CATÉGORIE", style: _headerStyle)),
                  DataColumn(label: Text("MONTANT MOUVEMENT", style: _headerStyle)),
                ],
                rows: filtered.map((m) {
                  final isEntree = m['type_mouvement'] == 'entree';
                  final montant = _parseNum(m['montant']);
                  final date = _formatDate(m['date_mouvement']);
                  final desc = (m['description'] ?? 'Mouvement sans libellé').toString();
                  final cat = (m['categorie'] ?? 'Caisse générale').toString();

                  return DataRow(
                    cells: [
                      // Date
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text(
                              date,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                color: Color(0xFF1E293B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Nature du flux (Badge Pilule)
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
                                isEntree ? 'Entrée Caisse' : 'Sortie Caisse',
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

                      // Description
                      DataCell(
                        Text(
                          desc,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),

                      // Catégorie
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cat,
                            style: const TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
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
        final m = filtered[index];
        final isEntree = m['type_mouvement'] == 'entree';
        final montant = _parseNum(m['montant']);
        final date = _formatDate(m['date_mouvement']);
        final desc = (m['description'] ?? 'Mouvement').toString();

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
                      desc,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Text(
                '${isEntree ? '+' : '-'} ${montant.toStringAsFixed(2)} \$',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: isEntree ? const Color(0xFF107C41) : const Color(0xFFC42B1C),
                ),
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
    final filtered = _filteredMouvements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Indicateurs Synthétiques avec Ondes Fluides
        _buildFinanceMetricsRow(),
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
  // HELPERS MODALES
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
              child: const Icon(Icons.account_balance_wallet_outlined, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isEmpty ? 'Aucun mouvement de caisse enregistré' : 'Aucun mouvement correspondant',
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
                  ? 'Utilisez les boutons "Entrée Caisse" ou "Sortie Caisse" pour initier un flux.'
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
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES FINANCE (WINDOWS BLOOM)
// ---------------------------------------------------------------------------
class FinanceMetricWavePainter extends CustomPainter {
  final double waveSeed;

  FinanceMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant FinanceMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}