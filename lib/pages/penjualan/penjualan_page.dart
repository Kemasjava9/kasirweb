import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart' hide DetailPenjualan;
import '../../models/penjualan_models.dart';
import '../../utils/code_generator.dart';
import 'penjualan_form_page.dart';
import 'package:printing/printing.dart';
import '../../utils/print_formats/faktur_print_format.dart';
import '../../utils/print_formats/surat_jalan_print_format.dart';

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({super.key});

  @override
  State<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Barang> _barangList = [];
  List<Pelanggan> _pelangganList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final barangSnapshot = await _firestore.collection('barang').get();
    final pelangganSnapshot = await _firestore.collection('pelanggan').get();

    setState(() {
      _barangList = barangSnapshot.docs.map((doc) {
        return Barang.fromMap(doc.data());
      }).toList();

      _pelangganList = pelangganSnapshot.docs.map((doc) {
        return Pelanggan.fromMap(doc.data());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Transaksi Penjualan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                      const SizedBox(width: 56),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('penjualan').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var penjualanList = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: penjualanList.length,
                    itemBuilder: (context, index) {
                      var data = penjualanList[index].data() as Map<String, dynamic>;
                      final nofaktur = data['nofaktur_jual']?.toString() ?? '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: const Icon(Icons.point_of_sale, color: Colors.blue),
                          title: Text('Penjualan #$nofaktur'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pelanggan: ${data['nama_pelanggan']}'),
                              Text('Tanggal: ${data['tanggal_jual']}'),
                              Text(
                                NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 1)
                                    .format((data['total_jual'] ?? 0).toDouble()),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  (data['status'] ?? 'Pending').toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: _getStatusColor(data['status']),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: FutureBuilder<QuerySnapshot>(
                                future: _firestore
                                    .collection('detail_penjualan')
                                    .where('nofaktur_jual', isEqualTo: nofaktur)
                                    .get(),
                                builder: (context, snapDetail) {
                                  if (snapDetail.connectionState == ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  if (snapDetail.hasError) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Error: ${snapDetail.error}'),
                                    );
                                  }

                                  final details = snapDetail.data?.docs ?? [];
                                  if (details.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Tidak ada item penjualan'),
                                    );
                                  }

                                  return Column(
                                    children: details.map((d) {
                                      final m = d.data() as Map<String, dynamic>;
                                      final kode = m['kode_barang'] ?? '';
                                      final barang = _barangList.firstWhere(
                                        (b) => b.kodeBarang == kode,
                                        orElse: () => Barang(
                                          kodeBarang: kode,
                                          namaBarang: kode,
                                          satuanPcs: 'pcs',
                                          satuanDus: 'dus',
                                          isiDus: 1,
                                          hargaPcs: (m['harga_satuan']?.toDouble() ?? 0.0),
                                          hargaDus: (m['harga_satuan']?.toDouble() ?? 0.0),
                                          jumlah: 0,
                                          hpp: 0.0,
                                          hppDus: 0.0,
                                        ),
                                      );
                                      final jumlah = m['jumlah'] ?? 0;
                                      final satuan = m['satuan'] ?? '';
                                      final hargaSatuan = (m['harga_satuan'] ?? 0).toDouble();
                                      final subtotal = (m['subtotal'] ?? 0).toDouble();

                                      return ListTile(
                                        title: Text('${barang.namaBarang} (${kode})'),
                                        subtitle: Text('$jumlah $satuan • ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 1).format(hargaSatuan)}'),
                                        trailing: Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 1).format(subtotal)),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                            ButtonBar(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.green),
                                  tooltip: 'Lihat Detail',
                                  onPressed: () => _showDetailDialog(data),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Hapus Penjualan',
                                  onPressed: () => _showDeleteDialog(data, nofaktur),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.print, color: Colors.blue),
                                  tooltip: 'Cetak Faktur',
                                  onPressed: () => _printFaktur(data),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.local_shipping, color: Colors.blue),
                                  tooltip: 'Buat Surat Jalan',
                                  onPressed: () => _showSuratJalanDialog(data),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PenjualanFormPage()));
          if (result != null && result is Map) {
            try {
              final pelanggan = result['pelanggan'] as String?;
              final tanggal = result['tanggal'] as DateTime?;
              final caraBayar = result['cara_bayar'] as String? ?? '';
              final itemsRaw = result['items'] as List<dynamic>?;

              if (pelanggan == null || tanggal == null || itemsRaw == null || itemsRaw.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data penjualan tidak lengkap')));
                return;
              }

              // Reconstruct DetailPenjualan instances from maps (or pass-through if already of that type)
              final items = <DetailPenjualan>[];
              for (var it in itemsRaw) {
                if (it is DetailPenjualan) {
                  items.add(it);
                } else if (it is Map<String, dynamic>) {
                  items.add(DetailPenjualan.fromMap(it));
                } else if (it is Map) {
                  items.add(DetailPenjualan.fromMap(Map<String, dynamic>.from(it)));
                }
              }

              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item penjualan tidak valid')));
                return;
              }

              final sales = result['sales'] as String?;
              final komisi = result['komisi'] as String?;
              await _savePenjualan(pelanggan, tanggal, caraBayar, items, sales, komisi);
            } catch (e, st) {
              // Don't crash the app; show error and log
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memproses penjualan: $e')));
              // ignore: avoid_print
              print('Error processing penjualan result: $e\n$st');
            }
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Penjualan',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Lunas':
        return Colors.green;
      case 'Belum Lunas':
      case 'Pending':
        return Colors.orange;
      case 'Batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // _calculateTotal removed; totals are computed in form pages now.

  Future<void> _savePenjualan(String pelanggan, DateTime tanggal, String caraBayar, List<DetailPenjualan> cartItems, String? sales, String? komisi) async {
    try {
      // Start a new batch
      final batch = _firestore.batch();
      
      // Generate penjualan code PJnnnnn/MM/YYYY
      final now = DateTime.now();
      final noFaktur = await CodeGenerator.nextMonthlyCode(_firestore, 'penjualan', 'nofaktur_jual', 'PJ', 5, now.month, now.year);
      
      // Calculate total
      double total = 0;
      for (var item in cartItems) {
        total += item.subtotal;
      }

      final pelangganData = _pelangganList.firstWhere((p) => p.kodePelanggan == pelanggan);

      // Prepare penjualan data according to schema
      final penjualanData = {
        'nofaktur_jual': noFaktur,
        'tanggal_jual': DateFormat('dd-MM-yyyy').format(tanggal),
        'total_jual': total,
        'id_user': 1, // Default user ID
        'nama_sales': sales ?? 'Sales 1',
        'bayar': total.toString(),
        'nama_pelanggan': pelangganData.namaPelanggan,
        'cara_bayar': caraBayar,
        'status': caraBayar.toLowerCase() == 'tunai' ? 'Lunas' : 'Belum Lunas',
        'diskon': 0.0,
        'biaya_lain_lain': 0.0,
        'ongkos_kirim': 0.0,
        'komisi': komisi ?? '',
      };

      // Add penjualan document to batch
      final penjualanRef = _firestore.collection('penjualan').doc();
      batch.set(penjualanRef, penjualanData);

      // Process each item in the cart
      for (var item in cartItems) {
        // Prepare detail penjualan data according to schema
        final detailData = {
          'id_detail_jual': DateTime.now().millisecondsSinceEpoch.toString(),
          'nofaktur_jual': noFaktur,
          'kode_barang': item.kodeBarang,
          'jumlah': item.jumlah,
          'harga_satuan': item.hargaSatuan,
          'subtotal': item.subtotal,
          'satuan': item.satuan,
          'nilai_komisi': item.nilaiKomisi,
          'nama_komisi': item.namaKomisi,
        };

        // Add detail_penjualan document to batch
        final detailRef = _firestore.collection('detail_penjualan').doc();
        batch.set(detailRef, detailData);

        // Update stock in the same batch
        final stokToReduce = item.satuan == 'dus' 
          ? item.jumlah * _barangList.firstWhere((b) => b.kodeBarang == item.kodeBarang).isiDus 
          : item.jumlah;
        
        final barangRef = _firestore.collection('barang').doc(item.kodeBarang);
        batch.update(barangRef, {
          'jumlah': FieldValue.increment(-stokToReduce)
        });
      }

      // Commit the entire batch atomically
      await batch.commit();

      // Diagnostic: count how many detail_penjualan were saved for this nofaktur
      try {
        final q = await _firestore.collection('detail_penjualan').where('nofaktur_jual', isEqualTo: noFaktur).get();
        final savedCount = q.docs.length;
        // ignore: avoid_print
        print('Saved penjualan $noFaktur with $savedCount detail_penjualan items');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Penjualan berhasil disimpan ($savedCount item)')),
        );
      } catch (e) {
        // ignore: avoid_print
        print('Error counting detail_penjualan after commit: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penjualan berhasil disimpan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }

  void _showSuratJalanDialog(Map<String, dynamic> penjualanData) async {
    final nofaktur = penjualanData['nofaktur_jual']?.toString() ?? '';
    final TextEditingController nomorController = TextEditingController();
    final TextEditingController penerimaController = TextEditingController(text: penjualanData['nama_pelanggan'] ?? '');
    final TextEditingController alamatController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime tanggal = DateTime.now();
    bool usePenjualanData = true;
    List<Map<String, dynamic>> items = [];

    // If using penjualan data, prefetch detail_penjualan
    Future<void> loadItemsFromPenjualan() async {
      final q = await _firestore.collection('detail_penjualan').where('nofaktur_jual', isEqualTo: nofaktur).get();
      items = q.docs.map((d) {
        final m = d.data();
        final kode = m['kode_barang'] ?? '';
        final barang = _barangList.firstWhere((b) => b.kodeBarang == kode, orElse: () => Barang(kodeBarang: kode, namaBarang: kode, satuanPcs: 'pcs', satuanDus: 'dus', isiDus: 1, hargaPcs: m['harga_satuan']?.toDouble() ?? 0.0, hargaDus: m['harga_satuan']?.toDouble() ?? 0.0, jumlah: 0, hpp: 0.0, hppDus: 0.0));
        return {
          'kode_barang': kode,
          'nama_barang': barang.namaBarang,
          'jumlah': m['jumlah'] ?? 0,
          'satuan': m['satuan'] ?? '',
        };
      }).toList();
    }

    await loadItemsFromPenjualan();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Buat Surat Jalan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: nomorController,
                        decoration: const InputDecoration(labelText: 'Nomor Surat (biarkan kosong untuk auto)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: tanggal, firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (picked != null) setState(() => tanggal = picked);
                      },
                      child: const Text('Pilih Tanggal'),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  TextField(controller: penerimaController, decoration: const InputDecoration(labelText: 'Penerima')),
                  const SizedBox(height: 8),
                  TextField(controller: alamatController, decoration: const InputDecoration(labelText: 'Alamat')),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('Sumber:'),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Dari Penjualan'),
                      selected: usePenjualanData,
                      onSelected: (v) => setState(() => usePenjualanData = true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Manual'),
                      selected: !usePenjualanData,
                      onSelected: (v) => setState(() => usePenjualanData = false),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (usePenjualanData) ...[
                    const Text('Item (dari penjualan):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: items.map((it) {
                        return Row(
                          children: [
                            Expanded(child: Text('${it['nama_barang']} (${it['kode_barang']})')),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: it['jumlah'].toString(),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => it['jumlah'] = int.tryParse(v) ?? 0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(it['satuan'] ?? ''),
                          ],
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const Text('Masukkan item secara manual (satu per baris: kode|nama|jumlah|satuan)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 5,
                      decoration: const InputDecoration(hintText: 'Contoh: B001|Produk A|2|pcs'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        final lines = notesController.text.split('\n');
                        items = [];
                        for (var ln in lines) {
                          final parts = ln.split('|');
                          if (parts.length >= 4) {
                            items.add({
                              'kode_barang': parts[0].trim(),
                              'nama_barang': parts[1].trim(),
                              'jumlah': int.tryParse(parts[2].trim()) ?? 0,
                              'satuan': parts[3].trim(),
                            });
                          }
                        }
                        setState(() {});
                      },
                      child: const Text('Parse Manual'),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  // Save surat jalan
                  Navigator.pop(context);
                  await _saveSuratJalan(
                    nomorController.text,
                    tanggal,
                    nofaktur,
                    penerimaController.text,
                    alamatController.text,
                    items,
                    usePenjualanData,
                    notesController.text,
                  );
                },
                child: const Text('Simpan Surat Jalan'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _saveSuratJalan(
    String nomor,
    DateTime tanggal,
    String nofakturJual,
    String penerima,
    String alamat,
    List<Map<String, dynamic>> items,
    bool fromPenjualan,
    String notes,
  ) async {
    try {
      final now = DateTime.now();
      if (nomor.isEmpty) {
        // Use width=4 to produce SJ0001/MM/YYYY
        nomor = await CodeGenerator.nextMonthlyCode(_firestore, 'surat_jalan', 'nomor_surat', 'SJ', 4, now.month, now.year);
      }

      final data = {
        'nomor_surat': nomor,
        'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
        'nofaktur_jual': nofakturJual,
        'penerima': penerima,
        'alamat': alamat,
        'items': items,
        'from_penjualan': fromPenjualan,
        'notes': notes,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('surat_jalan').doc(nomor).set(data);

      // Prepare saved data for printing/export
      final savedData = Map<String, dynamic>.from(data);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Surat jalan disimpan')));
      // Show post-save options (print/share)
      _showSuratJalanPostSaveOptions(savedData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error menyimpan surat jalan: $e')));
    }
  }

  void _showSuratJalanPostSaveOptions(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Surat Jalan Disimpan'),
          content: const Text('Pilih aksi berikut untuk surat jalan:'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _printSuratJalan(data);
              },
              child: const Text('Cetak'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final bytes = await SuratJalanPrintFormat.buildSuratJalanPdf(data);
                  await Printing.sharePdf(bytes: bytes, filename: 'SuratJalan_${data['nomor_surat'] ?? 'sj'}.pdf');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error share PDF: $e')));
                }
              },
              child: const Text('Bagikan'),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ],
        );
      },
    );
  }



  Future<void> _printSuratJalan(Map<String, dynamic> data) async {
    try {
      final bytes = await SuratJalanPrintFormat.buildSuratJalanPdf(data);
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generate/print PDF: $e')));
    }
  }

  void _showDetailDialog(Map<String, dynamic> data) {
    final nofaktur = data['nofaktur_jual']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Make the dialog wider on larger screens while keeping it scrollable
          insetPadding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 24.0),
          title: Text('Detail Penjualan #$nofaktur'),
          content: Builder(
            builder: (ctx) {
              // Responsive width: use up to 90% of screen width but cap at 1000px
              final screenW = MediaQuery.of(ctx).size.width;
              final dialogMaxW = screenW > 1000 ? 1000.0 : screenW * 0.9;
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: dialogMaxW),
                child: SingleChildScrollView(
                  child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Faktur: $nofaktur'),
                Text('Tanggal: ${data['tanggal_jual']}'),
                Text('Pelanggan: ${data['nama_pelanggan']}'),
                Text('Sales: ${data['nama_sales']}'),
                Text('Cara Bayar: ${data['cara_bayar']}'),
                Text('Status: ${data['status']}'),
                Text('Diskon: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(data['diskon'] ?? 0)}'),
                Text('Ongkos Kirim: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(data['ongkos_kirim'] ?? 0)}'),
                Text('Biaya Lain: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(data['biaya_lain_lain'] ?? 0)}'),
                Text('Total: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(data['total_jual'] ?? 0)}'),
                const SizedBox(height: 16),
                const Text('Detail Item:', style: TextStyle(fontWeight: FontWeight.bold)),
                FutureBuilder<QuerySnapshot>(
                  future: _firestore.collection('detail_penjualan').where('nofaktur_jual', isEqualTo: nofaktur).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final details = snapshot.data?.docs ?? [];
                    return Column(
                      children: details.map((doc) {
                        final item = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text('${item['kode_barang']}'),
                          subtitle: Text('${item['jumlah']} ${item['satuan']} x ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['harga_satuan'])}'),
                          trailing: Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['subtotal'])),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
            ElevatedButton(
              onPressed: (data['status'] == 'Lunas')
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Konfirmasi Pembayaran'),
                          content: const Text('Tandai penjualan ini sebagai Lunas?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Lunas')),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      try {
                        final q = await _firestore.collection('penjualan').where('nofaktur_jual', isEqualTo: nofaktur).get();
                        final batch = _firestore.batch();
                        for (var doc in q.docs) {
                          batch.update(doc.reference, {
                            'status': 'Lunas',
                            'tanggal_lunas': FieldValue.serverTimestamp(),
                          });
                        }
                        await batch.commit();
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Status pembayaran diupdate menjadi Lunas')));
                      } catch (e) {
                        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Error update status: $e')));
                      }
                    },
              child: const Text('Lunas'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(Map<String, dynamic> data, String nofaktur) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus penjualan #$nofaktur?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await _deletePenjualan(nofaktur);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePenjualan(String nofaktur) async {
    try {
      // Get detail items to restore stock
      final detailSnapshot = await _firestore.collection('detail_penjualan').where('nofaktur_jual', isEqualTo: nofaktur).get();
      final batch = _firestore.batch();

      // Restore stock for each item
      for (var doc in detailSnapshot.docs) {
        final data = doc.data();
        final kodeBarang = data['kode_barang'];

        // Safe parsing: jumlah may come as int, double or string
        final rawJumlah = data['jumlah'];
        final int jumlah = (rawJumlah is num) ? rawJumlah.toInt() : int.tryParse(rawJumlah?.toString() ?? '0') ?? 0;

        final satuan = (data['satuan'] ?? '').toString();

        // Find barang in local cache; if missing, use sensible defaults
        final barang = _barangList.firstWhere(
          (b) => b.kodeBarang == kodeBarang,
          orElse: () => Barang(
            kodeBarang: kodeBarang,
            namaBarang: kodeBarang,
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

        final stokToRestore = satuan == 'dus' ? jumlah * barang.isiDus : jumlah;

        // Use set with merge to avoid failing if barang doc is missing
        final barangRef = _firestore.collection('barang').doc(kodeBarang);
        batch.set(barangRef, {
          'jumlah': FieldValue.increment(stokToRestore)
        }, SetOptions(merge: true));

        // Delete detail item
        batch.delete(doc.reference);
      }

      // Delete main penjualan document(s)
      final penjualanQuery = await _firestore.collection('penjualan').where('nofaktur_jual', isEqualTo: nofaktur).get();
      for (var doc in penjualanQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penjualan berhasil dihapus')));
      // Refresh local cache
      _loadData();
    } catch (e, st) {
      debugPrint('Error deleting penjualan $nofaktur: $e');
      debugPrintStack(stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error menghapus penjualan: $e')));
    }
  }

  Future<void> _printFaktur(Map<String, dynamic> data) async {
    final nofaktur = data['nofaktur_jual']?.toString() ?? '';
    try {
      // Get detail items
      final detailSnapshot = await _firestore.collection('detail_penjualan').where('nofaktur_jual', isEqualTo: nofaktur).get();
      final items = detailSnapshot.docs.map((doc) => doc.data()).toList();

      final bytes = await FakturPrintFormat.buildFakturPdf(data, items, _barangList);
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mencetak faktur: $e')));
    }
  }
}

