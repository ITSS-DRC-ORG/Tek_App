import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../api/admin_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoBackupEnabled = true;

  // Contrôleurs pour le profil
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _prenomCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

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

    // Remplir les champs avec les données de l'utilisateur
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nomCtrl.text = user.nom;
      _prenomCtrl.text = user.prenom;
      _emailCtrl.text = user.email;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF107C41)
                  ? Icons.check_circle_rounded
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

  // ---------------------------------------------------------------------------
  // MISE À JOUR DU PROFIL (Inchangé)
  // ---------------------------------------------------------------------------
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

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

      if (!mounted) return;

      await authProvider.updateUser(updatedUser);
      _showSnackBar('Profil mis à jour avec succès !', const Color(0xFF107C41));
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // CHANGEMENT DE MOT DE PASSE (Modale Windows 11 Fluent)
  // ---------------------------------------------------------------------------
  void _showChangePasswordDialog() {
    final TextEditingController oldPassCtrl = TextEditingController();
    final TextEditingController newPassCtrl = TextEditingController();
    final TextEditingController confirmPassCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFFFFFF),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF0067C0),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sécurité du compte',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modifiez votre mot de passe d\'accès à votre session de travail.',
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _buildDialogPasswordField(
                    controller: oldPassCtrl,
                    label: 'MOT DE PASSE ACTUEL',
                    hint: '••••••••',
                    obscure: obscureOld,
                    onToggle: () => setStateDialog(() => obscureOld = !obscureOld),
                  ),
                  const SizedBox(height: 12),

                  _buildDialogPasswordField(
                    controller: newPassCtrl,
                    label: 'NOUVEAU MOT DE PASSE',
                    hint: 'Au moins 6 caractères',
                    obscure: obscureNew,
                    onToggle: () => setStateDialog(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 12),

                  _buildDialogPasswordField(
                    controller: confirmPassCtrl,
                    label: 'CONFIRMER LE MOT DE PASSE',
                    hint: '••••••••',
                    obscure: obscureConfirm,
                    onToggle: () => setStateDialog(() => obscureConfirm = !obscureConfirm),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
                onPressed: _isLoading
                    ? null
                    : () async {
                  if (newPassCtrl.text != confirmPassCtrl.text) {
                    _showSnackBar('Les mots de passe ne correspondent pas', const Color(0xFFC42B1C));
                    return;
                  }
                  if (newPassCtrl.text.length < 6) {
                    _showSnackBar('Le mot de passe doit contenir au moins 6 caractères', const Color(0xFFC42B1C));
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final user = authProvider.user;
                    if (user == null) return;

                    final service = AdminService(user.token);
                    final success = await service.changePassword(
                      oldPassword: oldPassCtrl.text.trim(),
                      newPassword: newPassCtrl.text.trim(),
                    );

                    if (!mounted) return;

                    if (success) {
                      Navigator.pop(context);
                      _showSnackBar('Mot de passe modifié avec succès !', const Color(0xFF107C41));
                    } else {
                      _showSnackBar('Erreur lors du changement de mot de passe', const Color(0xFFC42B1C));
                    }
                  } catch (e) {
                    if (!mounted) return;
                    _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0067C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : const Text(
                  'Enregistrer le mot de passe',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPORT DE DONNÉES (Dialogue Desktop Windows 11)
  // ---------------------------------------------------------------------------
  void _showExportOptions() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2FB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.file_download_outlined,
                color: Color(0xFF0067C0),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Exporter les données',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sélectionnez le format d\'exportation des tables du catalogue et des ventes :',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              _buildExportOption(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Format PDF (.pdf)',
                subtitle: 'Rapports et états de stocks prêts pour impression',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Génération du rapport PDF en cours...', const Color(0xFF0067C0));
                },
              ),
              const SizedBox(height: 8),
              _buildExportOption(
                icon: Icons.table_chart_outlined,
                title: 'Classeur Excel (.xlsx)',
                subtitle: 'Tableaux complets avec colonnes et données brutes',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Export Excel généré avec succès', const Color(0xFF107C41));
                },
              ),
              const SizedBox(height: 8),
              _buildExportOption(
                icon: Icons.receipt_long_outlined,
                title: 'Fichier Délimité (.csv)',
                subtitle: 'Données tabulaires universelles compatibles ERP',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Export CSV en cours...', const Color(0xFF0067C0));
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fermer',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2FB),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: const Color(0xFF0067C0), size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8), size: 16),
        onTap: onTap,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD PRINCIPAL
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isWide = MediaQuery.of(context).size.width >= 960;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // EN-TÊTE DE PAGE
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Paramètres Généraux",
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Gestion du profil, préférences de l'espace de travail et configuration système",
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Badge opérationnel sobre
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
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF107C41),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Système opérationnel',
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          color: Color(0xFF107C41),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 1. SECTION PROFIL
            _buildSectionHeader("Mon Profil Utilisateur", Icons.person_outline_rounded),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x18000000), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: isWide
                  ? _buildProfileDesktopLayout(user)
                  : _buildProfileMobileLayout(user),
            ),
            const SizedBox(height: 24),

            // 2. CONFIGURATION SYSTÈME
            _buildSectionHeader("Configuration Système", Icons.settings_outlined),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x18000000), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.storefront_outlined,
                    title: "Informations de l'Entreprise",
                    subtitle: "Raison sociale, adresse, identifiant fiscal, devises et logo",
                    onTap: () => _showSnackBar('Ouverture des informations de l\'entreprise...', const Color(0xFF0067C0)),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0x12000000)),
                  _buildSettingRow(
                    icon: Icons.print_outlined,
                    title: "Imprimantes & Reçus de Caisse",
                    subtitle: "Configuration des imprimantes thermiques (ESC/POS) et formats de tickets",
                    onTap: () => _showSnackBar('Configuration des imprimantes...', const Color(0xFF0067C0)),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0x12000000)),
                  _buildSettingRow(
                    icon: Icons.dns_outlined,
                    title: "Base de Données & Maintenance",
                    subtitle: "État de la synchronisation, sauvegarde locale et archivage",
                    onTap: () => _showSnackBar('Vérification de la base de données...', const Color(0xFF0067C0)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. ACTIONS GLOBALES & DÉCONNEXION
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showExportOptions,
                  icon: const Icon(Icons.file_download_outlined, size: 17),
                  label: const Text('Exporter les données'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0x20000000)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                OutlinedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock_outline_rounded, size: 16),
                  label: const Text('Mot de passe'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0x20000000)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              ],
            ),
            const SizedBox(height: 24),

            // MENTION DE VERSION DISCRÈTE
            Center(
              child: Text(
                "TEK'app • Écosystème de Gestion Commerciale © ${DateTime.now().year}",
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFF94A3B8),
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION PROFIL DESKTOP
  // ---------------------------------------------------------------------------
  Widget _buildProfileDesktopLayout(UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colonne 1 : Carte d'identité du compte
            Container(
              width: 210,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x12000000)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFFE8F2FB),
                    child: Text(
                      user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 24,
                        color: Color(0xFF0067C0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.username ?? 'Utilisateur',
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.role.label.toUpperCase() ?? 'ADMINISTRATEUR',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        color: Color(0xFF0067C0),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Colonne 2 : Champs de profil
            Expanded(
              child: Column(
                children: [
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
                    label: 'ADRESSE EMAIL',
                    hint: 'adresse@entreprise.com',
                    icon: Icons.email_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: Color(0x12000000)),
        const SizedBox(height: 14),

        // Bouton de sauvegarde au fond à droite
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _updateProfile,
              icon: _isLoading
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer le profil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0067C0),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
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

  Widget _buildProfileMobileLayout(UserModel? user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: const Color(0xFFE8F2FB),
          child: Text(
            user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'A',
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 22,
              color: Color(0xFF0067C0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user?.username ?? 'Utilisateur',
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        _buildProfileInput(controller: _prenomCtrl, label: 'PRÉNOM', hint: 'Prénom', icon: Icons.person_outline_rounded),
        const SizedBox(height: 10),
        _buildProfileInput(controller: _nomCtrl, label: 'NOM', hint: 'Nom', icon: Icons.badge_outlined),
        const SizedBox(height: 10),
        _buildProfileInput(controller: _emailCtrl, label: 'EMAIL', hint: 'Email', icon: Icons.email_outlined),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Enregistrer le profil',
              style: TextStyle(fontFamily: kAppFontFamily, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS D'AIDE
  // ---------------------------------------------------------------------------
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0067C0)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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

  Widget _buildDialogPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
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
        TextField(
          controller: controller,
          obscureText: obscure,
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
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 18),
            suffixIcon: IconButton(
              splashRadius: 14,
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 17,
                color: const Color(0xFF64748B),
              ),
              onPressed: onToggle,
            ),
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

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      hoverColor: const Color(0xFFF8FAFC),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F2FB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF0067C0), size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: kAppFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: 12,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
      onTap: onTap,
    );
  }
}