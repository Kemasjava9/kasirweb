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
        locale: 'id', symbol: ' ', decimalDigits: 1);
    final formatSubtotal = NumberFormat.currency(
        locale: 'id', symbol: ' ', decimalDigits: 0);
    final formatnumber = NumberFormat.decimalPattern('id');

    final noFaktur = header['nofaktur_jual'] ?? '';
    final tgl = header['tanggal_jual'] ?? '';
    final pelanggan = header['nama_pelanggan'] ?? '';
    final status = header['status'] ?? '';
    final total = double.tryParse(header['total_jual']?.toString() ?? '0') ?? 0.0;
    final diskon = double.tryParse(header['diskon']?.toString() ?? '0') ?? 0.0;
    final bayar = double.tryParse(header['bayar']?.toString() ?? '0') ?? 0.0;
    final sisaKurang = total - bayar;
    final sumsubtotal = details.fold<double>(
        0,
        (previousValue, element) =>
            previousValue + (double.tryParse(element['subtotal']?.toString() ?? '0') ?? 0.0));

    // Ukuran kertas fixed 210mm x 148mm
    final pageFormat = PdfPageFormat(
      215 * PdfPageFormat.mm, // Lebar
      140 * PdfPageFormat.mm, // Tinggi
      marginLeft: 8,
      marginRight: 8,
      marginTop: 8,
      marginBottom: 8,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==============================
              // HEADER - 2 kolom
              // ==============================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Kolom kiri - INFO TOKO/PELANGGAN
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Center(
                          child: pw.Text("NOTA PENJUALAN",
                              style: pw.TextStyle(
                                  fontSize: 14, 
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text("Kepada:",
                            style: pw.TextStyle(
                                fontSize: 10, 
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text(pelanggan, 
                            style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 5),
                      ],
                    ),
                  ),
                  
                  // Kolom kanan - INFO FAKTUR
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("INVOICE",
                            style: pw.TextStyle(
                                fontSize: 10, 
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text("No: $noFaktur", 
                            style: pw.TextStyle(fontSize: 9)),
                        pw.Text("Tgl: $tgl", 
                            style: pw.TextStyle(fontSize: 9)),
                        pw.Text("Status: $status", 
                            style: pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Divider(height: 16, thickness: 0.5),

              // ==============================
              // TABEL ITEM
              // ==============================
              pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(width: 0.5),
                  right: pw.BorderSide(width: 0.5),
                  top: pw.BorderSide(width: 0.5),
                  bottom: pw.BorderSide(width: 0.5),
                  horizontalInside: pw.BorderSide.none,
                  verticalInside: pw.BorderSide(width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25),  // No
                  1: const pw.FlexColumnWidth(2.5),  // Produk
                  2: const pw.FixedColumnWidth(45),  // Qty
                  3: const pw.FixedColumnWidth(35),  // Unit
                  4: const pw.FixedColumnWidth(80),  // Harga
                  5: const pw.FixedColumnWidth(80),  // Subtotal
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  // HEADER TABLE
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: pw.Text("NO", 
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: pw.Text("PRODUK", 
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.left)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: pw.Text("QTY", 
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: pw.Text("UNIT", 
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: pw.Text("HARGA", 
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: pw.Text("SUBTOTAL", 
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  
                  // ITEM DETAILS
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

                    return pw.TableRow(
                      decoration: i.isEven ? pw.BoxDecoration(color: PdfColors.grey50) : null,
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                            child: pw.Text((i + 1).toString(), 
                                style: pw.TextStyle(fontSize: 9),
                                textAlign: pw.TextAlign.center)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                            child: pw.Text(barang.namaBarang, 
                                style: pw.TextStyle(fontSize: 9),
                                textAlign: pw.TextAlign.left,
                                maxLines: 2)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                            child: pw.Text(formatnumber.format(d['jumlah'] ?? 0).toString(), 
                                style: pw.TextStyle(fontSize: 9),
                                textAlign: pw.TextAlign.center)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                            child: pw.Text(d['satuan'] ?? '', 
                                style: pw.TextStyle(fontSize: 9),
                                textAlign: pw.TextAlign.center)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text("Rp", style: pw.TextStyle(fontSize: 9)),
                                pw.Text(format.format(harga), 
                                    style: pw.TextStyle(fontSize: 9)),
                              ],
                            ),
                          ),
                        pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text("Rp", style: pw.TextStyle(fontSize: 9)),
                                pw.Text(formatSubtotal.format(d['subtotal'] ?? 0), 
                                    style: pw.TextStyle(fontSize: 9)),
                              ],
                            ),
                          ),
                      ],
                    );
                  })
                ],
              ),

              pw.SizedBox(height: 16),

              // ==============================
              // TOTAL SECTION
              // ==============================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // TANDA TANGAN
                  pw.Container(
                    width: 70, // Lebar tetap untuk tanda tangan
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Terima Kasih",
                            style: pw.TextStyle(
                                fontSize: 9, 
                                fontStyle: pw.FontStyle.italic)),
                        pw.SizedBox(height: 15),
                        pw.Text("Kasir,",
                            style: pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 30),
                        pw.Text("_____________",
                            style: pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                  
                  // TOTAL PEMBAYARAN - DIPERKECIL
                  pw.Container(
                    width: 150, // Lebar tabel diperkecil
                    child: pw.Table(
                      border: pw.TableBorder.all(width: 0.5),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1.8), // Label lebih lebar
                        1: const pw.FlexColumnWidth(2),   // Nilai lebih sempit
                      },
                      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: [
                        pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                              child: pw.Text("Subtotal",
                                  style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Text("Rp ",
                                      style: pw.TextStyle(fontSize: 9)),
                                  pw.Text(formatSubtotal.format(sumsubtotal),
                                      style: pw.TextStyle(fontSize: 9)),
                                ],
                              )),
                        ]),
                        pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                              child: pw.Text("Diskon",
                                  style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Text("Rp ",
                                      style: pw.TextStyle(fontSize: 9)),
                                  pw.Text(formatSubtotal.format(diskon),
                                      style: pw.TextStyle(fontSize: 9)),
                                ],
                              )),
                        ]),
                        pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                              child: pw.Text("Total",
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Text("Rp ",
                                      style: pw.TextStyle(
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold)),
                                  pw.Text(formatSubtotal.format(total),
                                      style: pw.TextStyle(
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold)),
                                ],
                              )),
                        ]),
                        pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                              child: pw.Text("Bayar",
                                  style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Text("Rp ",
                                      style: pw.TextStyle(fontSize: 9)),
                                  pw.Text(formatSubtotal.format(bayar),
                                      style: pw.TextStyle(fontSize: 9)),
                                ],
                              )),
                        ]),
                        pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                              child: pw.Text(sisaKurang >= 0 ? 'Kembali:' : 'Sisa:',
                                  style: pw.TextStyle(fontSize: 9))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Text("Rp ",
                                      style: pw.TextStyle(fontSize: 9)),
                                  pw.Text(formatSubtotal.format(sisaKurang.abs()),
                                      style: pw.TextStyle(fontSize: 9)),
                                ],
                              )),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              
              // ==============================
              // FOOTER
              // ==============================
              pw.Center(
                child: pw.Text(
                  "Barang yang sudah dibeli tidak dapat dikembalikan",
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}