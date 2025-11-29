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

class ProdukTerlarisWidget extends StatefulWidget {
  const ProdukTerlarisWidget({super.key});

  @override
  _ProdukTerlarisWidgetState createState() => _ProdukTerlarisWidgetState();
}

class _ProdukTerlarisWidgetState extends State<ProdukTerlarisWidget> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _products = [];

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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date Picker Row
        Padding(
          padding: const EdgeInsets.all(16.0),
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
        // Data Display
        FutureBuilder<List<Map<String, dynamic>>>(
          future: LaporanDb.getBestSellingProducts(
            startDate: DateFormat('yyyy-MM-dd').format(_startDate),
            endDate: DateFormat('yyyy-MM-dd').format(_endDate),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              _products = snapshot.data!;
            }
            return _buildBestSellingProducts(_products);
          },
        ),
      ],
    );
  }

  Widget _buildBestSellingProducts(List<Map<String, dynamic>> products) {
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
                  '10 Produk Terlaris',
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
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blueGrey[50]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Terjual', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Total Penjualan', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                  ],
                ),
                ...products.map((product) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(product['nama_barang']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(product['total_terjual'].toString(), textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _formatCurrency(product['total_penjualan']),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _exportToCSV() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    try {
      // Prepare CSV data
      List<List<String>> csvData = [
        ['Produk', 'Terjual', 'Total Penjualan'], // Headers
        ..._products.map((product) => [
              product['nama_barang']?.toString() ?? '',
              product['total_terjual']?.toString() ?? '0',
              _formatCurrency(product['total_penjualan']),
            ]),
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      String fileName = 'produk_terlaris_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

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

  static String _formatCurrency(num? value) {
    final safeValue = value ?? 0; // kalau null, anggap 0
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 1,
    );
    return formatter.format(safeValue.toDouble());
  }
}
