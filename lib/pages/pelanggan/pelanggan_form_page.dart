import 'package:flutter/material.dart';
import '../../models/models.dart';

class PelangganFormPage extends StatefulWidget {
  final Pelanggan? pelanggan;

  const PelangganFormPage({super.key, this.pelanggan});

  @override
  State<PelangganFormPage> createState() => _PelangganFormPageState();
}

class _PelangganFormPageState extends State<PelangganFormPage> {
  late final TextEditingController kodeController;
  late final TextEditingController namaController;
  late final TextEditingController alamatController;
  late final TextEditingController telpController;
  late final TextEditingController keteranganController;

  @override
  void initState() {
    super.initState();
    kodeController = TextEditingController(text: widget.pelanggan?.kodePelanggan ?? '');
    namaController = TextEditingController(text: widget.pelanggan?.namaPelanggan ?? '');
    alamatController = TextEditingController(text: widget.pelanggan?.alamatPelanggan ?? '');
    telpController = TextEditingController(text: widget.pelanggan?.noTelp ?? '');
    keteranganController = TextEditingController(text: widget.pelanggan?.keterangan ?? '');
  }

  @override
  void dispose() {
    kodeController.dispose();
    namaController.dispose();
    alamatController.dispose();
    telpController.dispose();
    keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pelanggan == null ? 'Tambah Pelanggan' : 'Edit Pelanggan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: kodeController, decoration: const InputDecoration(labelText: 'Kode Pelanggan')),
              const SizedBox(height: 8),
              TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
              const SizedBox(height: 8),
              TextField(controller: alamatController, decoration: const InputDecoration(labelText: 'Alamat'), maxLines: 3),
              const SizedBox(height: 8),
              TextField(controller: telpController, decoration: const InputDecoration(labelText: 'No. Telepon'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(controller: keteranganController, decoration: const InputDecoration(labelText: 'Keterangan'), maxLines: 2),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Batal')),
                  ElevatedButton(onPressed: () {
                    final p = Pelanggan(
                      kodePelanggan: kodeController.text,
                      namaPelanggan: namaController.text,
                      alamatPelanggan: alamatController.text,
                      noTelp: telpController.text,
                      keterangan: keteranganController.text,
                    );
                    Navigator.of(context).pop(p);
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
