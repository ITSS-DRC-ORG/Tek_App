import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tek_app/api/admin_service.dart';
import 'package:tek_app/providers/auth_provider.dart';
import 'package:tek_app/screens/cashier/cashier_sales.dart';

/// ---------------------------------------------------------------------------
/// TOKENS DE DESIGN — palette officielle de l'application
/// ---------------------------------------------------------------------------
class K {
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

  static const sidebarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF37474F), Color(0xFF546E7A)],
  );

  static const Duration anim = Duration(milliseconds: 280);
  static const double radius = 16.0;
  static const double radiusSm = 10.0;  // <-- AJOUTÉ
  static const double radiusXs = 6.0;
  static const double radiusXl = 20.0;

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.055),
        blurRadius: 18,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      );

  static BoxShadow get subtleShadow => BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );
}

class InvoiceValidationView extends StatefulWidget {
  const InvoiceValidationView({super.key});

  @override
  State<InvoiceValidationView> createState() => _InvoiceValidationViewState();
}

class _InvoiceValidationViewState extends State<InvoiceValidationView> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  List<Map<String, dynamic>> _pendingInvoices = [];

  @override
  void initState() {
    super.initState();
    _loadPendingInvoices();
  }

  Future<void> _loadPendingInvoices() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final service = AdminService(user.token);
        final sales = await service.getSales(statut: 'en_cours');
        setState(() {
          _pendingInvoices = sales.map((s) => s as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle_rounded : Icons.error_outline_rounded,
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
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: K.primary))
                : _pendingInvoices.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: _pendingInvoices.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final invoice = _pendingInvoices[index];
                          return _buildInvoiceCard(invoice);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: K.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(K.radiusSm),
          ),
          child: const Icon(Icons.check_circle_rounded, color: K.success, size: 24),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validation des factures',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: K.textPrimary,
              ),
            ),
            Text(
              'Validez les factures en attente',
              style: TextStyle(
                color: K.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: K.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(K.radiusXl),
          ),
          child: Text(
            '${_pendingInvoices.length} en attente',
            style: const TextStyle(
              color: K.info,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final total = double.tryParse(invoice['total_ttc']?.toString() ?? '0') ?? 0;
    final client = invoice['client_nom'] as String? ?? 'Client';
    final numero = invoice['numero_facture'] as String? ?? '';
    final date = invoice['created_at'] as String? ?? '';
    
    String formattedDate = '';
    try {
      final dateTime = DateTime.parse(date);
      formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      formattedDate = date.substring(0, 10);
    }

    // ✅ Encapsuler dans Material
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: K.surface,
          borderRadius: BorderRadius.circular(K.radiusSm),
          border: Border.all(color: K.border),
          boxShadow: [K.subtleShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: K.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(K.radiusSm),
                  ),
                  child: const Icon(Icons.pending_rounded, color: K.warning, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: K.textPrimary,
                        ),
                      ),
                      Text(
                        numero,
                        style: const TextStyle(
                          fontSize: 12,
                          color: K.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: K.success,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: K.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ✅ Bouton Voir avec Material
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CashierSales(initialFilter: 'en_cours'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(K.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: K.border),
                        borderRadius: BorderRadius.circular(K.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility_rounded, size: 16, color: K.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Voir',
                            style: TextStyle(
                              color: K.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ✅ Bouton Valider
               // Dans _buildInvoiceCard - Remplacer le bouton Valider

ElevatedButton.icon(
  onPressed: _isActionLoading ? null : () async {
    // ✅ Afficher le dialogue avec sélecteur de mode
    await _validateInvoiceWithModePicker(invoice);
  },
  icon: _isActionLoading
      ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
      : const Icon(Icons.check_circle_rounded, size: 16),
  label: Text(_isActionLoading ? '...' : 'Valider'),
  style: ElevatedButton.styleFrom(
    backgroundColor: K.success,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(K.radiusSm),
    ),
  ),
),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showValidationDialog(Map<String, dynamic> invoice) {
    final total = double.tryParse(invoice['total_ttc']?.toString() ?? '0') ?? 0;
    final client = invoice['client_nom'] as String? ?? 'Client';
    final numero = invoice['numero_facture'] as String? ?? '';

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: K.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: K.success),
            ),
            const SizedBox(width: 12),
            const Text(
              'Valider la facture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: K.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous valider la facture $numero ?',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: K.surfaceAlt,
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Client', client),
                  _buildInfoRow('Montant', '\$${total.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: K.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: K.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.radiusSm),
              ),
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: K.textMuted,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: K.textPrimary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Dans InvoiceValidationView - Modifier _validateInvoice

Future<void> _validateInvoice(Map<String, dynamic> invoice) async {
  setState(() => _isActionLoading = true);
  try {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      _showSnackBar('Utilisateur non connecté', Colors.red);
      return;
    }

    final service = AdminService(user.token);
    
    // ✅ Utiliser la méthode avec mode_paiement
    final result = await service.validateInvoiceWithMode(
      invoice['id'] as int,
      modePaiement: 'especes', // ou récupérer depuis un sélecteur
    );

    if (result['success'] == true) {
      _showSnackBar('✅ Facture validée avec succès', Colors.green);
      _loadPendingInvoices();
    } else {
      _showSnackBar('❌ ${result['message'] ?? 'Erreur de validation'}', Colors.red);
    }
  } catch (e) {
    _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
  } finally {
    setState(() => _isActionLoading = false);
  }
}
// Dans InvoiceValidationView - Ajouter un sélecteur de mode paiement

Future<void> _validateInvoiceWithModePicker(Map<String, dynamic> invoice) async {
  String selectedMode = 'especes';
  
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(K.radiusXl),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: K.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment_rounded, color: K.success),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mode de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: K.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sélectionnez le mode de paiement :',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: K.border),
                  borderRadius: BorderRadius.circular(K.radiusSm),
                ),
                child: DropdownButton<String>(
                  value: selectedMode,
                  isExpanded: true,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 'especes', child: Text('💰 Espèces')),
                    DropdownMenuItem(value: 'carte', child: Text('💳 Carte bancaire')),
                    DropdownMenuItem(value: 'mobile_money', child: Text('📱 Mobile Money')),
                    DropdownMenuItem(value: 'cheque', child: Text('📝 Chèque')),
                    DropdownMenuItem(value: 'transfert', child: Text('🏦 Virement bancaire')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedMode = value);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(color: K.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: K.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(K.radiusSm),
                ),
              ),
              child: const Text('Valider'),
            ),
          ],
        );
      },
    ),
  );

  if (result == true) {
    // Appeler la validation avec le mode sélectionné
    await _validateInvoiceWithMode(invoice, selectedMode);
  }
}

// Nouvelle méthode de validation avec mode
Future<void> _validateInvoiceWithMode(Map<String, dynamic> invoice, String mode) async {
  setState(() => _isActionLoading = true);
  try {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      _showSnackBar('Utilisateur non connecté', Colors.red);
      return;
    }

    final service = AdminService(user.token);
    final result = await service.validateInvoiceWithMode(
      invoice['id'] as int,
      modePaiement: mode,
    );

    if (result['success'] == true) {
      _showSnackBar('✅ Facture validée avec succès', Colors.green);
      _loadPendingInvoices();
    } else {
      _showSnackBar('❌ ${result['message'] ?? 'Erreur de validation'}', Colors.red);
    }
  } catch (e) {
    _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
  } finally {
    setState(() => _isActionLoading = false);
  }
}
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 64, color: K.success),
          SizedBox(height: 16),
          Text(
            'Toutes les factures sont validées !',
            style: TextStyle(
              color: K.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Aucune facture en attente de validation',
            style: TextStyle(color: K.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}