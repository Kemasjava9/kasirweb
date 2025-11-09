import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/code_generator.dart';
import '../../models/models.dart';
import 'barang_form_page.dart';

class BarangPage extends StatefulWidget {
  const BarangPage({super.key});

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  Barang? _selectedBarang;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
                  'Data Barang',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
            const SizedBox(height: 12),
            // Header dan Search
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari barang...',
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
                  const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedBarang != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showBarangForm(_selectedBarang),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _deleteBarang(_selectedBarang!),
                      icon: const Icon(Icons.delete),
                      label: const Text('Hapus'),
                    ),
                    const SizedBox(width: 12),
                    Text('Dipilih: ${_selectedBarang!.namaBarang}'),
                  ],
                ),
              ),
            // List Barang
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('barang').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var barangList = snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return Barang.fromMap(data);
                  }).toList();

                  // Filter berdasarkan search
                  if (_searchController.text.isNotEmpty) {
                    barangList = barangList.where((barang) {
                      return barang.namaBarang
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase());
                    }).toList();
                  }

                  // Responsive: show DataTable on wide screens, cards on small screens
                  return LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth >= 800) {
                      // DataTable for wider screens
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Kode Barang')),
                            DataColumn(label: Text('Nama Barang')),
                            DataColumn(label: Text('Satuan Pcs')),
                            DataColumn(label: Text('Satuan Dus')),
                            DataColumn(label: Text('Isi Dus')),
                            DataColumn(label: Text('Harga Pcs')),
                            DataColumn(label: Text('Harga Dus')),
                            DataColumn(label: Text('Jumlah')),
                            DataColumn(label: Text('HPP')),
                            DataColumn(label: Text('HPP Dus')),
                            DataColumn(label: Text('Aksi')),
                          ],
                          rows: barangList.map((barang) {
                            return DataRow(
                              selected: _selectedBarang == barang,
                              onSelectChanged: (selected) {
                                setState(() {
                                  _selectedBarang = selected == true ? barang : null;
                                });
                              },
                              cells: [
                              DataCell(Text(barang.kodeBarang)),
                              DataCell(Text(barang.namaBarang)),
                              DataCell(Text(barang.satuanPcs)),
                              DataCell(Text(barang.satuanDus)),
                              DataCell(Text(barang.isiDus.toString())),
                              DataCell(Text(currency.format(barang.hargaPcs))),
                              DataCell(Text(currency.format(barang.hargaDus))),
                              DataCell(Text(barang.jumlah.toString())),
                              DataCell(Text(currency.format(barang.hpp))),
                              DataCell(Text(currency.format(barang.hppDus))),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () async {
                                      final result = await Navigator.push<Barang?>(
                                        context,
                                        MaterialPageRoute(builder: (_) => BarangFormPage(barang: barang)),
                                      );
                                      if (result != null) {
                                        await _saveBarang(
                                          barang,
                                          result.kodeBarang,
                                          result.namaBarang,
                                          result.satuanPcs,
                                          result.satuanDus,
                                          result.isiDus.toString(),
                                          result.hargaPcs.toString(),
                                          result.hargaDus.toString(),
                                          result.jumlah.toString(),
                                          result.hpp.toString(),
                                          result.hppDus.toString(),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteBarang(barang),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      );
                    }

                    // Small screens: existing card list
                    return ListView.builder(
                      itemCount: barangList.length,
                      itemBuilder: (context, index) {
                        final barang = barangList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.inventory, color: Colors.blue),
                            title: Text(barang.namaBarang),
                            subtitle: Text('Stok: ${barang.jumlah} | Harga: ${currency.format(barang.hargaPcs)}'),
                            selected: _selectedBarang == barang,
                            selectedTileColor: Colors.blue.withOpacity(0.08),
                            onTap: () {
                              setState(() {
                                _selectedBarang = _selectedBarang == barang ? null : barang;
                              });
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () {
                                    setState(() => _selectedBarang = barang);
                                    _showBarangForm(barang);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() => _selectedBarang = barang);
                                    _deleteBarang(barang);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Barang?>(context, MaterialPageRoute(builder: (_) => const BarangFormPage()));
          if (result != null) {
            await _saveBarang(
              null,
              result.kodeBarang,
              result.namaBarang,
              result.satuanPcs,
              result.satuanDus,
              result.isiDus.toString(),
              result.hargaPcs.toString(),
              result.hargaDus.toString(),
              result.jumlah.toString(),
              result.hpp.toString(),
              result.hppDus.toString(),
            );
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Barang',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showBarangForm(Barang? barang) {
    final kodeController = TextEditingController(text: barang?.kodeBarang ?? '');
    final namaController = TextEditingController(text: barang?.namaBarang ?? '');
    final hargaPcsController = TextEditingController(text: barang?.hargaPcs.toString() ?? '');
    final hppController = TextEditingController(text: barang?.hpp.toString() ?? '');
    final satuanPcsController = TextEditingController(text: barang?.satuanPcs ?? 'pcs');
    final satuanDusController = TextEditingController(text: barang?.satuanDus ?? 'dus/pack');
    final isiDusController = TextEditingController(text: barang?.isiDus.toString() ?? '');
    final hargaDusController = TextEditingController(text: barang?.hargaDus.toString() ?? '');
    final hppDusController = TextEditingController(text: barang?.hppDus.toString() ?? '');
    final jumlahController = TextEditingController(text: barang?.jumlah.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(barang == null ? 'Tambah Barang' : 'Edit Barang'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (barang != null) TextField(
                controller: kodeController,
                decoration: const InputDecoration(labelText: 'Kode Barang'),
                enabled: false, // Make it read-only when editing
              ),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
              ),
              TextField(
                controller: hargaPcsController,
                decoration: const InputDecoration(labelText: 'Harga per Pcs'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: hargaDusController,
                decoration: const InputDecoration(labelText: 'Harga per Dus'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: satuanPcsController,
                decoration: const InputDecoration(labelText: 'Satuan Pcs'),
              ),
              TextField(
                controller: satuanDusController,
                decoration: const InputDecoration(labelText: 'Satuan Dus'),
              ),
              TextField(
                controller: isiDusController,
                decoration: const InputDecoration(labelText: 'Isi Dus'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: hppController,
                decoration: const InputDecoration(labelText: 'HPP Pcs'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: hppDusController,
                decoration: const InputDecoration(labelText: 'HPP Dus'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: jumlahController,
                decoration: const InputDecoration(labelText: 'Jumlah Stok'),
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              await _saveBarang(
                barang,
                kodeController.text,
                namaController.text,
                satuanPcsController.text,
                satuanDusController.text,
                isiDusController.text,
                hargaPcsController.text,
                hargaDusController.text,
                jumlahController.text,
                hppController.text,
                hppDusController.text,
              );
              // Close the dialog after saving
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBarang(
    Barang? barang,
    String kode,
    String nama,
    String satuanPcs,
    String satuanDus,
    String isiDusInput,
    String hargaPcsInput,
    String hargaDusInput,
    String jumlah,
    String hppInput,
    String hppDusInput,
  ) async {
    if (kode.isEmpty) {
      // Generate kode barang automatically if empty: format B00001
      kode = await CodeGenerator.nextSequentialCode(_firestore, 'barang', 'kode_barang', 'B', 5);
    }

    if (nama.isEmpty || hargaPcsInput.isEmpty || jumlah.isEmpty || hppInput.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    try {
      final parsedHargaPcs = double.parse(hargaPcsInput);
      final parsedHargaDus = double.tryParse(hargaDusInput) ?? (parsedHargaPcs * (double.tryParse(isiDusInput) ?? 1));
      final parsedIsiDus = int.tryParse(isiDusInput) ?? 1;
      final parsedHpp = double.tryParse(hppInput) ?? 0;
      final parsedHppDus = double.tryParse(hppDusInput) ?? (parsedHpp * parsedIsiDus);

      final barangData = Barang(
        kodeBarang: kode,
        namaBarang: nama,
        satuanPcs: satuanPcs,
        satuanDus: satuanDus,
        isiDus: parsedIsiDus,
        hargaPcs: parsedHargaPcs,
        hargaDus: parsedHargaDus,
        jumlah: int.parse(jumlah),
        hpp: parsedHpp,
        hppDus: parsedHppDus,
      );

      if (barang == null) {
        // Tambah baru
        await _firestore.collection('barang').doc(kode).set(barangData.toMap());
      } else {
        // Update
        await _firestore.collection('barang').doc(barang.kodeBarang).update(barangData.toMap());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barang ${barang == null ? 'ditambahkan' : 'diupdate'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _deleteBarang(Barang barang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Yakin ingin menghapus ${barang.namaBarang}?'),
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
        // Start a batch operation
        final batch = _firestore.batch();
        
        // Get document reference
        final barangRef = _firestore.collection('barang').doc(barang.kodeBarang);
        
        // Check if document exists
        final doc = await barangRef.get();
        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang tidak ditemukan di database')),
          );
          return;
        }

        // Delete the barang document
        batch.delete(barangRef);

        // Commit the batch
        await batch.commit();

        // Clear the selection if the deleted item was selected
        if (_selectedBarang?.kodeBarang == barang.kodeBarang) {
          setState(() {
            _selectedBarang = null;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus barang: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}