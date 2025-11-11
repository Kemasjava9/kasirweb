import 'package:flutter/material.dart';

class Sales {
  final String? id;
  final String namaSales;

  Sales({
    this.id,
    required this.namaSales,
  });
}

class SalesFormPage extends StatefulWidget {
  final Sales? sales;

  const SalesFormPage({super.key, this.sales});

  @override
  State<SalesFormPage> createState() => _SalesFormPageState();
}

class _SalesFormPageState extends State<SalesFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaSalesController;

  @override
  void initState() {
    super.initState();
    _namaSalesController = TextEditingController(text: widget.sales?.namaSales ?? '');
  }

  @override
  void dispose() {
    _namaSalesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sales == null ? 'Tambah Sales' : 'Edit Sales'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _namaSalesController,
              decoration: const InputDecoration(
                labelText: 'Nama Sales',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama sales harus diisi';
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
                    Sales(
                      id: widget.sales?.id,
                      namaSales: _namaSalesController.text.trim(),
                    ),
                  );
                }
              },
              child: Text(widget.sales == null ? 'Simpan' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}