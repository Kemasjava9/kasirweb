import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KomisiTab extends StatelessWidget {
  const KomisiTab({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Data Komisi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('komisi').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final komisiList = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: komisiList.length,
                  itemBuilder: (context, index) {
                    final komisi = komisiList[index];
                    final komisiData = komisi.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text('${komisiData['nama_sales'] ?? ''} - ${komisiData['persentase']}%'),
                        subtitle: Text('Periode: ${komisiData['periode'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _editKomisi(context, komisi.id, komisiData),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteKomisi(context, komisi.id),
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
    );
  }

  Future<void> _editKomisi(BuildContext context, String id, Map<String, dynamic> currentData) async {
    final TextEditingController namaSalesController = TextEditingController(text: currentData['nama_sales']);
    final TextEditingController persentaseController = TextEditingController(text: currentData['persentase'].toString());
    final TextEditingController periodeController = TextEditingController(text: currentData['periode']);

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Komisi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaSalesController,
                decoration: const InputDecoration(labelText: 'Nama Sales'),
              ),
              TextField(
                controller: persentaseController,
                decoration: const InputDecoration(labelText: 'Persentase Komisi'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: periodeController,
                decoration: const InputDecoration(labelText: 'Periode'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'nama_sales': namaSalesController.text,
              'persentase': double.tryParse(persentaseController.text) ?? 0,
              'periode': periodeController.text,
            }),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance.collection('komisi').doc(id).update(result);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komisi berhasil diperbarui')),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteKomisi(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komisi'),
        content: const Text('Yakin ingin menghapus data komisi ini?'),
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
        await FirebaseFirestore.instance.collection('komisi').doc(id).delete();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komisi berhasil dihapus')),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  static Future<void> handleAddKomisi(BuildContext context) async {
    final TextEditingController namaSalesController = TextEditingController();
    final TextEditingController persentaseController = TextEditingController();
    final TextEditingController periodeController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Komisi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaSalesController,
                decoration: const InputDecoration(labelText: 'Nama Sales'),
              ),
              TextField(
                controller: persentaseController,
                decoration: const InputDecoration(labelText: 'Persentase Komisi'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: periodeController,
                decoration: const InputDecoration(labelText: 'Periode'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'nama_sales': namaSalesController.text,
              'persentase': double.tryParse(persentaseController.text) ?? 0,
              'periode': periodeController.text,
              'created_at': FieldValue.serverTimestamp(),
            }),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance.collection('komisi').add(result);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komisi berhasil ditambahkan')),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}