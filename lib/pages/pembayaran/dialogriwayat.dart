import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DialogRiwayatPembayaran {
    static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Future<void> show(BuildContext context, List<Map<String, dynamic>> riwayatPembayaran, {String? nofaktur}) async {
    final TextEditingController pembayaranController = TextEditingController();
    DateTime? tanggalPembayaran;
    final TextEditingController keteranganController = TextEditingController();
    List<Map<String, dynamic>> pembayaranList = List.from(riwayatPembayaran);
    double? totalJual;
    double currentBayar = 0.0;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // If nofaktur provided and totals not loaded yet, fetch penjualan totals
            if (nofaktur != null && nofaktur.isNotEmpty && totalJual == null) {
              // load penjualan totals
              () async {
                try {
                  final q = await _firestore
                      .collection('penjualan')
                      .where('nofaktur_jual', isEqualTo: nofaktur)
                      .get();
                  if (q.docs.isNotEmpty) {
                    final d = q.docs.first.data();
                    final rawTotal = d['total_jual'];
                    double t = 0;
                    if (rawTotal is num) t = rawTotal.toDouble();
                    else if (rawTotal is String) t = double.tryParse(rawTotal) ?? 0;

                    final rawBayar = d['bayar'];
                    double b = 0;
                    if (rawBayar is num) b = rawBayar.toDouble();
                    else if (rawBayar is String) b = double.tryParse(rawBayar) ?? 0;

                    totalJual = t;
                    currentBayar = b;
                    // trigger rebuild
                    setState(() {});
                  }
                } catch (_) {}
              }();
            }

            return AlertDialog(
              title: const Text('Riwayat Pembayaran'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // show total and remaining if available
                      if (totalJual != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalJual)}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Terbayar: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(currentBayar)}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sisa: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                                  .format((totalJual! - currentBayar).clamp(0, double.infinity))}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                      ],
                      // List riwayat pembayaran
                      if (pembayaranList.isEmpty)
                        const Text('Belum ada riwayat pembayaran.')
                      else ...[
                        ...pembayaranList.map((data) {
                          final tanggal = data['tanggal'] ?? '';
                          final nominal = data['nominal'] ?? 0;
                          final keterangan = data['keterangan'] ?? '';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.payment),
                              title: Text(
                                'Rp ${NumberFormat('#,##0', 'id').format(nominal)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tanggal: $tanggal'),
                                  if (keterangan.isNotEmpty) Text('Keterangan: $keterangan'),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const Divider(height: 24),
                      ],
                      // Input pembayaran baru
                      TextField(
                        controller: pembayaranController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nominal Pembayaran',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tanggalPembayaran == null
                                  ? 'Tanggal pembayaran belum dipilih'
                                  : 'Tanggal: ${DateFormat('dd-MM-yyyy').format(tanggalPembayaran!)}',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => tanggalPembayaran = picked);
                              }
                            },
                            child: const Text('Pilih Tanggal'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: keteranganController,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan',
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nominal = int.tryParse(pembayaranController.text) ?? 0;
                    if (nominal <= 0 || tanggalPembayaran == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nominal dan tanggal harus diisi')),
                      );
                      return;
                    }
                    final newPembayaran = {
                      'tanggal': DateFormat('dd-MM-yyyy').format(tanggalPembayaran!),
                      'nominal': nominal,
                      'keterangan': keteranganController.text,
                      'created_at': FieldValue.serverTimestamp(),
                    };
                      try {
                      // include invoice reference if provided
                      if (nofaktur != null && nofaktur.isNotEmpty) {
                        newPembayaran['nofaktur_jual'] = nofaktur;
                      }
                      await _firestore.collection('riwayat_pembayaran').add(newPembayaran);
                      pembayaranList.add({
                        'tanggal': newPembayaran['tanggal'],
                        'nominal': newPembayaran['nominal'],
                        'keterangan': newPembayaran['keterangan'],
                        if (nofaktur != null) 'nofaktur_jual': nofaktur,
                      });

                      // Update penjualan.bayar and status if nofaktur available
                      if (nofaktur != null && nofaktur.isNotEmpty) {
                        try {
                          final q = await _firestore
                              .collection('penjualan')
                              .where('nofaktur_jual', isEqualTo: nofaktur)
                              .get();
                          for (var doc in q.docs) {
                            final d = doc.data();
                            // parse current bayar safely
                            final rawBayar = d['bayar'];
                            double currentBayar = 0;
                            if (rawBayar is num) {
                              currentBayar = rawBayar.toDouble();
                            } else if (rawBayar is String) {
                              currentBayar = double.tryParse(rawBayar) ?? 0;
                            }
                            final rawTotal = d['total_jual'];
                            double totalJual = 0;
                            if (rawTotal is num) {
                              totalJual = rawTotal.toDouble();
                            } else if (rawTotal is String) {
                              totalJual = double.tryParse(rawTotal) ?? 0;
                            }
                            final added = (newPembayaran['nominal'] as num).toDouble();
                            final updatedBayar = currentBayar + added;
                            final updatedStatus = updatedBayar >= totalJual ? 'Lunas' : (d['status'] ?? 'Belum Lunas');
                            await doc.reference.update({
                              'bayar': updatedBayar.toString(),
                              'status': updatedStatus,
                            });
                            // update local currentBayar so UI shows updated sisa
                            currentBayar = updatedBayar;
                          }
                        } catch (e) {
                          // ignore penjualan update failure but notify user
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pembayaran tersimpan, tapi gagal update penjualan: $e')),
                          );
                        }
                      }
                      pembayaranController.clear();
                      tanggalPembayaran = null;
                      keteranganController.clear();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pembayaran berhasil disimpan')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal menyimpan pembayaran: $e')),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
