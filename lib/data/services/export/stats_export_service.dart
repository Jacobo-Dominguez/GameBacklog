import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class StatsExportService {
  static Future<void> exportStatsToPdf({
    required String username,
    required Map<String, String> quickStats,
    required Uint8List? genreChartBytes,
    required Uint8List? monthlyChartBytes,
    required Map<String, String> extraStats,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GameBacklog - Informe de Estadísticas',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Usuario: $username',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  pw.Text(dateFormat.format(now)),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Quick Stats
              pw.Text('Resumen General', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.GridView(
                crossAxisCount: 2,
                childAspectRatio: 4,
                children: quickStats.entries.map((e) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Row(
                      children: [
                        pw.Text('${e.key}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(e.value),
                      ],
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 30),

              // Charts
              pw.Row(
                children: [
                  if (genreChartBytes != null)
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text('Distribución por Género', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 10),
                          pw.Image(pw.MemoryImage(genreChartBytes), height: 200),
                        ],
                      ),
                    ),
                  if (monthlyChartBytes != null)
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text('Actividad Mensual', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 10),
                          pw.Image(pw.MemoryImage(monthlyChartBytes), height: 200),
                        ],
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Extra Stats
              pw.Text('Otros Hitos', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...extraStats.entries.map((e) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(e.key),
                      pw.Text(e.value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),

              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('Generado por GameBacklog App', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'GameBacklog_Stats_${username}_${now.millisecondsSinceEpoch}.pdf',
    );
  }
}
