import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/screens/inventory/stock_dashboard.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard.dart';
import '../cashier/cashier_home.dart';

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

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    final success = await authProvider.login(user, pass);
    if (!mounted) return;

    if (!success) {
      setState(() {
        _errorMessage = authProvider.error ??
            'Identifiants incorrects. Vérifiez vos accès.';
      });
      return;
    }

    final role = authProvider.user!.role;
    final Widget nextScreen = _routeForRole(role);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  Widget _routeForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.gestionnaire:
        return const StockDashboard();
      case UserRole.caissier:
      case UserRole.vendeur:
        return const CashierHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 920;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F7), // Canevas desktop propre et reposant
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 940 : 430,
              ),
              child: isDesktop
                  ? _buildDesktopCard(isLoading)
                  : _buildCompactCard(isLoading),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LAYOUT DESKTOP : CARTE CENTRÉE HAUTE PRÉCISION
  // ---------------------------------------------------------------------------
  Widget _buildDesktopCard(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 30,
            spreadRadius: 0,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Volet Gauche : Présentation sobre et monochrome
            Expanded(
              flex: 10,
              child: _buildShowcaseVolet(),
            ),

            // Séparateur vertical ultra fin
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0x12000000),
            ),

            // Volet Droit : Console de connexion
            Expanded(
              flex: 11,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 44),
                child: _buildLoginForm(isLoading, isDesktop: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VOLET GAUCHE : IDENTITÉ VISUELLE SOBRE (Bleu signature unique & Neutres)
  // ---------------------------------------------------------------------------
  Widget _buildShowcaseVolet() {
    return Container(
      color: const Color(0xFFF9FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bannière d'onde fluide monochrome (Dégradé bleu pur, sans arc-en-ciel)
          SizedBox(
            height: 175,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF004E8C),
                        Color(0xFF0067C0),
                        Color(0xFF1E88E5),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: FluentWavePainter(waveSeed: 1.6),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge logo simple et net
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.grid_view_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "TEK'app",
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Portail Commercial",
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Gestion intégrée des stocks, ventes et administration.",
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xDDFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Liste des modules avec palette unifiée (un seul bleu d'accent, zéro multicolor)
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MODULES ACCESSIBLES",
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),

                _buildUnifiedTile(
                  title: "Administration & Audit",
                  subtitle: "Supervision complète et bilans d'activité",
                  icon: Icons.admin_panel_settings_outlined,
                ),
                const SizedBox(height: 10),

                _buildUnifiedTile(
                  title: "Gestion des Stocks",
                  subtitle: "Suivi des mouvements et inventaires",
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 10),

                _buildUnifiedTile(
                  title: "Point de Vente",
                  subtitle: "Encaissements et facturation comptoir",
                  icon: Icons.point_of_sale_outlined,
                ),

                const SizedBox(height: 24),

                // Note de sécurité sobre
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Connexion chiffrée selon les permissions de votre compte.",
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF94A3B8),
                        ),
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

  // Composant de tuile unifiée : couleur unique élégante (Fond gris/bleuté doux, icône bleu Windows)
  Widget _buildUnifiedTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x12000000), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: const Color(0xFF0067C0), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VOLET DROIT : FORMULAIRE DE CONNEXION ÉPURÉ
  // ---------------------------------------------------------------------------
  Widget _buildLoginForm(bool isLoading, {required bool isDesktop}) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Connexion",
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Veuillez renseigner vos accès pour débuter la session.",
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 26),

          // Message d'erreur
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFB91C1C),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Champ Identifiant
          _buildFieldHeader("UTILISATEUR"),
          const SizedBox(height: 6),
          TextFormField(
            controller: _userController,
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
            decoration: _inputDecoration(
              hint: "Nom d'utilisateur",
              icon: Icons.person_outline_rounded,
            ),
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),

          // Champ Mot de passe
          _buildFieldHeader("MOT DE PASSE"),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
            decoration: _inputDecoration(
              hint: "••••••••",
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                splashRadius: 16,
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => isLoading ? null : _handleLogin(),
          ),

          const SizedBox(height: 28),

          // Bouton Principal Bleu Windows
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0067C0),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Text(
                "Se connecter",
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          const Center(
            child: Text(
              "Appuyez sur [Entrée ↵] pour valider",
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "TEK'app © ${DateTime.now().year}",
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
        letterSpacing: 0.6,
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
      hintStyle: const TextStyle(
        fontFamily: kAppFontFamily,
        color: Color(0xFF94A3B8),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LAYOUT MOBILE / FENÊTRE RÉDUITE
  // ---------------------------------------------------------------------------
  Widget _buildCompactCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0067C0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "TEK'app",
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildLoginForm(isLoading, isDesktop: false),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES (Épuré & Monochrome Bleu)
// ---------------------------------------------------------------------------
class FluentWavePainter extends CustomPainter {
  final double waveSeed;

  FluentWavePainter({required this.waveSeed});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.24),
          Colors.white.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.85);

    path.cubicTo(
      size.width * 0.25,
      size.height * (0.35 + 0.1 * math.sin(waveSeed)),
      size.width * 0.55,
      size.height * (0.95 - 0.1 * math.cos(waveSeed)),
      size.width,
      size.height * 0.45,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);

    final ridgePath = Path();
    ridgePath.moveTo(0, size.height * 0.85);
    ridgePath.cubicTo(
      size.width * 0.25,
      size.height * (0.35 + 0.1 * math.sin(waveSeed)),
      size.width * 0.55,
      size.height * (0.95 - 0.1 * math.cos(waveSeed)),
      size.width,
      size.height * 0.45,
    );
    canvas.drawPath(ridgePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant FluentWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}