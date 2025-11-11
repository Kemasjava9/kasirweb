import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../export/export_page.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _currentReport = '';

  void _setLoading(String reportType, bool loading) {
    setState(() {
      _isLoading = loading;
      _currentReport = loading ? reportType : '';
    });
  }

  Future<void> _generateLaporanPenjualan() async {
    _setLoading('penjualan', true);
    try {
      // Get penjualan data for the last 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final querySnapshot = await _firestore
          .collection('penjualan')
          .where('tanggal', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .orderBy('tanggal', descending: true)
          .get();

      double totalPenjualan = 0;
      int totalTransaksi = querySnapshot.docs.length;

      for (var doc in querySnapshot.docs) {
        totalPenjualan += (doc.data()['grand_total'] ?? 0).toDouble();
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Laporan Penjualan (30 Hari Terakhir)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Transaksi: $totalTransaksi'),
              Text('Total Penjualan: Rp ${totalPenjualan.toStringAsFixed(0)}'),
              const SizedBox(height: 16),
              const Text('Untuk export detail, gunakan menu Export Data.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExportPage()),
                );
              },
              child: const Text('Export Data'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _setLoading('penjualan', false);
    }
  }

  Future<void> _generateLaporanPembelian() async {
    _setLoading('pembelian', true);
    try {
      // Get pembelian data for the last 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final querySnapshot = await _firestore
          .collection('pembelian')
          .where('tanggal', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .orderBy('tanggal', descending: true)
          .get();

      double totalPembelian = 0;
      int totalTransaksi = querySnapshot.docs.length;

      for (var doc in querySnapshot.docs) {
        totalPembelian += (doc.data()['total'] ?? 0).toDouble();
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Laporan Pembelian (30 Hari Terakhir)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Transaksi: $totalTransaksi'),
              Text('Total Pembelian: Rp ${totalPembelian.toStringAsFixed(0)}'),
              const SizedBox(height: 16),
              const Text('Untuk export detail, gunakan menu Export Data.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExportPage()),
                );
              },
              child: const Text('Export Data'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _setLoading('pembelian', false);
    }
  }

  Future<void> _generateLaporanStok() async {
    _setLoading('stok', true);
    try {
      final querySnapshot = await _firestore.collection('barang').get();

      int totalBarang = querySnapshot.docs.length;
      int totalStok = 0;
      int barangHabis = 0;

      for (var doc in querySnapshot.docs) {
        final jumlah = (doc.data()['jumlah'] ?? 0) as int;
        totalStok += jumlah;
        if (jumlah == 0) barangHabis++;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Laporan Stok Barang'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Jenis Barang: $totalBarang'),
              Text('Total Stok Keseluruhan: $totalStok'),
              Text('Barang Habis: $barangHabis'),
              const SizedBox(height: 16),
              const Text('Untuk export detail, gunakan menu Export Data.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExportPage()),
                );
              },
              child: const Text('Export Data'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _setLoading('stok', false);
    }
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required VoidCallback onGenerate,
    required String type,
  }) {
    final bool isLoading = _isLoading && _currentReport == type;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : onGenerate,
              icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.analytics),
              label: Text(isLoading ? 'Memuat...' : 'Generate Laporan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildReportCard(
              title: 'Laporan Penjualan',
              description: 'Laporan penjualan 30 hari terakhir dengan ringkasan total transaksi dan nilai penjualan.',
              onGenerate: _generateLaporanPenjualan,
              type: 'penjualan',
            ),

            _buildReportCard(
              title: 'Laporan Pembelian',
              description: 'Laporan pembelian 30 hari terakhir dengan ringkasan total transaksi dan nilai pembelian.',
              onGenerate: _generateLaporanPembelian,
              type: 'pembelian',
            ),

            _buildReportCard(
              title: 'Laporan Stok Barang',
              description: 'Laporan stok barang saat ini dengan total jenis barang, total stok, dan barang habis.',
              onGenerate: _generateLaporanStok,
              type: 'stok',
            ),

            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Data Lengkap',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Untuk mendapatkan data lengkap dalam format Excel, gunakan menu Export Data.',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExportPage()),
                        );
                      },
                      icon: const Icon(Icons.file_download, color: Colors.blue),
                      label: const Text('Buka Export Data', style: TextStyle(color: Colors.blue)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
