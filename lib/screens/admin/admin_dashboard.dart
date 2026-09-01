import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import 'package:tek_app/screens/admin/view/product_view.dart';
import 'package:tek_app/screens/admin/view/settings_view.dart';
import 'package:tek_app/screens/admin/view/user_view.dart';
import 'package:tek_app/screens/admin/view/depot_view.dart';
import 'package:tek_app/screens/admin/view/invoice_validation_view.dart';
import 'package:tek_app/screens/stock/stock_supply.dart';
import 'package:tek_app/screens/stock/stock_transfers.dart'; // ✅ Ajout de l'import
import 'package:tek_app/screens/cashier/cashier_sales.dart';
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

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  late AdminService _adminService;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user!;
    _adminService = AdminService(user.token);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user!;
    
    if (_adminService.token != user.token) {
      _adminService = AdminService(user.token);
    }

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: K.bg,
      body: isWide
          ? Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _buildContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _buildMobileLayout(),
    );
  }

  // ---------------------------------------------------------------------
  // CONTENU PRINCIPAL
  // ---------------------------------------------------------------------
  Widget _buildContent() {
   final List<Widget> _views = [
  ProductView(service: _adminService),
  UserView(service: _adminService),
  DepotView(service: _adminService),
  const InvoiceValidationView(),
  const StockTransfers(),
  const StockSupply(), // ✅ Ajout de la page Ravitaillement
  const SettingsView(),
];

    return _views[_selectedIndex];
  }

  // ---------------------------------------------------------------------
  // LAYOUT MOBILE
  // ---------------------------------------------------------------------
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: K.surface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: K.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "TEK'app",
          style: TextStyle(
            color: K.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: K.surfaceAlt,
              borderRadius: BorderRadius.circular(K.radiusSm),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: K.textMuted, size: 20),
          ),
        ],
      ),
      drawer: _buildMobileDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContent(),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // DRAWER MOBILE
  // ---------------------------------------------------------------------
  Widget _buildMobileDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: K.sidebarGradient),
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
                        borderRadius: BorderRadius.circular(K.radiusSm),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.storefront_rounded,
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
                  'ADMINISTRATION',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _mobileDrawerItem(Icons.inventory_rounded, 'Produits', 0),
              _mobileDrawerItem(Icons.people_rounded, 'Utilisateurs', 1),
              _mobileDrawerItem(Icons.warehouse_rounded, 'Dépôts', 2),
              _mobileDrawerItem(Icons.check_circle_rounded, 'Validation', 3),
              _mobileDrawerItem(Icons.swap_horiz_rounded, 'Transferts', 4), // ✅ Nouvel item
              _mobileDrawerItem(Icons.local_shipping_rounded, 'Ravitaillement', 5),
              _mobileDrawerItem(Icons.settings_rounded, 'Paramètres', 5),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(K.radiusSm),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      child: Text(
                        _getUserInitials(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getUserName(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Déconnexion',
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.white70, size: 19),
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/'),
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
          borderRadius: BorderRadius.circular(K.radiusSm),
          onTap: () {
            setState(() => _selectedIndex = index);
            Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: K.anim,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(K.radiusSm),
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
  // SIDEBAR DESKTOP
  // ---------------------------------------------------------------------
  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(gradient: K.sidebarGradient),
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
                      borderRadius: BorderRadius.circular(K.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.storefront_rounded,
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
                'ADMINISTRATION',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _sidebarItem(Icons.inventory_rounded, "Produits", 0),
            _sidebarItem(Icons.people_rounded, "Utilisateurs", 1),
            _sidebarItem(Icons.warehouse_rounded, "Dépôts", 2),
            _sidebarItem(Icons.check_circle_rounded, "Validation", 3),
            _sidebarItem(Icons.swap_horiz_rounded, "Transferts", 4), // ✅ Nouvel item
            _sidebarItem(Icons.local_shipping_rounded, "Ravitaillement", 5),
            _sidebarItem(Icons.settings_rounded, "Paramètres", 6),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    child: Text(
                      _getUserInitials(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getUserName(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Déconnexion',
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white70, size: 19),
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/'),
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
          borderRadius: BorderRadius.circular(K.radiusSm),
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: K.anim,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(K.radiusSm),
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
  // TOP BAR
  // ---------------------------------------------------------------------
  Widget _buildTopBar() {
final titles = ['Produits', 'Utilisateurs', 'Dépôts', 'Validation', 'Transferts', 'Ravitaillement', 'Paramètres'];    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: K.border)),
      ),
      child: Row(
        children: [
          Text(
            "Gestion des ${titles[_selectedIndex]}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: K.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: K.surfaceAlt,
              borderRadius: BorderRadius.circular(K.radiusSm),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: K.textMuted, size: 20),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 20,
            backgroundColor: K.accentSoft,
            child: Text(
              _getUserInitials(),
              style: const TextStyle(
                color: K.primary,
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
  // UTILITAIRES
  // ---------------------------------------------------------------------
  String _getUserInitials() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return 'A';
    final username = user.username;
    return username.isNotEmpty ? username[0].toUpperCase() : 'A';
  }

  String _getUserName() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return 'Admin';
    return user.nom.isNotEmpty ? user.nom : user.username;
  }

  // ---------------------------------------------------------------------
  // NAVIGATION VERS LA VALIDATION DES FACTURES
  // ---------------------------------------------------------------------
  void _navigateToInvoiceValidation() {
    setState(() {
      _selectedIndex = 3;
    });
  }

  void _navigateToTransfers() {
    setState(() {
      _selectedIndex = 4;
    });
  }

  // Méthodes publiques pour rediriger depuis d'autres parties de l'app
  void navigateToInvoiceValidation() {
    _navigateToInvoiceValidation();
  }

  void navigateToTransfers() {
    _navigateToTransfers();
  }
}