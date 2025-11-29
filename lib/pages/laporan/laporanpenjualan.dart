import '../../db/laporan_db.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/date_utils.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class SalesDetailWidget extends StatefulWidget {
  const SalesDetailWidget({super.key});

  @override
  State<SalesDetailWidget> createState() => _SalesDetailWidgetState();
}

class _SalesDetailWidgetState extends State<SalesDetailWidget> {
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _filteredSalesData = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  double _totalPenjualan = 0.0; // Variabel untuk menyimpan total penjualan

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isLoading = true;
        _totalPenjualan = 0.0; // Reset total saat ganti tanggal
      });
      _loadSalesData();
    }
  }

  // Fungsi untuk menghitung total penjualan
  void _calculateTotalPenjualan() {
    double total = 0.0;
    for (var sale in _filteredSalesData) {
      // Hitung subtotal untuk setiap item: harga * qty
      double harga = (sale['Harga Satuan'] ?? 0).toDouble();
      double qty = (sale['Jumlah_Converted'] ?? 0).toDouble();
      double subtotal = harga * qty;
      total += subtotal;
    }
    setState(() {
      _totalPenjualan = total;
    });
  }

  Future<void> _loadSalesData() async {
    try {
      final data = await LaporanDb.getsalesbynofaktur(
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
      );
      setState(() {
        _salesData = data;
        _filteredSalesData = data;
        _isLoading = false;
      });
      _calculateTotalPenjualan(); // Hitung total setelah data dimuat
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
        _isLoading = false;
        _totalPenjualan = 0.0;
      });
    }
  }

  void _filterSales(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSalesData = _salesData;
      } else {
        _filteredSalesData = _salesData.where((sale) {
          final noFaktur = sale['No Faktur']?.toString().toLowerCase() ?? '';
          final pelanggan = sale['Nama Pelanggan']?.toString().toLowerCase() ?? '';
          final sales = sale['Nama Sales']?.toString().toLowerCase() ?? '';
          final barang = sale['Nama Barang']?.toString().toLowerCase() ?? '';
          return noFaktur.contains(query.toLowerCase()) ||
                 pelanggan.contains(query.toLowerCase()) ||
                 sales.contains(query.toLowerCase()) ||
                 barang.contains(query.toLowerCase());
        }).toList();
      }
    });
    _calculateTotalPenjualan(); // Hitung ulang total setelah filter
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _totalPenjualan = 0.0;
    });
    await _loadSalesData();
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
            // Date Picker Row
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Periode: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pilih Tanggal'),
                  ),
                ],
              ),
            ),
            
            // Total Penjualan Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Penjualan:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      _formatCurrency(_totalPenjualan),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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
                  'Detail Penjualan',
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
                  labelText: 'Cari No.Faktur/Pelanggan/Sales/Barang',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _filterSales,
              ),
            ),
            const SizedBox(height: 16),
            _buildSalesTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTable() {
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

    if (_filteredSalesData.isEmpty) {
      return Column(
        children: [
          Text(
            _searchQuery.isEmpty
                ? 'Tidak ada data penjualan'
                : 'Tidak ditemukan penjualan dengan kata kunci "$_searchQuery"',
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
                    'Jumlah Data: ${_filteredSalesData.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('No Faktur', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Sales', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Barang', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                    label: Text('Harga', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Laba', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Diskon', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                    label: Text('Ongkir', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(label: Text('Satuan', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _filteredSalesData.map((sale) {
                  // Hitung subtotal per baris
                  double harga = (sale['Harga Satuan'] ?? 0).toDouble();
                  double qty = (sale['Jumlah_Converted'] ?? 0).toDouble();
                  double subtotal = harga * qty;
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(sale['No Faktur']?.toString() ?? '-')),
                      DataCell(Text(_formatDate(sale['Tanggal Jual']))),
                      DataCell(Text(sale['Nama Pelanggan']?.toString() ?? '-')),
                      DataCell(Text(sale['Nama Sales']?.toString() ?? '-')),
                      DataCell(Text(sale['Nama Barang']?.toString() ?? '-')),
                      DataCell(Text(_formatCurrency(sale['Harga Satuan']))),
                      DataCell(Text(sale['Jumlah_Converted']?.toString() ?? '0')),
                      DataCell(
                        Text(
                          _formatCurrency(subtotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(_formatCurrency(sale['Laba']))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(sale['Status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sale['Status']?.toString().toUpperCase() ?? '-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(sale['Cara Bayar']?.toString() ?? '-')),
                      DataCell(Text(_formatCurrency(sale['Diskon']))),
                      DataCell(Text(_formatCurrency(sale['Ongkos Kirim']))),
                      DataCell(Text(sale['Satuan']?.toString() ?? '-')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      return formatFlexibleDate(date, 'dd/MM/yyyy', fallback: date.toString());
    } catch (e) {
      return date.toString();
    }
  }

  static String _formatCurrency(num? value) {
    final safeValue = value ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 1,
    );
    return formatter.format(safeValue.toDouble());
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

  Future<void> _exportToCSV() async {
    if (_filteredSalesData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    try {
      // Prepare CSV data
      List<List<String>> csvData = [
        ['No Faktur', 'Tanggal', 'Pelanggan', 'Sales', 'Barang', 'Harga', 'Qty', 'Subtotal', 'Laba', 'Status', 'Pembayaran', 'Diskon', 'Ongkir', 'Satuan'], // Headers
        ..._filteredSalesData.map((sale) {
          double harga = (sale['Harga Satuan'] ?? 0).toDouble();
          double qty = (sale['Jumlah_Converted'] ?? 0).toDouble();
          double subtotal = harga * qty;
          return [
            sale['No Faktur']?.toString() ?? '',
            _formatDate(sale['Tanggal Jual']),
            sale['Nama Pelanggan']?.toString() ?? '',
            sale['Nama Sales']?.toString() ?? '',
            sale['Nama Barang']?.toString() ?? '',
            sale['Harga Satuan_formatted'] ?? _formatCurrency(sale['Harga Satuan']),
            sale['Jumlah_Converted']?.toString() ?? '0',
            _formatCurrency(subtotal),
            sale['Laba_formatted'] ?? _formatCurrency(sale['Laba']),
            sale['Status']?.toString() ?? '',
            sale['Cara Bayar']?.toString() ?? '',
            sale['Diskon_formatted'] ?? _formatCurrency(sale['Diskon']),
            sale['Ongkos Kirim_formatted'] ?? _formatCurrency(sale['Ongkos Kirim']),
            sale['Satuan']?.toString() ?? '',
          ];
        }),
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Create file
      String fileName = 'laporan_penjualan_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      File file = File('${directory!.path}/$fileName');
      await file.writeAsString(csv);

      // Open file
      await OpenFile.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV berhasil diekspor: $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor CSV: $e')),
      );
    }
  }
}
