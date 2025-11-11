import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Komisi {
  final String? id;
  final String namaKomisi;
  final double nilaiKomisi;

  Komisi({
    this.id,
    required this.namaKomisi,
    required this.nilaiKomisi,
  });
}

class KomisiFormPage extends StatefulWidget {
  final Komisi? komisi;

  const KomisiFormPage({super.key, this.komisi});

  @override
  State<KomisiFormPage> createState() => _KomisiFormPageState();
}

class _KomisiFormPageState extends State<KomisiFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaKomisiController;
  late TextEditingController _nilaiKomisiController;

  @override
  void initState() {
    super.initState();
    _namaKomisiController = TextEditingController(text: widget.komisi?.namaKomisi ?? '');
    _nilaiKomisiController = TextEditingController(
      text: widget.komisi?.nilaiKomisi.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _namaKomisiController.dispose();
    _nilaiKomisiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.komisi == null ? 'Tambah Komisi' : 'Edit Komisi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _namaKomisiController,
              decoration: const InputDecoration(
                labelText: 'Nama Komisi',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama komisi harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nilaiKomisiController,
              decoration: const InputDecoration(
                labelText: 'Nilai Komisi',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nilai komisi harus diisi';
                }
                final number = int.tryParse(value);
                if (number == null) {
                  return 'Nilai komisi harus berupa angka';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(
                    context,
                    Komisi(
                      id: widget.komisi?.id,
                      namaKomisi: _namaKomisiController.text.trim(),
                      nilaiKomisi: double.parse(_nilaiKomisiController.text),
                    ),
                  );
                }
              },
              child: Text(widget.komisi == null ? 'Simpan' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}