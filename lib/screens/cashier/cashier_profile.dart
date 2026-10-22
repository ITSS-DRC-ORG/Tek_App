import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

class CashierProfile extends StatefulWidget {
  const CashierProfile({super.key});

  @override
  State<CashierProfile> createState() => _CashierProfileState();
}

class _CashierProfileState extends State<CashierProfile>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nomCtrl;
  late TextEditingController _prenomCtrl;
  late TextEditingController _emailCtrl;
  bool _isEditing = false;
  bool _isSaving = false;

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
    _animationController.forward();

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nomCtrl = TextEditingController(text: user?.nom ?? '');
    _prenomCtrl = TextEditingController(text: user?.prenom ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nomCtrl.text.isEmpty || _prenomCtrl.text.isEmpty) {
      _showSnackBar('Le nom et le prénom sont obligatoires', const Color(0xFFD97706));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        _showSnackBar('Utilisateur non connecté', const Color(0xFFC42B1C));
        return;
      }

      final service = AdminService(user.token);
      final updatedUser = await service.updateProfile(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );

      await authProvider.updateUser(updatedUser);

      setState(() => _isEditing = false);
      _showSnackBar('Profil mis à jour avec succès !', const Color(0xFF107C41));
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF107C41)
                  ? Icons.check_circle_rounded
                  : color == const Color(0xFFD97706)
                  ? Icons.warning_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x18000000), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Bannière Visuelle avec Ondes Fluides (Windows Bloom)
              _buildWaveProfileHeader(user),

              // 2. Contenu des Informations / Formulaire
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isEditing)
                      _buildProfileInfoGrid(user)
                    else
                      _buildEditForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. BANNIÈRE SUPÉRIEURE AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildWaveProfileHeader(UserModel? user) {
    final initials = user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'C';
    final fullName = '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim();
    final displayName = fullName.isNotEmpty ? fullName : (user?.username ?? 'Caissier');

    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          // Dégradé de base cobalt
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF004E8C),
                  Color(0xFF0067C0),
                  Color(0xFF2886DE),
                ],
              ),
            ),
          ),
          // Ondes vectorielles
          Positioned.fill(
            child: CustomPaint(
              painter: ProfileMetricWavePainter(waveSeed: 1.8),
            ),
          ),
          // Contenu du profil sur la bannière
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              children: [
                // Avatar utilisateur
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x20000000),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        color: Color(0xFF0067C0),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              user?.role.label.toUpperCase() ?? 'CAISSIER',
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (user?.depotNom != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                user!.depotNom!,
                                style: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_isEditing)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Modifier le profil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0067C0),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. AFFICHAGE DES INFORMATIONS (MODE CONSULTATION)
  // ---------------------------------------------------------------------------
  Widget _buildProfileInfoGrid(UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DÉTAILS DU COMPTE & AFFECTATION',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.person_outline_rounded,
                label: 'Nom & Prénom',
                value: '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim().isNotEmpty
                    ? '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim()
                    : 'Non défini',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.email_outlined,
                label: 'Adresse e-mail',
                value: user?.email.isNotEmpty == true ? user!.email : 'Non renseignée',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.shield_outlined,
                label: 'Rôle applicatif',
                value: user?.role.label ?? 'Caissier',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.storefront_outlined,
                label: 'Point de vente assigné',
                value: user?.depotNom ?? 'Tous les guichets',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: const Color(0xFF0067C0), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
  // 3. FORMULAIRE D'ÉDITION FLUENT (MODE MODIFICATION)
  // ---------------------------------------------------------------------------
  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MODIFICATION DES INFORMATIONS PERSONNELLES',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _buildProfileInput(
                controller: _prenomCtrl,
                label: 'PRÉNOM',
                hint: 'Votre prénom',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildProfileInput(
                controller: _nomCtrl,
                label: 'NOM',
                hint: 'Votre nom',
                icon: Icons.badge_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _buildProfileInput(
          controller: _emailCtrl,
          label: 'ADRESSE E-MAIL',
          hint: 'adresse@entreprise.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),

        // Boutons Annuler / Enregistrer au fond
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                setState(() => _isEditing = false);
                final user = Provider.of<AuthProvider>(context, listen: false).user;
                if (user != null) {
                  _nomCtrl.text = user.nom;
                  _prenomCtrl.text = user.prenom;
                  _emailCtrl.text = user.email;
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0x20000000)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer les modifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0067C0),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: kAppFontFamily,
              color: Color(0xFFA0AEC0),
              fontSize: 12.5,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
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
              borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DE LA BANNIÈRE DE PROFIL
// ---------------------------------------------------------------------------
class ProfileMetricWavePainter extends CustomPainter {
  final double waveSeed;

  ProfileMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant ProfileMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}