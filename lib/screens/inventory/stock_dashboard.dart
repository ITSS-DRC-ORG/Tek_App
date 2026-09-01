import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/screens/stock/stock_supply.dart';
import '../../providers/auth_provider.dart';
import 'package:tek_app/screens/stock/stock_home.dart';
import 'package:tek_app/screens/stock/stock_products.dart';
import 'package:tek_app/screens/stock/stock_transfers.dart';
import 'package:tek_app/screens/stock/stock_reports.dart';
import 'package:tek_app/screens/stock/stock_settings.dart';

/// ---------------------------------------------------------------------------
/// TOKENS DE DESIGN — palette officielle de l'application
/// ---------------------------------------------------------------------------
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

  // ✅ Ajout du gradient pour la sidebar
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
}

class StockDashboard extends StatefulWidget {
  const StockDashboard({super.key});

  @override
  State<StockDashboard> createState() => _StockDashboardState();
}

class _StockDashboardState extends State<StockDashboard> {
  int _selectedIndex = 0;

  // ✅ Liste des pages avec les bonnes classes
 final List<Widget> _pages = const [
  StockHome(),           // 0 - Tableau de bord
  StockProducts(),       // 1 - Produits
  StockSupply(),         // 2 - Ravitaillement
  StockTransfers(),      // 3 - Transferts
  StockReports(),        // 4 - Rapports
  StockSettings(),       // 5 - Paramètres
];
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: _K.bg,
      appBar: isWide ? null : _buildMobileAppBar(user),
      drawer: isWide ? null : _buildMobileDrawer(user),
      body: isWide
          ? Row(
              children: [
                _buildSidebar(user),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(user),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _pages[_selectedIndex],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: isWide
          ? null
          : _buildBottomNavigationBar(),
    );
  }

  // ---------------------------------------------------------------------
  // CONFIRMATION DE DÉCONNEXION
  // ---------------------------------------------------------------------
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_K.radiusXl),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        backgroundColor: _K.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _K.danger.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: _K.danger,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Déconnexion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _K.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir vous déconnecter ?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _K.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vous devrez vous reconnecter pour accéder à votre compte.',
              style: TextStyle(
                fontSize: 13,
                color: _K.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _K.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Se déconnecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _K.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_K.radiusSm),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );

    if (confirm == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  // ---------------------------------------------------------------------
  // SIDEBAR DESKTOP
  // ---------------------------------------------------------------------
  Widget _buildSidebar(UserModel? user) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(gradient: _K.sidebarGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(_K.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.inventory_2_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "TEK'app",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'STOCKS & DÉPÔTS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _sidebarItem(Icons.dashboard_rounded, 'Tableau de bord', 0),
            _sidebarItem(Icons.inventory_2_rounded, 'Produits', 1),
            _sidebarItem(Icons.local_shipping_rounded, 'Ravitaillement', 2),

            _sidebarItem(Icons.swap_horiz_rounded, 'Transferts', 3),
            _sidebarItem(Icons.bar_chart_rounded, 'Rapports', 4),
            _sidebarItem(Icons.settings_rounded, 'Paramètres', 5),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(_K.radiusSm),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    child: Text(
                      user?.username.isNotEmpty == true
                          ? user!.username[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user?.nom ?? 'Magasinier',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Déconnexion',
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white70, size: 19),
                    onPressed: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_K.radiusSm),
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: _K.anim,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(_K.radiusSm),
              border: selected
                  ? Border.all(color: Colors.white.withOpacity(0.18))
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? Colors.white : Colors.white70),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TOP BAR DESKTOP
  // ---------------------------------------------------------------------
  Widget _buildTopBar(UserModel? user) {
final titles = ['Tableau de bord', 'Produits', 'Ravitaillement', 'Transferts', 'Rapports', 'Paramètres'];    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _K.surface,
        border: Border(bottom: BorderSide(color: _K.border)),
      ),
      child: Row(
        children: [
          Text(
            titles[_selectedIndex],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _K.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _K.surfaceAlt,
              borderRadius: BorderRadius.circular(_K.radiusSm),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: _K.textMuted, size: 20),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 20,
            backgroundColor: _K.accentSoft,
            child: Text(
              user?.username.isNotEmpty == true
                  ? user!.username[0].toUpperCase()
                  : 'S',
              style: const TextStyle(
                color: _K.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // APP BAR MOBILE
  // ---------------------------------------------------------------------
  PreferredSizeWidget _buildMobileAppBar(UserModel? user) {
    return AppBar(
      backgroundColor: _K.surface,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: _K.primary),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text(
        "TEK'app - Stocks",
        style: TextStyle(
          color: _K.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _K.surfaceAlt,
            borderRadius: BorderRadius.circular(_K.radiusSm),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              color: _K.textMuted, size: 20),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // DRAWER MOBILE
  // ---------------------------------------------------------------------
  Widget _buildMobileDrawer(UserModel? user) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: _K.sidebarGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(_K.radiusSm),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.inventory_2_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "TEK'app",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'STOCKS & DÉPÔTS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
             // Mettre à jour _mobileDrawerItem et _sidebarItem
_mobileDrawerItem(Icons.dashboard_rounded, 'Tableau de bord', 0),
_mobileDrawerItem(Icons.inventory_2_rounded, 'Produits', 1),
_mobileDrawerItem(Icons.local_shipping_rounded, 'Ravitaillement', 2),
_mobileDrawerItem(Icons.swap_horiz_rounded, 'Transferts', 3),
_mobileDrawerItem(Icons.bar_chart_rounded, 'Rapports', 4),
_mobileDrawerItem(Icons.settings_rounded, 'Paramètres', 5),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(_K.radiusSm),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      child: Text(
                        user?.username.isNotEmpty == true
                            ? user!.username[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user?.nom ?? 'Magasinier',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Déconnexion',
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.white70, size: 19),
                      onPressed: () => _confirmLogout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileDrawerItem(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_K.radiusSm),
          onTap: () {
            setState(() => _selectedIndex = index);
            Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: _K.anim,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(_K.radiusSm),
              border: selected
                  ? Border.all(color: Colors.white.withOpacity(0.18))
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? Colors.white : Colors.white70),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR MOBILE
  // ---------------------------------------------------------------------
 // Dans stock_dashboard.dart
Widget _buildBottomNavigationBar() {
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: _selectedIndex,
    onTap: (index) => setState(() => _selectedIndex = index),
    selectedItemColor: _K.primary,
    unselectedItemColor: _K.textMuted,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_rounded),
        label: 'Produits',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.local_shipping_rounded),
        label: 'Ravitaillement',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.swap_horiz_rounded),
        label: 'Transferts',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_rounded),
        label: 'Rapports',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_rounded),
        label: 'Paramètres',
      ),
    ],
  );
}
}