import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../utils/code_generator.dart';
import 'supplier_form_page.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Data Supplier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari supplier...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 56), // Space for FAB margin
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('supplier').orderBy('nama_supplier').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  var supplierList = snapshot.data!.docs.map((doc) => Supplier.fromMap(doc.data() as Map<String, dynamic>)).toList();

                  final q = _searchController.text.trim();
                  if (q.isNotEmpty) {
                    supplierList = supplierList.where((s) => s.namaSupplier.toLowerCase().contains(q.toLowerCase())).toList();
                  }

                  return ListView.builder(
                    itemCount: supplierList.length,
                    itemBuilder: (context, index) {
                      final supplier = supplierList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.business, color: Colors.green),
                          title: Text(supplier.namaSupplier),
                          subtitle: Text(supplier.alamatSupplier),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () async {
                                  final result = await Navigator.push<Supplier?>(context, MaterialPageRoute(builder: (_) => SupplierFormPage(supplier: supplier)));
                                  if (result != null) {
                                    await _saveSupplier(supplier, result.kodeSupplier, result.namaSupplier, result.alamatSupplier, result.telpSupplier);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteSupplier(supplier),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Supplier?>(context, MaterialPageRoute(builder: (_) => const SupplierFormPage()));
          if (result != null) {
            await _saveSupplier(null, result.kodeSupplier, result.namaSupplier, result.alamatSupplier, result.telpSupplier);
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Supplier',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _saveSupplier(Supplier? supplier, String kode, String nama, String alamat, String telp) async {
    if (kode.isEmpty) {
      kode = await CodeGenerator.nextSequentialCode(_firestore, 'supplier', 'kode_supplier', 'SP', 4);
    }

    if (kode.isEmpty || nama.isEmpty || alamat.isEmpty || telp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua field harus diisi')));
      return;
    }

    try {
      final supplierData = Supplier(kodeSupplier: kode, namaSupplier: nama, alamatSupplier: alamat, telpSupplier: telp);
      if (supplier == null) {
        await _firestore.collection('supplier').doc(kode).set(supplierData.toMap());
      } else {
        await _firestore.collection('supplier').doc(supplier.kodeSupplier).update(supplierData.toMap());
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Supplier ${supplier == null ? 'ditambahkan' : 'diupdate'}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _deleteSupplier(Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Supplier'),
        content: Text('Yakin ingin menghapus ${supplier.namaSupplier}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('supplier').doc(supplier.kodeSupplier).delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier dihapus')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}