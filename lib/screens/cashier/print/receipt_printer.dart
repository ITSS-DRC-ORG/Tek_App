import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptPrinter {
// Largeur POS 72 mm ≈ 204.1 pt (1 pt = 1/72 in)
  static const double _posWidth = 204.1;

// Nom de l'établissement officiel
  static const String _companyName = "QUINCAILLERIE LA GRÂCE";
  static const String _companyActivity =
      "Matériaux de Construction & Quincaillerie Générale";
  static const String _companyContact =
      "Tél : +243 000 000 000 — Vente au Comptoir & En Gros";

// ---------------------------------------------------------------------
// GESTION SÉCURISÉE DES POLICES UNICODE (ROBOTO)
// ---------------------------------------------------------------------
  static pw.Font? _cachedRegular;
  static pw.Font? _cachedBold;

  static Future<void> _initFonts() async {
    if (_cachedRegular != null && _cachedBold != null) return;
    try {
      _cachedRegular = await PdfGoogleFonts.robotoRegular();
      _cachedBold = await PdfGoogleFonts.robotoBold();
    } catch (_) {
// Fallback local standard si pas de connexion internet
      _cachedRegular = pw.Font.helvetica();
      _cachedBold = pw.Font.helveticaBold();
    }
  }

  /// Nettoie les chaînes de caractères pour éliminer tout symbole corrompu
  static String _safe(dynamic text) {
    if (text == null) return '';
    return text
        .toString()
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('•', '-')
        .replaceAll('\u00A0', ' ') // Espace insécable
        .replaceAll('\u202F', ' ') // Espace fine insécable
        .trim();
  }

// ---------------------------------------------------------------------
// 1. REÇU TICKET DE CAISSE POS — 72 mm (IMPRESSION DIRECTE)
// ---------------------------------------------------------------------
  static Future<void> printReceipt({
    required Map<String, dynamic> sale,
    required List<Map<String, dynamic>> lines,
    required String clientName,
    required String depotName,
    required double subtotal,
    required double remise,
    required double total,
    required String numeroFacture,
    String documentType = 'FACTURE',
  }) async {
    final pdfBytes = await _generatePosPDF(
      sale: sale,
      lines: lines,
      clientName: clientName,
      depotName: depotName,
      subtotal: subtotal,
      remise: remise,
      total: total,
      numeroFacture: numeroFacture,
      documentType: documentType,
    );

// Sauvegarde sécurisée sans crash
    _savePdfSafely(
        pdfBytes, '${documentType.toLowerCase()}_$numeroFacture.pdf');

    final double height = 270.0 + (lines.length * 24.0);
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: '${documentType.toLowerCase()}_$numeroFacture',
      format: PdfPageFormat(_posWidth, height, marginAll: 5),
      usePrinterSettings: true,
    );
  }

// ---------------------------------------------------------------------
// 2. RAPPORT FINANCIER & LOGISTIQUE — A4 PROFESSIONNEL
// ---------------------------------------------------------------------
  static Future<void> printReport({
    required String title,
    required Map<String, dynamic> data,
    required String filename,
  }) async {
    await _initFonts();

    final pdf = pw.Document();
    final font = _cachedRegular;
    final fontBold = _cachedBold ?? _cachedRegular;

    final primaryColor = PdfColor.fromHex('#004E8C');
    final darkSlate = PdfColor.fromHex('#0F172A');
    final greyText = PdfColor.fromHex('#64748B');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _companyName,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _companyActivity,
                      style: pw.TextStyle(
                          font: font, fontSize: 8.5, color: greyText),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F1F5F9'),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        "Date : ${_fmt(DateTime.now())}",
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 8.5, color: darkSlate),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1.5, color: primaryColor),
            pw.SizedBox(height: 8),

