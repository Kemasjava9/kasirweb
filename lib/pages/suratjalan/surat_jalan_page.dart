import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/surat_jalan_models.dart';
import 'surat_jalan_form_page.dart';

class SuratJalanPage extends StatefulWidget {
  const SuratJalanPage({super.key});

  @override
  State<SuratJalanPage> createState() => _SuratJalanPageState();
}

class _SuratJalanPageState extends State<SuratJalanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  SuratJalan? _selectedSuratJalan;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Surat Jalan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari surat jalan...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedSuratJalan != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _editSuratJalan(_selectedSuratJalan!),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _deleteSuratJalan(_selectedSuratJalan!),
                      icon: const Icon(Icons.delete),
                      label: const Text('Hapus'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _printSuratJalan(_selectedSuratJalan!),
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak'),
                    ),
                    const SizedBox(width: 12),
                    Text('Dipilih: ${_selectedSuratJalan!.noSuratJalan}'),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('surat_jalan')
                    .orderBy('tanggal', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var suratJalanList = snapshot.data!.docs.map((doc) {
                    return SuratJalan.fromMap(doc.data() as Map<String, dynamic>);
                  }).toList();

                  if (_searchController.text.isNotEmpty) {
                    suratJalanList = suratJalanList.where((sj) {
                      return sj.noSuratJalan.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                             sj.namaPelanggan.toLowerCase().contains(_searchController.text.toLowerCase());
                    }).toList();
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 800) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('No Surat Jalan')),
                              DataColumn(label: Text('Tanggal')),
                              DataColumn(label: Text('No Penjualan')),
                              DataColumn(label: Text('Pelanggan')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Aksi')),
                            ],
                            rows: suratJalanList.map((sj) {
                              return DataRow(
                                selected: _selectedSuratJalan?.noSuratJalan == sj.noSuratJalan,
                                onSelectChanged: (selected) {
                                  setState(() {
                                    _selectedSuratJalan = selected == true ? sj : null;
                                  });
                                },
                                cells: [
                                  DataCell(Text(sj.noSuratJalan)),
                                  DataCell(Text(_dateFormat.format(sj.tanggal))),
                                  DataCell(Text(sj.noPenjualan)),
                                  DataCell(Text(sj.namaPelanggan)),
                                  DataCell(_buildStatusChip(sj.status)),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _editSuratJalan(sj),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.print, color: Colors.green),
                                        onPressed: () => _printSuratJalan(sj),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteSuratJalan(sj),
                                      ),
                                    ],
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: suratJalanList.length,
                        itemBuilder: (context, index) {
                          final sj = suratJalanList[index];
                          return Card(
                            child: ListTile(
                              title: Text(sj.noSuratJalan),
                              subtitle: Text(
                                '${_dateFormat.format(sj.tanggal)} - ${sj.namaPelanggan}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStatusChip(sj.status),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editSuratJalan(sj),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print, color: Colors.green),
                                    onPressed: () => _printSuratJalan(sj),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteSuratJalan(sj),
                                  ),
                                ],
                              ),
                              selected: _selectedSuratJalan?.noSuratJalan == sj.noSuratJalan,
                              onTap: () {
                                setState(() {
                                  _selectedSuratJalan = _selectedSuratJalan?.noSuratJalan == sj.noSuratJalan ? null : sj;
                                });
                              },
                            ),
                          );
                        },
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
        onPressed: () => _createSuratJalan(),
        child: const Icon(Icons.add),
        tooltip: 'Buat Surat Jalan',
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'draft':
        color = Colors.grey;
        label = 'Draft';
        break;
      case 'terkirim':
        color = Colors.blue;
        label = 'Terkirim';
        break;
      case 'selesai':
        color = Colors.green;
        label = 'Selesai';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _createSuratJalan() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const SuratJalanFormPage(),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Surat Jalan berhasil dibuat')),
      );
    }
  }

  void _editSuratJalan(SuratJalan suratJalan) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SuratJalanFormPage(suratJalan: suratJalan),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Surat Jalan berhasil diupdate')),
      );
    }
  }

  void _deleteSuratJalan(SuratJalan suratJalan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Surat Jalan'),
        content: Text('Yakin ingin menghapus surat jalan ${suratJalan.noSuratJalan}?'),
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
        final batch = _firestore.batch();
        
        final docRef = _firestore.collection('surat_jalan').doc(suratJalan.noSuratJalan);
        final doc = await docRef.get();
        
        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Surat Jalan tidak ditemukan')),
          );
          return;
        }

        batch.delete(docRef);
        await batch.commit();

        if (_selectedSuratJalan?.noSuratJalan == suratJalan.noSuratJalan) {
          setState(() {
            _selectedSuratJalan = null;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surat Jalan berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error menghapus surat jalan: $e')),
        );
      }
    }
  }

  void _printSuratJalan(SuratJalan suratJalan) {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur cetak akan segera tersedia')),
    );
  }
}