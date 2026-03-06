import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../models/pembelian_models.dart';
import '../../utils/code_generator.dart';
import '../../utils/print_formats/pembelian_print_format.dart';
import 'pembelian_form_page.dart';
import 'pembelian_edit_page.dart';
import 'package:printing/printing.dart';

class PembelianPage extends StatefulWidget {
  const PembelianPage({super.key});

  @override
  State<PembelianPage> createState() => _PembelianPageState();
}

class _PembelianPageState extends State<PembelianPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Barang> _barangList = [];
  List<Supplier> _supplierList = [];

  // Variabel untuk draggable FAB
  Offset _fabPosition = Offset.zero;
  bool _isFabDragging = false;
  final double _fabSize = 56.0;

  // Variabel untuk filter dan pencarian
  String _selectedStatus = 'Semua';
  String _searchText = '';
  
  // Variabel untuk filter bulan - BARU
  DateTime? _selectedMonth;
  bool _isMonthFilterActive = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _fabPosition = Offset(
          screenSize.width - _fabSize - 100,
          screenSize.height - _fabSize - 60 - kToolbarHeight,
        );
      });
    });
  }

  void _loadData() async {
    final barangSnapshot = await _firestore.collection('barang').get();
    final supplierSnapshot = await _firestore.collection('supplier').get();

    setState(() {
      _barangList = barangSnapshot.docs.map((doc) {
        return Barang.fromMap(doc.data());
      }).toList();

      _supplierList = supplierSnapshot.docs.map((doc) {
        return Supplier.fromMap(doc.data());
      }).toList();
    });
    print('Supplier list loaded: $_supplierList');
  }

  // METHOD BARU: Menampilkan dialog pemilihan bulan
  void _showMonthPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Bulan'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown Tahun
                DropdownButtonFormField<int>(
                  value: _selectedMonth?.year ?? DateTime.now().year,
                  decoration: const InputDecoration(
                    labelText: 'Tahun',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(5, (index) {
                    int year = DateTime.now().year - 2 + index;
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMonth = DateTime(
                          value,
                          _selectedMonth?.month ?? DateTime.now().month,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Dropdown Bulan
                DropdownButtonFormField<int>(
                  value: _selectedMonth?.month ?? DateTime.now().month,
                  decoration: const InputDecoration(
                    labelText: 'Bulan',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Januari')),
                    DropdownMenuItem(value: 2, child: Text('Februari')),
                    DropdownMenuItem(value: 3, child: Text('Maret')),
                    DropdownMenuItem(value: 4, child: Text('April')),
                    DropdownMenuItem(value: 5, child: Text('Mei')),
                    DropdownMenuItem(value: 6, child: Text('Juni')),
                    DropdownMenuItem(value: 7, child: Text('Juli')),
                    DropdownMenuItem(value: 8, child: Text('Agustus')),
                    DropdownMenuItem(value: 9, child: Text('September')),
                    DropdownMenuItem(value: 10, child: Text('Oktober')),
                    DropdownMenuItem(value: 11, child: Text('November')),
                    DropdownMenuItem(value: 12, child: Text('Desember')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        if (_selectedMonth == null) {
                          _selectedMonth = DateTime(DateTime.now().year, value);
                        } else {
                          _selectedMonth = DateTime(_selectedMonth!.year, value);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedMonth = null;
                  _isMonthFilterActive = false;
                });
                Navigator.pop(context);
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isMonthFilterActive = _selectedMonth != null;
                });
                Navigator.pop(context);
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'Transaksi Pembelian',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 56),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Filter Section
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filter Status
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          items: ['Semua', 'Lunas', 'Belum Lunas']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Filter Bulan - TOMBOL BARU
                      SizedBox(
                        width: 140,
                        child: ElevatedButton.icon(
                          onPressed: _showMonthPickerDialog,
                          icon: Icon(
                            _isMonthFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _isMonthFilterActive 
                                ? DateFormat('MMM yyyy', 'id').format(_selectedMonth!)
                                : 'Filter Bulan',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isMonthFilterActive ? Colors.blue : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Search Field
                      SizedBox(
                        width: 220,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Cari Supplier / ID',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            prefixIcon: Icon(Icons.search, size: 20),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchText = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Indikator Filter Aktif
                if (_isMonthFilterActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Menampilkan: ${DateFormat('MMMM yyyy', 'id').format(_selectedMonth!)}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMonth = null;
                              _isMonthFilterActive = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: 14, color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // List Pembelian
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('pembelian').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var pembelianList = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status']?.toString() ?? '';
                        final idBeli = data['id_beli']?.toString() ?? '';
                        final kodeSupplier = data['kode_supplier']?.toString() ?? '';
                        final tanggalBeli = data['tanggal_beli']?.toString() ?? '';

                        // FILTER BULAN - BARU
                        bool monthMatch = true;
                        if (_isMonthFilterActive && _selectedMonth != null) {
                          try {
                            final tanggal = DateTime.parse(tanggalBeli);
                            monthMatch = tanggal.month == _selectedMonth!.month && 
                                        tanggal.year == _selectedMonth!.year;
                          } catch (e) {
                            monthMatch = false;
                          }
                        }

                        // Find supplier name
                        final supplier = _supplierList.firstWhere(
                          (s) => s.kodeSupplier.trim().toLowerCase() == kodeSupplier.trim().toLowerCase(),
                          orElse: () => Supplier(
                            kodeSupplier: kodeSupplier,
                            namaSupplier: data['nama_supplier']?.toString() ?? '',
                            alamatSupplier: '',
                            telpSupplier: '',
                          ),
                        );
                        final namaSupplier = supplier.namaSupplier;

                        // Filter by status
                        bool statusMatch = _selectedStatus == 'Semua' ||
                            (_selectedStatus == 'Lunas' && status == 'Lunas') ||
                            (_selectedStatus == 'Belum Lunas' && status != 'Lunas');

                        // Filter by search text
                        bool searchMatch = _searchText.isEmpty ||
                            idBeli.toLowerCase().contains(_searchText.toLowerCase()) ||
                            namaSupplier.toLowerCase().contains(_searchText.toLowerCase()) ||
                            kodeSupplier.toLowerCase().contains(_searchText.toLowerCase());

                        return statusMatch && searchMatch && monthMatch;
                      }).toList();

                      // Sort berdasarkan id_beli (format: PB00001/03/2026)
                      pembelianList.sort((a, b) {
                        final idBeliA = (a.data() as Map<String, dynamic>)['id_beli']?.toString() ?? '';
                        final idBeliB = (b.data() as Map<String, dynamic>)['id_beli']?.toString() ?? '';
                        
                        return _compareIdBeli(idBeliB, idBeliA);
                      });

                      if (pembelianList.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada data pembelian',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_isMonthFilterActive)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedMonth = null;
                                      _isMonthFilterActive = false;
                                    });
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset Filter'),
                                ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: pembelianList.length,
                        itemBuilder: (context, index) {
                          var data = pembelianList[index].data() as Map<String, dynamic>;
                          final idBeli = data['id_beli']?.toString() ?? '';
                          final kodeSupplier = data['kode_supplier']?.toString() ?? '';

                          // Try to find supplier by kode_supplier
                          final supplier = _supplierList.firstWhere(
                            (s) => s.kodeSupplier.trim().toLowerCase() ==
                                kodeSupplier.trim().toLowerCase(),
                            orElse: () => Supplier(
                              kodeSupplier: kodeSupplier,
                              namaSupplier: data['nama_supplier']?.toString() ??
                                  'Supplier tidak ditemukan',
                              alamatSupplier: '',
                              telpSupplier: '',
                            ),
                          );
                          final namaSupplier = supplier.namaSupplier;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: const Icon(
                                Icons.shopping_cart,
                                color: Colors.green,
                              ),
                              title: Text('Pembelian #${data['id_beli']}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Supplier: $namaSupplier'),
                                  Text('Tanggal: ${data['tanggal_beli']}'),
                                  Text(
                                    'Total: Rp ${NumberFormat('#,###').format(data['total_beli'])}',
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(
                                      data['status'] ?? 'Pending',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: _getStatusColor(data['status']),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: FutureBuilder<QuerySnapshot>(
                                    future: _firestore
                                        .collection('detail_pembelian')
                                        .where('id_beli', isEqualTo: idBeli)
                                        .get(),
                                    builder: (context, snapDetail) {
                                      if (snapDetail.connectionState == ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      if (snapDetail.hasError) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Error: ${snapDetail.error}'),
                                        );
                                      }

                                      final details = snapDetail.data?.docs ?? [];
                                      if (details.isEmpty) {
                                        return const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Tidak ada item pembelian'),
                                        );
                                      }

                                      return Column(
                                        children: details.map((d) {
                                          final m = d.data() as Map<String, dynamic>;
                                          final kode = m['kode_barang'] ?? '';
                                          final barang = _barangList.firstWhere(
                                            (b) => b.kodeBarang == kode,
                                            orElse: () => Barang(
                                              kodeBarang: kode,
                                              namaBarang: kode,
                                              satuanPcs: 'pcs',
                                              satuanDus: 'dus',
                                              isiDus: 1,
                                              hargaPcs: (m['harga_satuan']?.toDouble() ?? 0.0),
                                              hargaDus: (m['harga_satuan']?.toDouble() ?? 0.0),
                                              jumlah: 0,
                                              hpp: 0.0,
                                              hppDus: 0.0,
                                            ),
                                          );
                                          final jumlah = m['jumlah'] ?? 0;
                                          final hargaSatuan = (m['harga_satuan'] ?? 0).toDouble();
                                          final subtotal = (m['subtotal'] ?? 0).toDouble();

                                          return ListTile(
                                            dense: true,
                                            title: Text(
                                              '${barang.namaBarang} (${kode})',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            subtitle: Text(
                                              '${NumberFormat('#,###').format(jumlah)} • ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 1).format(hargaSatuan)}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            trailing: Text(
                                              NumberFormat.currency(
                                                locale: 'id',
                                                symbol: 'Rp ',
                                                decimalDigits: 0,
                                              ).format(subtotal),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ),
                                ButtonBar(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Colors.green, size: 22),
                                      tooltip: 'Lihat Detail',
                                      onPressed: () => _showDetailDialog(data),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange, size: 22),
                                      tooltip: 'Edit Pembelian',
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PembelianEditPage(
                                              pembelianData: data,
                                              barangList: _barangList,
                                              supplierList: _supplierList,
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                                      tooltip: 'Hapus Pembelian',
                                      onPressed: () => _showDeleteDialog(data, idBeli),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.print, color: Colors.blue, size: 22),
                                      tooltip: 'Cetak',
                                      onPressed: () => _printPembelian(data),
                                    ),
                                  ],
                                ),
                              ],
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

          // Draggable Floating Action Button
          Positioned(
            left: _fabPosition.dx,
            top: _fabPosition.dy,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _isFabDragging = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _fabPosition = Offset(
                    (_fabPosition.dx + details.delta.dx).clamp(
                      0,
                      screenSize.width - _fabSize,
                    ),
                    (_fabPosition.dy + details.delta.dy).clamp(
                      0,
                      screenSize.height - _fabSize,
                    ),
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _isFabDragging = false;
                });
              },
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PembelianFormPage(
                      barangList: _barangList,
                      supplierList: _supplierList,
                    ),
                  ),
                );
                if (result != null && result is Map) {
                  final supplier = result['supplier'] as String;
                  final tanggal = result['tanggal'] as DateTime;
                  final items = result['items'] as List<DetailPembelian>;
                  final statusPembayaran = result['status_pembayaran'] as String? ?? 'Belum Lunas';
                  final docStatus = result['status'] as String? ?? 'Draft';
                  final jatuhTempo = result['jatuh_tempo'] as DateTime?;
                  _savePembelian(
                    supplier,
                    tanggal,
                    items,
                    statusPembayaran,
                    docStatus,
                    jatuhTempo,
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _fabSize,
                height: _fabSize,
                decoration: BoxDecoration(
                  color: _isFabDragging
                      ? Colors.blue[700]
                      : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: _isFabDragging ? 10 : 5,
                      spreadRadius: _isFabDragging ? 2 : 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _isFabDragging ? Icons.drag_handle : Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Lunas':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _savePembelian(
    String supplier,
    DateTime tanggal,
    List<DetailPembelian> cartItems,
    String statusPembayaran,
    String docStatus,
    DateTime? jatuhTempo,
  ) async {
    try {
      // Generate pembelian code PBnnnnn/MM/YYYY
      final now = DateTime.now();
      final pembelianId = await CodeGenerator.nextMonthlyCode(
        _firestore,
        'pembelian',
        'id_beli',
        'PB',
        5,
        now.month,
        now.year,
      );

      // Calculate total
      double total = 0;
      for (var item in cartItems) {
        total += item.subtotal;
      }

      // Find supplier name for display fallback
      final supplierObj = _supplierList.firstWhere(
        (s) => s.kodeSupplier == supplier,
        orElse: () => Supplier(
          kodeSupplier: supplier,
          namaSupplier: supplier,
          alamatSupplier: '',
          telpSupplier: '',
        ),
      );

      // Prepare batch
      final batch = _firestore.batch();
      final pembelianRef = _firestore.collection('pembelian').doc();
      final pembelianData = {
        'id_beli': pembelianId,
        'tanggal_beli': DateFormat('yyyy-MM-dd').format(tanggal),
        'kode_supplier': supplier,
        'nama_supplier': supplierObj.namaSupplier,
        'total_beli': total,
        'status': statusPembayaran,
        'status_doc': docStatus,
        'jatuh_tempo': jatuhTempo != null
            ? DateFormat('yyyy-MM-dd').format(jatuhTempo)
            : DateFormat('yyyy-MM-dd').format(tanggal.add(const Duration(days: 30))),
      };

      batch.set(pembelianRef, pembelianData);

      // Add detail rows and update stock using increment
      for (var item in cartItems) {
        final detailRef = _firestore.collection('detail_pembelian').doc();
        final detailData = {
          'id_detail_beli': detailRef.id,
          'id_beli': pembelianId,
          'kode_barang': item.kodeBarang,
          'satuan': item.satuan,
          'jumlah': item.jumlah,
          'harga_satuan': item.hargaSatuan,
          'subtotal': item.subtotal,
        };
        batch.set(detailRef, detailData);

        // Compute stock increment based on selected satuan.
        final barangRef = _firestore.collection('barang').doc(item.kodeBarang);
        final barangObj = _barangList.firstWhere(
          (b) => b.kodeBarang == item.kodeBarang,
          orElse: () => Barang(
            kodeBarang: item.kodeBarang,
            namaBarang: item.kodeBarang,
            satuanPcs: 'pcs',
            satuanDus: 'dus',
            isiDus: 1,
            hargaPcs: item.hargaSatuan,
            hargaDus: item.hargaSatuan,
            jumlah: 0,
            hpp: 0,
            hppDus: 0,
          ),
        );

        final stokToAdd = (item.satuan == 'dus')
            ? (item.jumlah * barangObj.isiDus)
            : item.jumlah;
        batch.update(barangRef, {'jumlah': FieldValue.increment(stokToAdd)});
      }

      // Commit batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembelian berhasil disimpan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDetailDialog(Map<String, dynamic> data) {
    final idBeli = data['id_beli']?.toString() ?? '';
    final kodeSupplier = data['kode_supplier']?.toString() ?? '';
    final supplier = _supplierList.firstWhere(
      (s) => s.kodeSupplier == kodeSupplier,
      orElse: () => Supplier(
        kodeSupplier: kodeSupplier,
        namaSupplier: data['nama_supplier']?.toString() ?? 'Supplier tidak ditemukan',
        alamatSupplier: '',
        telpSupplier: '',
      ),
    );
    final namaSupplier = supplier.namaSupplier;
    final status = data['status']?.toString() ?? '';
    final tanggal = data['tanggal_beli']?.toString() ?? '';
    final jatuhTempo = data['jatuh_tempo']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detail Pembelian #$idBeli'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID Beli: $idBeli'),
                Text('Tanggal: $tanggal'),
                Text('Supplier: $namaSupplier'),
                Text('Status: $status'),
                Text('Jatuh Tempo: $jatuhTempo'),
                const SizedBox(height: 16),
                const Text(
                  'Detail Item:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<QuerySnapshot>(
                  future: _firestore
                      .collection('detail_pembelian')
                      .where('id_beli', isEqualTo: idBeli)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final details = snapshot.data?.docs ?? [];
                    if (details.isEmpty) {
                      return const Text('Tidak ada item');
                    }

                    return SizedBox(
                      height: 200,
                      child: ListView(
                        children: details.map((doc) {
                          final item = doc.data() as Map<String, dynamic>;
                          final kodeBarang = item['kode_barang']?.toString() ?? '';
                          final barang = _barangList.firstWhere(
                            (b) => b.kodeBarang == kodeBarang,
                            orElse: () => Barang(
                              kodeBarang: kodeBarang,
                              namaBarang: kodeBarang,
                              satuanPcs: 'pcs',
                              satuanDus: 'dus',
                              isiDus: 1,
                              hargaPcs: 0.0,
                              hargaDus: 0.0,
                              jumlah: 0,
                              hpp: 0.0,
                              hppDus: 0.0,
                            ),
                          );
                          final namaBarang = barang.namaBarang;
                          final jumlah = item['jumlah'] ?? 0;
                          final harga = NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 1,
                          ).format(item['harga_satuan'] ?? 0);
                          final subtotal = NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(item['subtotal'] ?? 0);

                          return ListTile(
                            dense: true,
                            title: Text('$namaBarang ($jumlah)'),
                            subtitle: Text('Harga: $harga'),
                            trailing: Text('$subtotal'),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: (data['status'] == 'Lunas')
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Konfirmasi Pembayaran'),
                          content: const Text(
                            'Tandai pembelian ini sebagai Lunas?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Ya, Lunas'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      try {
                        // Update all pembelian documents that match this id_beli
                        final q = await _firestore
                            .collection('pembelian')
                            .where('id_beli', isEqualTo: idBeli)
                            .get();
                        final batch = _firestore.batch();
                        for (var doc in q.docs) {
                          batch.update(doc.reference, {
                            'status': 'Lunas',
                            'tanggal_lunas': FieldValue.serverTimestamp(),
                          });
                        }
                        await batch.commit();
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Status pembayaran diupdate menjadi Lunas',
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Error update status: $e')),
                        );
                      }
                    },
              child: const Text('Lunas'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(Map<String, dynamic> data, String idBeli) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus pembelian #$idBeli?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await _deletePembelian(idBeli);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePembelian(String idBeli) async {
    try {
      // Find detail items
      final detailSnapshot = await _firestore
          .collection('detail_pembelian')
          .where('id_beli', isEqualTo: idBeli)
          .get();
      final batch = _firestore.batch();

      // Reduce stock for each item (reverse the increment done when saving pembelian)
      for (var doc in detailSnapshot.docs) {
        final data = doc.data();
        final kodeBarang = data['kode_barang'];

        // Safely parse jumlah as int
        final rawJumlah = data['jumlah'];
        final int jumlah = (rawJumlah is num)
            ? rawJumlah.toInt()
            : int.tryParse(rawJumlah?.toString() ?? '0') ?? 0;

        final satuan = (data['satuan'] ?? 'pcs').toString();

        final barangObj = _barangList.firstWhere(
          (b) => b.kodeBarang == kodeBarang,
          orElse: () => Barang(
            kodeBarang: kodeBarang,
            namaBarang: kodeBarang,
            satuanPcs: 'pcs',
            satuanDus: 'dus',
            isiDus: 1,
            hargaPcs: 0,
            hargaDus: 0,
            jumlah: 0,
            hpp: 0,
            hppDus: 0,
          ),
        );

        final stokToRestore = (satuan == 'dus')
            ? (jumlah * barangObj.isiDus)
            : jumlah;

        // Use set with merge so we don't fail if the barang document is missing
        final barangRef = _firestore.collection('barang').doc(kodeBarang);
        batch.set(barangRef, {
          'jumlah': FieldValue.increment(-stokToRestore),
        }, SetOptions(merge: true));

        // Delete detail item
        batch.delete(doc.reference);
      }

      // Delete main pembelian document(s) where id_beli == idBeli
      final pembelianQuery = await _firestore
          .collection('pembelian')
          .where('id_beli', isEqualTo: idBeli)
          .get();
      for (var doc in pembelianQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembelian berhasil dihapus')),
      );
      // Refresh local lists/state
      _loadData();
    } catch (e, st) {
      // Log stacktrace to help debugging
      debugPrint('Error deleting pembelian: $e');
      debugPrintStack(stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menghapus pembelian: $e')),
      );
    }
  }

  Future<void> _printPembelian(Map<String, dynamic> data) async {
    try {
      final idBeli = data['id_beli']?.toString() ?? '';
      // Get detail items
      final detailSnapshot = await _firestore
          .collection('detail_pembelian')
          .where('id_beli', isEqualTo: idBeli)
          .get();
      final items = detailSnapshot.docs.map((d) => d.data()).toList();

      final bytes = await PembelianPrintFormat.buildPembelianPdf(
        data,
        items.cast<Map<String, dynamic>>(),
        _barangList,
        _supplierList,
      );
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mencetak pembelian: $e')),
      );
    }
  }

  int _compareIdBeli(String a, String b) {
    // Extract the date part (after the last '/')
    String dateA = a.contains('/') ? a.split('/').sublist(1).join('/') : '';
    String dateB = b.contains('/') ? b.split('/').sublist(1).join('/') : '';
    
    // Compare dates in reverse (newest first)
    int dateCompare = dateB.compareTo(dateA);
    if (dateCompare != 0) return dateCompare;
    
    // If same date, compare the ID numbers
    String numA = a.split('/')[0].replaceAll(RegExp(r'[^0-9]'), '');
    String numB = b.split('/')[0].replaceAll(RegExp(r'[^0-9]'), '');
    
    int intA = int.tryParse(numA) ?? 0;
    int intB = int.tryParse(numB) ?? 0;
    
    return intB.compareTo(intA);
  }
}
