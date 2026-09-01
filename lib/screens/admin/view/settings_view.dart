import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import '../../../providers/auth_provider.dart';
import '../../../api/admin_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 300),
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
              color == K.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.radiusSm)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // UPDATE PROFIL
  // ---------------------------------------------------------------------
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user == null) {
        _showSnackBar('Utilisateur non connecté', K.danger);
        return;
      }

      // Mise à jour via l'API
      final service = AdminService(user.token);
      final updatedUser = await service.updateProfile(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );

      if (!mounted) return;
      
      // Mettre à jour l'utilisateur dans le provider
      await authProvider.updateUser(updatedUser);
      
      _showSnackBar('Profil mis à jour avec succès !', K.success);
      
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', K.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // CHANGE PASSWORD
  // ---------------------------------------------------------------------
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
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.radiusXl)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: K.info.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, color: K.info, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Changer le mot de passe'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassCtrl,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureOld = !obscureOld),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(K.radiusSm),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(K.radiusSm),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(K.radiusSm),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler', style: TextStyle(color: K.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newPassCtrl.text != confirmPassCtrl.text) {
                    _showSnackBar('Les mots de passe ne correspondent pas', K.danger);
                    return;
                  }
                  if (newPassCtrl.text.length < 6) {
                    _showSnackBar('Le mot de passe doit contenir au moins 6 caractères', K.danger);
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
                      _showSnackBar('Mot de passe modifié avec succès !', K.success);
                    } else {
                      _showSnackBar('Erreur lors du changement de mot de passe', K.danger);
                    }
                  } catch (e) {
                    if (!mounted) return;
                    _showSnackBar('Erreur: ${e.toString()}', K.danger);
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: K.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(K.radiusSm),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Changer le mot de passe'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // EXPORT DATA
  // ---------------------------------------------------------------------
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(K.radiusXl)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exporter les données',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: K.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choisissez le format d\'exportation',
              style: TextStyle(color: K.textMuted),
            ),
            const SizedBox(height: 20),
            _buildExportOption(
              icon: Icons.picture_as_pdf_rounded,
              title: 'PDF',
              subtitle: 'Export en format PDF',
              color: K.danger,
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Export PDF en cours...', K.info);
              },
            ),
            const Divider(height: 1),
            _buildExportOption(
              icon: Icons.table_chart_rounded,
              title: 'Excel',
              subtitle: 'Export en format Excel (XLSX)',
              color: K.success,
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Export Excel en cours...', K.info);
              },
            ),
            const Divider(height: 1),
            _buildExportOption(
              icon: Icons.text_snippet_rounded,
              title: 'CSV',
              subtitle: 'Export en format CSV',
              color: K.info,
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Export CSV en cours...', K.info);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(K.radiusSm),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: K.textMuted),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Paramètres Généraux",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: K.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isWide)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: K.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(K.radiusXl),
                      border: Border.all(color: K.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: K.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Système opérationnel',
                          style: TextStyle(color: K.success, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 25),

            // Section Profil
            _buildSectionTitle("Mon Profil", Icons.person_rounded),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: K.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: K.border),
                boxShadow: [K.cardShadow],
              ),
              child: isWide
                  ? _buildProfileDesktop(user)
                  : _buildProfileMobile(user),
            ),

            const SizedBox(height: 30),

            // Section Application
            _buildSectionTitle("Configuration Système", Icons.settings_rounded),
            _buildSettingTile(
              icon: Icons.business_rounded,
              title: "Informations Quincaillerie",
              subtitle: "Nom, adresse, numéro de contribuable, logo",
              onTap: () {
                _showSnackBar('Ouverture des informations quincaillerie...', K.info);
              },
            ),
            _buildSettingTile(
              icon: Icons.print_rounded,
              title: "Imprimantes & Facturation",
              subtitle: "Configurer les imprimantes thermiques et format PDF",
              onTap: () {
                _showSnackBar('Ouverture de la configuration des imprimantes...', K.info);
              },
            ),
            _buildSettingTile(
              icon: Icons.storage_rounded,
              title: "Base de données",
              subtitle: "État de la connexion et sauvegardes",
              onTap: () {
                _showSnackBar('Vérification de la base de données...', K.info);
              },
            ),
            
            const SizedBox(height: 20),

            // Section Préférences
            _buildSectionTitle("Préférences", Icons.tune_rounded),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: K.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: K.border),
                boxShadow: [K.cardShadow],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Notifications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Recevoir des alertes et notifications'),
                    value: _notificationsEnabled,
                    activeColor: K.info,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Mode sombre',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Activer le thème sombre'),
                    value: _darkModeEnabled,
                    activeColor: K.primary,
                    onChanged: (value) => setState(() => _darkModeEnabled = value),
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Sauvegarde automatique',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Sauvegarder automatiquement les données'),
                    value: _autoBackupEnabled,
                    activeColor: K.success,
                    onChanged: (value) => setState(() => _autoBackupEnabled = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateProfile,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer les modifications'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: K.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(K.radiusSm),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: const Text('Changer le mot de passe'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: K.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(K.radiusSm),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showExportOptions,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Exporter les données'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: K.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(K.radiusSm),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => authProvider.logout(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text("Déconnexion"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: K.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(K.radiusSm),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Footer
            Center(
              child: Text(
                "TEK'app v1.0.0 • Tous droits réservés © ${DateTime.now().year}",
                style: const TextStyle(
                  color: K.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // WIDGETS D'AIDE
  // ---------------------------------------------------------------------
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: K.primary),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: K.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDesktop(UserModel? user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: K.primary,
          child: Text(
            user?.username[0].toUpperCase() ?? "A",
            style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 25),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.nom ?? "Administrateur",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: K.textPrimary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email_rounded, color: K.textMuted, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    user?.email ?? "admin@sgqg.com",
                    style: const TextStyle(color: K.textMuted, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: K.accentSoft,
                  borderRadius: BorderRadius.circular(K.radiusXl),
                ),
                child: Text(
                  "Rôle : ${user?.role.label ?? 'Administrateur'}",
                  style: const TextStyle(color: K.primary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _updateProfile,
          icon: const Icon(Icons.edit_rounded),
          label: const Text("Modifier le profil"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: const BorderSide(color: K.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(K.radiusSm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMobile(UserModel? user) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: K.primary,
              child: Text(
                user?.username[0].toUpperCase() ?? "A",
                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.nom ?? "Administrateur",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: K.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? "admin@sgqg.com",
                    style: const TextStyle(color: K.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: K.accentSoft,
                      borderRadius: BorderRadius.circular(K.radiusXl),
                    ),
                    child: Text(
                      "Rôle : ${user?.role.label ?? 'Administrateur'}",
                      style: const TextStyle(color: K.primary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _updateProfile,
            icon: const Icon(Icons.edit_rounded),
            label: const Text("Modifier le profil"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: K.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: K.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: K.bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: K.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: K.textMuted),
        onTap: onTap,
      ),
    );
  }
}