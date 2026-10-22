import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/screens/cashier/cashier_clients.dart';
import 'package:tek_app/screens/cashier/cashier_dashboard.dart';
import 'package:tek_app/screens/cashier/cashier_profile.dart';
import 'package:tek_app/screens/cashier/cashier_sales.dart' hide CashierDashboard;
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../admin/view/finance_view.dart';

class CashierHome extends StatefulWidget {
  const CashierHome({super.key});

  @override
  State<CashierHome> createState() => _CashierHomeState();
}

class _CashierHomeState extends State<CashierHome> {

  bool get _hasFinanceAccess {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user?.role == UserRole.caissier || user?.role == UserRole.admin;
  }

  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final isCaissier = user?.role == UserRole.caissier || user?.role == UserRole.admin;

    _pages = [
      const CashierDashboard(),
      const CashierSales(),
      const CashierClients(),
      if (isCaissier) const FinanceView(),
      const CashierProfile(),
    ];
  }

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
          'Êtes-vous sûr de vouloir vous déconnecter de l\'espace caisse ?\nVos opérations en cours ont été enregistrées.',
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
      await Provider.of<AuthProvider>(context, listen: false).logout();
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
                      Icons.point_of_sale_rounded,
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
                        "Espace Caisse & Vente",
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
                'POINT DE VENTE',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Navigation Caisse
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _sidebarItem(Icons.dashboard_outlined, 'Tableau de bord', 0),
                  _sidebarItem(Icons.shopping_bag_outlined, 'Ventes & Tickets', 1),
                  _sidebarItem(Icons.people_outline_rounded, 'Répertoire Clients', 2),
                  if (_hasFinanceAccess)
                    _sidebarItem(Icons.account_balance_wallet_outlined, 'Finance & Caisse', 3),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 1, color: Color(0x10000000)),
                  ),
                  _sidebarItem(
                    Icons.person_outline_rounded,
                    'Mon Profil',
                    _hasFinanceAccess ? 4 : 3,   // ← index dynamique
                  ),
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
    final initials = user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'C';

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
                  user?.nom ?? 'Caissier',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user?.depotNom ?? 'Guichet actif',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
      'Ventes & Factures',
      'Répertoire Clients',
      if (_hasFinanceAccess) 'Finance & Caisse',
      'Mon Profil',
    ];
    final initials = user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'C';

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
                "Espace Caisse",
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

          // Indicateur guichet ouvert
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
                  "Guichet Ouvert",
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
        "TEK'app — Caisse",
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
                      Icons.point_of_sale_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "TEK'app Caisse",
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
            _mobileDrawerItem(Icons.shopping_bag_outlined, 'Ventes & Tickets', 1),
            _mobileDrawerItem(Icons.people_outline_rounded, 'Répertoire Clients', 2),
            if (_hasFinanceAccess)
              _mobileDrawerItem(Icons.account_balance_wallet_outlined, 'Finance', 3),
            _mobileDrawerItem(
              Icons.person_outline_rounded,
              'Mon Profil',
              _hasFinanceAccess ? 4 : 3,
            ),
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
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_bag_outlined),
        activeIcon: Icon(Icons.shopping_bag_rounded),
        label: 'Ventes',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline_rounded),
        activeIcon: Icon(Icons.people_rounded),
        label: 'Clients',
      ),
      if (_hasFinanceAccess)
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Finance',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profil',
      ),
    ];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFFFFFFF),
      currentIndex: _selectedIndex.clamp(0, items.length - 1),
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: const Color(0xFF0067C0),
      unselectedItemColor: const Color(0xFF64748B),
      selectedLabelStyle: const TextStyle(
          fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(
          fontFamily: kAppFontFamily, fontSize: 11, fontWeight: FontWeight.w500),
      items: items,
    );
  }
}