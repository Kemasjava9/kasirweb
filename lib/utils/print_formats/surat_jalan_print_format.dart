import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

class SuratJalanPrintFormat {
  static Future<Uint8List> buildSuratJalanPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final items = (data['items'] as List<dynamic>?) ?? [];

    final tableData = <List<String>>[
      ['Kode', 'Nama', 'Jumlah', 'Satuan'],
      ...items.map((it) => [
            (it['kode_barang'] ?? '').toString(),
            (it['nama_barang'] ?? '').toString(),
            (it['jumlah'] ?? '').toString(),
            (it['satuan'] ?? '').toString(),
          ])
    ];

    pdf.addPage(
      pw.Page(
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SURAT JALAN',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('No: ${data['nomor_surat'] ?? ''}'),
                    pw.Text('Tanggal: ${data['tanggal'] ?? ''}'),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('Penerima: ${data['penerima'] ?? ''}'),
                pw.Text('Alamat: ${data['alamat'] ?? ''}'),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Items:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Table.fromTextArray(
                  context: ctx,
                  data: tableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                pw.SizedBox(height: 12),
                pw.Text('Notes:'),
                pw.Text(data['notes'] ?? ''),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
