import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/models.dart';

class PembelianPrintFormat {
  static Future<Uint8List> buildPembelianPdf(
    Map<String, dynamic> pembelianData,
    List<Map<String, dynamic>> detailItems,
    List<Barang> barangList,
    List<Supplier> supplierList,
  ) async {
    final pdf = pw.Document();
    final idBeli = pembelianData['id_beli']?.toString() ?? '';
    final kodeSupplier = pembelianData['kode_supplier'] ?? '';
    final supplier = supplierList.firstWhere(
      (s) => s.kodeSupplier == kodeSupplier,
      orElse: () => Supplier(
        kodeSupplier: kodeSupplier,
        namaSupplier: kodeSupplier,
        alamatSupplier: '',
        telpSupplier: '',
      ),
    );



    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(210 * PdfPageFormat.mm, 149 * PdfPageFormat.mm),
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PURCHASE ORDER',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('No. PO: $idBeli', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      child: pw.Text('Supplier: ${supplier.namaSupplier}'),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('Tanggal: ${pembelianData['tanggal_beli'] ?? ''}'),
                    ),
                    pw.Expanded(
                      child: pw.Text('Status: ${pembelianData['status'] ?? ''}'),
                    )
                  ]
                ),
                pw.Text('Jatuh Tempo: ${pembelianData['jatuh_tempo'] ?? ''}'),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Detail Barang:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Satuan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Harga', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                      ],
                    ),
                    ...detailItems.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final item = entry.value;
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

                      return pw.TableRow(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(index.toString()),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(barang.namaBarang),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(NumberFormat('#,###').format(item['jumlah'] ?? 0)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(item['satuan']?.toString() ?? ''),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 1).format(item['harga_satuan'] ?? 0)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['subtotal'] ?? 0)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(pembelianData['total_beli'] ?? 0)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          "Disetujui oleh,"
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          "____________________"
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          "Diterima oleh,"),
                        pw.SizedBox(height: 30), 
                        pw.Text(
                          "____________________"
                        ),
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
