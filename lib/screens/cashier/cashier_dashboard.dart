import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import 'package:tek_app/screens/cashier/cashier_sales.dart';
import 'package:tek_app/screens/stock/stock_reports.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

/// ---------------------------------------------------------------------------
/// TOKENS DE DESIGN — palette officielle de l'application
/// ---------------------------------------------------------------------------
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

  static const sidebarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF37474F), Color(0xFF546E7A)],
  );

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

  static BoxShadow get subtleShadow => BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );
}

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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

  // ---------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------
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

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final todaySales = _stats['ventes']?['aujourd_hui']?['total'] ?? 0.0;
    final todayCount = _stats['ventes']?['aujourd_hui']?['nombre'] ?? 0;
    final monthSales = _stats['ventes']?['mois']?['total'] ?? 0.0;
    final monthCount = _stats['ventes']?['mois']?['nombre'] ?? 0;
    final alertCount = _stats['stocks']?['produits_alerte'] ?? 0;
    final soldeCaisse = _stats['caisse']?['solde'] ?? 0.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(
            todaySales: todaySales,
            todayCount: todayCount,
            monthSales: monthSales,
            monthCount: monthCount,
            alertCount: alertCount,
            soldeCaisse: soldeCaisse,
          ),
          const SizedBox(height: 16),

          _buildSecondRow(),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: K.surface,
                borderRadius: BorderRadius.circular(K.radius),
                border: Border.all(color: K.border),
                boxShadow: [K.cardShadow],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: K.primary))
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Activité récente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: K.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _recentActivities.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.history_rounded, size: 48, color: K.textMuted),
                                        SizedBox(height: 12),
                                        Text(
                                          'Aucune activité récente',
                                          style: TextStyle(color: K.textMuted),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _recentActivities.length > 5 ? 5 : _recentActivities.length,
                                    itemBuilder: (context, index) {
                                      final activity = _recentActivities[index];
                                      return _buildActivityTile(activity);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // STATS ROW
  // ---------------------------------------------------------------------
 Widget _buildStatsRow({
  required double todaySales,
  required int todayCount,
  required double monthSales,
  required int monthCount,
  required int alertCount,
  required double soldeCaisse,
}) {
  final isWide = MediaQuery.of(context).size.width >= 900;

  if (isWide) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: (MediaQuery.of(context).size.width - 36) / 4,
          child: _buildStatCard(
            icon: Icons.today_rounded,
            title: 'Ventes du jour',
            value: '\$${todaySales.toStringAsFixed(0)}',
            subtitle: '$todayCount vente${todayCount > 1 ? 's' : ''}',
            color: K.success,
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 36) / 4,
          child: _buildStatCard(
            icon: Icons.calendar_month_rounded,
            title: 'Ventes du mois',
            value: '\$${monthSales.toStringAsFixed(0)}',
            subtitle: '$monthCount vente${monthCount > 1 ? 's' : ''}',
            color: K.info,
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 36) / 4,
          child: _buildStatCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Solde caisse',
            value: '\$${soldeCaisse.toStringAsFixed(0)}',
            subtitle: 'Disponible',
            color: K.primary,
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 36) / 4,
          child: _buildStatCard(
            icon: Icons.warning_rounded,
            title: 'Alertes stock',
            value: '$alertCount',
            subtitle: alertCount > 0 ? 'À surveiller' : 'Aucune alerte',
            color: alertCount > 0 ? K.danger : K.success,
          ),
        ),
      ],
    );
  } else {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.today_rounded,
                title: 'Ventes du jour',
                value: '\$${todaySales.toStringAsFixed(0)}',
                subtitle: '$todayCount vente${todayCount > 1 ? 's' : ''}',
                color: K.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_month_rounded,
                title: 'Ventes du mois',
                value: '\$${monthSales.toStringAsFixed(0)}',
                subtitle: '$monthCount vente${monthCount > 1 ? 's' : ''}',
                color: K.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Solde caisse',
                value: '\$${soldeCaisse.toStringAsFixed(0)}',
                subtitle: 'Disponible',
                color: K.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.warning_rounded,
                title: 'Alertes stock',
                value: '$alertCount',
                subtitle: alertCount > 0 ? 'À surveiller' : 'Aucune alerte',
                color: alertCount > 0 ? K.danger : K.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(
          color: K.border,
          width: 1,
        ),
        boxShadow: [K.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(K.radiusXs),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: K.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: K.textMuted,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 // Dans cashier_dashboard.dart - Corriger la méthode _buildSecondRow

Widget _buildSecondRow() {
  final isWide = MediaQuery.of(context).size.width >= 900;
  
  // ✅ Convertir en double pour éviter les erreurs de type
  final totalEvolution = (_comparaison['evolution']?['total'] ?? 0).toDouble();
  final pourcentage = (_comparaison['evolution']?['pourcentage'] ?? 0).toDouble();

  if (isWide) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildTopProductsCard(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: _buildComparisonCard(totalEvolution, pourcentage),
        ),
      ],
    );
  } else {
    return Column(
      children: [
        _buildTopProductsCard(),
        const SizedBox(height: 12),
        _buildComparisonCard(totalEvolution, pourcentage),
      ],
    );
  }
}
 Widget _buildTopProductsCard() {
  final topItems = _topProducts.take(3).toList();
  final colors = [K.success, K.info, K.warning];

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: K.surface,
      borderRadius: BorderRadius.circular(K.radiusSm),
      border: Border.all(color: K.border),
      boxShadow: [K.cardShadow],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, color: K.warning, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Top produits',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: K.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              'Ce mois',
              style: TextStyle(
                fontSize: 10,
                color: K.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (topItems.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Aucune vente ce mois',
                style: TextStyle(color: K.textMuted, fontSize: 12),
              ),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: topItems.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final nom = product['nom'] as String? ?? 'Produit';
              final quantite = product['quantite'] as int? ?? 0;
              // ✅ Convertir en double
              final total = (product['total'] as num?)?.toDouble() ?? 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: colors[index % colors.length],
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nom,
                        style: const TextStyle(
                          fontSize: 12,
                          color: K.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$quantite',
                      style: TextStyle(
                        fontSize: 11,
                        color: K.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: K.success,
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
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: K.surface,
      borderRadius: BorderRadius.circular(K.radiusSm),
      border: Border.all(color: K.border),
      boxShadow: [K.cardShadow],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.compare_arrows_rounded, color: K.info, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Comparaison',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: K.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else ...[
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: K.success, size: 16),
              const SizedBox(width: 4),
              Text(
                '${pourcentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: pourcentage >= 0 ? K.success : K.danger,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'vs mois dernier',
                style: TextStyle(
                  fontSize: 11,
                  color: K.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${totalEvolution.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              color: K.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: K.surfaceAlt,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Container(
              width: (MediaQuery.of(context).size.width * 0.6 * ((pourcentage / 100).clamp(0, 1))),
              height: 6,
              decoration: BoxDecoration(
                color: pourcentage >= 0 ? K.success : K.danger,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

  // ---------------------------------------------------------------------
  // ACTIVITY TILE
  // ---------------------------------------------------------------------
  Widget _buildActivityTile(dynamic activity) {
    final type = activity['type'] as String? ?? '';
    final reference = activity['reference'] as String? ?? '';
    final date = activity['date'] as String? ?? '';
    final montant = activity['montant'] as double? ?? 0;
    final statut = activity['statut'] as String? ?? '';

    IconData icon;
    Color color;
    String label;

    switch (type) {
      case 'vente':
        icon = Icons.shopping_cart_rounded;
        color = K.success;
        label = 'Vente';
        break;
      case 'caisse':
        icon = Icons.point_of_sale_rounded;
        color = K.info;
        label = 'Caisse';
        break;
      case 'transfert':
        icon = Icons.swap_horiz_rounded;
        color = K.warning;
        label = 'Transfert';
        break;
      default:
        icon = Icons.notifications_rounded;
        color = K.primary;
        label = 'Activité';
    }

    return InkWell(
      onTap: () {
        if (type == 'vente') {
          // Naviguer vers le détail de la vente
        }
      },
      borderRadius: BorderRadius.circular(K.radiusSm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: K.surfaceAlt,
          borderRadius: BorderRadius.circular(K.radiusSm),
          border: Border.all(color: K.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label: $reference',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: K.textPrimary,
                    ),
                  ),
                  if (montant > 0)
                    Text(
                      '\$${montant.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: K.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (statut.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: K.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(K.radiusXl),
                      ),
                      child: Text(
                        statut,
                        style: const TextStyle(
                          color: K.info,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (date.isNotEmpty)
              Text(
                date.substring(0, 10),
                style: const TextStyle(
                  fontSize: 10,
                  color: K.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}