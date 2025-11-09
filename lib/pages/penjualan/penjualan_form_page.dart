import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/dialog_helper.dart';
import 'widgets/penjualan_widgets.dart';
import 'penjualan_provider.dart';

class PenjualanFormPage extends StatefulWidget {
  const PenjualanFormPage({Key? key}) : super(key: key);

  @override
  State<PenjualanFormPage> createState() => _PenjualanFormPageState();
}

class _PenjualanFormPageState extends State<PenjualanFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final PenjualanProvider _provider;

  final _diskonController = TextEditingController(text: '0');
  final _ongkosKirimController = TextEditingController(text: '0');
  final _biayaLainController = TextEditingController(text: '0');
  final _bayarController = TextEditingController(text: '0');

  final _metodePembayaran = ['Tunai', 'Transfer'];
  final _statusPembayaranOptions = ['Belum Lunas', 'Lunas'];

  @override
  void initState() {
    super.initState();
    _provider = PenjualanProvider();
    _provider.loadData().catchError((e) {
      if (mounted) DialogHelper.showSnackBar(context, message: 'Error loading data: $e', isError: true);
    });
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
          child: AlertDialog(
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
                DropdownButtonFormField<String>(
                  value: _provider.selectedStatusPembayaran,
                  decoration: const InputDecoration(labelText: 'Status Pembayaran'),
                  items: _statusPembayaranOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => _provider.selectedStatusPembayaran = v,
                  validator: (v) => v == null ? 'Pilih status pembayaran' : null,
                ),
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
        );
      },
    );
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
                    items: [
                      DropdownMenuItem(value: selectedBarang!.satuanPcs, child: Text('${selectedBarang!.satuanPcs}')), 
                      DropdownMenuItem(value: selectedBarang!.satuanDus, child: Text('${selectedBarang!.satuanDus}')),
                    ],
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

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<PenjualanProvider>(
        builder: (context, provider, _) {
          return LoadingOverlay(
            isLoading: provider.isLoading,
            child: Scaffold(
              appBar: AppBar(title: const Text('Tambah Penjualan')),
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
                          DropdownButtonFormField<String>(
                            value: provider.selectedPelanggan,
                            decoration: const InputDecoration(labelText: 'Pelanggan'),
                            items: provider.pelangganList.map((p) => DropdownMenuItem(value: p.kodePelanggan, child: Text(p.namaPelanggan))).toList(),
                            onChanged: (v) => provider.selectedPelanggan = v,
                            validator: (v) => v == null ? 'Pilih pelanggan' : null,
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
                      onFinishTap: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final result = await provider.savePenjualan(context);
                        if (result != null) Navigator.pop(context, result);
                      },
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
