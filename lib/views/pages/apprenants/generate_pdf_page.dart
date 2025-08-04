import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateInvoicePdf({
  required String concours,
  required double montant,
  required String numeroClient,
}) async {
  final pdf = pw.Document();

  // Chargement du logo depuis les assets
  final ByteData logoData = await rootBundle.load('assets/images/image1.png');//logo_yeki
  final Uint8List logoBytes = logoData.buffer.asUint8List();

  final date = DateTime.now();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo et titre
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(pw.MemoryImage(logoBytes), width: 80),
                pw.Text('FACTURE',
                    style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepOrange)),
              ],
            ),
            pw.SizedBox(height: 30),

            // Détails
            pw.Text('Date : ${date.day}/${date.month}/${date.year}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Numéro client : $numeroClient',
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),

            pw.Text('Détail de la commande',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Concours', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Montant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(concours),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${montant.toStringAsFixed(0)} FCFA'),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Total
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TOTAL : ${montant.toStringAsFixed(0)} FCFA',
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepOrange),
              ),
            ),
            pw.Spacer(),

            // Footer
            pw.Divider(),
            pw.Center(
              child: pw.Text('Merci d’avoir utilisé Yéki 🙏',
                  style: const pw.TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    ),
  );

  // Sauvegarde locale
  final output = await getTemporaryDirectory();
  final file = File("${output.path}/facture_yeki_${DateTime.now().millisecondsSinceEpoch}.pdf");
  await file.writeAsBytes(await pdf.save());

  // Aperçu ou impression
  await Printing.sharePdf(bytes: await pdf.save(), filename: file.path);
}
