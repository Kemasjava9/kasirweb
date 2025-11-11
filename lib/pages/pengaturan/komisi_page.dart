import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'komisi_form_page.dart';

class KomisiPage extends StatefulWidget {
  const KomisiPage({super.key});

  @override
  State<KomisiPage> createState() => _KomisiPageState();
}

class _KomisiPageState extends State<KomisiPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleAddKomisi() async {
    final result = await Navigator.push<Komisi?>(
      context,
      MaterialPageRoute(builder: (_) => const KomisiFormPage()),
    );
    if (result != null) {
      await _saveKomisiData(result);
    }
  }

  Future<void> _saveKomisiData(Komisi komisi) async {
    try {
      await _firestore.collection('komisi').add({
        'nama_komisi': komisi.namaKomisi,
        'nilai_komisi': komisi.nilaiKomisi,
        'created_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komisi berhasil ditambahkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error menambahkan komisi: $e')),
        );
      }
    }
  }

  Future<void> _deleteKomisi(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komisi'),
        content: const Text('Yakin ingin menghapus komisi ini?'),
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
        await _firestore.collection('komisi').doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komisi berhasil dihapus')),
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
        title: const Text('Data Komisi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddKomisi,
        child: const Icon(Icons.add),
        tooltip: 'Tambah Komisi',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    title: Text(komisiData['nama_komisi'] ?? ''),
                    subtitle: Text('Nilai: ${NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(komisiData['nilai_komisi'] ?? 0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () async {
                            final result = await Navigator.push<Komisi?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => KomisiFormPage(
                                  komisi: Komisi(
                                    id: komisi.id,
                                    namaKomisi: komisiData['nama_komisi'] ?? '',
                                    nilaiKomisi: (komisiData['nilai_komisi'] ?? 0).toDouble(),
                                  ),
                                ),
                              ),
                            );
                            if (result != null) {
                              await _firestore.collection('komisi').doc(komisi.id).update({
                                'nama_komisi': result.namaKomisi,
                                'nilai_komisi': result.nilaiKomisi,
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteKomisi(komisi.id),
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
