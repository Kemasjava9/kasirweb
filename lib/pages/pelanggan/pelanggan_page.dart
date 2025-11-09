import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../utils/code_generator.dart';
import 'pelanggan_form_page.dart';

class PelangganPage extends StatefulWidget {
  const PelangganPage({super.key});

  @override
  State<PelangganPage> createState() => _PelangganPageState();
}

class _PelangganPageState extends State<PelangganPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Pelanggan?>(
            context,
            MaterialPageRoute(builder: (_) => const PelangganFormPage()),
          );
          if (result != null) {
            _savePelanggan(null, result.kodePelanggan, result.namaPelanggan, 
              result.alamatPelanggan, result.noTelp, result.keterangan);
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Pelanggan',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Data Pelanggan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari pelanggan...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 56), // Space for FAB margin
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('pelanggan').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var pelangganList = snapshot.data!.docs.map((doc) {
                    return Pelanggan.fromMap(doc.data() as Map<String, dynamic>);
                  }).toList();

                  if (_searchController.text.isNotEmpty) {
                    pelangganList = pelangganList.where((pelanggan) {
                      return pelanggan.namaPelanggan
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase());
                    }).toList();
                  }

                  return ListView.builder(
                    itemCount: pelangganList.length,
                    itemBuilder: (context, index) {
                      final pelanggan = pelangganList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.people, color: Colors.orange),
                          title: Text(pelanggan.namaPelanggan),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pelanggan.alamatPelanggan),
                              Text(pelanggan.noTelp),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () async {
                                  final result = await Navigator.push<Pelanggan?>(
                                    context,
                                    MaterialPageRoute(builder: (_) => PelangganFormPage(pelanggan: pelanggan)),
                                  );
                                  if (result != null) {
                                    _savePelanggan(pelanggan, result.kodePelanggan, result.namaPelanggan, result.alamatPelanggan, result.noTelp, result.keterangan);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePelanggan(pelanggan),
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
    );
  }

  // Dialog-based pelanggan form replaced by PelangganFormPage

  void _savePelanggan(
    Pelanggan? pelanggan,
    String kode,
    String nama,
    String alamat,
    String telp,
    String keterangan,
  ) async {
    // Generate kode pelanggan if empty: PL0001
    if (kode.isEmpty) {
      kode = await CodeGenerator.nextSequentialCode(_firestore, 'pelanggan', 'kode_pelanggan', 'PL', 4);
    }

    if (kode.isEmpty || nama.isEmpty || alamat.isEmpty || telp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field wajib harus diisi')),
      );
      return;
    }

    try {
      final pelangganData = Pelanggan(
        kodePelanggan: kode,
        namaPelanggan: nama,
        alamatPelanggan: alamat,
        noTelp: telp,
        keterangan: keterangan,
      );

      if (pelanggan == null) {
        await _firestore.collection('pelanggan').doc(kode).set(pelangganData.toMap());
      } else {
        await _firestore.collection('pelanggan').doc(pelanggan.kodePelanggan).update(pelangganData.toMap());
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pelanggan ${pelanggan == null ? 'ditambahkan' : 'diupdate'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _deletePelanggan(Pelanggan pelanggan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text('Yakin ingin menghapus ${pelanggan.namaPelanggan}?'),
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
        await _firestore.collection('pelanggan').doc(pelanggan.kodePelanggan).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pelanggan dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}