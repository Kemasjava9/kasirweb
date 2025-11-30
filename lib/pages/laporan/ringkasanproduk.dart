import '../../db/laporan_db.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class RingkasanProdukWidget extends StatelessWidget {
  const RingkasanProdukWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: LaporanDb.getProductSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return buildProductSummaryCard(context, snapshot.data ?? {});
      },
    );
  }

  Widget buildProductSummaryCard(BuildContext context, Map<String, dynamic> summary) {
    // Convert values to proper types with null safety
    final productCount = (summary['product_count'] as num?)?.toInt() ?? 0;
    final jumlahproduk = (summary['jumlahstoktotal'] as num?)?.toInt() ?? 0;
    final hppValue = (summary['hpp_value'] as num?)?.toDouble() ?? 0.0;
    final sellingValue = (summary['selling_value'] as num?)?.toDouble() ?? 0.0;
    final totalDebt = (summary['total_debt'] as num?)?.toDouble() ?? 0.0;
    final totalReceivable = (summary['total_receivable'] as num?)?.toDouble() ?? 0.0;

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
                  'Ringkasan Produk',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportToCSV(context, summary),
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Jumlah Produk', productCount.toString(), Icons.list),
            _buildSummaryRow('Jumlah Stok Produk', jumlahproduk.toString(), Icons.production_quantity_limits_rounded),
            _buildSummaryRow('Nilai HPP Stok', _formatCurrency(hppValue), Icons.inventory),
            _buildSummaryRow('Nilai Jual Stok', _formatCurrency(sellingValue), Icons.sell),
            _buildSummaryRow('Total Hutang Pembelian', _formatCurrency(totalDebt), Icons.money_off, Colors.red),
            _buildSummaryRow('Total Piutang Penjualan', _formatCurrency(totalReceivable), Icons.money, Colors.green),
          ],
        ),
      ),
    );
  }

  static String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  static _buildSummaryRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blueGrey),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _exportToCSV(BuildContext context, Map<String, dynamic> summary) async {
    try {
      // Prepare CSV data
      List<List<String>> csvData = [
        ['Label', 'Nilai'], // Headers
        ['Jumlah Produk', (summary['product_count'] as num?)?.toInt().toString() ?? '0'],
        ['Jumlah Stok Produk', (summary['jumlahstoktotal'] as num?)?.toInt().toString() ?? '0'],
        ['Nilai HPP Stok', _formatCurrency((summary['hpp_value'] as num?)?.toDouble() ?? 0.0)],
        ['Nilai Jual Stok', _formatCurrency((summary['selling_value'] as num?)?.toDouble() ?? 0.0)],
        ['Total Hutang Pembelian', _formatCurrency((summary['total_debt'] as num?)?.toDouble() ?? 0.0)],
        ['Total Piutang Penjualan', _formatCurrency((summary['total_receivable'] as num?)?.toDouble() ?? 0.0)],
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
      String fileName = 'ringkasan_produk_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
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
