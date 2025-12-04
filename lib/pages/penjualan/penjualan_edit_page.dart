import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/models.dart';
import '../../models/penjualan_models.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/dialog_helper.dart';
import 'widgets/penjualan_widgets.dart';
import 'penjualan_provider.dart';

class PenjualanEditPage extends StatefulWidget {
  final String nofakturJual;

  const PenjualanEditPage({Key? key, required this.nofakturJual}) : super(key: key);

  @override
  State<PenjualanEditPage> createState() => _PenjualanEditPageState();
}

class _PenjualanEditPageState extends State<PenjualanEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final PenjualanProvider _provider;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _diskonController = TextEditingController(text: '0');
  final _ongkosKirimController = TextEditingController(text: '0');
  final _biayaLainController = TextEditingController(text: '0');
  final _bayarController = TextEditingController(text: '0');

  final _metodePembayaran = ['Tunai', 'Transfer'];
  final _statusPembayaranOptions = ['Belum Lunas', 'Lunas', 'Kembalian'];

  List<DetailPenjualan> originalItems = []; // To track original items for stock adjustment

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = PenjualanProvider();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      await _provider.loadData();

      // Load penjualan data
      final penjualanDoc = await _firestore.collection('penjualan').where('nofaktur_jual', isEqualTo: widget.nofakturJual).limit(1).get();
      if (penjualanDoc.docs.isEmpty) {
        throw Exception('Penjualan tidak ditemukan');
      }
      final data = penjualanDoc.docs.first.data();

      // Load detail items
      final detailsSnapshot = await _firestore.collection('detail_penjualan').where('nofaktur_jual', isEqualTo: widget.nofakturJual).get();
      final details = detailsSnapshot.docs.map((doc) => DetailPenjualan.fromMap(doc.data())).toList();

      setState(() {
        // Find pelanggan from nama
        final pelanggan = _provider.pelangganList.firstWhere(
          (p) => p.namaPelanggan == data['nama_pelanggan'],
          orElse: () => Pelanggan(kodePelanggan: '', namaPelanggan: '', alamatPelanggan: '', noTelp: '', keterangan: ''),
        );
        _provider.selectedPelanggan = pelanggan.kodePelanggan.isNotEmpty ? pelanggan.kodePelanggan : null;

        _provider.selectedDate = DateFormat('dd-MM-yyyy').parse(data['tanggal_jual']);
        _provider.selectedSales = data['nama_sales'];
        _provider.selectedKomisi = data['komisi'];
        _provider.selectedMetodePembayaran = data['cara_bayar'];
        _provider.selectedStatusPembayaran = data['status'];
        _diskonController.text = (data['diskon'] ?? 0).toString();
        _ongkosKirimController.text = (data['ongkos_kirim'] ?? 0).toString();
        _biayaLainController.text = (data['biaya_lain_lain'] ?? 0).toString();
        _bayarController.text = (data['bayar'] ?? '0');

        _provider.cartItems.clear();
        _provider.cartItems.addAll(details);
        originalItems = List.from(details); // Copy for stock adjustment

        _provider.calculateTotal(
          diskon: double.tryParse(_diskonController.text) ?? 0,
          ongkosKirim: double.tryParse(_ongkosKirimController.text) ?? 0,
          biayaLain: double.tryParse(_biayaLainController.text) ?? 0,
        );

        _provider.bayar = double.tryParse(_bayarController.text) ?? 0;

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        DialogHelper.showSnackBar(context, message: 'Error loading data: $e', isError: true);
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _diskonController.dispose();
    _ongkosKirimController.dispose();
    _biayaLainController.dispose();
    _bayarController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<bool?> _showPaymentDialog() async {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final localKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: _provider,
          child: Consumer<PenjualanProvider>(
            builder: (context, provider, _) => AlertDialog(
              title: const Text('Detail Pembayaran'),
              content: Form(
                key: localKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: _diskonController,
                      label: 'Diskon (Rp)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) => _provider.calculateTotal(
                        diskon: double.tryParse(v) ?? 0,
                        ongkosKirim: double.tryParse(_ongkosKirimController.text) ?? 0,
                        biayaLain: double.tryParse(_biayaLainController.text) ?? 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _ongkosKirimController,
                      label: 'Ongkos Kirim (Rp)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) => _provider.calculateTotal(
                        diskon: double.tryParse(_diskonController.text) ?? 0,
                        ongkosKirim: double.tryParse(v) ?? 0,
                        biayaLain: double.tryParse(_biayaLainController.text) ?? 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _biayaLainController,
                      label: 'Biaya Lain-lain (Rp)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) => _provider.calculateTotal(
                        diskon: double.tryParse(_diskonController.text) ?? 0,
                        ongkosKirim: double.tryParse(_ongkosKirimController.text) ?? 0,
                        biayaLain: double.tryParse(v) ?? 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _bayarController,
                      label: 'Bayar (Rp)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v == null || v.isEmpty ? 'Masukkan jumlah pembayaran' : null,
                      onChanged: (v) => _provider.bayar = double.tryParse(v) ?? 0,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _provider.selectedMetodePembayaran,
                      decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                      items: _metodePembayaran.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => _provider.selectedMetodePembayaran = v,
                      validator: (v) => v == null ? 'Pilih metode pembayaran' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_provider.selectedStatusPembayaran ?? 'Belum Lunas', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    if (_provider.kembalian > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(currency.format(_provider.kembalian), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Belanja', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(currency.format(_provider.totalBelanja), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    if (localKey.currentState!.validate()) {
                      _provider.calculateTotal(
                        diskon: double.tryParse(_diskonController.text) ?? 0,
                        ongkosKirim: double.tryParse(_ongkosKirimController.text) ?? 0,
                        biayaLain: double.tryParse(_biayaLainController.text) ?? 0,
                      );
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, PenjualanProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != provider.selectedDate) {
      provider.selectedDate = picked;
    }
  }

  void _showAddItemDialog(PenjualanProvider provider) {
    Barang? selectedBarang;
    String? selectedSatuan;
    int jumlah = 1;
    double nilaiKomisi = 0;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Tambah Produk'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Barang>(
                  value: selectedBarang,
                  decoration: const InputDecoration(labelText: 'Pilih Barang'),
                  items: provider.barangList.map((b) => DropdownMenuItem(value: b, child: Text(b.namaBarang))).toList(),
                  onChanged: (v) => setState(() {
                    selectedBarang = v;
                    selectedSatuan = null;
                  }),
                ),
                if (selectedBarang != null) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedSatuan,
                    decoration: const InputDecoration(labelText: 'Pilih Satuan'),
                    items: [selectedBarang!.satuanPcs, selectedBarang!.satuanDus].toSet().map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => selectedSatuan = v),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Jumlah'),
                  keyboardType: TextInputType.number,
                  initialValue: '1',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => jumlah = int.tryParse(v) ?? 1,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nilai Komisi', prefixText: 'Rp '),
                  keyboardType: TextInputType.number,
                  initialValue: '0',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => nilaiKomisi = double.tryParse(v) ?? 0,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton(
                onPressed: selectedBarang == null || selectedSatuan == null
                    ? null
                    : () {
                        final harga = selectedSatuan == selectedBarang!.satuanPcs ? selectedBarang!.hargaPcs : selectedBarang!.hargaDus;
                        provider.addToCart(selectedBarang!, selectedSatuan!, jumlah, harga, nilaiKomisi);
                        Navigator.pop(context);
                      },
                child: const Text('Tambah ke Keranjang'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _saveEdits() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final batch = _firestore.batch();

      // Update penjualan document
      final penjualanQuery = await _firestore.collection('penjualan').where('nofaktur_jual', isEqualTo: widget.nofakturJual).limit(1).get();
      if (penjualanQuery.docs.isEmpty) throw Exception('Penjualan tidak ditemukan');
      final penjualanRef = penjualanQuery.docs.first.reference;

      final total = _provider.totalBelanja;
      final selectedPelangganObj = _provider.pelangganList.firstWhere(
        (p) => p.kodePelanggan == _provider.selectedPelanggan,
        orElse: () => Pelanggan(kodePelanggan: '', namaPelanggan: '', alamatPelanggan: '', noTelp: '', keterangan: ''),
      );
      batch.update(penjualanRef, {
        'tanggal_jual': DateFormat('dd-MM-yyyy').format(_provider.selectedDate),
        'nama_pelanggan': selectedPelangganObj.namaPelanggan,
        'nama_sales': _provider.selectedSales,
        'komisi': _provider.selectedKomisi,
        'cara_bayar': _provider.selectedMetodePembayaran,
        'status': _provider.selectedStatusPembayaran,
        'total_jual': total,
        'bayar': _bayarController.text,
        'diskon': double.tryParse(_diskonController.text) ?? 0,
        'ongkos_kirim': double.tryParse(_ongkosKirimController.text) ?? 0,
        'biaya_lain_lain': double.tryParse(_biayaLainController.text) ?? 0,
      });

      // Delete all old detail items and restore stock
      final detailsQuery = await _firestore.collection('detail_penjualan').where('nofaktur_jual', isEqualTo: widget.nofakturJual).get();
      for (var doc in detailsQuery.docs) {
        final item = DetailPenjualan.fromMap(doc.data());
        batch.delete(doc.reference);
        // Restore stock (add back)
        final barangRef = _firestore.collection('barang').doc(item.kodeBarang);
        final barang = _provider.barangList.firstWhere((b) => b.kodeBarang == item.kodeBarang);
        final stokToRestore = item.satuan == 'dus' ? item.jumlah * barang.isiDus : item.jumlah;
        batch.update(barangRef, {'jumlah': FieldValue.increment(stokToRestore)});
      }

      // Add new detail items and reduce stock
      for (var item in _provider.cartItems) {
        final detailRef = _firestore.collection('detail_penjualan').doc();
        final newItem = DetailPenjualan(
          idDetailJual: DateTime.now().millisecondsSinceEpoch.toString(),
          nofakturJual: widget.nofakturJual,
          kodeBarang: item.kodeBarang,
          jumlah: item.jumlah,
          hargaSatuan: item.hargaSatuan,
          subtotal: item.subtotal,
          satuan: item.satuan,
          nilaiKomisi: item.nilaiKomisi,
          namaKomisi: item.namaKomisi,
        );
        batch.set(detailRef, newItem.toMap());
        // Reduce stock
        final barangRef = _firestore.collection('barang').doc(item.kodeBarang);
        final barang = _provider.barangList.firstWhere((b) => b.kodeBarang == item.kodeBarang);
        final stokToReduce = item.satuan == 'dus' ? item.jumlah * barang.isiDus : item.jumlah;
        batch.update(barangRef, {'jumlah': FieldValue.increment(-stokToReduce)});
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penjualan berhasil diperbarui')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<PenjualanProvider>(
        builder: (context, provider, _) {
          return LoadingOverlay(
            isLoading: _isLoading || provider.isLoading,
            child: Scaffold(
              appBar: AppBar(
                title: Text('Edit Penjualan #${widget.nofakturJual}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: Colors.white)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: provider.cartItems.isNotEmpty ? _saveEdits : null,
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
              body: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Detail Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: TextEditingController(text: DateFormat('dd/MM/yyyy', 'id').format(provider.selectedDate)),
                                  decoration: const InputDecoration(
                                    labelText: 'Tanggal',
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(context, provider),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: provider.selectedPelanggan,
                                  decoration: const InputDecoration(labelText: 'Pelanggan'),
                                  items: provider.pelangganList.map((p) => DropdownMenuItem(value: p.kodePelanggan, child: Text(p.namaPelanggan))).toList(),
                                  onChanged: (v) => provider.selectedPelanggan = v,
                                  validator: (v) => v == null ? 'Pilih pelanggan' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: provider.selectedSales,
                                  decoration: const InputDecoration(labelText: 'Pilih Sales'),
                                  items: provider.salesList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (v) => provider.selectedSales = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: provider.selectedKomisi,
                                  decoration: const InputDecoration(labelText: 'Pilih Komisi'),
                                  items: provider.komisiList.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                                  onChanged: (v) => provider.selectedKomisi = v,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: PenjualanItemList(
                        items: provider.cartItems,
                        barangList: provider.barangList,
                        currencyFormat: currency,
                        onDeleteItem: (id) => provider.removeFromCart(id.toString()),
                      ),
                    ),

                    PaymentSummaryWidget(
                      totalBelanja: provider.totalBelanja,
                      currencyFormat: currency,
                      onPaymentTap: () async => await _showPaymentDialog(),
                      isValid: provider.cartItems.isNotEmpty,
                      onFinishTap: _saveEdits,
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _showAddItemDialog(provider),
                child: const Icon(Icons.add_shopping_cart),
              ),
            ),
          );
        },
      ),
    );
  }
}
