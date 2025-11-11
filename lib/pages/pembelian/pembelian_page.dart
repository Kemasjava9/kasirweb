import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../models/pembelian_models.dart';
import '../../utils/code_generator.dart';
import '../../utils/print_formats/pembelian_print_format.dart';
import 'pembelian_form_page.dart';
import 'package:printing/printing.dart';

class PembelianPage extends StatefulWidget {
  const PembelianPage({super.key});

  @override
  State<PembelianPage> createState() => _PembelianPageState();
}

class _PembelianPageState extends State<PembelianPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Barang> _barangList = [];
  List<Supplier> _supplierList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final barangSnapshot = await _firestore.collection('barang').get();
    final supplierSnapshot = await _firestore.collection('supplier').get();

    setState(() {
      _barangList = barangSnapshot.docs.map((doc) {
        return Barang.fromMap(doc.data());
      }).toList();

      _supplierList = supplierSnapshot.docs.map((doc) {
        return Supplier.fromMap(doc.data());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => PembelianFormPage(barangList: _barangList, supplierList: _supplierList)));
          if (result != null && result is Map) {
            final supplier = result['supplier'] as String;
            final tanggal = result['tanggal'] as DateTime;
            final items = result['items'] as List<DetailPembelian>;
            final statusPembayaran = result['status_pembayaran'] as String? ?? 'Belum Lunas';
            final docStatus = result['status'] as String? ?? 'Draft';
            final jatuhTempo = result['jatuh_tempo'] as DateTime?;
            _savePembelian(supplier, tanggal, items, statusPembayaran, docStatus, jatuhTempo);
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Pembelian',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Transaksi Pembelian',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const SizedBox(width: 56), // reserve space for FAB
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('pembelian').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var pembelianList = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: pembelianList.length,
                    itemBuilder: (context, index) {
                      var data = pembelianList[index].data() as Map<String, dynamic>;
                      final idBeli = data['id_beli']?.toString() ?? '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: const Icon(Icons.shopping_cart, color: Colors.green),
                          title: Text('Pembelian #${data['id_beli']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Supplier: ${data['kode_supplier']}'),
                              Text('Tanggal: ${data['tanggal_beli']}'),
                              Text('Total: Rp ${NumberFormat('#,###').format(data['total_beli'])}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  data['status'] ?? 'Pending',
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
                                future: _firestore.collection('detail_pembelian').where('id_beli', isEqualTo: idBeli).get(),
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
                                      child: Text('Tidak ada item pembelian'),
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
                                      final hargaSatuan = (m['harga_satuan'] ?? 0).toDouble();
                                      final subtotal = (m['subtotal'] ?? 0).toDouble();

                                      return ListTile(
                                        title: Text('${barang.namaBarang} (${kode})'),
                                        subtitle: Text('$jumlah • ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(hargaSatuan)}'),
                                        trailing: Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(subtotal)),
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
                                  tooltip: 'Hapus Pembelian',
                                  onPressed: () => _showDeleteDialog(data, idBeli),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.print, color: Colors.blue),
                                  tooltip: 'Cetak',
                                  onPressed: () => _printPembelian(data),
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
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Lunas':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


  void _savePembelian(String supplier, DateTime tanggal, List<DetailPembelian> cartItems, String statusPembayaran, String docStatus, DateTime? jatuhTempo) async {
    try {

      // Generate pembelian code PBnnnnn/MM/YYYY
      final now = DateTime.now();
      final pembelianId = await CodeGenerator.nextMonthlyCode(_firestore, 'pembelian', 'id_beli', 'PB', 5, now.month, now.year);

      // Calculate total
      double total = 0;
      for (var item in cartItems) {
        total += item.subtotal;
      }

      // Prepare batch
      final batch = _firestore.batch();

  // Use an auto-generated document id for the Firestore document
  // because `pembelianId` produced by nextMonthlyCode contains
  // slashes (e.g. PB00001/11/2025). Using that string as a doc id
  // would be interpreted as a nested path and can create unexpected
  // document ids such as '11'. Store the generated code inside the
  // document data (`id_beli`) instead.
  final pembelianRef = _firestore.collection('pembelian').doc();
      final pembelianData = {
        'id_beli': pembelianId,
        'tanggal_beli': DateFormat('yyyy-MM-dd').format(tanggal),
        'kode_supplier': supplier,
        'total_beli': total,
        // Save payment status from form (Lunas / Belum Lunas)
        'status': statusPembayaran,
        // Preserve document creation status (Draft / Final) in a separate field
        'status_doc': docStatus,
        'jatuh_tempo': jatuhTempo != null ? DateFormat('yyyy-MM-dd').format(jatuhTempo) : DateFormat('yyyy-MM-dd').format(tanggal.add(const Duration(days: 30))),
      };

      batch.set(pembelianRef, pembelianData);

      // Add detail rows and update stock using increment
      for (var item in cartItems) {
        final detailRef = _firestore.collection('detail_pembelian').doc();
        final detailData = {
          'id_detail_beli': detailRef.id,
          'id_beli': pembelianId,
          'kode_barang': item.kodeBarang,
          'satuan': item.satuan,
          'jumlah': item.jumlah,
          'harga_satuan': item.hargaSatuan,
          'subtotal': item.subtotal,
        };
        batch.set(detailRef, detailData);

        // Compute stock increment based on selected satuan.
        // If satuan is 'dus', convert to pcs by multiplying with isiDus.
        final barangRef = _firestore.collection('barang').doc(item.kodeBarang);
        final barangObj = _barangList.firstWhere(
          (b) => b.kodeBarang == item.kodeBarang,
          orElse: () => Barang(
            kodeBarang: item.kodeBarang,
            namaBarang: item.kodeBarang,
            satuanPcs: 'pcs',
            satuanDus: 'dus',
            isiDus: 1,
            hargaPcs: item.hargaSatuan,
            hargaDus: item.hargaSatuan,
            jumlah: 0,
            hpp: 0,
            hppDus: 0,
          ),
        );

        final stokToAdd = (item.satuan == 'dus') ? (item.jumlah * barangObj.isiDus) : item.jumlah;
        batch.update(barangRef, {
          'jumlah': FieldValue.increment(stokToAdd),
        });
      }

      // Commit batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembelian berhasil disimpan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Stock updates are handled in the write batch when saving pembelian.
  
  // Stock updates are handled in the write batch when saving pembelian.

  void _showDetailDialog(Map<String, dynamic> data) {
    final idBeli = data['id_beli']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detail Pembelian #$idBeli'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID Beli: $idBeli'),
                Text('Tanggal: ${data['tanggal_beli']}'),
                Text('Supplier: ${data['kode_supplier']}'),
                Text('Status: ${data['status']}'),
                Text('Jatuh Tempo: ${data['jatuh_tempo'] ?? ''}'),
                const SizedBox(height: 12),
                const Text('Detail Item:', style: TextStyle(fontWeight: FontWeight.bold)),
                FutureBuilder<QuerySnapshot>(
                  future: _firestore.collection('detail_pembelian').where('id_beli', isEqualTo: idBeli).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final details = snapshot.data?.docs ?? [];
                    if (details.isEmpty) return const Text('Tidak ada item');

                    return Column(
                      children: details.map((doc) {
                        final item = doc.data() as Map<String, dynamic>;
                        final kode = item['kode_barang'] ?? '';
                        final barang = _barangList.firstWhere((b) => b.kodeBarang == kode, orElse: () => Barang(kodeBarang: kode, namaBarang: kode, satuanPcs: 'pcs', satuanDus: 'dus', isiDus: 1, hargaPcs: item['harga_satuan']?.toDouble() ?? 0.0, hargaDus: item['harga_satuan']?.toDouble() ?? 0.0, jumlah: 0, hpp: 0.0, hppDus: 0.0));
                        return ListTile(
                          title: Text('${barang.namaBarang} (${kode})'),
                          subtitle: Text('${item['jumlah']} x ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['harga_satuan'])}'),
                          trailing: Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['subtotal'] ?? 0)),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
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
                          content: const Text('Tandai pembelian ini sebagai Lunas?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Lunas')),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      try {
                        // Update all pembelian documents that match this id_beli
                        final q = await _firestore.collection('pembelian').where('id_beli', isEqualTo: idBeli).get();
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

  void _showDeleteDialog(Map<String, dynamic> data, String idBeli) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus pembelian #$idBeli?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await _deletePembelian(idBeli);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePembelian(String idBeli) async {
    try {
      // Find detail items
      final detailSnapshot = await _firestore.collection('detail_pembelian').where('id_beli', isEqualTo: idBeli).get();
      final batch = _firestore.batch();

      // Reduce stock for each item (reverse the increment done when saving pembelian)
      for (var doc in detailSnapshot.docs) {
        final data = doc.data();
        final kodeBarang = data['kode_barang'];

        // Safely parse jumlah as int
        final rawJumlah = data['jumlah'];
        final int jumlah = (rawJumlah is num) ? rawJumlah.toInt() : int.tryParse(rawJumlah?.toString() ?? '0') ?? 0;

        final satuan = (data['satuan'] ?? 'pcs').toString();

        final barangObj = _barangList.firstWhere(
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

        final stokToRestore = (satuan == 'dus') ? (jumlah * barangObj.isiDus) : jumlah;

        // Use set with merge so we don't fail if the barang document is missing
        final barangRef = _firestore.collection('barang').doc(kodeBarang);
        batch.set(barangRef, {
          'jumlah': FieldValue.increment(-stokToRestore),
        }, SetOptions(merge: true));

        // Delete detail item
        batch.delete(doc.reference);
      }

      // Delete main pembelian document(s) where id_beli == idBeli
      final pembelianQuery = await _firestore.collection('pembelian').where('id_beli', isEqualTo: idBeli).get();
      for (var doc in pembelianQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembelian berhasil dihapus')));
      // Refresh local lists/state
      _loadData();
    } catch (e, st) {
      // Log stacktrace to help debugging
      debugPrint('Error deleting pembelian: $e');
      debugPrintStack(stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error menghapus pembelian: $e')));
    }
  }

  Future<void> _printPembelian(Map<String, dynamic> data) async {
    try {
      final idBeli = data['id_beli']?.toString() ?? '';
      // Get detail items
      final detailSnapshot = await _firestore.collection('detail_pembelian').where('id_beli', isEqualTo: idBeli).get();
      final items = detailSnapshot.docs.map((d) => d.data()).toList();

      final bytes = await PembelianPrintFormat.buildPembelianPdf(data, items.cast<Map<String, dynamic>>(), _barangList);
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mencetak pembelian: $e')));
    }
  }
}