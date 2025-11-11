import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/models.dart';

class PembelianPrintFormat {
  static Future<Uint8List> buildPembelianPdf(
    Map<String, dynamic> pembelianData,
    List<Map<String, dynamic>> detailItems,
    List<Barang> barangList,
  ) async {
    final pdf = pw.Document();
    final idBeli = pembelianData['id_beli']?.toString() ?? '';

    final tableData = <List<String>>[
      ['Kode', 'Nama', 'Jumlah', 'Satuan', 'Harga', 'Subtotal'],
      ...detailItems.map((item) {
        final kode = item['kode_barang'] ?? '';
        final barang = barangList.firstWhere(
          (b) => b.kodeBarang == kode,
          orElse: () => Barang(
            kodeBarang: kode,
            namaBarang: kode,
            satuanPcs: 'pcs',
            satuanDus: 'dus',
            isiDus: 1,
            hargaPcs: 0,
            hargaDus: 0,
            jumlah: 0,
            hpp: 0,
            hppDus: 0,
          ),
        );

        return [
          kode,
          barang.namaBarang,
          (item['jumlah'] ?? 0).toString(),
          item['satuan']?.toString() ?? '',
          NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['harga_satuan'] ?? 0),
          NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['subtotal'] ?? 0),
        ];
      })
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
                  'FAKTUR PEMBELIAN',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text('ID Beli: $idBeli'),
                pw.Text('Tanggal: ${pembelianData['tanggal_beli'] ?? ''}'),
                pw.Text('Supplier: ${pembelianData['kode_supplier'] ?? ''}'),
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
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Total: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(pembelianData['total_beli'] ?? 0)}'),
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
