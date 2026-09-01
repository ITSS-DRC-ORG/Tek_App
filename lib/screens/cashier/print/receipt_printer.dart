import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ReceiptPrinter {
  static const double _pageWidth = 227.0; // 80mm en points

  /// Génère un reçu PDF et l'ouvre dans le dialogue d'impression
  static Future<void> printReceipt({
    required Map<String, dynamic> sale,
    required List<Map<String, dynamic>> lines,
    required String clientName,
    required String depotName,
    required double subtotal,
    required double remise,
    required double total,
    required String numeroFacture,
  }) async {
    try {
      final Uint8List pdfBytes = await _generateReceiptPDF(
        sale: sale,
        lines: lines,
        clientName: clientName,
        depotName: depotName,
        subtotal: subtotal,
        remise: remise,
        total: total,
        numeroFacture: numeroFacture,
      );

      // ✅ Pour Windows : sauvegarder et ouvrir le PDF
      if (Platform.isWindows) {
        await _openPdfWindows(pdfBytes, 'reçu_$numeroFacture.pdf');
      } else {
        // ✅ Pour Mobile : utiliser printing
        try {
          await Printing.layoutPdf(
            onLayout: (_) => pdfBytes,
            name: 'reçu_$numeroFacture.pdf',
          );
          print('✅ Dialogue d\'impression lancé');
        } catch (e) {
          print('⚠️ Erreur impression, partage du PDF...');
          await Printing.sharePdf(
            bytes: pdfBytes,
            filename: 'reçu_$numeroFacture.pdf',
          );
        }
      }
      
    } catch (e) {
      print('❌ Erreur impression: $e');
      rethrow;
    }
  }

  /// ✅ Pour Windows : sauvegarder et ouvrir le PDF
  static Future<void> _openPdfWindows(Uint8List pdfBytes, String filename) async {
    try {
      // Sauvegarder dans le dossier Documents
      final documentsPath = Platform.environment['USERPROFILE'];
      if (documentsPath == null) {
        throw Exception('Impossible de trouver le dossier Documents');
      }

      final directory = Directory('$documentsPath\\Documents\\TEK_app_Receipts');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}\\$filename');
      await file.writeAsBytes(pdfBytes);
      
      print('✅ PDF sauvegardé dans: ${file.path}');

      // ✅ Ouvrir le PDF avec l'application par défaut
      try {
        await Process.run('start', [file.path], runInShell: true);
        print('✅ PDF ouvert dans le visualiseur par défaut');
      } catch (e) {
        print('⚠️ Impossible d\'ouvrir automatiquement le PDF: $e');
        print('📁 Le fichier est disponible dans: ${file.path}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde PDF: $e');
      rethrow;
    }
  }

  /// Génère le reçu PDF avec une police Unicode
  static Future<Uint8List> _generateReceiptPDF({
    required Map<String, dynamic> sale,
    required List<Map<String, dynamic>> lines,
    required String clientName,
    required String depotName,
    required double subtotal,
    required double remise,
    required double total,
    required String numeroFacture,
  }) async {
    final pdf = pw.Document();

    // ✅ Utiliser une police Unicode (Times-Roman supporte bien les accents)
    // ou charger une police personnalisée
    pw.Font? font;
    try {
      // ✅ Essayer de charger Roboto
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      font = pw.Font.ttf(fontData.buffer.asByteData());
      print('✅ Police Roboto chargée');
    } catch (e) {
      // ✅ Fallback : utiliser Times-Roman (support Unicode)
      print('⚠️ Police Roboto non trouvée, utilisation de Times-Roman');
      font = null; // Utilisera la police par défaut avec les styles appropriés
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_pageWidth, 600, marginAll: 10),
        build: (context) {
          // ✅ Utiliser des styles avec police par défaut
          final defaultStyle = pw.TextStyle(
            font: font,
            fontSize: 11,
          );
          final boldStyle = pw.TextStyle(
            font: font,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          );
          final titleStyle = pw.TextStyle(
            font: font,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // En-tête
              pw.Text('TEK\'APP', style: titleStyle, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Text('Quincaillerie Générale', style: defaultStyle, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Text(
                _formatDateTime(DateTime.now()),
                style: defaultStyle.copyWith(color: PdfColors.grey),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),

              // Numéro de facture
              pw.SizedBox(height: 8),
              pw.Text(
                'Facture: $numeroFacture',
                style: boldStyle.copyWith(fontSize: 14),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),

              // Informations client
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Client:', style: boldStyle),
                  pw.Text(clientName, style: defaultStyle),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Dépôt:', style: boldStyle),
                  pw.Text(depotName, style: defaultStyle),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),

              // Entête des produits
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(width: 30, child: pw.Text('Qté', style: boldStyle)),
                  pw.Container(width: 100, child: pw.Text('Produit', style: boldStyle)),
                  pw.Container(
                    width: 50,
                    child: pw.Text('Prix', style: boldStyle, textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.Divider(thickness: 1),

              // Lignes de produits
              pw.SizedBox(height: 4),
              ...lines.map((line) {
                final nom = (line['produit_nom'] ?? '').toString();
                final qte = line['quantite'] as int? ?? 0;
                final prix = line['prix_unitaire'] as double? ?? 0;
                final totalLigne = qte * prix;

                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(width: 30, child: pw.Text('$qte', style: defaultStyle)),
                    pw.Container(
                      width: 100,
                      child: pw.Text(
                        nom.length > 20 ? '${nom.substring(0, 20)}...' : nom,
                        style: defaultStyle,
                      ),
                    ),
                    pw.Container(
                      width: 50,
                      child: pw.Text(
                        '${totalLigne.toStringAsFixed(0)} \$',
                        style: defaultStyle,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                );
              }).toList(),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),

              // Totaux
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Sous-total:', style: defaultStyle),
                  pw.Text('${subtotal.toStringAsFixed(0)} \$', style: defaultStyle),
                ],
              ),
              if (remise > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Remise:', style: defaultStyle),
                    pw.Text(
                      '-${remise.toStringAsFixed(0)} \$',
                      style: defaultStyle.copyWith(color: PdfColors.red),
                    ),
                  ],
                ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: boldStyle.copyWith(fontSize: 16)),
                  pw.Text(
                    '${total.toStringAsFixed(0)} \$',
                    style: boldStyle.copyWith(fontSize: 16, color: PdfColors.green),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),

              // Pied de page
              pw.SizedBox(height: 8),
              pw.Text(
                'Mode: ${sale['mode_livraison'] == 'retrait_magasin' ? 'Retrait magasin' : 'Livraison à domicile'}',
                style: defaultStyle,
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Merci de votre confiance !',
                style: boldStyle,
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
              pw.Text(
                'TEK\'app © ${DateTime.now().year}',
                style: defaultStyle.copyWith(fontSize: 8, color: PdfColors.grey),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Génère un rapport PDF
  static Future<void> printReport({
    required String title,
    required Map<String, dynamic> data,
    required String filename,
  }) async {
    try {
      final pdf = await _generateReportPDF(title, data);
      await Printing.sharePdf(bytes: pdf, filename: filename);
      print('✅ Rapport PDF généré avec succès');
    } catch (e) {
      print('❌ Erreur génération rapport PDF: $e');
      rethrow;
    }
  }

  static Future<Uint8List> _generateReportPDF(String title, Map<String, dynamic> data) async {
    final pdf = pw.Document();
    
    // Charger la police
    pw.Font? font;
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      font = pw.Font.ttf(fontData.buffer.asByteData());
    } catch (e) {
      print('⚠️ Police non trouvée');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                data['subtitle'] ?? '',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                  color: PdfColors.grey,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 16),
              ...data['sections']?.map<pw.Widget>((section) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      section['title'] ?? '',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (section['subtitle'] != null)
                      pw.Text(
                        section['subtitle'],
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 12,
                          color: PdfColors.grey,
                        ),
                      ),
                    pw.SizedBox(height: 8),
                    ...section['items']?.map<pw.Widget>((item) {
                      return pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            item['label'] ?? '',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            item['value'] ?? '',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    }).toList() ?? [],
                    pw.SizedBox(height: 12),
                    pw.Divider(),
                  ],
                );
              }).toList() ?? [],
              pw.SizedBox(height: 32),
              pw.Text(
                'Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }
}