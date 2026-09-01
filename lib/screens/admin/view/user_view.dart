import 'package:flutter/material.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import '../../../models/user_model.dart';
import '../../../api/admin_service.dart';
import '../../../models/depot_model.dart';

class UserView extends StatefulWidget {
  final AdminService service;
  const UserView({super.key, required this.service});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  List<UserModel> _filteredUsers = [];
  List<UserModel> _allUsers = [];
  
  // Contrôleurs pour le formulaire
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

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
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
    if (query.isEmpty) {
      setState(() => _filteredUsers = _allUsers);
    } else {
      setState(() {
        _filteredUsers = _allUsers.where((user) =>
          user.username.toLowerCase().contains(query.toLowerCase()) ||
          user.nom.toLowerCase().contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase())
        ).toList();
      });
    }
  }

  // ---------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------
  Future<void> _createUser() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showSnackBar('Nom d\'utilisateur et mot de passe requis', K.danger);
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
      _showSnackBar('Utilisateur ${newUser.username} créé avec succès !', K.success);
      _refreshUsers();
      
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', K.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------
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
        _showSnackBar('Erreur lors du chargement des utilisateurs', K.danger);
      }
    }
  }

  // ---------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------
  Future<void> _updateUser() async {
    if (_usernameCtrl.text.isEmpty) {
      _showSnackBar('Nom d\'utilisateur requis', K.danger);
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
      _showSnackBar('Utilisateur ${updatedUser.username} modifié avec succès !', K.success);
      _refreshUsers();
      
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', K.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------
  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.radiusXl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: K.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, color: K.danger, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Confirmer la suppression'),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer l\'utilisateur "${user.username}" ?\nCette action est irréversible.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: K.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: K.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
            ),
            child: const Text('Supprimer'),
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
        _showSnackBar('Utilisateur "${user.username}" supprimé avec succès', K.success);
        _refreshUsers();
      } else {
        _showSnackBar('Erreur lors de la suppression', K.danger);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: ${e.toString()}', K.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // SHOW DIALOG (Create/Update)
  // ---------------------------------------------------------------------
  void _showUserDialog({UserModel? user}) {
    final isEditing = user != null;
    
    if (isEditing) {
      _usernameCtrl.text = user.username;
      _emailCtrl.text = user.email;
      _nomCtrl.text = user.nom;
      _prenomCtrl.text = user.prenom;
      _passwordCtrl.text = '********';
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
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
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
                child: Container(
                  width: isWide ? 600 : double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                    maxWidth: 600,
                  ),
                  decoration: BoxDecoration(
                    color: K.surface,
                    borderRadius: BorderRadius.circular(K.radiusXl),
                    border: Border.all(color: K.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(K.radiusXl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header avec gradient
                            Container(
                              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [K.primary, K.primary.withOpacity(0.8)],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(K.radiusSm),
                                    ),
                                    child: Icon(
                                      isEditing ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isEditing ? 'Modifier l\'Utilisateur' : 'Nouvel Utilisateur',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          isEditing ? 'Modifiez les informations de l\'utilisateur' : 'Remplissez les informations ci-dessous',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                                      onPressed: () async {
                                        await _animationController.reverse();
                                        if (mounted) Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Formulaire scrollable
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Informations de connexion
                                    _buildSectionTitle('Informations de connexion', Icons.login_rounded),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _usernameCtrl,
                                      hint: 'Nom d\'utilisateur',
                                      icon: Icons.person_outline_rounded,
                                      isRequired: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _emailCtrl,
                                      hint: 'Email',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _passwordCtrl,
                                      hint: isEditing ? 'Nouveau mot de passe (optionnel)' : 'Mot de passe',
                                      icon: Icons.lock_outline_rounded,
                                      isRequired: !isEditing,
                                      obscureText: true,
                                    ),
                                    const SizedBox(height: 24),

                                    // Informations personnelles
                                    _buildSectionTitle('Informations personnelles', Icons.person_outline_rounded),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _nomCtrl,
                                            hint: 'Nom',
                                            icon: Icons.badge_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _prenomCtrl,
                                            hint: 'Prénom',
                                            icon: Icons.badge_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Attributions
                                    _buildSectionTitle('Attributions', Icons.admin_panel_settings_rounded),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<UserRole>(
                                      value: _selectedRole,
                                      decoration: _buildDropdownDecoration('Rôle', Icons.admin_panel_settings_rounded),
                                      items: UserRole.values.map((role) {
                                        return DropdownMenuItem(
                                          value: role,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: _getRoleColor(role),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(_getRoleLabel(role)),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) setState(() => _selectedRole = value);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    FutureBuilder<List<Depot>>(
                                      future: widget.service.getDepots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Container(
                                            height: 56,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: K.surfaceAlt,
                                              borderRadius: BorderRadius.circular(K.radiusSm),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.warehouse_rounded, color: K.textMuted),
                                                const SizedBox(width: 12),
                                                const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: K.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  'Chargement des dépôts...',
                                                  style: TextStyle(color: K.textMuted, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        final depots = snapshot.data ?? [];
                                        return DropdownButtonFormField<int?>(
                                          value: _selectedDepotId,
                                          hint: const Text('Sélectionner un dépôt (optionnel)'),
                                          decoration: _buildDropdownDecoration('Dépôt', Icons.warehouse_rounded),
                                          items: [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text('Aucun dépôt'),
                                            ),
                                            ...depots.map((depot) {
                                              return DropdownMenuItem(
                                                value: depot.id,
                                                child: Text(depot.nom),
                                              );
                                            }),
                                          ],
                                          onChanged: (value) {
                                            setState(() => _selectedDepotId = value);
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Statut actif
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: K.surfaceAlt,
                                        borderRadius: BorderRadius.circular(K.radiusSm),
                                      ),
                                      child: SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                          'Compte actif',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: K.textPrimary,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _isActif ? 'L\'utilisateur peut se connecter' : 'Le compte est désactivé',
                                          style: const TextStyle(fontSize: 12, color: K.textMuted),
                                        ),
                                        value: _isActif,
                                        activeColor: K.success,
                                        inactiveThumbColor: K.danger,
                                        activeTrackColor: K.success.withOpacity(0.3),
                                        inactiveTrackColor: K.danger.withOpacity(0.2),
                                        onChanged: (value) => setState(() => _isActif = value),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Footer avec boutons
                            Container(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: K.border, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isLoading ? null : () async {
                                        await _animationController.reverse();
                                        if (mounted) Navigator.pop(context);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: const BorderSide(color: K.border),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(K.radiusSm),
                                        ),
                                      ),
                                      child: const Text(
                                        'Annuler',
                                        style: TextStyle(color: K.textMuted),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : (isEditing ? _updateUser : _createUser),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: K.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(K.radiusSm),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation(Colors.white),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(isEditing ? Icons.save_rounded : Icons.check_rounded, size: 20),
                                                const SizedBox(width: 8),
                                                Text(isEditing ? 'Modifier' : 'Créer'),
                                              ],
                                            ),
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

  // ---------------------------------------------------------------------
  // WIDGETS D'AIDE
  // ---------------------------------------------------------------------
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: K.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: K.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: K.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: K.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: K.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: K.textMuted, size: 20),
        suffixIcon: isRequired
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.star_rounded,
                  color: K.danger,
                  size: 12,
                ),
              )
            : null,
        filled: true,
        fillColor: K.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusSm),
          borderSide: const BorderSide(color: K.primary, width: 1.5),
        ),
      ),
    );
  }

  InputDecoration _buildDropdownDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: K.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: K.textMuted, size: 20),
      filled: true,
      fillColor: K.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(K.radiusSm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(K.radiusSm),
        borderSide: const BorderSide(color: K.primary, width: 1.5),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return K.danger;
      case UserRole.vendeur: return K.info;
      case UserRole.caissier: return K.success;
      case UserRole.magasinier: return Colors.orange;
      case UserRole.gestionnaire_depot: return Colors.purple;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Administrateur';
      case UserRole.vendeur: return 'Vendeur';
      case UserRole.caissier: return 'Caissier';
      case UserRole.magasinier: return 'Magasinier';
      case UserRole.gestionnaire_depot: return 'Gestionnaire de dépôt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return FutureBuilder<List<UserModel>>(
      future: widget.service.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: K.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: K.danger),
                const SizedBox(height: 12),
                Text(
                  "Erreur: ${snapshot.error}",
                  style: const TextStyle(color: K.danger, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshUsers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: K.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        _allUsers = snapshot.data ?? [];
        if (_filteredUsers.isEmpty && _searchCtrl.text.isEmpty) {
          _filteredUsers = _allUsers;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide)
              _buildDesktopHeader()
            else
              _buildMobileHeader(),
            const SizedBox(height: 25),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: K.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: K.border),
                  boxShadow: [K.cardShadow],
                ),
                child: _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : isWide
                        ? _buildDesktopTable()
                        : _buildMobileList(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // HEADERS
  // ---------------------------------------------------------------------
  Widget _buildDesktopHeader() {
    final activeUsers = _allUsers.where((u) => u.actif).length;
    return Row(
      children: [
        StatChip(
          icon: Icons.people_alt_rounded, 
          label: 'Utilisateurs', 
          value: '${_allUsers.length}', 
          color: K.info
        ),
        const SizedBox(width: 12),
        StatChip(
          icon: Icons.verified_user_rounded, 
          label: 'Comptes Actifs', 
          value: '$activeUsers',
          color: K.success
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _showUserDialog,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('Nouvel Utilisateur'),
          style: ElevatedButton.styleFrom(
            backgroundColor: K.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final activeUsers = _allUsers.where((u) => u.actif).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              StatChip(
                icon: Icons.people_alt_rounded, 
                label: 'Total', 
                value: '${_allUsers.length}', 
                color: K.info
              ),
              const SizedBox(width: 10),
              StatChip(
                icon: Icons.verified_user_rounded, 
                label: 'Actifs', 
                value: '$activeUsers',
                color: K.success
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          onChanged: _filterUsers,
          decoration: InputDecoration(
            hintText: 'Rechercher un utilisateur...',
            hintStyle: const TextStyle(color: K.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: K.textMuted, size: 20),
            filled: true,
            fillColor: K.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(K.radiusSm),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showUserDialog,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Nouvel Utilisateur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: K.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // TABLE DESKTOP
  // ---------------------------------------------------------------------
 Widget _buildDesktopTable() {
  return SingleChildScrollView(
    child: DataTable(
      headingRowColor: MaterialStateProperty.all(K.surfaceAlt),
      horizontalMargin: 20,
      columnSpacing: 30,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 56,
      columns: const [
        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Utilisateur', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Nom complet', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Rôle', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
        // ✅ Supprimer 'numeric: true'
        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: _filteredUsers.map((user) {
        final isEven = _filteredUsers.indexOf(user).isEven;
        return DataRow(
          color: MaterialStateProperty.all(isEven ? K.surface : K.bg.withOpacity(0.4)),
          cells: [
            DataCell(Text('#${user.id}', style: const TextStyle(color: K.textMuted, fontSize: 12))),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: K.accentSoft,
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: const TextStyle(color: K.primary, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            DataCell(Text('${user.prenom} ${user.nom}')),
            DataCell(_buildRoleBadge(user.role)),
            DataCell(_buildStatusBadge(user.actif)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: K.info, size: 18),
                    onPressed: () => _showUserDialog(user: user),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: K.danger, size: 18),
                    onPressed: () => _deleteUser(user),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    ),
  );
}
  // ---------------------------------------------------------------------
  // LISTE MOBILE
  // ---------------------------------------------------------------------
  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredUsers.length,
      separatorBuilder: (_, __) => const Divider(color: K.border, height: 1),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: K.accentSoft,
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
              style: const TextStyle(color: K.primary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          title: Text(
            user.username,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user.prenom} ${user.nom}', style: const TextStyle(color: K.textMuted, fontSize: 13)),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: K.info, size: 20),
                onPressed: () => _showUserDialog(user: user),
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: K.danger, size: 20),
                onPressed: () => _deleteUser(user),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // BADGES
  // ---------------------------------------------------------------------
  Widget _buildRoleBadge(UserRole role) {
    final color = _getRoleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getRoleLabel(role).toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(bool actif) {
    final color = actif ? K.success : K.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          actif ? 'Actif' : 'Inactif',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // ÉTATS
  // ---------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchCtrl.text.isEmpty ? Icons.people_outline_rounded : Icons.search_off_rounded,
            size: 48,
            color: K.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            _searchCtrl.text.isEmpty ? 'Aucun utilisateur enregistré' : 'Aucun résultat trouvé',
            style: const TextStyle(color: K.textMuted, fontSize: 14),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                _filterUsers('');
              },
              child: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }
}