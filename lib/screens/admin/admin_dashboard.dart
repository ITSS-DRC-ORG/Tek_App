import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/screens/admin/view/finance_view.dart';
import 'package:tek_app/screens/admin/view/product_view.dart';
import 'package:tek_app/screens/admin/view/settings_view.dart';
import 'package:tek_app/screens/admin/view/stock_to_recover_view.dart';
import 'package:tek_app/screens/admin/view/user_view.dart';
import 'package:tek_app/screens/admin/view/depot_view.dart';
import 'package:tek_app/screens/admin/view/invoice_validation_view.dart';
import 'package:tek_app/screens/stock/stock_supply.dart';
import 'package:tek_app/screens/stock/stock_transfers.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  AdminService? _adminService;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _adminService = AdminService(user.token);
    }
  }

  // ---------------------------------------------------------------------------
  // DIALOGUE DE CONFIRMATION DE DÉCONNEXION (WINDOWS 11 FLUENT 2)
  // ---------------------------------------------------------------------------
  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
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
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFC42B1C), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Déconnexion',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment fermer votre session administrateur ?',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            color: Color(0xFF475569),
            height: 1.4,
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
              'Annuler',
              style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
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

    if (ok == true && mounted) {
      // 1. Redirection propre vers la page de connexion
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/', (route) => false);
      // 2. Déconnexion de l'état
      Provider.of<AuthProvider>(context, listen: false).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Récupération sécurisée sans opérateur d'assertion "!"
    final user = Provider.of<AuthProvider>(context).user;

    // ✅ Si l'utilisateur est déconnecté, on évite le crash en affichant un écran neutre
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F3F7),
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF0067C0),
          ),
        ),
      );
    }

    // Mise à jour du service si le token a changé
    if (_adminService == null || _adminService!.token != user.token) {
      _adminService = AdminService(user.token);
    }

    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F7),
      body: isWide
          ? Row(
        children: [
          _buildSidebar(user),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.all(22.0),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : _buildMobileLayout(user),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENU PRINCIPAL
  // ---------------------------------------------------------------------------
  Widget _buildContent() {
    if (_adminService == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0067C0)));
    }

    final List<Widget> views = [
      ProductView(service: _adminService!),
      UserView(service: _adminService!),
      DepotView(service: _adminService!),
      const InvoiceValidationView(),
      const StockToRecoverView(),
      const StockTransfers(),
      const StockSupply(),
      const FinanceView(),
      const SettingsView(),
    ];

    return views[_selectedIndex];
  }

  // ---------------------------------------------------------------------------
  // SIDEBAR DESKTOP (Design Fluent 2 Windows 11)
  // ---------------------------------------------------------------------------
  Widget _buildSidebar(dynamic user) {
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
                      Icons.grid_view_rounded,
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
                        "Espace Administrateur",
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
                'GESTION COMMERCIALE',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Navigation des modules
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _sidebarItem(Icons.inventory_2_outlined, "Produits & Articles", 0),
                  _sidebarItem(Icons.people_outline_rounded, "Équipe & Rôles", 1),
                  _sidebarItem(Icons.warehouse_outlined, "Entrepôts & Dépôts", 2),
                  _sidebarItem(Icons.receipt_long_outlined, "Validation Factures", 3),
                  _sidebarItem(Icons.pending_actions_rounded, "Stocks à Récupérer", 4),
                  _sidebarItem(Icons.swap_horiz_rounded, "Transferts de Stock", 5),

                  _sidebarItem(Icons.local_shipping_outlined, "Ravitaillement", 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 1, color: Color(0x10000000)),
                  ),
                  _sidebarItem(Icons.account_balance_wallet_outlined, "Finance & Caisse", 7),
                  _sidebarItem(Icons.settings_outlined, "Paramètres Généraux", 8),
                ],
              ),
            ),

            // Profil Utilisateur en pied de Sidebar
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

  // Carte Utilisateur en bas de Sidebar
  Widget _buildSidebarUserCard(dynamic user) {
    final initials = _getUserInitials(user);
    final name = _getUserName(user);

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
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  "Administrateur",
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
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF64748B),
              size: 17,
            ),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BAR DESKTOP (Style Fluent sobre & Fil d'Ariane)
  // ---------------------------------------------------------------------------
  Widget _buildTopBar() {
    final titles = [
      'Articles & Produits',
      'Équipe & Utilisateurs',
      'Sites & Dépôts',
      'Validation des Factures',
      'Stocks à Récupérer',
      'Transferts Inter-Dépôts',
      'Ravitaillement de Stock',
      'Finance & Caisse',
      'Paramètres Généraux',
    ];

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
          Row(
            children: [
              const Text(
                "Administration",
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

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x10000000)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  "Session Active",
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LAYOUT MOBILE
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout(dynamic user) {
    final titles = [
      'Produits',
      'Utilisateurs',
      'Dépôts',
      'Validation',
      'Stocks à Récupérer',
      'Transferts',
      'Ravitaillement',
      'Finance',
      'Paramètres'
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(
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
      ),
      drawer: _buildMobileDrawer(user),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildMobileDrawer(dynamic user) {
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
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "TEK'app",
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x12000000)),
            const SizedBox(height: 12),
            _mobileDrawerItem(Icons.inventory_2_outlined, 'Produits', 0),
            _mobileDrawerItem(Icons.people_outline_rounded, 'Utilisateurs', 1),
            _mobileDrawerItem(Icons.warehouse_outlined, 'Dépôts', 2),
            _mobileDrawerItem(Icons.receipt_long_outlined, 'Validation Factures', 3),
            _mobileDrawerItem(Icons.pending_actions_rounded, 'Stocks à Récupérer', 4),
            _mobileDrawerItem(Icons.swap_horiz_rounded, 'Transferts', 5),
            _mobileDrawerItem(Icons.local_shipping_outlined, 'Ravitaillement', 6),
            _mobileDrawerItem(Icons.account_balance_wallet_outlined, 'Finance', 7),
            _mobileDrawerItem(Icons.settings_outlined, 'Paramètres', 8),
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
  // UTILITAIRES
  // ---------------------------------------------------------------------------
  String _getUserInitials(dynamic user) {
    if (user == null) return 'A';
    final username = user.username ?? '';
    return username.isNotEmpty ? username[0].toUpperCase() : 'A';
  }

  String _getUserName(dynamic user) {
    if (user == null) return 'Admin';
    final nom = user.nom ?? '';
    return nom.isNotEmpty ? nom : (user.username ?? 'Admin');
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION PUBLIQUE
  // ---------------------------------------------------------------------------
  void _navigateToInvoiceValidation() {
    setState(() => _selectedIndex = 3);
  }

  void navigateToStockToRecover() {
    setState(() => _selectedIndex = 4);
  }

  void _navigateToTransfers() {
    setState(() => _selectedIndex = 5);
  }

  void navigateToInvoiceValidation() {
    _navigateToInvoiceValidation();
  }

  void navigateToTransfers() {
    _navigateToTransfers();
  }
}