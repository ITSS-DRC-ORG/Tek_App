import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

class StockSettings extends StatefulWidget {
  const StockSettings({super.key});

  @override
  State<StockSettings> createState() => _StockSettingsState();
}

class _StockSettingsState extends State<StockSettings> with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 400),
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
      _showSnackBar('Le nom et prénom sont requis', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user == null) {
        _showSnackBar('Utilisateur non connecté', Colors.red);
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
      _showSnackBar('✅ Profil mis à jour avec succès !', Colors.green);
      
    } catch (e) {
      _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
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
              color == Colors.green ? Icons.check_circle_rounded : 
              color == Colors.orange ? Icons.warning_rounded : 
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _K.surface,
          borderRadius: BorderRadius.circular(_K.radius),
          border: Border.all(color: _K.border),
          boxShadow: [_K.cardShadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(user),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profil utilisateur
                      _buildProfileCard(user),
                      const SizedBox(height: 24),
                      // Préférences
                      _buildPreferencesCard(),
                      const SizedBox(height: 24),
                      // Bouton de déconnexion
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------
  Widget _buildHeader(UserModel? user) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _K.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_K.radiusSm),
          ),
          child: const Icon(Icons.person_rounded, color: _K.primary, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mon Profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _K.textPrimary,
                ),
              ),
              Text(
                'Gérez vos informations personnelles',
                style: TextStyle(
                  color: _K.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (_isEditing)
          Row(
            children: [
              TextButton(
                onPressed: _isSaving ? null : () {
                  setState(() => _isEditing = false);
                  final user = Provider.of<AuthProvider>(context, listen: false).user;
                  if (user != null) {
                    _nomCtrl.text = user.nom;
                    _prenomCtrl.text = user.prenom;
                    _emailCtrl.text = user.email;
                  }
                },
                child: const Text('Annuler', style: TextStyle(color: _K.textMuted)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _K.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_K.radiusSm),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // CARTE DE PROFIL
  // ---------------------------------------------------------------------
  Widget _buildProfileCard(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _K.surfaceAlt,
        borderRadius: BorderRadius.circular(_K.radiusSm),
        border: Border.all(color: _K.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar et infos
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_K.primary, _K.primary.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user?.username.isNotEmpty == true
                        ? user!.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nom ?? 'Utilisateur',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _K.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'Email non défini',
                      style: const TextStyle(
                        color: _K.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _K.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(_K.radiusXl),
                          ),
                          child: Text(
                            user?.role.label ?? 'Rôle inconnu',
                            style: const TextStyle(
                              color: _K.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user?.depotNom != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _K.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(_K.radiusXl),
                            ),
                            child: Text(
                              '🏢 ${user!.depotNom}',
                              style: const TextStyle(
                                color: _K.info,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_isEditing)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _isEditing = true);
                  },
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Modifier'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    side: const BorderSide(color: _K.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_K.radiusSm),
                    ),
                  ),
                ),
            ],
          ),
          if (_isEditing) ...[
            const Divider(height: 24),
            const Text(
              'Modifier mes informations',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _K.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _nomCtrl,
                    label: 'Nom',
                    icon: Icons.person_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _prenomCtrl,
                    label: 'Prénom',
                    icon: Icons.person_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _K.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _K.textMuted, size: 20),
        filled: true,
        fillColor: _K.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_K.radiusSm),
          borderSide: const BorderSide(color: _K.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_K.radiusSm),
          borderSide: const BorderSide(color: _K.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PRÉFÉRENCES
  // ---------------------------------------------------------------------
  Widget _buildPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _K.surfaceAlt,
        borderRadius: BorderRadius.circular(_K.radiusSm),
        border: Border.all(color: _K.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: _K.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Préférences',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _K.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreferenceTile(
            icon: Icons.notifications_active_rounded,
            title: 'Alertes de stock',
            subtitle: 'Recevoir des alertes lorsque le stock est bas',
            value: _alertEnabled,
            onChanged: (value) => setState(() => _alertEnabled = value),
            activeColor: _K.success,
          ),
          const Divider(height: 20),
          _buildPreferenceTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Transfert automatique',
            subtitle: 'Transférer automatiquement vers les dépôts',
            value: _autoTransfert,
            onChanged: (value) => setState(() => _autoTransfert = value),
            activeColor: _K.info,
          ),
          const Divider(height: 20),
          _buildPreferenceTile(
            icon: Icons.email_rounded,
            title: 'Notifications par email',
            subtitle: 'Recevoir les rapports par email',
            value: _notifyEmail,
            onChanged: (value) => setState(() => _notifyEmail = value),
            activeColor: _K.primary,
          ),
          const Divider(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _K.surface,
                  borderRadius: BorderRadius.circular(_K.radiusXs),
                ),
                child: const Icon(Icons.warning_rounded, size: 20, color: _K.warning),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seuil d\'alerte',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _K.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Quantité minimale avant alerte',
                      style: TextStyle(
                        color: _K.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_alertThreshold > 1) {
                        setState(() => _alertThreshold--);
                      }
                    },
                    icon: const Icon(Icons.remove_rounded, color: _K.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: _K.surface,
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _K.surface,
                      border: Border.all(color: _K.border),
                      borderRadius: BorderRadius.circular(_K.radiusSm),
                    ),
                    child: Text(
                      '$_alertThreshold',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _K.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() => _alertThreshold++);
                    },
                    icon: const Icon(Icons.add_rounded, color: _K.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: _K.surface,
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showSnackBar('✅ Préférences enregistrées avec succès !', Colors.green);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _K.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_K.radiusSm),
                ),
                elevation: 0,
              ),
              child: const Text('Enregistrer les préférences'),
            ),
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
    required Color activeColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _K.surface,
            borderRadius: BorderRadius.circular(_K.radiusXs),
          ),
          child: Icon(icon, size: 20, color: _K.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _K.textPrimary,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _K.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          inactiveThumbColor: _K.textMuted,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // BOUTON DE DÉCONNEXION
  // ---------------------------------------------------------------------
  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _K.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(_K.radiusSm),
        border: Border.all(color: _K.danger.withOpacity(0.2)),
      ),
      child: TextButton.icon(
        onPressed: () {
          _showLogoutConfirmation();
        },
        icon: const Icon(Icons.logout_rounded, color: _K.danger),
        label: const Text(
          'Se déconnecter',
          style: TextStyle(
            color: _K.danger,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_K.radiusSm),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_K.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _K.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: _K.danger, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Déconnexion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _K.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: _K.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _K.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_K.radiusSm),
              ),
            ),
            child: const Text('Se déconnecter'),
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

// ---------------------------------------------------------------------
// TOKENS DE DESIGN
// ---------------------------------------------------------------------
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
}