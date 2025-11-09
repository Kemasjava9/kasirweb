import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../models/pembelian_models.dart';

class PembelianFormPage extends StatefulWidget {
  final List<Barang> barangList;
  final List<Supplier> supplierList;

  const PembelianFormPage({super.key, required this.barangList, required this.supplierList});

  @override
  State<PembelianFormPage> createState() => _PembelianFormPageState();
}

class _PembelianFormPageState extends State<PembelianFormPage> {
  String? selectedSupplier;
  DateTime tanggal = DateTime.now();
  DateTime? jatuhTempo;
  String statusPembayaran = 'Belum Lunas';
  String status = 'Draft';

  // Item inputs
  Barang? _selectedBarangObj;
  String? _selectedBarangKode;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController(text: '0');
  final TextEditingController _hargaController = TextEditingController(text: '0');
  String _selectedSatuan = 'pcs';

  List<DetailPembelian> cartItems = [];

  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 1);

  double get total {
    double t = 0;
    for (var it in cartItems) t += it.subtotal;
    return t;
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
      idBeli: '',
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

  @override
  void dispose() {
    _searchController.dispose();
    _jumlahController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pembelian'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Batal', style: TextStyle(color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: selectedSupplier != null && cartItems.isNotEmpty
                  ? () => Navigator.of(context).pop({
                        'supplier': selectedSupplier,
                        'tanggal': tanggal,
                        'items': cartItems,
                        'status_pembayaran': statusPembayaran,
                        'status': status,
                        'jatuh_tempo': jatuhTempo
                      })
                  : null,
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
                            const Expanded(child: Text('Tambah Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
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
                                      return ListTile(
                                        title: Text(barang.namaBarang),
                                        subtitle: Text('${item.jumlah} x ${currency.format(item.hargaSatuan)}'),
                                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(currency.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeItem(index))]),
                                      );
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
                      onPressed: selectedSupplier != null && cartItems.isNotEmpty ? () => Navigator.of(context).pop({'supplier': selectedSupplier, 'tanggal': tanggal, 'items': cartItems, 'status_pembayaran': statusPembayaran, 'status': status, 'jatuh_tempo': jatuhTempo}) : null,
                      child: const Text('Simpan Pembelian'),
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

class TambahBarangPembelianPage extends StatefulWidget {
  final List<Barang> barangList;
  const TambahBarangPembelianPage({super.key, required this.barangList});

  @override
  State<TambahBarangPembelianPage> createState() => _TambahBarangPembelianPageState();
}

class _TambahBarangPembelianPageState extends State<TambahBarangPembelianPage> {
  String? selectedBarang;
  String satuan = 'pcs';
  final jumlahController = TextEditingController();
  final hargaController = TextEditingController();

  @override
  void dispose() {
    jumlahController.dispose();
    hargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Barang'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Batal', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedBarang,
              decoration: const InputDecoration(labelText: 'Pilih Barang', border: OutlineInputBorder()),
              items: widget.barangList.map((b) => DropdownMenuItem(value: b.kodeBarang, child: Text(b.namaBarang))).toList(),
              onChanged: (v) {
                setState(() {
                  selectedBarang = v;
                  if (v != null) {
                    final barang = widget.barangList.firstWhere((b) => b.kodeBarang == v);
                    hargaController.text = (barang.hpp != 0 ? barang.hpp : barang.hargaPcs).toStringAsFixed(0);
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(controller: jumlahController, decoration: const InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: satuan, decoration: const InputDecoration(labelText: 'Satuan', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'pcs', child: Text('pcs')), DropdownMenuItem(value: 'dus', child: Text('dus'))], onChanged: (v) => setState(() => satuan = v ?? 'pcs')),
            const SizedBox(height: 8),
            TextField(controller: hargaController, decoration: const InputDecoration(labelText: 'Harga Satuan', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Batal')),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                onPressed: selectedBarang != null && jumlahController.text.isNotEmpty && hargaController.text.isNotEmpty
                    ? () {
                        final detail = DetailPembelian(idDetailBeli: DateTime.now().millisecondsSinceEpoch.toString(), idBeli: '', kodeBarang: selectedBarang!, satuan: satuan, jumlah: int.parse(jumlahController.text), hargaSatuan: double.parse(hargaController.text), subtotal: int.parse(jumlahController.text) * double.parse(hargaController.text));
                        Navigator.of(context).pop(detail);
                      }
                    : null,
                child: const Text('Tambah'),
              )
            ])
          ],
        ),
      ),
    );
  }
}