// Titre du rapport
            pw.Text(
              _safe(title),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: darkSlate,
              ),
            ),
            if ((data['subtitle'] ?? '').toString().isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                _safe(data['subtitle']),
                style: pw.TextStyle(font: font, fontSize: 10, color: greyText),
              ),
            ],
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "$_companyName — Logiciel de Gestion Commerciale TEK'app",
                style: pw.TextStyle(font: font, fontSize: 8, color: greyText),
              ),
              pw.Text(
                'Page ${context.pageNumber} / ${context.pagesCount}',
                style:
                    pw.TextStyle(font: fontBold, fontSize: 8, color: darkSlate),
              ),
            ],
          ),
        ),
        build: (context) {
          final children = <pw.Widget>[];

          for (final section in (data['sections'] as List? ?? [])) {
            children.add(pw.SizedBox(height: 12));
            children.add(
              pw.Text(
                _safe(section['title'] ?? ''),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            );

            if (section['subtitle'] != null) {
              children.add(pw.SizedBox(height: 2));
              children.add(
                pw.Text(
                  _safe(section['subtitle']),
                  style: pw.TextStyle(font: font, fontSize: 9, color: greyText),
                ),
              );
            }
            children.add(pw.SizedBox(height: 6));

// TABLEAU PRINCIPAL DES DONNÉES
            if (section['table'] is Map) {
              final table = section['table'] as Map;
              final headers = (table['headers'] as List?)?.cast<String>() ?? [];
              final rows = (table['rows'] as List?) ?? [];

              if (headers.isNotEmpty) {
                children.add(
                  pw.Table(
                    border: pw.TableBorder.all(
                        color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                    columnWidths: _columnWidths(headers.length),
                    children: [
// Ligne d'en-tête
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: primaryColor),
                        children: headers.map((h) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: pw.Text(
                              _safe(h),
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
// Lignes de données
                      ...rows.asMap().entries.map((entry) {
                        final i = entry.key;
                        final row = (entry.value as List?) ?? [];
                        final bg = i.isEven
                            ? PdfColor.fromHex('#F8FAFC')
                            : PdfColors.white;

                        return pw.TableRow(
                          decoration: pw.BoxDecoration(color: bg),
                          children: List.generate(headers.length, (col) {
                            final cell =
                                col < row.length ? _safe(row[col]) : '';
                            final isNumeric = col == headers.length - 1 ||
                                cell.contains('\$') ||
                                double.tryParse(cell.replaceAll(' ', '')) !=
                                    null;

                            return pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              child: pw.Text(
                                cell,
                                textAlign: isNumeric
                                    ? pw.TextAlign.right
                                    : pw.TextAlign.left,
                                style: pw.TextStyle(
                                  font: isNumeric ? fontBold : font,
                                  fontSize: 8.5,
                                  color: darkSlate,
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ],
                  ),
                );
              }
            }

// PAIRES CLÉ / VALEUR
            if (section['items'] is List) {
              final items = section['items'] as List;
              if (items.isNotEmpty) {
                children.add(
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(
                          color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
                    ),
                    child: pw.Column(
                      children: items.map((e) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                _safe(e['label'] ?? ''),
                                style: pw.TextStyle(
                                    font: font, fontSize: 9, color: greyText),
                              ),
                              pw.Text(
                                _safe(e['value'] ?? ''),
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 9.5,
                                    color: darkSlate),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
            }

            children.add(pw.SizedBox(height: 10));
          }

          return children;
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  static Map<int, pw.TableColumnWidth> _columnWidths(int count) {
    if (count == 2) {
      return {
        0: const pw.FlexColumnWidth(3.5),
        1: const pw.FlexColumnWidth(1.2)
      };
    }
    if (count == 3) {
      return {
        0: const pw.FlexColumnWidth(3.5),
        1: const pw.FlexColumnWidth(1.0),
        2: const pw.FlexColumnWidth(1.4),
      };
    }
    if (count == 4) {
      return {
        0: const pw.FlexColumnWidth(3.5),
        1: const pw.FlexColumnWidth(0.9),
        2: const pw.FlexColumnWidth(1.1),
        3: const pw.FlexColumnWidth(1.3),
      };
    }
    final map = <int, pw.TableColumnWidth>{0: const pw.FlexColumnWidth(3.2)};
    for (var i = 1; i < count; i++) {
      map[i] = const pw.FlexColumnWidth(1);
    }
    return map;
  }

// ---------------------------------------------------------------------
// 3. GÉNÉRATION DU PDF POS 72 mm (STYLE TICKET QUINCAILLERIE)
// ---------------------------------------------------------------------
  static Future<Uint8List> _generatePosPDF({
    required Map<String, dynamic> sale,
    required List<Map<String, dynamic>> lines,
    required String clientName,
    required String depotName,
    required double subtotal,
    required double remise,
    required double total,
    required String numeroFacture,
    required String documentType,
  }) async {
    await _initFonts();
    final pdf = pw.Document();
    final font = _cachedRegular;
    final fontBold = _cachedBold ?? _cachedRegular;

    final double height = 270.0 + (lines.length * 24.0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_posWidth, height, marginAll: 5),
        build: (context) {
          final regularStyle = pw.TextStyle(font: font, fontSize: 8.5);
          final boldStyle = pw.TextStyle(
              font: fontBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold);
          final titleStyle = pw.TextStyle(
              font: fontBold, fontSize: 13, fontWeight: pw.FontWeight.bold);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
// EN-TÊTE ÉTABLISSEMENT
              pw.Text(_companyName,
                  style: titleStyle, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 1.5),
              pw.Text(_companyActivity,
                  style: pw.TextStyle(
                      font: font, fontSize: 7, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 1),
              pw.Text("Dépôt / Magasin : ${_safe(depotName).toUpperCase()}",
                  style: pw.TextStyle(font: fontBold, fontSize: 7.5),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),

// RÉFÉRENCE DOCUMENT
              pw.SizedBox(height: 2),
              pw.Text(
                '${documentType == 'PROFORMA' ? 'PROFORMA' : 'TICKET DE CAISSE'} N° ${_safe(numeroFacture)}',
                style: boldStyle,
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 1.5),
              pw.Text("Date : ${_fmt(DateTime.now())}",
                  style: regularStyle, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),

// INFORMATIONS CLIENT
              pw.SizedBox(height: 2),
              _row('Client', _safe(clientName), regularStyle, boldStyle),
              _row('Point de retrait', _safe(depotName), regularStyle,
                  boldStyle),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),

// EN-TÊTE TABLEAU DES ARTICLES
              pw.SizedBox(height: 3),
              pw.Row(children: [
                pw.SizedBox(width: 24, child: pw.Text('Qté', style: boldStyle)),
                pw.Expanded(child: pw.Text('Article', style: boldStyle)),
                pw.SizedBox(
                    width: 44,
                    child: pw.Text('P.U.',
                        style: boldStyle, textAlign: pw.TextAlign.right)),
                pw.SizedBox(
                    width: 50,
                    child: pw.Text('Total',
                        style: boldStyle, textAlign: pw.TextAlign.right)),
              ]),
              pw.Divider(thickness: 0.5),

// LIGNES PRODUITS
              ...lines.map((line) {
                final nom = _safe(line['produit_nom'] ?? 'Article');
                final q = line['quantite'] as int? ?? 1;
                final p = (line['prix_unitaire'] as num?)?.toDouble() ?? 0.0;
                final lineTotal = q * p;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                          width: 24, child: pw.Text('$q', style: regularStyle)),
                      pw.Expanded(
                        child: pw.Text(nom, style: regularStyle, maxLines: 2),
                      ),
                      pw.SizedBox(
                        width: 44,
                        child: pw.Text('${p.toStringAsFixed(2)} \$',
                            style: regularStyle, textAlign: pw.TextAlign.right),
                      ),
                      pw.SizedBox(
                        width: 50,
                        child: pw.Text('${lineTotal.toStringAsFixed(2)} \$',
                            style: boldStyle, textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),

// CALCULS ET TOTAUX
              _row('Sous-total brut', '${subtotal.toStringAsFixed(2)} \$',
                  regularStyle, boldStyle),
              if (remise > 0)
                _row('Remise accordée', '- ${remise.toStringAsFixed(2)} \$',
                    regularStyle, boldStyle),

              pw.SizedBox(height: 4),
// CADRE NET À PAYER
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1.2),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NET À PAYER',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('${total.toStringAsFixed(2)} \$',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),
              pw.Text('Mode de règlement : COMPTANT (USD)',
                  style: regularStyle, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Text('Merci pour votre confiance !',
                  style: boldStyle, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 1.5),
              pw.Text(
                  'Les marchandises vendues ne sont ni reprises ni échangées.',
                  style: pw.TextStyle(
                      font: font, fontSize: 6.5, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 6),
              pw.Text("$_companyName — Système TEK'app",
                  style: pw.TextStyle(
                      font: font, fontSize: 6.5, color: PdfColors.grey),
                  textAlign: pw.TextAlign.center),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _row(
      String label, String value, pw.TextStyle d, pw.TextStyle b) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(_safe(label) + ' :', style: d),
          pw.Text(_safe(value), style: b),
        ],
      ),
    );
  }

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------
// GESTION DU RÉPERTOIRE INFAILLIBLE WINDOWS
// ---------------------------------------------------------------------
  static Future<Directory> _getSafeReceiptDirectory() async {
    final userProfile = Platform.environment['USERPROFILE'];

    if (userProfile != null) {
      try {
        final docDir = Directory('$userProfile\\Documents\\TEK_app_Receipts');
        if (await docDir.parent.exists()) {
          if (!await docDir.exists()) await docDir.create(recursive: true);
          return docDir;
        }
      } catch (_) {}

      try {
        final oneDriveDoc =
            Directory('$userProfile\\OneDrive\\Documents\\TEK_app_Receipts');
        if (await oneDriveDoc.parent.exists()) {
          if (!await oneDriveDoc.exists())
            await oneDriveDoc.create(recursive: true);
          return oneDriveDoc;
        }
      } catch (_) {}
    }

    final fallbackDir =
        Directory('${Directory.systemTemp.path}\\TEK_app_Receipts');
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    return fallbackDir;
  }

  static Future<void> _savePdfSafely(Uint8List bytes, String filename) async {
    try {
      final dir = await _getSafeReceiptDirectory();
      final file = File('${dir.path}\\$filename');
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }
}
