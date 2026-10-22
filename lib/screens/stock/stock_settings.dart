import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

class StockSettings extends StatefulWidget {
  const StockSettings({super.key});

  @override
  State<StockSettings> createState() => _StockSettingsState();
}

class _StockSettingsState extends State<StockSettings>
    with SingleTickerProviderStateMixin {
  // Profil
  late TextEditingController _nomCtrl;
  late TextEditingController _prenomCtrl;
  late TextEditingController _emailCtrl;
  bool _isEditing = false;
  bool _isSaving = false;

  // Préférences
  bool _alertEnabled = true;
  bool _autoTransfert = false;
  bool _notifyEmail = true;
  int _alertThreshold = 10;

  // Animation
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
      setState(() => _isSaving = false);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Carte de Profil avec Bannière Ondes Fluides (Windows Bloom)
              _buildProfileCard(user),
              const SizedBox(height: 20),

              // 2. Panneau des Préférences Logistiques
              _buildPreferencesCard(),
              const SizedBox(height: 20),

              // 3. Déconnexion & Sécurité
              _buildLogoutCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. CARTE DE PROFIL AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildProfileCard(UserModel? user) {
    final initials = user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'S';
    final fullName = '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim();
    final displayName = fullName.isNotEmpty ? fullName : (user?.username ?? 'Gestionnaire Stock');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bannière d'onde fluide
          SizedBox(
            height: 120,
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
                        Color(0xFF2886DE),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: StockSettingsWavePainter(waveSeed: 1.8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Row(
                    children: [
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
                                    user?.role.label.toUpperCase() ?? 'GESTIONNAIRE STOCK',
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
          ),

          // Contenu du profil
          Padding(
            padding: const EdgeInsets.all(24),
            child: !_isEditing
                ? _buildProfileInfoGrid(user)
                : _buildEditForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoGrid(UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DONNÉES DU COMPTE & AFFECTATION LOGISTIQUE',
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
                value: user?.role.label ?? 'Gestionnaire Stock',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.warehouse_outlined,
                label: 'Site logistique assigné',
                value: user?.depotNom ?? 'Tous les entrepôts',
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

  // ---------------------------------------------------------------------------
  // 2. PANNEAU DES PRÉFÉRENCES LOGISTIQUES
  // ---------------------------------------------------------------------------
  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFF0067C0), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Paramètres Logistiques & Surveillance',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildPreferenceTile(
            icon: Icons.notifications_active_outlined,
            title: 'Alertes visuelles de réassort',
            subtitle: 'Signaler immédiatement lorsqu\'un produit franchit le seuil minimal',
            value: _alertEnabled,
            onChanged: (value) => setState(() => _alertEnabled = value),
          ),
          const Divider(height: 16, thickness: 1, color: Color(0x10000000)),

          // Stepper de seuil d'alerte minimal
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB45309)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seuil d\'alerte par défaut',
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        'Quantité résiduelle minimale déclenchant la surveillance',
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (_alertThreshold > 1) {
                          setState(() => _alertThreshold--);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0x18000000)),
                        ),
                        child: const Icon(Icons.remove_rounded, color: Color(0xFF0F172A), size: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '$_alertThreshold u',
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0067C0),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => _alertThreshold++);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0x18000000)),
                        ),
                        child: const Icon(Icons.add_rounded, color: Color(0xFF0F172A), size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Bouton d'enregistrement des préférences
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  _showSnackBar('Préférences logistiques enregistrées avec succès !', const Color(0xFF107C41));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0067C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Enregistrer les préférences'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0067C0)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0067C0),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CARTE DE DÉCONNEXION
  // ---------------------------------------------------------------------------
  Widget _buildLogoutCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8E8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.logout_rounded, color: Color(0xFFC42B1C), size: 18),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fermeture de la session de stock',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  'Déconnectez ce terminal pour protéger les accès au module logistique',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _showLogoutConfirmation,
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC42B1C),
              side: const BorderSide(color: Color(0xFFC42B1C)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }

  Future<void> _showLogoutConfirmation() async {
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
              'Déconnexion',
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
          'Êtes-vous sûr de vouloir vous déconnecter du module de gestion des stocks ?',
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
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DE LA BANNIÈRE DE PROFIL STOCK
// ---------------------------------------------------------------------------
class StockSettingsWavePainter extends CustomPainter {
  final double waveSeed;

  StockSettingsWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant StockSettingsWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}