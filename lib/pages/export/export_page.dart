import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/models.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _currentExport = '';

  Future<String> _getExportDirectory() async {
    if (kIsWeb) return '';
    
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null || userProfile.isEmpty) {
        throw Exception('Could not find user profile directory');
      }
      final directory = '$userProfile\\Downloads';
      final dir = Directory(directory);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return directory;
    }
    
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception('Could not access external storage');
      }
      final downloadsDir = Directory('${externalDir.path}/Downloads');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }
      return downloadsDir.path;
    }
    
    return Directory.current.path;
  }

  void _setLoading(String exportType, bool loading) {
    setState(() {
      _isLoading = loading;
      _currentExport = loading ? exportType : '';
    });
  }

  Future<void> _exportPenjualan() async {
    _setLoading('penjualan', true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Penjualan'];

      // Headers
      final headers = [
        'No Faktur',
        'Tanggal',
        'Pelanggan',
        'Sales',
        'Total',
        'Diskon',
        'Ongkos Kirim',
        'Biaya Lain',
        'Grand Total',
        'Metode Pembayaran',
        'Status',
      ];

      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
      }

      // Get penjualan data
      final querySnapshot = await _firestore.collection('penjualan')
        .orderBy('created_at', descending: true)
        .get();

      var rowIndex = 1;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final values = [
          data['no_faktur'] ?? '',
          data['tanggal'] != null
            ? (data['tanggal'] as Timestamp).toDate().toString().split(' ')[0]
            : '',
          data['nama_pelanggan'] ?? '',
          data['nama_sales'] ?? '',
          data['total_belanja'] ?? 0,
          data['diskon'] ?? 0,
          data['ongkos_kirim'] ?? 0,
          data['biaya_lain'] ?? 0,
          data['grand_total'] ?? 0,
          data['metode_pembayaran'] ?? '',
          data['status'] ?? '',
        ];

        // Get detail penjualan
        final detailQuery = await _firestore
          .collection('detail_penjualan')
          .where('no_faktur', isEqualTo: data['no_faktur'])
          .get();

        if (detailQuery.docs.isNotEmpty) {
          // Add main row
          for (var i = 0; i < values.length; i++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: rowIndex,
            ));
            if (values[i] is num) {
              cell.value = DoubleCellValue(values[i].toDouble());
            } else {
              cell.value = TextCellValue(values[i].toString());
            }
          }
          rowIndex++;

          // Add detail headers
          final detailHeaders = ['', 'Kode Barang', 'Nama Barang', 'Jumlah', 'Satuan', 'Harga', 'Total'];
          for (var i = 0; i < detailHeaders.length; i++) {
            sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: rowIndex,
            )).value = TextCellValue(detailHeaders[i]);
          }
          rowIndex++;

          // Add details
          for (var detail in detailQuery.docs) {
            final detailData = detail.data();
            final detailValues = [
              '',  // Indent
              detailData['kode_barang'] ?? '',
              detailData['nama_barang'] ?? '',
              detailData['jumlah'] ?? 0,
              detailData['satuan'] ?? '',
              detailData['harga_satuan'] ?? 0,
              detailData['total'] ?? 0,
            ];

            for (var i = 0; i < detailValues.length; i++) {
              final cell = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: i,
                rowIndex: rowIndex,
              ));
              if (detailValues[i] is num) {
                cell.value = DoubleCellValue(detailValues[i].toDouble());
              } else {
                cell.value = TextCellValue(detailValues[i].toString());
              }
            }
            rowIndex++;
          }

          // Blank row after details
          rowIndex++;
        } else {
          // No details, just main row
          for (var i = 0; i < values.length; i++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: rowIndex,
            ));
            if (values[i] is num) {
              cell.value = DoubleCellValue(values[i].toDouble());
            } else {
              cell.value = TextCellValue(values[i].toString());
            }
          }
          rowIndex++;
        }
      }

      // Column widths
      final columnWidths = [15, 12, 25, 20, 15, 12, 15, 15, 15, 20, 12];
      for (var i = 0; i < columnWidths.length; i++) {
        sheet.setColumnWidth(i, columnWidths[i].toDouble());
      }

      // Save file
      String filePath;
      if (kIsWeb) {
        // Handle web platform - will be handled by the web platform's download API
        final fileName = 'Data_Penjualan_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        filePath = fileName;
      } else {
        final now = DateTime.now();
        final fileName = 'Data_Penjualan_${now.day}-${now.month}-${now.year}.xlsx';
        final directory = await _getExportDirectory();
        filePath = '$directory${Platform.pathSeparator}$fileName';
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File berhasil disimpan di: $filePath'),
            action: Platform.isWindows ? SnackBarAction(
              label: 'Buka Folder',
              onPressed: () async {
                await Process.run('explorer.exe', ['/select,', filePath]);
              },
            ) : null,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _setLoading('penjualan', false);
    }
  }

  Future<void> _exportPembelian() async {
    _setLoading('pembelian', true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Pembelian'];

      // Headers
      final headers = [
        'No Faktur',
        'Tanggal',
        'Supplier',
        'Total',
        'Metode Pembayaran',
        'Status',
      ];

      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
      }

      // Get pembelian data
      final querySnapshot = await _firestore.collection('pembelian')
        .orderBy('created_at', descending: true)
        .get();

      var rowIndex = 1;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final values = [
          data['no_faktur'] ?? '',
          data['tanggal'] != null
            ? (data['tanggal'] as Timestamp).toDate().toString().split(' ')[0]
            : '',
          data['nama_supplier'] ?? '',
          data['total'] ?? 0,
          data['metode_pembayaran'] ?? '',
          data['status'] ?? '',
        ];

        // Get detail pembelian
        final detailQuery = await _firestore
          .collection('detail_pembelian')
          .where('no_faktur', isEqualTo: data['no_faktur'])
          .get();

        if (detailQuery.docs.isNotEmpty) {
          // Add main row
          for (var i = 0; i < values.length; i++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: rowIndex,
            ));
            if (values[i] is num) {
              cell.value = DoubleCellValue(values[i].toDouble());
            } else {
              cell.value = TextCellValue(values[i].toString());
            }
          }
          rowIndex++;

          // Add detail headers
          final detailHeaders = ['', 'Kode Barang', 'Nama Barang', 'Jumlah', 'Satuan', 'Harga', 'Total'];
          for (var i = 0; i < detailHeaders.length; i++) {
            sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: rowIndex,
            )).value = TextCellValue(detailHeaders[i]);
          }
          rowIndex++;

          // Add details
          for (var detail in detailQuery.docs) {
            final detailData = detail.data();
            final detailValues = [
              '',  // Indent
              detailData['kode_barang'] ?? '',
              detailData['nama_barang'] ?? '',
              detailData['jumlah'] ?? 0,
              detailData['satuan'] ?? '',
              detailData['harga_satuan'] ?? 0,
              detailData['total'] ?? 0,
            ];

            for (var i = 0; i < detailValues.length; i++) {
              final cell = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: i,
                rowIndex: rowIndex,
              ));
              if (detailValues[i] is num) {
                cell.value = DoubleCellValue(detailValues[i].toDouble());
              } else {
                cell.value = TextCellValue(detailValues[i].toString());
              }
            }
            rowIndex++;
          }

          // Blank row after details
          rowIndex++;
        } else {
          // No details, just main row
          for (var i = 0; i < values.length; i++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: rowIndex,
            ));
            if (values[i] is num) {
              cell.value = DoubleCellValue(values[i].toDouble());
            } else {
              cell.value = TextCellValue(values[i].toString());
            }
          }
          rowIndex++;
        }
      }

      // Column widths
      final columnWidths = [15, 12, 25, 15, 20, 12];
      for (var i = 0; i < columnWidths.length; i++) {
        sheet.setColumnWidth(i, columnWidths[i].toDouble());
      }

      // Save file
      String filePath;
      if (kIsWeb) {
        // Handle web platform
        final fileName = 'Data_Pembelian_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        filePath = fileName;
      } else {
        final now = DateTime.now();
        final fileName = 'Data_Pembelian_${now.day}-${now.month}-${now.year}.xlsx';
        final directory = await _getExportDirectory();
        filePath = '$directory${Platform.pathSeparator}$fileName';
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File berhasil disimpan di: $filePath'),
            action: Platform.isWindows ? SnackBarAction(
              label: 'Buka Folder',
              onPressed: () async {
                await Process.run('explorer.exe', ['/select,', filePath]);
              },
            ) : null,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _setLoading('pembelian', false);
    }
  }

  Future<void> _exportBarang() async {
    _setLoading('barang', true);

    try {
      // Create a new Excel workbook
      final excel = Excel.createExcel();
      final sheet = excel['Barang'];

      // Add headers
      final headers = [
        'Kode Barang',
        'Nama Barang',
        'Satuan (Pcs)',
        'Satuan (Dus)',
        'Isi per Dus',
        'Harga (Pcs)',
        'Harga (Dus)',
        'Stok',
        'HPP',
        'HPP (Dus)'
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
      }

      // Get data barang from Firestore
      final querySnapshot = await _firestore.collection('barang').orderBy('kode_barang').get();
      var rowIndex = 1; // Start after header
      for (var doc in querySnapshot.docs) {
        final barang = Barang.fromMap(doc.data());
        final values = [
          barang.kodeBarang,
          barang.namaBarang,
          barang.satuanPcs,
          barang.satuanDus,
          barang.isiDus,
          barang.hargaPcs,
          barang.hargaDus,
          barang.jumlah,
          barang.hpp,
          barang.hppDus
        ];

        // Add data
        for (var i = 0; i < values.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
          if (values[i] is String) {
            cell.value = TextCellValue(values[i] as String);
          } else if (values[i] is int) {
            cell.value = IntCellValue(values[i] as int);
          } else if (values[i] is double) {
            cell.value = DoubleCellValue(values[i] as double);
          } else {
            cell.value = TextCellValue(values[i].toString());
          }
        }
        rowIndex++;
      }

      // Set column widths
      final columnWidths = [15, 30, 12, 12, 12, 15, 15, 12, 15, 15]; // Custom widths per column
      for (var i = 0; i < columnWidths.length; i++) {
        sheet.setColumnWidth(i, columnWidths[i].toDouble());
      }

      // Save file
      String filePath;
      if (kIsWeb) {
        // Handle web platform
        final fileName = 'Data_Barang_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        filePath = fileName;
      } else {
        final now = DateTime.now();
        final fileName = 'Data_Barang_${now.day}-${now.month}-${now.year}.xlsx';
        final directory = await _getExportDirectory();
        filePath = '$directory${Platform.pathSeparator}$fileName';
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        if (!mounted) return;

        if (Platform.isWindows) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File berhasil disimpan di: $filePath'),
              action: SnackBarAction(
                label: 'Buka Folder',
                onPressed: () async {
                  await Process.run('explorer.exe', ['/select', filePath]);
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File berhasil disimpan di: $filePath'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _setLoading('barang', false);
    }
  }

  Widget _buildExportCard({
    required String title,
    required String description,
    required VoidCallback onExport,
    required String type,
  }) {
    final bool isLoading = _isLoading && _currentExport == type;

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
              onPressed: _isLoading ? null : onExport,
              icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.file_download),
              label: Text(isLoading ? 'Mengexport...' : 'Export $title'),
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
        title: const Text('Export Data'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildExportCard(
              title: 'Data Penjualan',
              description: 'Export data penjualan beserta detailnya ke file Excel (.xlsx)',
              onExport: _exportPenjualan,
              type: 'penjualan',
            ),

            _buildExportCard(
              title: 'Data Pembelian',
              description: 'Export data pembelian beserta detailnya ke file Excel (.xlsx)',
              onExport: _exportPembelian,
              type: 'pembelian',
            ),

            _buildExportCard(
              title: 'Data Barang',
              description: 'Export data barang ke file Excel (.xlsx)',
              onExport: _exportBarang,
              type: 'barang',
            ),
          ],
        ),
      ),
    );
  }
}
