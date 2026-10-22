import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../api/admin_service.dart';

class StockToRecoverView extends StatefulWidget {
  const StockToRecoverView({super.key});

  @override
  State<StockToRecoverView> createState() => _StockToRecoverViewState();
}

class _StockToRecoverViewState extends State<StockToRecoverView> {
  bool _isLoading = true;
  List<dynamic> _ventes = [];
  String _filtre = 'en_attente';
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

  /// Convertit une valeur (String, num, null) en double.
  double _parseNum(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _load() async {
    print('🔵 _load appelé, filtre=$_filtre');
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      print('🔵 user=${user?.username}, token=${user?.token.substring(0, 10)}...');
      if (user == null) {
        print('❌ user null, abandon');
        return;
      }
      final service = AdminService(user.token);
      final data = await service.getVentesARecuperer(statut: _filtre);
      print('🟢 data reçu: ${data.length} éléments');
      setState(() {
        _ventes = data;
        _isLoading = false;
      });
    } catch (e, st) {
      print('❌ Erreur _load: $e');
      print(st);
      setState(() => _isLoading = false);
      _snack('Erreur lors du chargement : $e', const Color(0xFFC42B1C));
    }
  }

  List<dynamic> get _filteredVentes {
    final query = _searchCtrl.text.toLowerCase().trim();
    if (query.isEmpty) return _ventes;
    return _ventes.where((v) {
      final facture = (v['numero_facture'] as String? ?? '').toLowerCase();
      final client = (v['client_nom'] as String? ?? '').toLowerCase();
      final date = (v['date_retrait'] as String? ?? '').toLowerCase();
      return facture.contains(query) || client.contains(query) || date.contains(query);
    }).toList();
  }

