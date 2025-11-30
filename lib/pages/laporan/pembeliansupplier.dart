import '../../db/laporan_db.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/date_utils.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../models/pembelian_models.dart';

class PembelianSupplierWidget extends StatefulWidget {
  const PembelianSupplierWidget({super.key});

  @override
  State<PembelianSupplierWidget> createState() => _PembelianSupplierWidgetState();
}

class _PembelianSupplierWidgetState extends State<PembelianSupplierWidget> {
  List<Map<String, dynamic>> _allPurchases = [];
  List<Map<String, dynamic>> _filteredPurchases = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  double _totalPembelian = 0.0; // Variabel untuk menyimpan total pembelian

  @override
  void initState() {
    super.initState();
    _loadPurchaseData();
  }

  // Fungsi untuk menghitung total pembelian
  void _calculateTotalPembelian() {
    double total = 0.0;
    for (var purchase in _filteredPurchases) {
      // Gunakan subtotal yang sudah ada dari database
      double subtotal = (purchase['subtotal'] ?? 0).toDouble();
      total += subtotal;
    }
    setState(() {
      _totalPembelian = total;
    });
  }

  Future<void> _loadPurchaseData() async {
    try {
      final data = await LaporanDb.getPurchasesBySupplier();
      setState(() {
        _allPurchases = data;
        _filteredPurchases = data;
        _isLoading = false;
      });
      _calculateTotalPembelian(); // Hitung total setelah data dimuat
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
        _isLoading = false;
        _totalPembelian = 0.0;
      });
    }
  }

  void _filterPurchases(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPurchases = _allPurchases;
      } else {
        _filteredPurchases = _allPurchases.where((purchase) {
          final namaSupplier = purchase['nama_supplier']?.toString().toLowerCase() ?? '';
          final namaBarang = purchase['nama_barang']?.toString().toLowerCase() ?? '';
          return namaSupplier.contains(query.toLowerCase()) ||
                 namaBarang.contains(query.toLowerCase());
        }).toList();
      }
    });
    _calculateTotalPembelian(); // Hitung ulang total setelah filter
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _totalPembelian = 0.0;
    });
    await _loadPurchaseData();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Pembelian Card
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembelian:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      _formatCurrency(_totalPembelian),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Pembelian',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportToCSV,
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Cari Supplier/Barang',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _filterPurchases,
              ),
            ),
            const SizedBox(height: 16),
            _buildPurchasesTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasesTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    }

    if (_filteredPurchases.isEmpty) {
      return Column(
        children: [
          Text(
            _searchQuery.isEmpty
                ? 'Tidak ada data pembelian'
                : 'Tidak ditemukan pembelian dengan kata kunci "$_searchQuery"',
          ),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Refresh'),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            // Tambahan: Info jumlah data dan total
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jumlah Data: ${_filteredPurchases.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  ),
                  // Text(
                  //   'Total: ${_formatCurrency(_totalPembelian)}',
                  //   style: const TextStyle(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.bold,
                  //     color: Colors.red,
                  //   ),
                  // ),
                ],
              ),
            ),

            Column(
              children: _filteredPurchases.map((purchase) {
                final namaBarang = purchase['nama_barang']?.toString() ?? '';
                final namaSupplier = purchase['nama_supplier']?.toString() ?? '';
                final jumlah = NumberFormat('#,###').format(purchase['jumlah'] ?? 0);
                final hargaSatuan = (purchase['harga_satuan'] ?? 0).toDouble();
                final subtotal = (purchase['subtotal'] ?? 0).toDouble();

                return ListTile(
                  title: Text('$namaBarang ($namaSupplier)'),
                  subtitle: Text('$jumlah • ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 1).format(hargaSatuan)}'),
                  trailing: Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(subtotal)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    return formatFlexibleDate(date, 'dd/MM/yyyy', fallback: date.toString());
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'lunas':
        return Colors.green;
      case 'belum lunas':
        return Colors.orange;
      case 'campuran':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(num? value) {
    final safeValue = value ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      decimalDigits: 0,
    );
    return formatter.format(safeValue.toDouble()).replaceFirst('IDR', 'Rp');
  }

  Future<void> _exportToCSV() async {
    if (_filteredPurchases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    try {
      // Prepare CSV data
      List<List<String>> csvData = [
        ['Supplier', 'Barang', 'Harga', 'Jumlah', 'Subtotal', 'Status', 'Tanggal', 'Jatuh Tempo'], // Headers
        ..._filteredPurchases.map((purchase) => [
          purchase['nama_supplier']?.toString() ?? '',
          purchase['nama_barang']?.toString() ?? '',
          _formatCurrency(purchase['harga_satuan'] ?? 0),
          purchase['jumlah']?.toString() ?? '0',
          _formatCurrency(purchase['subtotal'] ?? 0),
          purchase['status']?.toString() ?? '',
          _formatDate(purchase['tanggal_beli']),
          _formatDate(purchase['jatuh_tempo']),
        ]),
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      String fileName = 'pembelian_supplier_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

      if (kIsWeb) {
        // Web download
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV berhasil diekspor: $fileName')),
        );
      } else {
        // Mobile/Non-web logic
        Directory? directory;
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        File file = File('${directory!.path}/$fileName');
        await file.writeAsString(csv);

        await OpenFile.open(file.path);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV berhasil diekspor: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor CSV: $e')),
      );
    }
  }
}
