import 'package:flutter/material.dart';
import 'package:tek_app/screens/cashier/print/receipt_printer.dart';
import 'package:tek_app/theme/app_theme.dart';

class PosReceiptDialog extends StatefulWidget {
  final Map<String, dynamic> saleData;
  final List<Map<String, dynamic>> lignes;
  final String clientName;
  final String depotName;
  final double subtotal;
  final double remise;
  final double total;
  final String numeroFacture;

  const PosReceiptDialog({
    super.key,
    required this.saleData,
    required this.lignes,
    required this.clientName,
    required this.depotName,
    required this.subtotal,
    required this.remise,
    required this.total,
    required this.numeroFacture,
  });

  @override
  State<PosReceiptDialog> createState() => _PosReceiptDialogState();
}

class _PosReceiptDialogState extends State<PosReceiptDialog> {
  bool _isPrinting = false;

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      await ReceiptPrinter.printReceipt(
        sale: widget.saleData,
        lines: widget.lignes,
        clientName: widget.clientName,
        depotName: widget.depotName,
        subtotal: widget.subtotal,
        remise: widget.remise,
        total: widget.total,
        numeroFacture: widget.numeroFacture,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'impression: $e',
              style: const TextStyle(fontFamily: kAppFontFamily)),
          backgroundColor: const Color(0xFFC42B1C),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(22, 18, 18, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.print_outlined, color: Color(0xFF0067C0), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Imprimante POS — Ticket de Caisse',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Format thermique 80mm / 58mm pour reçu client',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            splashRadius: 14,
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1, thickness: 1, color: Color(0x14000000)),
            const SizedBox(height: 14),

            // APERÇU ROULEAU DE PAPIER THERMIQUE POS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      "TEK'app — ${widget.depotName.toUpperCase()}",
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'TICKET N° : ${widget.numeroFacture}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: Color(0xFF0067C0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      'Client : ${widget.clientName}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('--------------------------------------------',
                      style: TextStyle(fontFamily: 'monospace', color: Color(0xFFCBD5E1)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),

                  // Aperçu des articles
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.lignes.length,
                      itemBuilder: (context, idx) {
                        final l = widget.lignes[idx];
                        final nom = l['produit_nom'] as String? ?? 'Article';
                        final qte = l['quantite'] as int? ?? 1;
                        final prix = (l['prix_unitaire'] as num?)?.toDouble() ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('$qte x $nom',
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('${(qte * prix).toStringAsFixed(2)} \$',
                                  style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),
                  const Text('--------------------------------------------',
                      style: TextStyle(fontFamily: 'monospace', color: Color(0xFFCBD5E1)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),

                  // Total Net
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL À PAYER',
                          style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 12)),
                      Text('${widget.total.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF0067C0))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer',
              style: TextStyle(fontFamily: kAppFontFamily, color: Color(0xFF64748B))),
        ),
        ElevatedButton.icon(
          onPressed: _isPrinting ? null : _handlePrint,
          icon: _isPrinting
              ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Icons.print_rounded, size: 17),
          label: Text(_isPrinting ? 'Impression...' : 'Imprimer sur l\'imprimante POS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0067C0),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}