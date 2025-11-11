import 'package:flutter/material.dart';
import '../../models/models.dart';

class BarangFormPage extends StatefulWidget {
  final Barang? barang;

  const BarangFormPage({super.key, this.barang});

  @override
  State<BarangFormPage> createState() => _BarangFormPageState();
}

class _BarangFormPageState extends State<BarangFormPage> {
  late final TextEditingController kodeController;
  late final TextEditingController namaController;
  late final TextEditingController hargaPcsController;
  late final TextEditingController hargaDusController;
  late final TextEditingController satuanPcsController;
  late final TextEditingController satuanDusController;
  late final TextEditingController isiDusController;
  late final TextEditingController hppController;
  late final TextEditingController hppDusController;
  late final TextEditingController jumlahController;

  @override
  void initState() {
    super.initState();
    kodeController = TextEditingController(text: widget.barang?.kodeBarang ?? '');
    namaController = TextEditingController(text: widget.barang?.namaBarang ?? '');
    hargaPcsController = TextEditingController(text: widget.barang?.hargaPcs.toString() ?? '');
    hargaDusController = TextEditingController(text: widget.barang?.hargaDus.toString() ?? '');
    satuanPcsController = TextEditingController(text: widget.barang?.satuanPcs ?? 'pcs');
    satuanDusController = TextEditingController(text: widget.barang?.satuanDus ?? 'dus/pack');
    isiDusController = TextEditingController(text: widget.barang?.isiDus.toString() ?? '');
    hppController = TextEditingController(text: widget.barang?.hpp.toString() ?? '');
    hppDusController = TextEditingController(text: widget.barang?.hppDus.toString() ?? '');
    jumlahController = TextEditingController(text: widget.barang?.jumlah.toString() ?? '');
  }

  @override
  void dispose() {
    kodeController.dispose();
    namaController.dispose();
    hargaPcsController.dispose();
    hargaDusController.dispose();
    satuanPcsController.dispose();
    satuanDusController.dispose();
    isiDusController.dispose();
    hppController.dispose();
    hppDusController.dispose();
    jumlahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.barang == null ? 'Tambah Barang' : 'Edit Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.barang != null)
                TextField(controller: kodeController, decoration: const InputDecoration(labelText: 'Kode Barang'), enabled: false),
              TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Barang')),
              TextField(controller: hargaPcsController, decoration: const InputDecoration(labelText: 'Harga per Pcs'), keyboardType: TextInputType.number),
              TextField(controller: hargaDusController, decoration: const InputDecoration(labelText: 'Harga per Dus'), keyboardType: TextInputType.number),
              TextField(controller: satuanPcsController, decoration: const InputDecoration(labelText: 'Satuan Pcs')),
              TextField(controller: satuanDusController, decoration: const InputDecoration(labelText: 'Satuan Dus')),
              TextField(controller: isiDusController, decoration: const InputDecoration(labelText: 'Isi Dus'), keyboardType: TextInputType.number),
              TextField(controller: hppController, decoration: const InputDecoration(labelText: 'HPP Pcs'), keyboardType: TextInputType.number),
              TextField(controller: hppDusController, decoration: const InputDecoration(labelText: 'HPP Dus'), keyboardType: TextInputType.number),
              TextField(controller: jumlahController, decoration: const InputDecoration(labelText: 'Jumlah Stok'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Batal')),
                  ElevatedButton(onPressed: () {
                    final barang = Barang(
                      kodeBarang: kodeController.text,
                      namaBarang: namaController.text,
                      satuanPcs: satuanPcsController.text,
                      satuanDus: satuanDusController.text,
                      isiDus: int.tryParse(isiDusController.text) ?? 1,
                      hargaPcs: double.tryParse(hargaPcsController.text) ?? 0,
                      hargaDus: double.tryParse(hargaDusController.text) ?? 0,
                      jumlah: int.tryParse(jumlahController.text) ?? 0,
                      hpp: double.tryParse(hppController.text) ?? 0,
                      hppDus: double.tryParse(hppDusController.text) ?? 0,
                    );
                    Navigator.of(context).pop(barang);
                  }, child: const Text('Simpan')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
