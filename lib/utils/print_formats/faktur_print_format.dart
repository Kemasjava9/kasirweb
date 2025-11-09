import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/models.dart';

class FakturPrintFormat {
  static Future<Uint8List> buildFakturPdf(
    Map<String, dynamic> penjualanData,
    List<Map<String, dynamic>> detailItems,
    List<Barang> barangList,
  ) async {
    final pdf = pw.Document();

    final nofaktur = penjualanData['nofaktur_jual']?.toString() ?? '';
    final tanggal = penjualanData['tanggal_jual']?.toString() ?? '';
    final pelanggan = penjualanData['nama_pelanggan']?.toString() ?? '';
    final diskon = (penjualanData['diskon'] ?? 0) as num;

    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    // Generate table rows
    final tableData = <List<String>>[
      ['No', 'Produk', 'Qty', 'Unit', 'Harga', 'Subtotal'],
      ...List.generate(detailItems.length, (index) {
        final item = detailItems[index];
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
        final harga = item['harga_satuan'] ?? 0;
        final subtotal = item['subtotal'] ?? (harga * (item['jumlah'] ?? 0));
        return [
          '${index + 1}',
          barang.namaBarang,
          '${item['jumlah'] ?? 0}',
          '${item['satuan'] ?? ''}',
          currency.format(harga),
          currency.format(subtotal),
        ];
      }),
    ];

    // Hitung subtotal dan total
    final subtotal = detailItems.fold<num>(
      0,
      (sum, item) => sum + (item['subtotal'] ?? (item['harga_satuan'] ?? 0) * (item['jumlah'] ?? 0)),
    );
    final total = subtotal - diskon;

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header perusahaan
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NOTA PENJUALAN',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INVOICE INFO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('No: $nofaktur'),
                      pw.Text('Tgl: $tanggal'),
                      pw.Text('Status: ${penjualanData['status'] ?? '-'}'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),

              // Kepada
              pw.Text('KEPADA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(pelanggan.isNotEmpty ? pelanggan : '-'),
              pw.SizedBox(height: 12),

              // Table
              pw.Table.fromTextArray(
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: pw.Color.fromInt(0xFFE0E0E0)),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(width: 0.5),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerHeight: 20,
                cellHeight: 22,
              ),

              pw.SizedBox(height: 12),

              // Subtotal, Diskon, Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Table(
                      border: pw.TableBorder.all(width: 1),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('Subtotal:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(currency.format(subtotal)),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('Diskon:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(currency.format(diskon)),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(currency.format(total)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Tanda tangan
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Kasir,'),
                      pw.SizedBox(height: 40),
                      pw.Text('________________'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}



