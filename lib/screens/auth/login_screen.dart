import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/screens/inventory/stock_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard.dart';
import '../cashier/cashier_home.dart';

/// ---------------------------------------------------------------------------
/// TOKENS DE DESIGN — identiques au reste de l'application
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

// Dans login_screen.dart

void _handleLogin() async {
  setState(() => _errorMessage = null);

  if (!(_formKey.currentState?.validate() ?? false)) return;

  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  String user = _userController.text.trim();
  String pass = _passController.text.trim();

  // ✅ Vérifier que les champs ne sont pas vides
  if (user.isEmpty || pass.isEmpty) {
    setState(() {
      _errorMessage = "Veuillez remplir tous les champs";
    });
    return;
  }

  // ✅ Appel login
  bool success = await authProvider.login(user, pass);

  if (!mounted) return;

  if (success) {
    // ✅ Utilisateur connecté avec succès
    final role = authProvider.user!.role;
    Widget nextScreen;

    print('🎯 Rôle: $role');
    
    switch (role) {
      case UserRole.admin:
        nextScreen = const AdminDashboard();
        break;
      case UserRole.vendeur:
      case UserRole.caissier:
        nextScreen = const CashierHome();
        break;
      case UserRole.magasinier:
      case UserRole.gestionnaire_depot:
        nextScreen = const StockDashboard();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  } else {
    // ✅ Afficher l'erreur du provider ou un message par défaut
    setState(() {
      _errorMessage = authProvider.error ?? "Identifiants incorrects. Vérifiez vos accès.";
    });
  }
}
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;

    return Scaffold(
      backgroundColor: _K.bg,
      body: SafeArea(
        child: isWide
            ? _buildDesktopLayout(isLoading)
            : _buildMobileLayout(isLoading),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LAYOUT DESKTOP (>= 900px)
  // ---------------------------------------------------------------------
  Widget _buildDesktopLayout(bool isLoading) {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildBrandPanel()),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: _buildFormCard(isLoading, true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // LAYOUT MOBILE (< 900px)
  // ---------------------------------------------------------------------
  Widget _buildMobileLayout(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Logo et branding compact
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: _K.sidebarGradient,
              borderRadius: BorderRadius.circular(_K.radiusXl),
              boxShadow: [_K.cardShadow],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "TEK'app",
            style: TextStyle(
              color: _K.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Gestion commerciale simplifiée",
            style: TextStyle(
              color: _K.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 30),

          // Carte de connexion
          _buildFormCard(isLoading, false),

          const SizedBox(height: 24),
          Text(
            "TEK'app © ${DateTime.now().year}",
            style: const TextStyle(fontSize: 11.5, color: _K.textMuted),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PANNEAU DE MARQUE (visible sur grand écran)
  // ---------------------------------------------------------------------
  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(gradient: _K.sidebarGradient),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(_K.radiusSm),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.storefront_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 28),
                const Text(
                  "TEK'app",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "La plateforme de gestion commerciale\npour vos ventes, stocks et équipes.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                _brandFeature(Icons.inventory_2_rounded,
                    "Gestion des stocks en temps réel"),
                const SizedBox(height: 16),
                _brandFeature(
                    Icons.point_of_sale_rounded, "Caisse et vente simplifiées"),
                const SizedBox(height: 16),
                _brandFeature(
                    Icons.people_alt_rounded, "Contrôle des accès par rôle"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandFeature(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_K.radiusXs),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // CARTE DE CONNEXION
  // ---------------------------------------------------------------------
  Widget _buildFormCard(bool isLoading, bool isWide) {
    return Container(
      padding: EdgeInsets.all(isWide ? 36 : 28),
      decoration: BoxDecoration(
        color: _K.surface,
        borderRadius: BorderRadius.circular(_K.radius),
        border: Border.all(color: _K.border),
        boxShadow: [_K.cardShadow],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isWide) ...[
              const SizedBox(height: 4),
              const Text(
                "Bienvenue",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _K.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Connectez-vous à votre espace",
                style: TextStyle(fontSize: 13, color: _K.textMuted),
              ),
              const SizedBox(height: 24),
            ] else ...[
              const Text(
                "Bienvenue",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _K.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Connectez-vous pour accéder à votre espace",
                style: TextStyle(fontSize: 13.5, color: _K.textMuted),
              ),
              const SizedBox(height: 32),
            ],
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _K.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(_K.radiusSm),
                  border: Border.all(color: _K.danger.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: _K.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: _K.danger,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            _buildLabel("Utilisateur"),
            const SizedBox(height: 8),
            TextFormField(
              controller: _userController,
              style: const TextStyle(fontSize: 14, color: _K.textPrimary),
              decoration: _inputDecoration(
                hint: "Entrez votre identifiant",
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Champ requis" : null,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            _buildLabel("Mot de passe"),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 14, color: _K.textPrimary),
              decoration: _inputDecoration(
                hint: "Entrez votre mot de passe",
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _K.textMuted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Champ requis" : null,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => isLoading ? null : _handleLogin(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _K.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _K.primary.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_K.radiusSm),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        "Se connecter",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (isWide) ...[
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "TEK'app © ${DateTime.now().year} — Tous droits réservés",
                  style: const TextStyle(fontSize: 11.5, color: _K.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: _K.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _K.textMuted, fontSize: 13.5),
      prefixIcon: Icon(icon, color: _K.textMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _K.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_K.radiusSm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_K.radiusSm),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_K.radiusSm),
        borderSide: const BorderSide(color: _K.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_K.radiusSm),
        borderSide: const BorderSide(color: _K.danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_K.radiusSm),
        borderSide: const BorderSide(color: _K.danger, width: 1.4),
      ),
    );
  }
}
