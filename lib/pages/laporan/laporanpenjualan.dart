import '../../db/laporan_db.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/date_utils.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

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
  double _totalPenjualan = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  void _calculateTotalPenjualan() {
    double total = 0.0;
    if (_salesData.isNotEmpty && _salesData.first.containsKey('is_summary')) {
      total = (_salesData.first['total_penjualan'] as num?)?.toDouble() ?? 0.0;
    }
    setState(() {
      _totalPenjualan = total;
    });
  }

  Future<void> _loadSalesData() async {
    try {
      final data = await LaporanDb.getSalesByInvoice();
      setState(() {
        _salesData = data;
        if (data.isNotEmpty && data.first['is_summary'] == true) {
          _filteredSalesData = data.sublist(1);
        } else {
          _filteredSalesData = data;
        }
        _isLoading = false;
      });
      _calculateTotalPenjualan();
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
      List<Map<String, dynamic>> dataOnly = _salesData.isNotEmpty && _salesData.first['is_summary'] == true
          ? _salesData.sublist(1)
          : _salesData;

      if (query.isEmpty) {
        _filteredSalesData = dataOnly;
      } else {
        _filteredSalesData = dataOnly.where((sale) {
          final noFaktur = sale['No Faktur']?.toString().toLowerCase() ?? '';
          final pelanggan = sale['Nama Pelanggan']?.toString().toLowerCase() ?? '';
          final sales = sale['Nama Sales']?.toString().toLowerCase() ?? '';

          bool itemsMatch = false;
          if (sale['items'] is List) {
            for (var item in sale['items']) {
              final barang = item['Nama Barang']?.toString().toLowerCase() ?? '';
              if (barang.contains(query.toLowerCase())) {
                itemsMatch = true;
                break;
              }
            }
          }

          return noFaktur.contains(query.toLowerCase()) ||
                 pelanggan.contains(query.toLowerCase()) ||
                 sales.contains(query.toLowerCase()) ||
                 itemsMatch;
        }).toList();
      }
    });
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
    // Different layout for web vs mobile
    if (kIsWeb) {
      // Web layout - wider, minimal padding for full width usage
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Penjualan:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      _formatCurrency(_totalPenjualan),
                      style: const TextStyle(
                        fontSize: 20,
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportToCSV,
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: _filterSales,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildSalesTable()),
          ],
        ),
      );
    } else {
      // Mobile layout - compact widget
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Penjualan:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      Text(
                        _formatCurrency(_totalPenjualan),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Penjualan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _exportToCSV,
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Cari No.Faktur/Pelanggan/Sales/Barang',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: _filterSales,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildSalesTable()),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSalesTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredSalesData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      );
    }

    if (kIsWeb) {
      // Web layout - detailed DataTable showing item-level data
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20.0,
            columns: const [
              DataColumn(label: Text('No Faktur')),
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Pelanggan')),
              DataColumn(label: Text('Barang')),
              DataColumn(label: Text('Harga')),
              DataColumn(label: Text('Qty')),
              DataColumn(label: Text('Satuan')),
              DataColumn(label: Text('Subtotal')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Pembayaran')),
              DataColumn(label: Text('Diskon')),
              DataColumn(label: Text('Ongkir')),
              DataColumn(label: Text('Sales')),
            ],
            rows: _filteredSalesData.expand((invoice) {
              final items = (invoice['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              if (items.isEmpty) {
                // If no items, show invoice summary row
                return [
                  DataRow(
                    cells: [
                      DataCell(Text(invoice['No Faktur']?.toString() ?? '-')),
                      DataCell(Text(invoice['Tanggal Jual']?.toString() ?? '-')),
                      DataCell(Text(invoice['Nama Pelanggan']?.toString() ?? '-')),
                      const DataCell(Text('-')),
                      const DataCell(Text('-')),
                      const DataCell(Text('-')),
                      const DataCell(Text('-')),
                      DataCell(
                        Text(
                          invoice['total_invoice_formatted']?.toString() ?? 'Rp 0',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                      DataCell(Text(invoice['Status']?.toString() ?? '-')),
                      DataCell(Text(invoice['Cara Bayar']?.toString() ?? '-')),
                      DataCell(Text(_formatCurrency(invoice['Diskon']))),
                      DataCell(Text(_formatCurrency(invoice['Ongkir']))),
                      DataCell(Text(invoice['Nama Sales']?.toString() ?? '-')),
                    ],
                  )
                ];
              } else {
                // Show one row per item
                return items.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(invoice['No Faktur']?.toString() ?? '-')),
                      DataCell(Text(invoice['Tanggal Jual']?.toString() ?? '-')),
                      DataCell(Text(invoice['Nama Pelanggan']?.toString() ?? '-')),
                      DataCell(Text(item['Nama Barang']?.toString() ?? '-')),
                      DataCell(Text(_formatCurrency(item['Harga Satuan']))),
                      DataCell(Text(_formatNumber(item['Jumlah']))),
                      DataCell(Text(item['Satuan']?.toString() ?? '-')),
                      DataCell(
                        Text(
                          item['Subtotal_formatted']?.toString() ?? 'Rp 0',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(Text(invoice['Status']?.toString() ?? '-')),
                      DataCell(Text(invoice['Cara Bayar']?.toString() ?? '-')),
                      DataCell(Text(_formatCurrency(invoice['Diskon']))),
                      DataCell(Text(_formatCurrency(invoice['Ongkir']))),
                      DataCell(Text(invoice['Nama Sales']?.toString() ?? '-')),
                    ],
                  );
                }).toList();
              }
            }).toList(),
          ),
        ),
      );
    }
      // Mobile layout - expandable list widget
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.builder(
          itemCount: _filteredSalesData.length,
          itemBuilder: (context, index) {
            final invoice = _filteredSalesData[index];
            final items = (invoice['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ExpansionTile(
                title: Text('Faktur: ${invoice['No Faktur']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${invoice['Tanggal Jual']} - ${invoice['Nama Pelanggan']}'),
                trailing: Text(
                  invoice['total_invoice_formatted']?.toString() ?? 'Rp 0',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                ),
                children: [
                  ...items.map((item) {
                    return ListTile(
                      title: Text(item['Nama Barang']?.toString() ?? '-'),
                      subtitle: Text('${_formatNumber(item['Jumlah'])} x ${_formatCurrency(item['Harga Satuan'])}'),
                      trailing: Text(
                        item['Subtotal_formatted']?.toString() ?? 'Rp 0',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status: ${invoice['Status']}'),
                        Text('Sales: ${invoice['Nama Sales']}'),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
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

  String _formatCurrency(num? value) {
    final safeValue = value ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 1,
    );
    return formatter.format(safeValue.toDouble());
  }

  String _formatNumber(num? value) {
    final safeValue = value ?? 0;
    final formatter = NumberFormat.decimalPattern('id_ID');
    return formatter.format(safeValue.toDouble());
  }

  Future<void> _exportToCSV() async {
    List<Map<String, dynamic>> dataToExport = _salesData.isNotEmpty && _salesData.first['is_summary'] == true
        ? _salesData.sublist(1)
        : _salesData;

    if (dataToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    try {
      List<List<String>> csvData = [
        ['No Faktur', 'Tanggal', 'Pelanggan', 'Sales', 'Status', 'Cara Bayar', 'Nama Barang', 'Harga Satuan', 'Jumlah', 'Subtotal', 'Laba', 'Satuan'],
      ];

      for (var invoice in dataToExport) {
        final items = (invoice['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (var item in items) {
          csvData.add([
            invoice['No Faktur']?.toString() ?? '',
            invoice['Tanggal Jual']?.toString() ?? '',
            invoice['Nama Pelanggan']?.toString() ?? '',
            invoice['Nama Sales']?.toString() ?? '',
            invoice['Status']?.toString() ?? '',
            invoice['Cara Bayar']?.toString() ?? '',
            item['Nama Barang']?.toString() ?? '',
            _formatCurrency(item['Harga Satuan']),
            _formatNumber(item['Jumlah']),
            _formatCurrency(item['Subtotal']),
            _formatCurrency(item['Laba']),
            item['Satuan']?.toString() ?? '',
          ]);
        }
      }

      String csv = const ListToCsvConverter().convert(csvData);
      Directory? directory;
      if (kIsWeb) {
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'laporan_penjualan.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
        String fileName = 'laporan_penjualan_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
        File file = File('${directory!.path}/$fileName');
        await file.writeAsString(csv);
        await OpenFile.open(file.path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV berhasil diekspor')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor CSV: $e')),
      );
    }
  }
}
