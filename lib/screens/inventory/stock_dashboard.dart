import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/screens/stock/stock_supply.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'package:tek_app/screens/stock/stock_home.dart';
import 'package:tek_app/screens/stock/stock_products.dart';
import 'package:tek_app/screens/stock/stock_transfers.dart';
import 'package:tek_app/screens/stock/stock_reports.dart';
import 'package:tek_app/screens/stock/stock_settings.dart';

class StockDashboard extends StatefulWidget {
  const StockDashboard({super.key});

  @override
  State<StockDashboard> createState() => _StockDashboardState();
}

class _StockDashboardState extends State<StockDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    StockHome(), // 0 - Tableau de bord
    StockProducts(), // 1 - Produits
    StockSupply(), // 2 - Ravitaillement
    StockTransfers(), // 3 - Transferts
    StockReports(), // 4 - Rapports
    StockSettings(), // 5 - Paramètres
  ];

  // ---------------------------------------------------------------------------
  // CONFIRMATION DE DÉCONNEXION (Dialogue Windows 11)
  // ---------------------------------------------------------------------------
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFC42B1C), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Fermer la session',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de l\'espace stocks ?\nTous les mouvements enregistrés ont été sauvegardés.',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
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
              backgroundColor: const Color(0xFFC42B1C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Se déconnecter',
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

    if (confirm == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F7),
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
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.all(22.0),
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: isWide ? null : _buildBottomNavigationBar(),
    );
  }

  // ---------------------------------------------------------------------------
  // SIDEBAR DESKTOP FLUENT 2
  // ---------------------------------------------------------------------------
  Widget _buildSidebar(UserModel? user) {
    return Container(
      width: 255,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(
          right: BorderSide(color: Color(0x18000000), width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête Marque
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0067C0),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x240067C0),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TEK'app",
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        "Gestion des Stocks",
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Séparateur de section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'LOGISTIQUE & FLUX',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Navigation Stocks
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _sidebarItem(Icons.dashboard_outlined, 'Tableau de bord', 0),
                  _sidebarItem(Icons.inventory_2_outlined, 'Catalogue Produits', 1),
                  _sidebarItem(Icons.local_shipping_outlined, 'Ravitaillement Stock', 2),
                  _sidebarItem(Icons.swap_horiz_rounded, 'Transferts Inter-Dépôts', 3),
                  _sidebarItem(Icons.bar_chart_rounded, 'Rapports Logistiques', 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 1, color: Color(0x10000000)),
                  ),
                  _sidebarItem(Icons.settings_outlined, 'Paramètres du Module', 5),
                ],
              ),
            ),

            // Pied de Sidebar : Utilisateur connecté
            _buildSidebarUserCard(user),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0x0C000000),
          onTap: () => setState(() => _selectedIndex = index),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F2FB) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Indicateur vertical signature Windows 11
                Container(
                  width: 3.5,
                  height: 18,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF0067C0) : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  icon,
                  size: 18,
                  color: selected ? const Color(0xFF0067C0) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      color: selected ? const Color(0xFF0067C0) : const Color(0xFF1E293B),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarUserCard(UserModel? user) {
    final initials = user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'S';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x14000000), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFFE8F2FB),
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                color: Color(0xFF0067C0),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.nom ?? 'Magasinier',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Gestionnaire Stock',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            splashRadius: 16,
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 17),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BAR DESKTOP (Style Fluent sobre & Fil d'Ariane)
  // ---------------------------------------------------------------------------
  Widget _buildTopBar(UserModel? user) {
    final titles = [
      'Tableau de bord',
      'Catalogue Produits',
      'Ravitaillement Stock',
      'Transferts Inter-Dépôts',
      'Rapports Logistiques',
      'Paramètres du Module',
    ];
    final initials = user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'S';

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0x14000000), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Fil d'Ariane professionnel
          Row(
            children: [
              const Text(
                "Espace Stocks",
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "/",
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                ),
              ),
              Text(
                titles[_selectedIndex],
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Indicateur de synchronisation active
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x15107C41)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF107C41),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  "Synchronisation Active",
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF107C41),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Bouton Notifications
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF64748B),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Avatar profil
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE8F2FB),
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                color: Color(0xFF0067C0),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR MOBILE
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildMobileAppBar(UserModel? user) {
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text(
        "TEK'app — Stocks",
        style: TextStyle(
          fontFamily: kAppFontFamily,
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0x14000000)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DRAWER MOBILE
  // ---------------------------------------------------------------------------
  Widget _buildMobileDrawer(UserModel? user) {
    return Drawer(
      backgroundColor: const Color(0xFFFAFAFA),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0067C0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "TEK'app Stocks",
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x12000000)),
            const SizedBox(height: 12),
            _mobileDrawerItem(Icons.dashboard_outlined, 'Tableau de bord', 0),
            _mobileDrawerItem(Icons.inventory_2_outlined, 'Produits', 1),
            _mobileDrawerItem(Icons.local_shipping_outlined, 'Ravitaillement', 2),
            _mobileDrawerItem(Icons.swap_horiz_rounded, 'Transferts', 3),
            _mobileDrawerItem(Icons.bar_chart_rounded, 'Rapports', 4),
            _mobileDrawerItem(Icons.settings_outlined, 'Paramètres', 5),
            const Spacer(),
            _buildSidebarUserCard(user),
          ],
        ),
      ),
    );
  }

  Widget _mobileDrawerItem(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() => _selectedIndex = index);
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F2FB) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? const Color(0xFF0067C0) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    color: selected ? const Color(0xFF0067C0) : const Color(0xFF1E293B),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR MOBILE
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFFFFFFF),
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: const Color(0xFF0067C0),
      unselectedItemColor: const Color(0xFF64748B),
      selectedLabelStyle: const TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2_rounded),
          label: 'Produits',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping_rounded),
          label: 'Ravitaillement',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.swap_horiz_rounded),
          activeIcon: Icon(Icons.swap_horiz_rounded),
          label: 'Transferts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          activeIcon: Icon(Icons.bar_chart_rounded),
          label: 'Rapports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings_rounded),
          label: 'Paramètres',
        ),
      ],
    );
  }
}