import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/models.dart';

class FakturPrintFormat {
  static Future<Uint8List> buildFakturPdf(
      Map<String, dynamic> header,
      List<Map<String, dynamic>> details,
      List<Barang> barangList) async {

    final pdf = pw.Document();
    final format = NumberFormat.currency(
        locale: 'id', symbol: 'Rp ', decimalDigits: 1);
    final formatSubtotal = NumberFormat.currency(
        locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final formatnumber = NumberFormat.decimalPattern('id');

    final noFaktur = header['nofaktur_jual'] ?? '';
    final tgl = header['tanggal_jual'] ?? '';
    final pelanggan = header['nama_pelanggan'] ?? '';
    final status = header['status'] ?? '';
    final total = (header['total_jual'] ?? 0).toDouble();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // ==============================
          // HEADER
          // ==============================
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("NOTA PENJUALAN",
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 16),
                  pw.Text("KEPADA:",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(pelanggan),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("INVOICE:",
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text("No: $noFaktur"),
                  pw.Text("Tgl: $tgl"),
                  pw.Text("Status: $status"),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ==============================
          // TABEL ITEM
          // ==============================
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(),
              2: const pw.FixedColumnWidth(80),
              3: const pw.FixedColumnWidth(50),
              4: const pw.FixedColumnWidth(90),
              5: const pw.FixedColumnWidth(100),
            },
            children: [
              pw.TableRow(
                decoration:
                    pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("No", textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("Produk", textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("Qty", textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("Unit", textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("Harga", textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("Subtotal", textAlign: pw.TextAlign.center)),
                ],
              ),
              ...List.generate(details.length, (i) {
                final d = details[i];
                final kode = d['kode_barang'];
                final barang = barangList.firstWhere(
                    (b) => b.kodeBarang == kode,
                    orElse: () => Barang(
                        kodeBarang: kode,
                        namaBarang: kode,
                        satuanPcs: '',
                        satuanDus: '',
                        isiDus: 1,
                        hargaPcs: 0,
                        hargaDus: 0,
                        jumlah: 0,
                        hpp: 0,
                        hppDus: 0));

                // Determine price based on unit
                final satuan = d['satuan'] ?? '';
                final harga = satuan == barang.satuanPcs ? barang.hargaPcs : barang.hargaDus;

                return pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text((i + 1).toString(), textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(barang.namaBarang, textAlign: pw.TextAlign.left)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(formatnumber.format(d['jumlah'] ?? 0).toString(), textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(d['satuan'] ?? '', textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(format.format(harga), textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(formatSubtotal.format(d['subtotal'] ?? 0), textAlign: pw.TextAlign.left)),
                ]);
              })
            ],
          ),

          pw.SizedBox(height: 20),

          // ==============================
          // TOTAL SECTION
          // ==============================
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 160,
                child: pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text("Subtotal")),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(formatSubtotal.format(total))),
                    ]),
                    pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text("Diskon")),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(formatSubtotal.format(0))),
                    ]),
                    pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text("Total",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(formatSubtotal.format(total),
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                    ]),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 40),

          // ==============================
          // SIGNATURE
          // ==============================
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text("Kasir,"),
              pw.SizedBox(height: 30),
              pw.Text("____________________"),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
