import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';
import '../../models/stock_model.dart';

class StockHome extends StatefulWidget {
  const StockHome({super.key});

  @override
  State<StockHome> createState() => _StockHomeState();
}

class _StockHomeState extends State<StockHome> {
  int _totalProducts = 0;
  int _totalDepots = 0;
  int _alertCount = 0;
  int _totalStock = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final products = await service.getAllProducts();
        final depots = await service.getDepots();
        final stocks = await service.getStocks();
        final alertes = await service.getStockAlertes();

        setState(() {
          _totalProducts = products.length;
          _totalDepots = depots.length;
          _alertCount = alertes.length;
          _totalStock = stocks.fold(0, (sum, s) => sum + s.quantite);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatCard(
              icon: Icons.inventory_2_rounded,
              title: 'Produits en stock',
              value: _isLoading ? '...' : '$_totalProducts',
              color: _K.info,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              icon: Icons.warehouse_rounded,
              title: 'Dépôts',
              value: _isLoading ? '...' : '$_totalDepots',
              color: _K.primary,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              icon: Icons.warning_rounded,
              title: 'Alertes stock',
              value: _isLoading ? '...' : '$_alertCount',
              color: _alertCount > 0 ? _K.danger : _K.success,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              icon: Icons.pie_chart_rounded,
              title: 'Total unités',
              value: _isLoading ? '...' : '$_totalStock',
              color: _K.info,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _K.surface,
              borderRadius: BorderRadius.circular(_K.radius),
              border: Border.all(color: _K.border),
              boxShadow: [_K.cardShadow],
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _K.primary),
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aperçu des stocks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _K.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _totalProducts == 0
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.inventory_2_rounded,
                                        size: 64,
                                        color: _K.textMuted,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Aucun produit en stock',
                                        style: TextStyle(
                                          color: _K.textMuted,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Ajoutez des produits pour commencer',
                                        style: TextStyle(
                                          color: _K.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildStockSummary(),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockSummary() {
    return Container(
      decoration: BoxDecoration(
        color: _K.surfaceAlt,
        borderRadius: BorderRadius.circular(_K.radiusSm),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Résumé du stock',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryItem('Produits', '$_totalProducts', _K.primary),
              const SizedBox(width: 16),
              _buildSummaryItem('Dépôts', '$_totalDepots', _K.info),
              const SizedBox(width: 16),
              _buildSummaryItem('Alertes', '$_alertCount', _alertCount > 0 ? _K.danger : _K.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _K.surface,
          borderRadius: BorderRadius.circular(_K.radiusSm),
          border: Border.all(color: _K.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _K.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _K.surface,
          borderRadius: BorderRadius.circular(_K.radiusSm),
          border: Border.all(color: _K.border),
          boxShadow: [_K.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(_K.radiusXs),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _K.textPrimary,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _K.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _K {
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