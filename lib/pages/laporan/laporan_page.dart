import 'package:flutter/material.dart';
import 'pembeliansupplier.dart';
import 'laporanpenjualan.dart';
import 'dataprodukterlaris.dart';
import 'lababersih.dart';
import 'laporankas.dart';
import 'laporankomisi.dart';
import 'ringkasanproduk.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

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
              'Pilih Jenis Laporan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 24),

            // Pembelian Supplier Report
            _buildReportButton(
              context,
              title: 'Laporan Pembelian Supplier',
              description: 'Detail pembelian berdasarkan supplier dengan informasi lengkap',
              icon: Icons.shopping_cart,
              color: Colors.blue,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Pembelian Supplier'),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  body: PembelianSupplierWidget(),
                )),
              ),
            ),

            // Penjualan Report
            _buildReportButton(
              context,
              title: 'Laporan Penjualan',
              description: 'Detail penjualan dengan laba dan informasi lengkap',
              icon: Icons.sell,
              color: Colors.green,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Laporan Penjualan'),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  body: SalesDetailWidget(),
                )),
              ),
            ),

            // Produk Terlaris Report
            _buildReportButton(
              context,
              title: 'Produk Terlaris',
              description: '10 produk terlaris berdasarkan jumlah penjualan',
              icon: Icons.trending_up,
              color: Colors.orange,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Produk Terlaris'),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  body: ProdukTerlarisWidget(),
                )),
              ),
            ),

            // Laba Bersih Report
            _buildReportButton(
              context,
              title: 'Laporan Laba Bersih',
              description: 'Perhitungan laba bersih dari penjualan dan pembelian',
              icon: Icons.account_balance_wallet,
              color: Colors.purple,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Laba Bersih'),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  body: LabaBersihWidget(),
                )),
              ),
            ),

            // Laporan Kas
            _buildReportButton(
              context,
              title: 'Laporan Kas',
              description: 'Arus kas masuk dan keluar dengan saldo akhir',
              icon: Icons.account_balance,
              color: Colors.teal,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LaporanKas()),
              ),
            ),

            // Komisi Report
            _buildReportButton(
              context,
              title: 'Laporan Komisi',
              description: 'Detail komisi penjualan berdasarkan produk',
              icon: Icons.people,
              color: Colors.indigo,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Laporan Komisi'),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  body: CommissionReportWidget(),
                )),
              ),
            ),

            // Ringkasan Produk
            _buildReportButton(
              context,
              title: 'Ringkasan Produk',
              description: 'Ringkasan stok produk, nilai HPP, dan piutang',
              icon: Icons.inventory,
              color: Colors.brown,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Ringkasan Produk'),
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                  ),
                  body: RingkasanProdukWidget(),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          elevation: 4,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.3), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
