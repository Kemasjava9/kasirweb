import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../models/pembelian_models.dart';

class PembelianEditPage extends StatefulWidget {
  final Map<String, dynamic> pembelianData;
  final List<Barang> barangList;
  final List<Supplier> supplierList;

  const PembelianEditPage({
    super.key,
    required this.pembelianData,
    required this.barangList,
    required this.supplierList,
  });

  @override
  State<PembelianEditPage> createState() => _PembelianEditPageState();
}

class _PembelianEditPageState extends State<PembelianEditPage> {
  late String? selectedSupplier;
  late DateTime tanggal;
  DateTime? jatuhTempo;
  late String statusPembayaran;
  late String status;

  // Item inputs
  Barang? _selectedBarangObj;
  String? _selectedBarangKode;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController(text: '0');
  final TextEditingController _hargaController = TextEditingController(text: '0');
  String _selectedSatuan = 'pcs';

  List<DetailPembelian> cartItems = [];
  List<DetailPembelian> originalItems = []; // To track changes for stock adjustment

  // For editing existing items
  int? _editingIndex;
  final TextEditingController _editJumlahController = TextEditingController();
  final TextEditingController _editHargaController = TextEditingController();
  String _editSatuan = 'pcs';

  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 1);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double get total {
    double t = 0;
    for (var it in cartItems) t += it.subtotal;
    return t;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // Load pembelian data
    selectedSupplier = widget.pembelianData['kode_supplier'];
    tanggal = DateFormat('yyyy-MM-dd').parse(widget.pembelianData['tanggal_beli']);
    jatuhTempo = widget.pembelianData['jatuh_tempo'] != null ? DateFormat('yyyy-MM-dd').parse(widget.pembelianData['jatuh_tempo']) : null;
    statusPembayaran = widget.pembelianData['status'] ?? 'Belum Lunas';
    status = widget.pembelianData['status_doc'] ?? 'Draft';

    // Load detail items
    final idBeli = widget.pembelianData['id_beli'];
    final detailsSnapshot = await _firestore.collection('detail_pembelian').where('id_beli', isEqualTo: idBeli).get();
    final details = detailsSnapshot.docs.map((doc) => DetailPembelian.fromMap(doc.data())).toList();

    setState(() {
      cartItems = details;
      originalItems = List.from(details); // Copy for stock adjustment
    });
  }

  void _addItem() {
    if (_selectedBarangKode == null) return;
    final jumlah = int.tryParse(_jumlahController.text) ?? 0;
    final harga = double.tryParse(_hargaController.text) ?? 0;
    if (jumlah <= 0) return;

    final barang = _selectedBarangObj ?? widget.barangList.firstWhere((b) => b.kodeBarang == _selectedBarangKode);

    final subtotal = jumlah * harga;
    final detail = DetailPembelian(
      idDetailBeli: DateTime.now().millisecondsSinceEpoch.toString(),
      idBeli: widget.pembelianData['id_beli'],
      kodeBarang: barang.kodeBarang,
      satuan: _selectedSatuan,
      jumlah: jumlah,
      hargaSatuan: harga,
      subtotal: subtotal,
    );

    setState(() {
      cartItems.add(detail);
      // reset item inputs
      _selectedBarangObj = null;
      _selectedBarangKode = null;
      _searchController.clear();
      _jumlahController.text = '0';
      _hargaController.text = '0';
      _selectedSatuan = 'pcs';
    });
  }

  void _removeItem(int index) {
    setState(() => cartItems.removeAt(index));
  }

  void _startEditItem(int index) {
    final item = cartItems[index];
    setState(() {
      _editingIndex = index;
      _editJumlahController.text = item.jumlah.toString();
      _editHargaController.text = item.hargaSatuan.toStringAsFixed(0);
      _editSatuan = item.satuan;
    });
  }

  void _saveEditItem() {
    if (_editingIndex == null) return;
    final jumlah = int.tryParse(_editJumlahController.text) ?? 0;
    final harga = double.tryParse(_editHargaController.text) ?? 0;
    if (jumlah <= 0) return;

    final subtotal = jumlah * harga;
    setState(() {
      cartItems[_editingIndex!] = cartItems[_editingIndex!].copyWith(
        jumlah: jumlah,
        hargaSatuan: harga,
        subtotal: subtotal,
        satuan: _editSatuan,
      );
      _editingIndex = null;
    });
  }

  void _cancelEditItem() {
    setState(() {
      _editingIndex = null;
    });
  }

  void _saveEdits() async {
    try {
      final idBeli = widget.pembelianData['id_beli'];
      final batch = _firestore.batch();

      // Update pembelian document
      final pembelianRef = _firestore.collection('pembelian').where('id_beli', isEqualTo: idBeli).limit(1).get().then((snap) => snap.docs.first.reference);
      final pembelianDoc = await pembelianRef;
      batch.update(pembelianDoc, {
        'tanggal_beli': DateFormat('yyyy-MM-dd').format(tanggal),
        'kode_supplier': selectedSupplier,
        'total_beli': total,
        'status': statusPembayaran,
        'status_doc': status,
        'jatuh_tempo': jatuhTempo != null ? DateFormat('yyyy-MM-dd').format(jatuhTempo!) : null,
      });

      // Delete old detail items and adjust stock
      for (var item in originalItems) {
        final detailQuery = await _firestore.collection('detail_pembelian').where('id_detail_beli', isEqualTo: item.idDetailBeli).limit(1).get();
        if (detailQuery.docs.isNotEmpty) {
          batch.delete(detailQuery.docs.first.reference);
        }
        // Subtract stock
        final barangRef = _firestore.collection('barang').doc(item.kodeBarang);
        final barangObj = widget.barangList.firstWhere((b) => b.kodeBarang == item.kodeBarang, orElse: () => Barang(kodeBarang: item.kodeBarang, namaBarang: item.kodeBarang, satuanPcs: 'pcs', satuanDus: 'dus', isiDus: 1, hargaPcs: 0, hargaDus: 0, jumlah: 0, hpp: 0, hppDus: 0));
        final stokToSubtract = (item.satuan == 'dus') ? (item.jumlah * barangObj.isiDus) : item.jumlah;
        batch.update(barangRef, {'jumlah': FieldValue.increment(-stokToSubtract)});
      }

      // Add new detail items and adjust stock
      for (var item in cartItems) {
        final detailRef = _firestore.collection('detail_pembelian').doc();
        batch.set(detailRef, item.toMap());
        // Add stock
        final barangRef = _firestore.collection('barang').doc(item.kodeBarang);
        final barangObj = widget.barangList.firstWhere((b) => b.kodeBarang == item.kodeBarang, orElse: () => Barang(kodeBarang: item.kodeBarang, namaBarang: item.kodeBarang, satuanPcs: 'pcs', satuanDus: 'dus', isiDus: 1, hargaPcs: 0, hargaDus: 0, jumlah: 0, hpp: 0, hppDus: 0));
        final stokToAdd = (item.satuan == 'dus') ? (item.jumlah * barangObj.isiDus) : item.jumlah;
        batch.update(barangRef, {'jumlah': FieldValue.increment(stokToAdd)});
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembelian berhasil diperbarui')),
      );
      Navigator.of(context).pop(true); // Indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _jumlahController.dispose();
    _hargaController.dispose();
    _editJumlahController.dispose();
    _editHargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pembelian'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Batal', style: TextStyle(color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: selectedSupplier != null && cartItems.isNotEmpty ? _saveEdits : null,
              child: const Text('Simpan'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;

                  final infoCard = Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informasi Pembelian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Tanggal',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(tanggal)),
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: tanggal, firstDate: DateTime(2020), lastDate: DateTime(2100));
                              if (picked != null) setState(() => tanggal = picked);
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedSupplier,
                            decoration: InputDecoration(labelText: 'Supplier', border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
                            items: widget.supplierList.map((s) => DropdownMenuItem(value: s.kodeSupplier, child: Text(s.namaSupplier))).toList(),
                            onChanged: (v) => setState(() => selectedSupplier = v),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(labelText: 'Jatuh Tempo', prefixIcon: const Icon(Icons.calendar_today), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
                            controller: TextEditingController(text: jatuhTempo == null ? '' : DateFormat('dd/MM/yyyy').format(jatuhTempo!)),
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: jatuhTempo ?? tanggal, firstDate: DateTime(2020), lastDate: DateTime(2100));
                              if (picked != null) setState(() => jatuhTempo = picked);
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: statusPembayaran,
                            decoration: InputDecoration(labelText: 'Status Pembayaran', border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
                            items: const [DropdownMenuItem(value: 'Belum Lunas', child: Text('Belum Lunas')), DropdownMenuItem(value: 'Lunas', child: Text('Lunas'))],
                            onChanged: (v) => setState(() => statusPembayaran = v ?? statusPembayaran),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: status,
                            decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
                            items: const [DropdownMenuItem(value: 'Draft', child: Text('Draft')), DropdownMenuItem(value: 'Final', child: Text('Final'))],
                            onChanged: (v) => setState(() => status = v ?? status),
                          ),
                        ],
                      ),
                    ),
                  );

                  final itemsCard = Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Expanded(child: Text('Edit Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                            Text('Total: ${currency.format(total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 12),
                          Autocomplete<Barang>(
                            displayStringForOption: (b) => b.namaBarang,
                            optionsBuilder: (text) {
                              if (text.text.isEmpty) return const Iterable<Barang>.empty();
                              return widget.barangList.where((b) => b.namaBarang.toLowerCase().contains(text.text.toLowerCase()));
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              controller.text = _searchController.text;
                              controller.selection = TextSelection.collapsed(offset: controller.text.length);
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Cari & Pilih Produk...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
                                onChanged: (v) => _searchController.text = v,
                              );
                            },
                            onSelected: (b) {
                              setState(() {
                                _selectedBarangObj = b;
                                _selectedBarangKode = b.kodeBarang;
                                _hargaController.text = (b.hpp != 0 ? b.hpp : b.hargaPcs).toStringAsFixed(0);
                                _searchController.text = b.namaBarang;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            SizedBox(
                              width: isWide ? 120 : double.infinity,
                              child: TextField(controller: _jumlahController, decoration: InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))), keyboardType: TextInputType.number),
                            ),
                            SizedBox(
                              width: isWide ? 100 : 140,
                              child: DropdownButtonFormField<String>(value: _selectedSatuan, decoration: InputDecoration(labelText: 'Satuan', border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))), items: const [DropdownMenuItem(value: 'pcs', child: Text('pcs')), DropdownMenuItem(value: 'dus', child: Text('dus'))], onChanged: (v) => setState(() => _selectedSatuan = v ?? _selectedSatuan)),
                            ),
                            SizedBox(
                              width: isWide ? 200 : double.infinity,
                              child: TextField(controller: _hargaController, decoration: InputDecoration(labelText: 'Harga Satuan', border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))), keyboardType: TextInputType.number),
                            ),
                            SizedBox(width: isWide ? null : double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(shape: const StadiumBorder()), onPressed: _selectedBarangKode != null ? _addItem : null, icon: const Icon(Icons.add_shopping_cart), label: const Text('Tambah'))),
                          ]),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('Daftar Item', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: cartItems.isEmpty
                                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]), const SizedBox(height: 8), const Text('Belum ada item', style: TextStyle(color: Colors.grey))]))
                                : ListView.separated(
                                    itemCount: cartItems.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = cartItems[index];
                                      final barang = widget.barangList.firstWhere((b) => b.kodeBarang == item.kodeBarang, orElse: () => Barang(kodeBarang: item.kodeBarang, namaBarang: item.kodeBarang, satuanPcs: 'pcs', satuanDus: 'dus', isiDus: 1, hargaPcs: item.hargaSatuan, hargaDus: item.hargaSatuan, jumlah: 0, hpp: item.hargaSatuan, hppDus: item.hargaSatuan));

                                      if (_editingIndex == index) {
                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(barang.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          flex: 2,
                                                          child: TextField(
                                                            controller: _editJumlahController,
                                                            decoration: const InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder()),
                                                            keyboardType: TextInputType.number,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          flex: 2,
                                                          child: DropdownButtonFormField<String>(
                                                            value: _editSatuan,
                                                            decoration: const InputDecoration(labelText: 'Satuan', border: OutlineInputBorder()),
                                                            items: const [
                                                              DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                                                              DropdownMenuItem(value: 'dus', child: Text('dus')),
                                                            ],
                                                            onChanged: (v) => setState(() => _editSatuan = v ?? _editSatuan),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          flex: 3,
                                                          child: TextField(
                                                            controller: _editHargaController,
                                                            decoration: const InputDecoration(labelText: 'Harga', border: OutlineInputBorder()),
                                                            keyboardType: TextInputType.number,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        ElevatedButton(
                                                          onPressed: _saveEditItem,
                                                          child: const Text('Simpan'),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        TextButton(
                                                          onPressed: _cancelEditItem,
                                                          child: const Text('Batal'),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } else {
                                        return ListTile(
                                          title: Text(barang.namaBarang),
                                          subtitle: Text('${item.jumlah} ${item.satuan} x ${currency.format(item.hargaSatuan)}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(currency.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                onPressed: () => _startEditItem(index),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _removeItem(index),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );

                  return isWide ? Row(children: [Expanded(flex: 4, child: infoCard), const SizedBox(width: 12), Expanded(flex: 6, child: itemsCard)]) : Column(children: [infoCard, const SizedBox(height: 8), itemsCard]);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(child: Text('Total: ${currency.format(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Batal')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: selectedSupplier != null && cartItems.isNotEmpty ? _saveEdits : null,
                      child: const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
