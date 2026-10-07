import 'dart0typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SuratJalanPrintFormat {
  static Future<Uint8List> buildSuratJalanPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final items = (data['items'] as List<dynamic>?) ?? [];

    final pageFormat = PdfPageFormat.a5.copyWith(
      marginLeft: 10,
      marginRight: 10,
      marginTop: 10,
      marginBottom: 10,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // HEADER SURAT JALAN
                pw.Center(
                  child: pw.Text(
                    'SURAT JALAN',
                    style: pw.TextStyle(
                      fontSize: 14, 
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(height: 1, thickness: 0.5),
                pw.SizedBox(height: 8),

                // INFO ATAS (NO, TGL, PENERIMA, ALAMAT)
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(60),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    pw.TableRow(children: [
                      pw.Text('No. Surat', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(': ${data['nomor_surat'] ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Tanggal', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(': ${data['tanggal'] ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Penerima', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(': ${data['penerima'] ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Alamat', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(': ${data['alamat'] ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                    ]),
                  ],
                ),
                pw.SizedBox(height: 10),

                pw.Text(
                  'Daftar Barang:',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),

                // TABEL BARANG DENGAN LEBAR KOLOM TERATUR
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(25),  // No
                    1: const pw.FixedColumnWidth(55),  // Kode
                    2: const pw.FlexColumnWidth(3.5),  // Nama Barang (fleksibel & paling lebar)
                    3: const pw.FixedColumnWidth(35),  // Jumlah
                    4: const pw.FixedColumnWidth(35),  // Satuan
                  },
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    // HEADER TABEL
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                          child: pw.Text('No', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                          child: pw.Text('Kode', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                          child: pw.Text('Nama Barang', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.left),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                          child: pw.Text('Jumlah', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                          child: pw.Text('Satuan', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                      ],
                    ),

                    // ISI TABEL
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final it = entry.value;

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                            child: pw.Text(index.toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                            child: pw.Text((it['kode_barang'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                            child: pw.Text((it['nama_barang'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8), maxLines: 2),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                            child: pw.Text((it['jumlah'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                            child: pw.Text((it['satuan'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 10),

                // NOTES SECTION
                if ((data['notes'] ?? '').toString().isNotEmpty) ...[
                  pw.Text('Catatan:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(data['notes'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 14),
                ],

                // AREA TANDA TANGAN
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('Pengirim,', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 30),
                        pw.Text('____________________', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('Penerima,', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 30),
                        pw.Text('____________________', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
