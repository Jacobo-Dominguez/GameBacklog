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
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      _buildStatCell('Total Juegos', quickStats['Total Juegos'] ?? '0'),
                      _buildStatCell('Horas Totales', quickStats['Horas Totales'] ?? '0'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildStatCell('Media por Juego', quickStats['Media por Juego'] ?? '0h'),
                      _buildStatCell('Completados', quickStats['Completados'] ?? '0'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Charts
              if (genreChartBytes != null || monthlyChartBytes != null) ...[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (genreChartBytes != null)
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text('Distribución por Género', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 10),
                            pw.Container(
                              height: 180,
                              child: pw.Image(pw.MemoryImage(genreChartBytes)),
                            ),
                          ],
                        ),
                      ),
                    if (genreChartBytes != null && monthlyChartBytes != null) pw.SizedBox(width: 20),
                    if (monthlyChartBytes != null)
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text('Actividad Mensual', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 10),
                            pw.Container(
                              height: 180,
                              child: pw.Image(pw.MemoryImage(monthlyChartBytes)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 30),
              ],

              // Extra Stats
              if (extraStats.isNotEmpty) ...[
                pw.Text('Otros Hitos', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
                  children: extraStats.entries.map((e) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(e.key),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(e.value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],

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

  static pw.Widget _buildStatCell(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
