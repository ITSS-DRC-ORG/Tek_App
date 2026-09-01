import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/screens/admin/admin_components.dart';
import '../../providers/auth_provider.dart';
import '../../api/admin_service.dart';

class CashierClients extends StatefulWidget {
  const CashierClients({super.key});

  @override
  State<CashierClients> createState() => _CashierClientsState();
}

class _CashierClientsState extends State<CashierClients> {
  bool _isLoading = true;
  List<dynamic> _clients = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final clients = await service.getClients();
        setState(() {
          _clients = clients;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(K.radius),
        border: Border.all(color: K.border),
        boxShadow: [K.cardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Clients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: K.textPrimary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
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
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Nouveau Client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: K.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(K.radiusSm),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: K.primary))
                  : _clients.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_rounded, size: 64, color: K.textMuted),
                              SizedBox(height: 16),
                              Text(
                                'Aucun client enregistré',
                                style: TextStyle(color: K.textMuted, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Ajoutez votre premier client',
                                style: TextStyle(color: K.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _clients.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final client = _clients[index];
                            final name = client['nom'] as String? ?? '';
                            final phone = client['telephone'] as String? ?? '';
                            final email = client['email'] as String? ?? '';
                            
                            // Filtrage
                            final query = _searchCtrl.text.toLowerCase();
                            if (query.isNotEmpty &&
                                !name.toLowerCase().contains(query) &&
                                !phone.contains(query) &&
                                !email.toLowerCase().contains(query)) {
                              return const SizedBox.shrink();
                            }

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: K.surfaceAlt,
                                borderRadius: BorderRadius.circular(K.radiusSm),
                                border: Border.all(color: K.border),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: K.accentSoft,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: K.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: K.textPrimary,
                                          ),
                                        ),
                                        if (phone.isNotEmpty)
                                          Text(
                                            phone,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: K.textMuted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (email.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: K.info.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(K.radiusXl),
                                      ),
                                      child: Text(
                                        email,
                                        style: const TextStyle(
                                          color: K.info,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}