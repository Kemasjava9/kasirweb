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
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'PURCHASE ORDER',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Divider(height: 1),
                pw.SizedBox(height: 8),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(90),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text('No. PO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('$idBeli', style: pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text('Supplier', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('${supplier.namaSupplier}', style: pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text('Tanggal', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('${pembelianData['tanggal_beli'] ?? ''}', style: pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text('Status', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('${pembelianData['status'] ?? ''}', style: pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text('Jatuh Tempo', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('${pembelianData['jatuh_tempo'] ?? ''}', style: pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Detail Barang:',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(16),
                    1: const pw.FlexColumnWidth(2.6),
                    2: const pw.FixedColumnWidth(24),
                    3: const pw.FixedColumnWidth(18),
                    4: const pw.FixedColumnWidth(28),
                    5: const pw.FixedColumnWidth(28),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('No', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('Jml', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('Sat', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('Harga', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('Sub', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
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
                pw.SizedBox(height: 10),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 110,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5, color: PdfColors.black),
                      color: PdfColors.grey200,
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(pembelianData['total_beli'] ?? 0),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Disetujui oleh,',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                        pw.SizedBox(height: 24),
                        pw.Text(
                          '____________________',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Diterima oleh,',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                        pw.SizedBox(height: 24),
                        pw.Text(
                          '____________________',
                          style: pw.TextStyle(fontSize: 8),
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
