import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'barang/barang_page.dart';
import 'supplier/supplier_page.dart';
import 'pelanggan/pelanggan_page.dart';
import 'pembelian/pembelian_page.dart';
import 'penjualan/penjualan_page.dart';
import 'pengaturan/settings_page.dart';
import 'suratjalan/surat_jalan_page.dart';
import 'laporan/laporan_page.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardPage({super.key, required this.userData});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Build navigation items (icon, label, page) dynamically based on user role
  List<Map<String, Object>> get _navItems {
    final items = <Map<String, Object>>[
      {'icon': Icons.dashboard, 'label': 'Dashboard', 'page': const DashboardHome()},
      {'icon': Icons.inventory, 'label': 'Barang', 'page': const BarangPage()},
      {'icon': Icons.business, 'label': 'Supplier', 'page': const SupplierPage()},
      {'icon': Icons.people, 'label': 'Pelanggan', 'page': const PelangganPage()},
      {'icon': Icons.shopping_cart, 'label': 'Pembelian', 'page': const PembelianPage()},
      {'icon': Icons.point_of_sale, 'label': 'Penjualan', 'page': const PenjualanPage()},
      {'icon': Icons.local_shipping, 'label': 'Surat Jalan', 'page': const SuratJalanPage()},
      {'icon': Icons.bar_chart, 'label': 'Laporan', 'page': const LaporanPage()},
    ];

    // Only add settings page for admin users
    try {
      if ((widget.userData['level'] ?? '') == 'admin') {
        items.add({'icon': Icons.settings, 'label': 'Pengaturan', 'page': const SettingsPage()});
      }
    } catch (_) {
      // If userData is missing or not a map, just don't add admin items
    }

    return items;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Penjualan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        // Show menu button only on small screens (Drawer)
        leading: LayoutBuilder(builder: (context, constraints) {
          if (MediaQuery.of(context).size.width < 800) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          }
          return const SizedBox.shrink();
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart, size: 36, color: Colors.white),
                    const SizedBox(height: 8),
                    const Text('Aplikasi Penjualan', style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      (widget.userData['nama_lengkap'] ?? widget.userData['namaLengkap'] ?? '').toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Build drawer tiles from _navItems so labels and indices stay in sync
              for (int i = 0; i < _navItems.length; i++)
                _buildDrawerTile(
                  _navItems[i]['icon'] as IconData,
                  _navItems[i]['label'] as String,
                  i,
                ),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final int safeIndex = (_selectedIndex >= 0 && _selectedIndex < _navItems.length)
          ? _selectedIndex
          : 0; // fallback to first page

        // Wide screens: show NavigationRail + content
        if (constraints.maxWidth >= 800) {
          return Row(
            children: [
              NavigationRail(
                selectedIndex: safeIndex,
                onDestinationSelected: (index) => _onItemTapped(index),
                labelType: NavigationRailLabelType.all,
                destinations: _navItems.map((item) {
                  return NavigationRailDestination(
                    icon: Icon(item['icon'] as IconData),
                    label: Text(item['label'] as String),
                  );
                }).toList(),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              // Content
              Expanded(child: _navItems[safeIndex]['page'] as Widget),
            ],
          );
        }

        // Small screens: show content only (Drawer available via AppBar)
        return _navItems[safeIndex]['page'] as Widget;
      }),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        // Close drawer and update index
        Navigator.of(context).pop();
        _onItemTapped(index);
      },
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _stats = {
    'totalBarang': 0,
    'totalSupplier': 0,
    'totalPelanggan': 0,
    'penjualanHariIni': 0.0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      // Get total barang
      final barangSnapshot = await _firestore.collection('barang').count().get();
      
      // Get total supplier
      final supplierSnapshot = await _firestore.collection('supplier').count().get();
      
      // Get total pelanggan
      final pelangganSnapshot = await _firestore.collection('pelanggan').count().get();
      
      // Get penjualan hari ini
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final penjualanSnapshot = await _firestore
          .collection('penjualan')
          .where('tanggal', isGreaterThanOrEqualTo: startOfDay)
          .where('tanggal', isLessThanOrEqualTo: endOfDay)
          .get();
      
      double totalPenjualan = 0;
      for (var doc in penjualanSnapshot.docs) {
        totalPenjualan += (doc.data()['grand_total'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          _stats = {
            'totalBarang': barangSnapshot.count,
            'totalSupplier': supplierSnapshot.count,
            'totalPelanggan': pelangganSnapshot.count,
            'penjualanHariIni': totalPenjualan,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return 'Rp ${(value / 1000000000).toStringAsFixed(1)}M';
    } else if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}Jt';
    } else if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadStats,
                    tooltip: 'Refresh Data',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Statistik cards
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 800;
                  final crossAxisCount = constraints.maxWidth > 1200
                    ? 4
                    : constraints.maxWidth > 800
                      ? 2
                      : constraints.maxWidth > 600
                        ? 2
                        : 1;

                  return GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: isWideScreen ? 3.0 : 1.5,
                    children: [
                      _buildStatCard(
                        'Total Barang',
                        _stats['totalBarang'].toString(),
                        Icons.inventory,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Total Supplier',
                        _stats['totalSupplier'].toString(),
                        Icons.business,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Total Pelanggan',
                        _stats['totalPelanggan'].toString(),
                        Icons.people,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Penjualan Hari Ini',
                        _formatCurrency(_stats['penjualanHariIni']),
                        Icons.trending_up,
                        Colors.red,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 200;
            
            if (isWideScreen) {
              // Wide screen: Row layout
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Narrow screen: Column layout
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}