  Future<void> _valider(int venteId) async {
    final ok = await _confirm(
      title: 'Valider la sortie de stock ?',
      msg: 'Le stock sera décrémenté immédiatement et la vente sera marquée comme livrée.',
      confirmLabel: 'Valider la sortie',
      confirmColor: const Color(0xFF107C41),
      icon: Icons.check_circle_outline_rounded,
    );
    if (!ok) return;
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;
      await AdminService(user.token).validerSortie(venteId);
      _snack('Sortie validée avec succès, stock mis à jour', const Color(0xFF107C41));
      await _load();
    } catch (e) {
      _snack('Erreur : $e', const Color(0xFFC42B1C));
    }
  }

  Future<void> _annuler(int venteId) async {
    final ok = await _confirm(
      title: 'Annuler ce retrait de stock ?',
      msg: 'La commande sera marquée comme annulée. Le stock physique ne sera pas impacté.',
      confirmLabel: 'Confirmer l\'annulation',
      confirmColor: const Color(0xFFC42B1C),
      icon: Icons.warning_amber_rounded,
    );
    if (!ok) return;
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;
      await AdminService(user.token).annulerRetrait(venteId);
      _snack('Retrait annulé avec succès', const Color(0xFFD97706));
      await _load();
    } catch (e) {
      _snack('Erreur : $e', const Color(0xFFC42B1C));
    }
  }

  Future<bool> _confirm({
    required String title,
    required String msg,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        actionsPadding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: confirmColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: confirmColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text(
              'Fermer',
              style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
    return r == true;
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
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildStockMetricsRow() {
    final total = _ventes.length;
    final totalEnAttente = _ventes
        .where((v) => (v['statut_livraison'] ?? 'en_attente') == 'en_attente')
        .length;
    final totalLivres = _ventes
        .where((v) => v['statut_livraison'] == 'livre')
        .length;
    final totalMontantEnAttente = _ventes
        .where((v) => (v['statut_livraison'] ?? 'en_attente') == 'en_attente')
        .fold<double>(0.0, (acc, item) => acc + _parseNum(item['total_ttc']));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 860;

        final cards = [
          _buildWaveMetricCard(
            title: "RETRAITS EN ATTENTE",
            value: "$totalEnAttente",
            subtitle: "Commandes prêtes",
            badge: "À délivrer",
            icon: Icons.schedule_rounded,
            gradient: const [
              Color(0xFFB45309),
              Color(0xFFD97706),
              Color(0xFFF59E0B),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "SORTIES LIVRÉES",
            value: "$totalLivres",
            subtitle: "Retraits complétés",
            badge: "Validées",
            icon: Icons.check_circle_outline_rounded,
            gradient: const [
              Color(0xFF0A5C36),
              Color(0xFF107C41),
              Color(0xFF2E945D),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "VALEUR EN ATTENTE",
            value: "${totalMontantEnAttente.toStringAsFixed(2)} \$",
            subtitle: "Marchandise engagée",
            badge: "Montant TTC",
            icon: Icons.account_balance_wallet_outlined,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 3.6,
          ),
          _buildWaveMetricCard(
            title: "TOTAL COMMANDES",
            value: "$total",
            subtitle: "Filtre actif : $_filtre",
            badge: "Registre",
            icon: Icons.inventory_2_outlined,
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
                    painter: StockMetricWavePainter(waveSeed: waveSeed),
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
                              fontSize: 20,
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
  // 2. BARRE D'OUTILS ET ACTIONS (RECHERCHE + FILTRE STATUT)
  // ---------------------------------------------------------------------------
  Widget _buildActionBar(bool isWide, int count) {
    return Row(
      children: [
        // Champ de recherche Fluent
        SizedBox(
          width: isWide ? 310 : 200,
          height: 38,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher facture, client...',
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
            "$count dossier(s) affiché(s)",
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ],

        const Spacer(),

        // Sélecteur de statut Fluent
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
              DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
              DropdownMenuItem(value: 'livre', child: Text('Livrées')),
              DropdownMenuItem(value: 'annule', child: Text('Annulées')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _filtre = v);
              _load();
            },
          ),
        ),
        const SizedBox(width: 10),

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
  // 3. TABLEAU DESKTOP HAUTE LISIBILITÉ (DATATABLE FLUENT 2)
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
                  DataColumn(label: Text("CLIENT BÉNÉFICIAIRE", style: _headerStyle)),
                  DataColumn(label: Text("DATE DE RETRAIT", style: _headerStyle)),
                  DataColumn(label: Text("TOTAL NET TTC", style: _headerStyle)),
                  DataColumn(label: Text("STATUT LIVRAISON", style: _headerStyle)),
                  DataColumn(label: Text("ACTIONS DISPONIBLES", style: _headerStyle)),
                ],
                rows: filtered.map((v) {
                  final facture = v['numero_facture'] ?? '—';
                  final clientNom = v['client_nom'] ?? 'Client non spécifié';
                  final dateRetrait = v['date_retrait'] ?? '—';
                  final statutLiv = v['statut_livraison'] ?? 'en_attente';
                  final isPending = statutLiv == 'en_attente';
                  final total = _parseNum(v['total_ttc']);

                  return DataRow(
                    cells: [
                      // Référence facture
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

                      // Client
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: const Color(0xFFF1F5F9),
                              child: Text(
                                clientNom.isNotEmpty ? clientNom[0].toUpperCase() : 'C',
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
                              clientNom,
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

                      // Date de retrait
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              dateRetrait,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF334155),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF0067C0),
                          ),
                        ),
                      ),

                      // Statut
                      DataCell(_buildStatusBadge(statutLiv)),

                      // Actions
                      DataCell(
                        isPending
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () => _annuler(v['id'] as int),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFC42B1C),
                                side: const BorderSide(color: Color(0x35C42B1C)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(0, 30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text(
                                'Annuler',
                                style: TextStyle(
                                  fontFamily: kAppFontFamily,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () => _valider(v['id'] as int),
                              icon: const Icon(Icons.check_rounded, size: 14),
                              label: const Text('Valider sortie'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF107C41),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                textStyle: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statutLiv == 'livre' ? Icons.check_circle_rounded : Icons.cancel_outlined,
                              size: 14,
                              color: statutLiv == 'livre' ? const Color(0xFF107C41) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              statutLiv == 'livre' ? 'Délivrée' : 'Annulée',
                              style: TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: statutLiv == 'livre' ? const Color(0xFF107C41) : const Color(0xFF94A3B8),
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
  // 4. LISTE MOBILE DE SECOURS (ÉCRANS ÉTROITS)
  // ---------------------------------------------------------------------------
  Widget _buildMobileList(List<dynamic> filtered) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final v = filtered[index];
        final facture = v['numero_facture'] ?? '—';
        final clientNom = v['client_nom'] ?? 'Client non spécifié';
        final dateRetrait = v['date_retrait'] ?? '—';
        final statutLiv = v['statut_livraison'] ?? 'en_attente';
        final isPending = statutLiv == 'en_attente';
        final total = _parseNum(v['total_ttc']);

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
                  _buildStatusBadge(statutLiv),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Client : $clientNom • Retrait : $dateRetrait',
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${total.toStringAsFixed(2)} \$',
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF0067C0),
                    ),
                  ),
                  if (isPending)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _annuler(v['id'] as int),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC42B1C),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 28),
                          ),
                          child: const Text('Annuler', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () => _valider(v['id'] as int),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF107C41),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 28),
                          ),
                          child: const Text('Valider', style: TextStyle(fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
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
    final filtered = _filteredVentes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Métriques avec Ondes Fluides Windows Bloom
        _buildStockMetricsRow(),
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
                strokeWidth: 2.5,
                color: Color(0xFF0067C0),
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
  // HELPERS VISUELS FLUENT 2
  // ---------------------------------------------------------------------------
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'livre':
        bg = const Color(0xFFE6F4EA);
        fg = const Color(0xFF107C41);
        label = 'Livrée';
        break;
      case 'annule':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'Annulée';
        break;
      case 'en_attente':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'En attente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
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
              child: const Icon(Icons.inbox_outlined, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Aucune sortie de stock trouvée'
                  : 'Aucun résultat pour cette recherche',
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
                  ? 'Il n\'y a aucune commande avec le filtre sélectionné.'
                  : 'Essayez avec un autre nom de client ou numéro de facture.',
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
                  setState(() {});
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0067C0),
                  side: const BorderSide(color: Color(0xFF0067C0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Effacer la recherche',
                    style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES STOCKS (WINDOWS BLOOM)
// ---------------------------------------------------------------------------
class StockMetricWavePainter extends CustomPainter {
  final double waveSeed;

  StockMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant StockMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}