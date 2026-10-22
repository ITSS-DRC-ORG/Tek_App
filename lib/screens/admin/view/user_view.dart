import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tek_app/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../api/admin_service.dart';
import '../../../models/depot_model.dart';

class UserView extends StatefulWidget {
  final AdminService service;
  const UserView({super.key, required this.service});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  List<UserModel> _filteredUsers = [];
  List<UserModel> _allUsers = [];

  // Contrôleurs formulaire
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _prenomCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.vendeur;
  int? _selectedDepotId;
  bool _isActif = true;
  bool _isLoading = false;
  int? _editingUserId;

  // Cache des dépôts
  List<Depot> _depots = [];
  bool _depotsLoaded = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadDepots();
  }

  Future<void> _loadDepots() async {
    try {
      final depots = await widget.service.getDepots();
      if (mounted) {
        setState(() {
          _depots = depots;
          _depotsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _depotsLoaded = true);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _passwordCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = query.isEmpty
          ? _allUsers
          : _allUsers.where((user) {
        final q = query.toLowerCase();
        return user.username.toLowerCase().contains(q) ||
            user.nom.toLowerCase().contains(q) ||
            user.email.toLowerCase().contains(q);
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // CREATE (Inchangé)
  // ---------------------------------------------------------------------------
  Future<void> _createUser() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showSnackBar('Nom d\'utilisateur et mot de passe requis', const Color(0xFFC42B1C));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final newUser = await widget.service.createUser(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: _selectedRole,
        depotId: _selectedDepotId,
        actif: _isActif,
      );
      if (!mounted) return;
      await _animationController.reverse();
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Utilisateur ${newUser.username} créé avec succès !', const Color(0xFF107C41));
      _refreshUsers();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // READ (Inchangé)
  // ---------------------------------------------------------------------------
  Future<void> _refreshUsers() async {
    try {
      final users = await widget.service.getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filterUsers(_searchCtrl.text);
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur lors du chargement des utilisateurs', const Color(0xFFC42B1C));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE (Inchangé)
  // ---------------------------------------------------------------------------
  Future<void> _updateUser() async {
    if (_usernameCtrl.text.isEmpty) {
      _showSnackBar('Nom d\'utilisateur requis', const Color(0xFFC42B1C));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final updatedUser = await widget.service.updateUser(
        _editingUserId!,
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        role: _selectedRole,
        depotId: _selectedDepotId,
        actif: _isActif,
      );
      if (!mounted) return;
      await _animationController.reverse();
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Utilisateur ${updatedUser.username} modifié avec succès !', const Color(0xFF107C41));
      _refreshUsers();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE (Dialogue Windows 11)
  // ---------------------------------------------------------------------------
  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFC42B1C),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirmer la suppression',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer le compte "${user.username}" ?\nCette opération est définitive et révoquera immédiatement ses accès.',
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF5F6368),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4A4A4A),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Supprimer le compte',
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

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await widget.service.deleteUser(user.id);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Utilisateur "${user.username}" supprimé avec succès', const Color(0xFF107C41));
        _refreshUsers();
      } else {
        _showSnackBar('Erreur lors de la suppression', const Color(0xFFC42B1C));
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', const Color(0xFFC42B1C));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // DIALOGUE CRÉATION / MODIFICATION (Design Windows 11 Fluent)
  // ---------------------------------------------------------------------------
  void _showUserDialog({UserModel? user}) {
    final isEditing = user != null;

    if (isEditing) {
      _usernameCtrl.text = user.username;
      _emailCtrl.text = user.email;
      _nomCtrl.text = user.nom;
      _prenomCtrl.text = user.prenom;
      _passwordCtrl.text = '';
      _selectedRole = user.role;
      _selectedDepotId = user.depotId;
      _isActif = user.actif;
      _editingUserId = user.id;
    } else {
      _usernameCtrl.clear();
      _emailCtrl.clear();
      _nomCtrl.clear();
      _prenomCtrl.clear();
      _passwordCtrl.clear();
      _selectedRole = UserRole.vendeur;
      _selectedDepotId = null;
      _isActif = true;
      _editingUserId = null;
    }
    _isLoading = false;

    final isWide = MediaQuery.of(context).size.width >= 900;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        _animationController.reset();
        _animationController.forward();

        return WillPopScope(
          onWillPop: () async {
            await _animationController.reverse();
            return true;
          },
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Dialog(
                elevation: 0,
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  width: isWide ? 560 : double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                    maxWidth: 560,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x18000000), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 28,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // En-tête du dialogue
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 18, 16, 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F2FB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isEditing
                                          ? Icons.manage_accounts_rounded
                                          : Icons.person_add_alt_1_rounded,
                                      color: const Color(0xFF0067C0),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEditing
                                            ? 'Modifier l\'utilisateur'
                                            : 'Nouvel utilisateur',
                                        style: const TextStyle(
                                          fontFamily: kAppFontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isEditing
                                            ? 'Mettre à jour les accès et permissions'
                                            : 'Renseignez les accès de connexion',
                                        style: const TextStyle(
                                          fontFamily: kAppFontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    splashRadius: 16,
                                    icon: const Icon(Icons.close_rounded, size: 19),
                                    color: const Color(0xFF64748B),
                                    onPressed: () async {
                                      await _animationController.reverse();
                                      if (mounted) Navigator.pop(dialogContext);
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 1, thickness: 1, color: Color(0x14000000)),

                            // Formulaire
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormSectionHeader('ACCÈS & IDENTIFIANTS', Icons.lock_outline_rounded),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      controller: _usernameCtrl,
                                      label: 'Nom d\'utilisateur',
                                      hint: 'ex: jdupont',
                                      icon: Icons.person_outline_rounded,
                                      isRequired: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _emailCtrl,
                                      label: 'Email professionnel',
                                      hint: 'ex: jdupont@entreprise.com',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _passwordCtrl,
                                      label: isEditing ? 'Nouveau mot de passe (optionnel)' : 'Mot de passe',
                                      hint: '••••••••',
                                      icon: Icons.key_rounded,
                                      isRequired: !isEditing,
                                      obscureText: true,
                                    ),

                                    const SizedBox(height: 20),
                                    _buildFormSectionHeader('IDENTITÉ', Icons.badge_outlined),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _prenomCtrl,
                                            label: 'Prénom',
                                            hint: 'ex: Jean',
                                            icon: Icons.badge_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _nomCtrl,
                                            label: 'Nom',
                                            hint: 'ex: Dupont',
                                            icon: Icons.badge_outlined,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),
                                    _buildFormSectionHeader('AFFECTATION & PERMISSIONS', Icons.admin_panel_settings_outlined),
                                    const SizedBox(height: 10),

                                    // Sélecteur de Rôle
                                    _buildFieldHeader('RÔLE APPLICATIF'),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<UserRole>(
                                      value: _selectedRole,
                                      dropdownColor: const Color(0xFFFFFFFF),
                                      style: const TextStyle(
                                        fontFamily: kAppFontFamily,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF0F172A),
                                      ),
                                      decoration: _buildDropdownDecoration(Icons.shield_outlined),
                                      items: UserRole.values.map((role) {
                                        return DropdownMenuItem(
                                          value: role,
                                          child: Text(
                                            _getRoleLabel(role),
                                            style: const TextStyle(
                                              fontFamily: kAppFontFamily,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) setStateDialog(() => _selectedRole = value);
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Sélecteur de Dépôt
                                    _buildFieldHeader('DÉPÔT RATTACHÉ'),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<int?>(
                                      value: _selectedDepotId,
                                      dropdownColor: const Color(0xFFFFFFFF),
                                      style: const TextStyle(
                                        fontFamily: kAppFontFamily,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF0F172A),
                                      ),
                                      hint: const Text(
                                        'Sélectionner un dépôt (optionnel)',
                                        style: TextStyle(
                                          fontFamily: kAppFontFamily,
                                          color: Color(0xFFA0AEC0),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      decoration: _buildDropdownDecoration(Icons.warehouse_outlined),
                                      items: [
                                        const DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text(
                                            'Aucun dépôt attribué',
                                            style: TextStyle(
                                              fontFamily: kAppFontFamily,
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        ..._depots.map((depot) {
                                          return DropdownMenuItem<int?>(
                                            value: depot.id,
                                            child: Text(
                                              depot.nom,
                                              style: const TextStyle(
                                                fontFamily: kAppFontFamily,
                                                fontSize: 13,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                      onChanged: (value) => setStateDialog(() => _selectedDepotId = value),
                                    ),
                                    const SizedBox(height: 16),

                                    // Carte Statut Actif
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0x14000000)),
                                      ),
                                      child: SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                          'Compte actif',
                                          style: TextStyle(
                                            fontFamily: kAppFontFamily,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                            fontSize: 13,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _isActif ? 'L\'utilisateur peut se connecter' : 'Le compte est suspendu',
                                          style: const TextStyle(
                                            fontFamily: kAppFontFamily,
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        value: _isActif,
                                        activeColor: const Color(0xFF0067C0),
                                        onChanged: (value) => setStateDialog(() => _isActif = value),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Divider(height: 1, thickness: 1, color: Color(0x14000000)),

                            // Pied de dialogue
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                      await _animationController.reverse();
                                      if (mounted) Navigator.pop(dialogContext);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF475569),
                                      side: const BorderSide(color: Color(0x20000000)),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : (isEditing ? _updateUser : _createUser),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0067C0),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
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
                                        : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isEditing ? Icons.save_rounded : Icons.check_rounded, size: 17),
                                        const SizedBox(width: 6),
                                        Text(
                                          isEditing ? 'Enregistrer' : 'Créer l\'utilisateur',
                                          style: const TextStyle(
                                            fontFamily: kAppFontFamily,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _animationController.reset();
    });
  }

  // ---------------------------------------------------------------------------
  // HELPERS UI
  // ---------------------------------------------------------------------------
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

  Widget _buildFormSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF0067C0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.6,
          ),
        ),
      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildFieldHeader(label.toUpperCase()),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Color(0xFFC42B1C), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
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

  InputDecoration _buildDropdownDecoration(IconData icon) {
    return InputDecoration(
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
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.vendeur:
        return 'Vendeur';
      case UserRole.caissier:
        return 'Caissier';
      case UserRole.gestionnaire:
        return 'Gestionnaire';
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD PRINCIPAL AVEC FUTUREBUILDER
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return FutureBuilder<List<UserModel>>(
      future: widget.service.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0067C0), strokeWidth: 2.2),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFC42B1C)),
                const SizedBox(height: 12),
                Text(
                  "Erreur: ${snapshot.error}",
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFFC42B1C),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshUsers,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0067C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          );
        }

        _allUsers = snapshot.data ?? [];
        _filteredUsers = _searchCtrl.text.isEmpty
            ? _allUsers
            : _allUsers.where((u) {
          final q = _searchCtrl.text.toLowerCase();
          return u.username.toLowerCase().contains(q) ||
              u.nom.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Indicateurs Synthétiques avec Ondes Fluides
            _buildUserMetricsRow(),
            const SizedBox(height: 18),

            // 2. Barre d'outils
            _buildActionBar(isWide),
            const SizedBox(height: 14),

            // 3. Tableau de données
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
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
                child: _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : isWide
                    ? _buildDesktopTable()
                    : _buildMobileDataRows(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. LES CARTES DE MÉTRIQUES STYLISÉES AVEC ONDES FLUIDES (WINDOWS BLOOM)
  // ---------------------------------------------------------------------------
  Widget _buildUserMetricsRow() {
    final total = _allUsers.length;
    final actifs = _allUsers.where((u) => u.actif).length;
    final admins = _allUsers.where((u) => u.role == UserRole.admin).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 740;

        final cards = [
          _buildWaveMetricCard(
            title: "TOTAL UTILISATEURS",
            value: "$total",
            subtitle: "Comptes enregistrés",
            badge: "Équipe",
            icon: Icons.people_outline_rounded,
            gradient: const [
              Color(0xFF004E8C),
              Color(0xFF0067C0),
              Color(0xFF2886DE),
            ],
            waveSeed: 1.2,
          ),
          _buildWaveMetricCard(
            title: "COMPTES ACTIFS",
            value: "$actifs",
            subtitle: "Opérationnels en direct",
            badge: "Accès Valides",
            icon: Icons.verified_user_outlined,
            gradient: const [
              Color(0xFF0A3B5C),
              Color(0xFF165B8C),
              Color(0xFF3A89C9),
            ],
            waveSeed: 2.4,
          ),
          _buildWaveMetricCard(
            title: "ADMINISTRATEURS",
            value: "$admins",
            subtitle: "Privilèges complets",
            badge: "Supervision",
            icon: Icons.admin_panel_settings_outlined,
            gradient: const [
              Color(0xFF1E293B),
              Color(0xFF334155),
              Color(0xFF475569),
            ],
            waveSeed: 3.6,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[1],
              const SizedBox(height: 12),
              cards[2],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
            const SizedBox(width: 14),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _buildWaveMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required String badge,
    required IconData icon,
    required List<Color> gradient,
    required double waveSeed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x18000000), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bannière supérieure fluide
          SizedBox(
            height: 64,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: UserMetricWavePainter(waveSeed: waveSeed),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icon, color: Colors.white, size: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pied de carte blanc
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF94A3B8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.more_horiz_rounded,
                  size: 16,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. BARRE D'ACTIONS
  // ---------------------------------------------------------------------------
  Widget _buildActionBar(bool isWide) {
    return Row(
      children: [
        Expanded(
          flex: isWide ? 0 : 1,
          child: SizedBox(
            width: isWide ? 310 : null,
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filterUsers,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1F1F1F),
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher par identifiant, nom, email...',
                hintStyle: const TextStyle(
                  fontFamily: kAppFontFamily,
                  color: Color(0xFF9CA3AF),
                  fontSize: 12.5,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6B7280),
                  size: 18,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  splashRadius: 14,
                  icon: const Icon(Icons.clear_rounded, size: 15, color: Color(0xFF6B7280)),
                  onPressed: () {
                    _searchCtrl.clear();
                    _filterUsers('');
                  },
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x18000000), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x18000000), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0067C0), width: 1.5),
                ),
              ),
            ),
          ),
        ),

        if (isWide) ...[
          const SizedBox(width: 14),
          Text(
            "${_filteredUsers.length} sur ${_allUsers.length} compte(s)",
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
        ],

        const Spacer(),

        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: () => _showUserDialog(),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
            label: Text(isWide ? "Nouvel Utilisateur" : "Ajouter"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0067C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TABLEAU DESKTOP HAUTE LISIBILITÉ
  // ---------------------------------------------------------------------------
  Widget _buildDesktopTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingRowHeight: 42,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
                horizontalMargin: 20,
                columnSpacing: 26,
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text("ID", style: _headerStyle)),
                  DataColumn(label: Text("UTILISATEUR", style: _headerStyle)),
                  DataColumn(label: Text("NOM COMPLET", style: _headerStyle)),
                  DataColumn(label: Text("RÔLE APPLICATIF", style: _headerStyle)),
                  DataColumn(label: Text("STATUT", style: _headerStyle)),
                  DataColumn(label: Text("ACTIONS", style: _headerStyle)),
                ],
                rows: _filteredUsers.map((user) {
                  return DataRow(
                    cells: [
                      // ID
                      DataCell(
                        Text(
                          '#${user.id}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Utilisateur (Avatar + Username + Email)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: const Color(0xFFE8F2FB),
                              child: Text(
                                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  color: Color(0xFF0067C0),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.username,
                                  style: const TextStyle(
                                    fontFamily: kAppFontFamily,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    fontSize: 13,
                                  ),
                                ),
                                if (user.email.isNotEmpty)
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      fontFamily: kAppFontFamily,
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Nom complet
                      DataCell(
                        Text(
                          '${user.prenom} ${user.nom}'.trim().isEmpty ? '—' : '${user.prenom} ${user.nom}',
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1E293B),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Rôle (Badge sobre)
                      DataCell(_buildRoleBadge(user.role)),

                      // Statut
                      DataCell(_buildStatusBadge(user.actif)),

                      // Actions
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF0067C0),
                                size: 17,
                              ),
                              splashRadius: 14,
                              tooltip: 'Modifier',
                              onPressed: () => _showUserDialog(user: user),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFC42B1C),
                                size: 17,
                              ),
                              splashRadius: 14,
                              tooltip: 'Supprimer',
                              onPressed: () => _deleteUser(user),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
    letterSpacing: 0.6,
  );

  // ---------------------------------------------------------------------------
  // 4. LIGNES MOBILE
  // ---------------------------------------------------------------------------
  Widget _buildMobileDataRows() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredUsers.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x12000000)),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE8F2FB),
                child: Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    color: Color(0xFF0067C0),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${user.prenom} ${user.nom}',
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildRoleBadge(user.role),
                        const SizedBox(width: 8),
                        _buildStatusBadge(user.actif),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF0067C0), size: 18),
                    onPressed: () => _showUserDialog(user: user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC42B1C), size: 18),
                    onPressed: () => _deleteUser(user),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BADGES (Rôle & Statut)
  // ---------------------------------------------------------------------------
  Widget _buildRoleBadge(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x10000000)),
      ),
      child: Text(
        _getRoleLabel(role),
        style: const TextStyle(
          fontFamily: kAppFontFamily,
          color: Color(0xFF334155),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool actif) {
    final color = actif ? const Color(0xFF107C41) : const Color(0xFFC42B1C);
    final bgColor = actif ? const Color(0xFFE6F4EA) : const Color(0xFFFDE8E8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            actif ? 'Actif' : 'Inactif',
            style: TextStyle(
              fontFamily: kAppFontFamily,
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ÉTAT VIDE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.people_outline_rounded, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isEmpty ? 'Aucun utilisateur enregistré' : 'Aucun résultat trouvé',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Cliquez sur "Nouvel Utilisateur" pour créer le premier accès.'
                  : 'Modifiez vos critères de recherche.',
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  _searchCtrl.clear();
                  _filterUsers('');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0067C0),
                  side: const BorderSide(color: Color(0xFF0067C0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'Effacer le filtre',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTER VECTORIEL : ONDES FLUIDES DES CARTES UTILISATEURS
// ---------------------------------------------------------------------------
class UserMetricWavePainter extends CustomPainter {
  final double waveSeed;

  UserMetricWavePainter({required this.waveSeed});

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
  bool shouldRepaint(covariant UserMetricWavePainter oldDelegate) =>
      oldDelegate.waveSeed != waveSeed;
}