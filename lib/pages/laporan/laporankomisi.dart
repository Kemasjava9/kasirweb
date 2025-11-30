import '../../db/laporan_db.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

class CommissionReportWidget extends StatefulWidget {
  const CommissionReportWidget({super.key});

  @override
  State<CommissionReportWidget> createState() => _CommissionReportWidgetState();
}

class _CommissionReportWidgetState extends State<CommissionReportWidget> {
  List<Map<String, dynamic>> _commissionData = [];
  List<Map<String, dynamic>> _filteredCommissionData = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCommissionData();
  }

  Future<void> _loadCommissionData() async {
    try {
      final data = await LaporanDb.getCommissionReport();
      setState(() {
        _commissionData = data;
        _filteredCommissionData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data komisi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterCommission(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCommissionData = _commissionData;
      } else {
        _filteredCommissionData = _commissionData.where((commission) {
          final kodeBarang = commission['kode_barang']?.toString().toLowerCase() ?? '';
          final namaBarang = commission['nama_barang']?.toString().toLowerCase() ?? '';
          final namaKomisi = commission['nama_komisi']?.toString().toLowerCase() ?? '';
          final satuan = commission['satuan']?.toString().toLowerCase() ?? '';
          return kodeBarang.contains(query.toLowerCase()) ||
                 namaBarang.contains(query.toLowerCase()) ||
                 namaKomisi.contains(query.toLowerCase()) ||
                 satuan.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadCommissionData();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Laporan Komisi',
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
                  labelText: 'Cari Kode/Nama Barang/Komisi',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _filterCommission,
              ),
            ),
            const SizedBox(height: 16),
            _buildCommissionTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionTable() {
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

    if (_filteredCommissionData.isEmpty) {
      return Column(
        children: [
          Text(
            _searchQuery.isEmpty
                ? 'Tidak ada data komisi'
                : 'Tidak ditemukan komisi dengan kata kunci "$_searchQuery"',
          ),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Refresh'),
          ),
        ],
      );
    }

    // Calculate total commission
    double totalKomisi = 0;
    for (var commission in _filteredCommissionData) {
      totalKomisi += (commission['total_komisi'] as num?)?.toDouble() ?? 0;
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          // Total Commission Summary
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Komisi:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatCurrency(totalKomisi),
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
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Kode Barang', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                    label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(label: Text('Satuan', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                    label: Text('Nilai Komisi', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(label: Text('Nama Komisi', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                    label: Text('Total Komisi', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                ],
                rows: _filteredCommissionData.map((commission) {
                  return DataRow(
                    cells: [
                      DataCell(Text(commission['kode_barang']?.toString() ?? '-')),
                      DataCell(Text(commission['nama_barang']?.toString() ?? '-')),
                      DataCell(Text(commission['jumlah']?.toString() ?? '0')),
                      DataCell(Text(commission['satuan']?.toString() ?? '-')),
                      DataCell(Text(_formatCurrency(commission['nilai_komisi']))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            commission['nama_komisi']?.toString() ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatCurrency(commission['total_komisi']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    try {
      final numValue = value is String ? double.tryParse(value) ?? 0 : (value as num).toDouble();
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(numValue);
    } catch (e) {
      return 'Rp 0';
    }
  }

  Future<void> _exportToCSV() async {
    if (_filteredCommissionData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    try {
      // Prepare CSV data
      List<List<String>> csvData = [
        ['Kode Barang', 'Nama Barang', 'Jumlah', 'Satuan', 'Nilai Komisi', 'Nama Komisi', 'Total Komisi'], // Headers
        ..._filteredCommissionData.map((commission) => [
          commission['kode_barang']?.toString() ?? '',
          commission['nama_barang']?.toString() ?? '',
          commission['jumlah']?.toString() ?? '0',
          commission['satuan']?.toString() ?? '',
          _formatCurrency(commission['nilai_komisi']),
          commission['nama_komisi']?.toString() ?? '',
          _formatCurrency(commission['total_komisi']),
        ]),
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      String fileName = 'laporan_komisi_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

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
