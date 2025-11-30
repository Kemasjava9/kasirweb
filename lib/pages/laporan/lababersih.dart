import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/laporan_db.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

class LabaBersihWidget extends StatefulWidget {
  const LabaBersihWidget({super.key});

  @override
  _LabaBersihWidgetState createState() => _LabaBersihWidgetState();
}

class _LabaBersihWidgetState extends State<LabaBersihWidget> {
  Map<String, dynamic> _profitData = {};


  static String formatRupiah(num? value) {
    final safeValue = value ?? 0; // kalau null, anggap 0
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 1,
    );
    return formatter.format(safeValue.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: LaporanDb.calculateNetProfit(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading data: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.hasData) {
          _profitData = snapshot.data!;
        }
        return _buildNetProfitCard(context, _profitData);
      },
    );
  }

  Widget _buildNetProfitCard(BuildContext context, Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Laporan Laba Bersih',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
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

            // Penjualan
              _buildProfitRow('Total Penjualan', data['total_penjualan'] ?? 0, Colors.green),
            _buildProfitRow('Laba Penjualan', data['laba_penjualan'] ?? 0, Colors.blue),
            const SizedBox(height: 10),

            // Komisi
            _buildProfitRow('Total Komisi', data['total_komisi'] ?? 0, Colors.green),
            const SizedBox(height: 10),

            // Pembelian
            _buildProfitRow('Total Pembelian', data['total_pembelian'] ?? 0, Colors.red),
            const Divider(),

            // Laba Bersih
            _buildProfitRow(
              'Laba Bersih',
              data['laba_bersih'] ?? 0,
              (data['laba_bersih'] ?? 0) >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildProfitRow(String label, num value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            formatRupiah(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV() async {
    if (_profitData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    try {
      // Prepare CSV data
      List<List<String>> csvData = [
        ['Label', 'Nilai'], // Headers
        ['Total Penjualan', formatRupiah(_profitData['total_penjualan'])],
        ['Laba Penjualan', formatRupiah(_profitData['laba_penjualan'])],
        ['Total Komisi', formatRupiah(_profitData['total_komisi'])],
        ['Total Pembelian', formatRupiah(_profitData['total_pembelian'])],
        ['Laba Bersih', formatRupiah(_profitData['laba_bersih'])],
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      String fileName = 'laba_bersih_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

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
