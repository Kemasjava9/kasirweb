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

class LaporanKas extends StatefulWidget {
  const LaporanKas({super.key});

  @override
  State<LaporanKas> createState() => _LaporanKasState();
}

class _LaporanKasState extends State<LaporanKas> {
  List<Map<String, dynamic>> _cashFlowData = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCashFlowData();
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
      });
      _loadCashFlowData();
    }
  }

  Future<void> _loadCashFlowData() async {
    try {
      final data = await LaporanDb.getLaporanKas(
        startDate: DateFormat('dd-MM-yyyy').format(_startDate),
        endDate: DateFormat('dd-MM-yyyy').format(_endDate),
      );
      setState(() {
        _cashFlowData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  DateTime _parseDate(String dateString) {
    try {
      // Try parsing as ISO format first
      if (dateString.contains('-')) {
        return DateTime.parse(dateString);
      }
      // Try parsing as dd-MM-yyyy format
      else if (dateString.contains('-')) {
        final parts = dateString.split('-');
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
      // Fallback to current date if parsing fails
      return DateTime.now();
    } catch (e) {
      return DateTime.now(); // Fallback to current date if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Kas"),
        actions: [
          ElevatedButton.icon(
            onPressed: _exportToCSV,
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
        ],
      ),
      body: _buildCashFlowContent(),
    );
  }

  Widget _buildCashFlowContent() {
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
              onPressed: () => setState(() {
                _isLoading = true;
                _loadCashFlowData();
              }),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_cashFlowData.isEmpty) {
      return const Center(child: Text("Tidak ada data laporan kas"));
    }

    final data = _cashFlowData;

    // Calculate total pemasukan and pengeluaran
    double totalMasuk = 0;
    double totalKeluar = 0;

    for (var item in data) {
      if (item['jenis'] == 'masuk') {
        totalMasuk += item['jumlah'] as double;
      } else {
        totalKeluar += item['jumlah'] as double;
      }
    }

    double saldo = totalMasuk - totalKeluar;

    return Column(
      children: [
        // Date Picker Row
        Padding(
          padding: const EdgeInsets.all(8.0),
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
        // Summary cards
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Pemasukan card
              Expanded(
                child: Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pemasukan",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp',
                            decimalDigits: 1,
                          ).format(totalMasuk),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Pengeluaran card
              Expanded(
                child: Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pengeluaran",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp',
                            decimalDigits: 1,
                          ).format(totalKeluar),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Saldo card
              Expanded(
                child: Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Saldo",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp',
                            decimalDigits: 1,
                          ).format(saldo),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

         Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final date = _parseDate(item['tanggal'].toString());

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    item['keterangan']?.toString() ?? 'No Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${DateFormat('dd/MM/yyyy').format(date)} • ${item['kategori']?.toString() ?? 'Uncategorized'}",
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item['jumlah_formatted'] ?? NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp',
                          decimalDigits: 1,
                        ).format(item['jumlah'] ?? 0),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item['jenis'] == 'keluar' ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        item['jenis'] == 'keluar' ? 'Pengeluaran' : 'Pemasukan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _exportToCSV() async {
    if (_cashFlowData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    try {
      // Prepare CSV data
      List<List<String>> csvData = [
        ['Tanggal', 'Keterangan', 'Kategori', 'Jumlah', 'Jenis'], // Headers
        ..._cashFlowData.map((item) => [
          _parseDate(item['tanggal'].toString()).toString(),
          item['keterangan']?.toString() ?? '',
          item['kategori']?.toString() ?? '',
          item['jumlah']?.toString() ?? '0',
          item['jenis']?.toString() ?? '',
        ]),
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      String fileName = 'laporan_kas_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

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
