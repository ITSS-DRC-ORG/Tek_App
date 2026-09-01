import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/models/user_model.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

class CashierProfile extends StatefulWidget {
  const CashierProfile({super.key});

  @override
  State<CashierProfile> createState() => _CashierProfileState();
}

class _CashierProfileState extends State<CashierProfile> with SingleTickerProviderStateMixin {
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: K.surface,
          borderRadius: BorderRadius.circular(K.radius),
          border: Border.all(color: K.border),
          boxShadow: [K.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(user),
            const Divider(height: 24),
            _buildProfileInfo(user),
            if (_isEditing) _buildEditForm(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [K.primary, K.primary.withOpacity(0.7)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              user?.username.isNotEmpty == true
                  ? user!.username[0].toUpperCase()
                  : 'C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
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
                user?.nom ?? 'Caissier',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: K.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: K.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(K.radiusXl),
                    ),
                    child: Text(
                      user?.role.label ?? 'Caissier',
                      style: const TextStyle(
                        color: K.primary,
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
                        color: K.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(K.radiusXl),
                      ),
                      child: Text(
                        '🏢 ${user!.depotNom}',
                        style: const TextStyle(
                          color: K.info,
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
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Modifier'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: const BorderSide(color: K.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
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
                child: const Text('Annuler', style: TextStyle(color: K.textMuted)),
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
                  backgroundColor: K.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(K.radiusSm),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProfileInfo(UserModel? user) {
    return Column(
      children: [
        _buildInfoRow(Icons.email_rounded, 'Email', user?.email ?? 'Non défini'),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.person_rounded, 'Nom', user?.nom ?? 'Non défini'),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.person_outline_rounded, 'Prénom', user?.prenom ?? 'Non défini'),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.admin_panel_settings_rounded,
          'Rôle',
          user?.role.label ?? 'Non défini',
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: K.primary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: K.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: K.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: K.surfaceAlt,
        borderRadius: BorderRadius.circular(K.radiusSm),
        border: Border.all(color: K.border),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _nomCtrl,
            label: 'Nom',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _prenomCtrl,
            label: 'Prénom',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailCtrl,
            label: 'Email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
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
      style: const TextStyle(fontSize: 14, color: K.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: K.textMuted, size: 20),
        filled: true,
        fillColor: K.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusSm),
          borderSide: const BorderSide(color: K.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusSm),
          borderSide: const BorderSide(color: K.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}