import 'package:flutter/material.dart';
import '../../models/models.dart';

class SupplierFormPage extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormPage({super.key, this.supplier});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  late final TextEditingController kodeController;
  late final TextEditingController namaController;
  late final TextEditingController alamatController;
  late final TextEditingController telpController;

  @override
  void initState() {
    super.initState();
    kodeController = TextEditingController(text: widget.supplier?.kodeSupplier ?? '');
    namaController = TextEditingController(text: widget.supplier?.namaSupplier ?? '');
    alamatController = TextEditingController(text: widget.supplier?.alamatSupplier ?? '');
    telpController = TextEditingController(text: widget.supplier?.telpSupplier ?? '');
  }

  @override
  void dispose() {
    kodeController.dispose();
    namaController.dispose();
    alamatController.dispose();
    telpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplier == null ? 'Tambah Supplier' : 'Edit Supplier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: kodeController,
                decoration: const InputDecoration(labelText: 'Kode Supplier'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Supplier'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: telpController,
                decoration: const InputDecoration(labelText: 'Telepon'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final supplier = Supplier(
                        kodeSupplier: kodeController.text,
                        namaSupplier: namaController.text,
                        alamatSupplier: alamatController.text,
                        telpSupplier: telpController.text,
                      );

                      Navigator.of(context).pop(supplier);
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
