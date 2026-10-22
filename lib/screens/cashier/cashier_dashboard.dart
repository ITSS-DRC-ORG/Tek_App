import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import 'package:tek_app/screens/cashier/cashier_sales.dart';
import 'package:tek_app/screens/stock/stock_reports.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentActivities = [];
  List<dynamic> _topProducts = [];
  Map<String, dynamic> _comparaison = {};

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final stats = await service.getDashboardStats();
        final activities = await service.getRecentActivities();
        final topProducts = await service.getTopProducts();
        final comparaison = await service.getSalesComparison();

        setState(() {
          _stats = stats;
          _recentActivities = activities;
          _topProducts = topProducts;
          _comparaison = comparaison;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION (Inchangée)
  // ---------------------------------------------------------------------------
  void _navigateToSales({String? filter}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CashierSales(initialFilter: filter),
      ),
    );
  }

  void _navigateToStockReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StockReports(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final todaySales = (_stats['ventes']?['aujourd_hui']?['total'] as num?)?.toDouble() ?? 0.0;
    final todayCount = _stats['ventes']?['aujourd_hui']?['nombre'] ?? 0;
    final monthSales = (_stats['ventes']?['mois']?['total'] as num?)?.toDouble() ?? 0.0;
    final monthCount = _stats['ventes']?['mois']?['nombre'] ?? 0;
    final alertCount = _stats['stocks']?['produits_alerte'] ?? 0;
    final soldeCaisse = (_stats['caisse']?['solde'] as num?)?.toDouble() ?? 0.0;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Les 4 Cartes Métriques Stylisées avec Ondes Fluides
              _buildStatsRow(
                todaySales: todaySales,
                todayCount: todayCount,
                monthSales: monthSales,
                monthCount: monthCount,
                alertCount: alertCount,
                soldeCaisse: soldeCaisse,
              ),
              const SizedBox(height: 18),

              // 2. Deuxième rangée : Top Produits + Comparatif
              _buildSecondRow(),
              const SizedBox(height: 18),

              // 3. Activité Récente (Tableau/Flux de Session)
              _buildRecentActivitySection(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. STATS ROW AVEC ONDES FLUIDES VECTORIELLES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildStatsRow({
    required double todaySales,
    required int todayCount,
    required double monthSales,
    required int monthCount,
    required int alertCount,
    required double soldeCaisse,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 940;

        final cards = [
          _buildWaveStatCard(
            title: "VENTES DU JOUR",
            value: "${todaySales.toStringAsFixed(2)} \$",
            subtitle: "$todayCount ticket${todayCount > 1 ? 's' : ''}",
            badge: "Aujourd'hui",
            icon: Icons.today_rounded,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveStatCard(
            title: "VENTES DU MOIS",
            value: "${monthSales.toStringAsFixed(2)} \$",
            subtitle: "$monthCount transaction${monthCount > 1 ? 's' : ''}",
            badge: "Mensuel",
            icon: Icons.calendar_month_rounded,
            gradient: const [
              Color(0xFF0A3B5C),
              Color(0xFF165B8C),
              Color(0xFF3A89C9),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveStatCard(
            title: "SOLDE DE CAISSE",
            value: "${soldeCaisse.toStringAsFixed(2)} \$",
            subtitle: "Disponible au tiroir",
            badge: "Caisse",
            icon: Icons.account_balance_wallet_rounded,
            gradient: const [
              Color(0xFF1E293B),
              Color(0xFF334155),
              Color(0xFF475569),
            ],
            waveSeed: 3.6,
          ),
          _buildWaveStatCard(
            title: "ALERTES DE STOCK",
            value: "$alertCount",
            subtitle: alertCount > 0 ? "Sous surveillance" : "Stock optimal",
            badge: "Stocks",
            icon: Icons.notifications_active_outlined,
            gradient: const [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF2563EB),
            ],
            waveSeed: 4.8,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          );
        } else {
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
      },
    );
  }

  Widget _buildWaveStatCard({
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
            height: 62,
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
                    painter: CashierMetricWavePainter(waveSeed: waveSeed),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. DEUXIÈME RANGÉE (TOP PRODUITS & COMPARATIF MENSUEL)
  // ---------------------------------------------------------------------------
  Widget _buildSecondRow() {
    final isWide = MediaQuery.of(context).size.width >= 960;
    final totalEvolution = (_comparaison['evolution']?['total'] ?? 0).toDouble();
    final pourcentage = (_comparaison['evolution']?['pourcentage'] ?? 0).toDouble();

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 13,
            child: _buildTopProductsCard(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 11,
            child: _buildComparisonCard(totalEvolution, pourcentage),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildTopProductsCard(),
          const SizedBox(height: 14),
          _buildComparisonCard(totalEvolution, pourcentage),
        ],
      );
    }
  }

  Widget _buildTopProductsCard() {
    final topItems = _topProducts.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.star_outline_rounded, color: Color(0xFF0067C0), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Top Produits Ventes',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Ce mois',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (topItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Aucune vente enregistrée ce mois-ci',
                  style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF94A3B8), fontSize: 12.5),
                ),
              ),
            )
          else
            Column(
              children: topItems.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                final nom = product['nom'] as String? ?? 'Article';
                final quantite = product['quantite'] as int? ?? 0;
                final total = (product['total'] as num?)?.toDouble() ?? 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x10000000)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2FB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontFamily: kAppFontFamily,
                              color: Color(0xFF0067C0),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nom,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$quantite vendus',
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '${total.toStringAsFixed(0)} \$',
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0067C0),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(double totalEvolution, double pourcentage) {
    final isPositive = pourcentage >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Color(0xFF0067C0), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Évolution Mensuelle',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${isPositive ? '+' : ''}${pourcentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? const Color(0xFF107C41) : const Color(0xFFC42B1C),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'par rapport au mois précédent',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Variation nette : ${isPositive ? '+' : ''}${totalEvolution.toStringAsFixed(0)} \$',
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          // Barre de progression sobre
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (pourcentage.abs() / 100).clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFF107C41) : const Color(0xFFC42B1C),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ACTIVITÉ RÉCENTE DE CAISSE
  // ---------------------------------------------------------------------------
  Widget _buildRecentActivitySection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.history_rounded, color: Color(0xFF0067C0), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Activité Récente de Session',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_recentActivities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aucune activité récente enregistrée',
                  style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivities.length > 5 ? 5 : _recentActivities.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
              itemBuilder: (context, index) {
                final activity = _recentActivities[index];
                return _buildActivityTile(activity);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(dynamic activity) {
    final type = activity['type'] as String? ?? '';
    final reference = activity['reference'] as String? ?? '';
    final date = activity['date'] as String? ?? '';
    final montant = (activity['montant'] as num?)?.toDouble() ?? 0.0;
    final statut = activity['statut'] as String? ?? '';

    IconData icon;
    String label;

    switch (type) {
      case 'vente':
        icon = Icons.shopping_bag_outlined;
        label = 'Vente';
        break;
      case 'caisse':
        icon = Icons.point_of_sale_rounded;
        label = 'Caisse';
        break;
      case 'transfert':
        icon = Icons.swap_horiz_rounded;
        label = 'Transfert';
        break;
      default:
        icon = Icons.notifications_none_rounded;
        label = 'Mouvement';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF0067C0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label • $reference',
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (date.isNotEmpty)
                  Text(
                    date.length >= 10 ? date.substring(0, 10) : date,
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          if (montant > 0) ...[
            Text(
              '${montant.toStringAsFixed(2)} \$',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF0067C0),
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (statut.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statut,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFF475569),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES DU TABLEAU DE BORD CAISSE
// ---------------------------------------------------------------------------
class CashierMetricWavePainter extends CustomPainter {
  final double waveSeed;

  CashierMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant CashierMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}