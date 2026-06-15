// lib/services/facture_service.dart
// ═══════════════════════════════════════════════════════════════════════════
//  SERVICE DE GÉNÉRATION DE FACTURE PDF
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FactureService {
  //static const String _logoBase64 = 'assets/images/yeki_logo.png'; // À remplacer par votre logo

  /// Génère une facture PDF pour un paiement
  static Future<File> genererFacture({
    required String reference,
    required String clientNom,
    required String clientEmail,
    required String description,
    required int montantLigne,
    required int montantPresentiel,
    required int montantTotal,
    required DateTime date,
    String? departementNom,
  }) async {
    final pdf = pw.Document();
    final format = NumberFormat('#,###', 'fr_FR');
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildEnTete(pdf),
          pw.SizedBox(height: 20),
          _buildInfosClient(clientNom, clientEmail, reference, date, dateFormat),
          pw.SizedBox(height: 30),
          _buildTableau(
            description: description,
            montantLigne: montantLigne,
            montantPresentiel: montantPresentiel,
            montantTotal: montantTotal,
            format: format,
          ),
          pw.SizedBox(height: 30),
          _buildFooter(departementNom),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/facture_$reference.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildEnTete(pw.Document pdf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'YÉKI',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.Text(
                  'Plateforme d\'apprentissage en ligne',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Acquittée',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.green700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue800),
      ],
    );
  }

  static pw.Widget _buildInfosClient(
    String nom,
    String email,
    String reference,
    DateTime date,
    DateFormat dateFormat,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Facturé à',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(nom, style: pw.TextStyle(fontSize: 12)),
              pw.Text(email, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Détails facture',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              _buildInfoLigne('Référence', reference),
              _buildInfoLigne('Date', dateFormat.format(date)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoLigne(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          '$label : ',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildTableau({
    required String description,
    required int montantLigne,
    required int montantPresentiel,
    required int montantTotal,
    required NumberFormat format,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          // En-tête tableau
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'Description',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'Montant',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Ligne 1 : Formation en ligne
          _buildTableRow('Formation en ligne', montantLigne, format, isFirst: false),
          // Ligne 2 : Frais présentiel (si applicable)
          if (montantPresentiel > 0)
            _buildTableRow('Frais présentiel', montantPresentiel, format),
          // Total
          pw.Divider(thickness: 1),
          _buildTableRow('TOTAL', montantTotal, format, isBold: true),
        ],
      ),
    );
  }

  static pw.Widget _buildTableRow(
    String label,
    int montant,
    NumberFormat format, {
    bool isFirst = true,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: isFirst
            ? null
            : pw.Border(top: pw.BorderSide(color: PdfColors.grey200)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              '${format.format(montant)} FCFA',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(String? departementNom) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Conditions de paiement',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Paiement effectué en ligne via CinetPay',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Cette facture fait foi de paiement',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            if (departementNom != null)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Formation',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(departementNom, style: pw.TextStyle(fontSize: 10)),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Text(
            'Merci de votre confiance !',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey500,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  /// Imprime ou partage la facture
  static Future<void> imprimerFacture(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }
}