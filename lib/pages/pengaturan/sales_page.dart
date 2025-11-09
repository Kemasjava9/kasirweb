import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sales_form_page.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleAddSales() async {
    final result = await Navigator.push<Sales?>(
      context,
      MaterialPageRoute(builder: (_) => const SalesFormPage()),
    );
    if (result != null) {
      await _saveSalesData(result);
    }
  }

  Future<void> _saveSalesData(Sales sales) async {
    try {
      await _firestore.collection('sales').add({
        'nama_sales': sales.namaSales,
        'created_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sales berhasil ditambahkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error menambahkan sales: $e')),
        );
      }
    }
  }

  Future<void> _deleteSales(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Sales'),
        content: const Text('Yakin ingin menghapus sales ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('sales').doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sales berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sales'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddSales,
        child: const Icon(Icons.add),
        tooltip: 'Tambah Sales',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('sales').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final salesList = snapshot.data!.docs;
            return ListView.builder(
              itemCount: salesList.length,
              itemBuilder: (context, index) {
                final sales = salesList[index];
                final salesData = sales.data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(salesData['nama_sales'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () async {
                            final result = await Navigator.push<Sales?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SalesFormPage(
                                  sales: Sales(
                                    id: sales.id,
                                    namaSales: salesData['nama_sales'] ?? '',
                                  ),
                                ),
                              ),
                            );
                            if (result != null) {
                              await _firestore.collection('sales').doc(sales.id).update({
                                'nama_sales': result.namaSales,
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSales(sales.id),
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
    );
  }
}
