import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LaporanDb {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to safely convert values
  static dynamic _safeValue(dynamic value, {dynamic defaultValue}) {
    if (value == null) return defaultValue ?? '';
    if (value is num) return value.toDouble();
    if (value is String && value.isEmpty) return defaultValue ?? '';
    return value;
  }

  // Helper method to format currency
  static String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    try {
      final numValue = value is String ? double.tryParse(value) ?? 0 : (value as num).toDouble();
      final formatter = NumberFormat('#,##0', 'id_ID');
      return 'Rp ${formatter.format(numValue)}';
    } catch (e) {
      return 'Rp 0';
    }
  }

  // Helper method to format date
  static String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      if (date is Timestamp) {
        return DateFormat('dd/MM/yyyy').format(date.toDate());
      }
      if (date is String) {
        final parsedDate = DateTime.tryParse(date);
        if (parsedDate != null) {
          return DateFormat('dd/MM/yyyy').format(parsedDate);
        }
        return date;
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  // Get best selling products with improved error handling
  static Future<List<Map<String, dynamic>>> getBestSellingProducts({
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('detail_penjualan')
          .get();

      final Map<String, Map<String, dynamic>> productSales = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final namaBarang = data['nama_barang']?.toString().trim() ?? '';
        
        if (namaBarang.isEmpty) continue;

        final jumlah = (data['jumlah'] as num?)?.toDouble() ?? 0;
        final hargaSatuan = (data['harga_satuan'] as num?)?.toDouble() ?? 0;
        final hpp = (data['HPP'] as num?)?.toDouble() ?? 0;

        if (productSales.containsKey(namaBarang)) {
          productSales[namaBarang]!['total_terjual'] += jumlah;
          productSales[namaBarang]!['total_penjualan'] += (hargaSatuan * jumlah);
          productSales[namaBarang]!['total_hpp'] += (hpp * jumlah);
        } else {
          productSales[namaBarang] = {
            'nama_barang': namaBarang,
            'total_terjual': jumlah,
            'total_penjualan': hargaSatuan * jumlah,
            'total_hpp': hpp * jumlah,
            'laba_kotor': (hargaSatuan - hpp) * jumlah,
          };
        }
      }

      // Calculate profit and add formatted values
      final productsList = productSales.values.map((product) {
        final totalPenjualan = product['total_penjualan'] as double;
        final totalHpp = product['total_hpp'] as double;
        final labaKotor = totalPenjualan - totalHpp;
        
        return {
          ...product,
          'laba_kotor': labaKotor,
          'total_penjualan_formatted': _formatCurrency(totalPenjualan),
          'total_hpp_formatted': _formatCurrency(totalHpp),
          'laba_kotor_formatted': _formatCurrency(labaKotor),
        };
      }).toList();

      // Sort by total_terjual descending
      productsList.sort((a, b) => (b['total_terjual'] as double).compareTo(a['total_terjual'] as double));

      return productsList.take(limit).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data produk terlaris: $e');
    }
  }

  // Improved net profit calculation with better error handling
  static Future<Map<String, dynamic>> calculateNetProfit() async {
    try {
      // Get sales data
      final salesQuery = await _firestore
          .collection('detail_penjualan')
          .get();

      double totalPenjualan = 0;
      double totalLabaPenjualan = 0;

      for (var doc in salesQuery.docs) {
        final data = doc.data();
        final jumlah = (data['jumlah'] as num?)?.toDouble() ?? 0;
        final hargaSatuan = (data['harga_satuan'] as num?)?.toDouble() ?? 0;
        final namaBarang = data['nama_barang']?.toString() ?? '';
        final satuanPenjualan = data['satuan']?.toString();

        totalPenjualan += hargaSatuan * jumlah;

        // Calculate profit based on unit matching
        double profit = 0;
        String formula = '';
        if (namaBarang.isNotEmpty) {
          final barangQuery = await _firestore
              .collection('barang')
              .where('nama_barang', isEqualTo: namaBarang)
              .limit(1)
              .get();

          if (barangQuery.docs.isNotEmpty) {
            final barangData = barangQuery.docs.first.data();
            final satuanPcs = barangData['satuan_pcs']?.toString();
            final satuanDus = barangData['satuan_dus']?.toString();
            final hpp = (barangData['HPP'] as num?)?.toDouble() ?? 0;
            final hppDus = (barangData['HPP_dus'] as num?)?.toDouble();
            final isiDus = (barangData['isi_dus'] as num?)?.toDouble() ?? 1;

            if (satuanPenjualan != null && satuanPcs != null &&
                satuanPenjualan.toLowerCase() == satuanPcs.toLowerCase()) {
              // pcs unit: (harga_satuan - HPP) * jumlah
              profit = (hargaSatuan - hpp) * jumlah;
              formula = '($hargaSatuan - $hpp) * $jumlah = $profit';
            } else if (satuanPenjualan != null && satuanDus != null &&
                satuanPenjualan.toLowerCase() == satuanDus.toLowerCase() &&
                hppDus != null) {
              // dus unit: (harga_satuan - HPP_dus) * (jumlah / isi_dus)
              profit = (hargaSatuan - hppDus) * (jumlah / isiDus);
              formula = '($hargaSatuan - $hppDus) * ($jumlah / $isiDus) = $profit';
            } else {
              // fallback: (harga_satuan - HPP) * jumlah
              profit = (hargaSatuan - hpp) * jumlah;
              formula = '($hargaSatuan - $hpp) * $jumlah = $profit (fallback)';
            }
          } else {
            // Fallback if barang not found: use HPP from detail_penjualan or 0
            final hpp = (data['HPP'] as num?)?.toDouble() ?? 0;
            profit = (hargaSatuan - hpp) * jumlah;
            formula = '($hargaSatuan - $hpp) * $jumlah = $profit (fallback - barang not found)';
          }
        } else {
          // Fallback if no nama_barang: try to get HPP from barang collection using kode_barang
          final kodeBarang = data['kode_barang']?.toString();
          double hpp = 0;

          if (kodeBarang != null && kodeBarang.isNotEmpty) {
            final barangQuery = await _firestore
                .collection('barang')
                .where('kode_barang', isEqualTo: kodeBarang)
                .limit(1)
                .get();

            if (barangQuery.docs.isNotEmpty) {
              final barangData = barangQuery.docs.first.data();
              hpp = (barangData['HPP'] as num?)?.toDouble() ?? 0;
              print('DEBUG: Found HPP from barang collection: $hpp for kode_barang: $kodeBarang');
            } else {
              print('DEBUG: No barang found for kode_barang: $kodeBarang');
            }
          } else {
            print('DEBUG: No kode_barang available');
          }

          // If still no HPP, try from detail_penjualan
          if (hpp == 0) {
            final hppRaw = data['HPP'];
            if (hppRaw is num) {
              hpp = hppRaw.toDouble();
            } else if (hppRaw is String) {
              hpp = double.tryParse(hppRaw) ?? 0;
            }
            print('DEBUG: Using HPP from detail_penjualan: $hpp');
          }

          profit = (hargaSatuan - hpp) * jumlah;
          formula = '($hargaSatuan - $hpp) * $jumlah = $profit (fallback - no nama_barang)';
        }

        totalLabaPenjualan += profit;

        // Debug: Print detailed profit calculation for each item
        print('DEBUG: $namaBarang ($satuanPenjualan) - Formula: $formula');
      }

      // Debug: Print total laba penjualan
      print('DEBUG: Total Laba Penjualan = $totalLabaPenjualan');

      // Get commission data from detail_penjualan
      final commissionQuery = await _firestore
          .collection('detail_penjualan')
          .get();

      double totalKomisi = 0;
      for (var doc in commissionQuery.docs) {
        final data = doc.data();
        final jumlah = (data['jumlah'] as num?)?.toDouble() ?? 0;
        final nilaiKomisi = (data['nilai_komisi'] as num?)?.toDouble() ?? 0;
        totalKomisi += jumlah * nilaiKomisi;
      }

      // Get purchase data
      final purchaseQuery = await _firestore
          .collection('detail_pembelian')
          .get();

      double totalPembelian = 0;
      for (var doc in purchaseQuery.docs) {
        final data = doc.data();
        final jumlah = (data['jumlah'] as num?)?.toDouble() ?? 0;
        final hargaSatuan = (data['harga_satuan'] as num?)?.toDouble() ?? 0;
        totalPembelian += hargaSatuan * jumlah;
      }

      final labaBersih = totalPenjualan - totalPembelian - totalKomisi;

      return {
        'total_penjualan': totalPenjualan,
        'total_penjualan_formatted': _formatCurrency(totalPenjualan),
        'laba_penjualan': totalLabaPenjualan,
        'laba_penjualan_formatted': _formatCurrency(totalLabaPenjualan),
        'total_komisi': totalKomisi,
        'total_komisi_formatted': _formatCurrency(totalKomisi),
        'total_pembelian': totalPembelian,
        'total_pembelian_formatted': _formatCurrency(totalPembelian),
        'laba_bersih': labaBersih,
        'laba_bersih_formatted': _formatCurrency(labaBersih),
        'periode': 'Keseluruhan',
      };
    } catch (e) {
      throw Exception('Gagal menghitung laba bersih: $e');
    }
  }

  // Get cash flow report with improved data structure
  static Future<List<Map<String, dynamic>>> getLaporanKas() async {
    try {
      final querySnapshot = await _firestore
          .collection('kas')
          .orderBy('tanggal', descending: true)
          .get();

      double totalPemasukan = 0;
      double totalPengeluaran = 0;

      final List<Map<String, dynamic>> results = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final jumlah = (data['jumlah'] as num?)?.toDouble() ?? 0;
        final jenis = data['jenis']?.toString() ?? '';

        if (jenis.toLowerCase() == 'masuk') {
          totalPemasukan += jumlah;
        } else if (jenis.toLowerCase() == 'keluar') {
          totalPengeluaran += jumlah;
        }

        results.add({
          'id': doc.id,
          'tanggal': _formatDate(data['tanggal']),
          'tanggal_timestamp': data['tanggal'],
          'keterangan': _safeValue(data['keterangan'], defaultValue: '-'),
          'kategori': _safeValue(data['kategori'], defaultValue: '-'),
          'jenis': jenis,
          'jumlah': jumlah,
          'jumlah_formatted': _formatCurrency(jumlah),
        });
      }

      // Add summary as first item
      final saldo = totalPemasukan - totalPengeluaran;
      results.insert(0, {
        'is_summary': true,
        'total_pemasukan': totalPemasukan,
        'total_pemasukan_formatted': _formatCurrency(totalPemasukan),
        'total_pengeluaran': totalPengeluaran,
        'total_pengeluaran_formatted': _formatCurrency(totalPengeluaran),
        'saldo': saldo,
        'saldo_formatted': _formatCurrency(saldo),
        'periode': 'Keseluruhan',
      });

      return results;
    } catch (e) {
      throw Exception('Gagal mengambil laporan kas: $e');
    }
  }

  // Get commission report with improved formatting
  static Future<List<Map<String, dynamic>>> getCommissionReport() async {
    try {
      final querySnapshot = await _firestore
          .collection('komisi')
          .orderBy('tanggal', descending: true)
          .get();

      double totalKomisiAll = 0;
      final results = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final totalKomisi = (data['total_komisi'] as num?)?.toDouble() ?? 0;
        totalKomisiAll += totalKomisi;

        return {
          'id': doc.id,
          'tanggal': _formatDate(data['tanggal']),
          'kode_barang': _safeValue(data['kode_barang'], defaultValue: '-'),
          'nama_barang': _safeValue(data['nama_barang'], defaultValue: '-'),
          'jumlah': _safeValue(data['jumlah'], defaultValue: 0.0),
          'satuan': _safeValue(data['satuan'], defaultValue: '-'),
          'nilai_komisi': _safeValue(data['nilai_komisi'], defaultValue: 0.0),
          'nilai_komisi_formatted': _formatCurrency(data['nilai_komisi']),
          'nama_komisi': _safeValue(data['nama_komisi'], defaultValue: '-'),
          'total_komisi': totalKomisi,
          'total_komisi_formatted': _formatCurrency(totalKomisi),
        };
      }).toList();

      // Add total summary if there are results
      if (results.isNotEmpty) {
        results.insert(0, {
          'is_total': true,
          'total_komisi_all': totalKomisiAll,
          'total_komisi_all_formatted': _formatCurrency(totalKomisiAll),
          'jumlah_transaksi': results.length,
          'periode': 'Keseluruhan',
        });
      }

      return results;
    } catch (e) {
      throw Exception('Gagal mengambil laporan komisi: $e');
    }
  }

  // Get sales by invoice number with improved performance
  static Future<List<Map<String, dynamic>>> getSalesByInvoice() async {
    try {
      final querySnapshot = await _firestore
          .collection('detail_penjualan')
          .orderBy('tanggal_jual', descending: true)
          .get();

      // Group by invoice number
      final Map<String, Map<String, dynamic>> invoiceMap = {};
      double totalPenjualan = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final noFaktur = data['nofaktur_jual']?.toString() ?? '';

        if (noFaktur.isEmpty) continue;

        final jumlah = (data['jumlah'] as num?)?.toDouble() ?? 0;
        final hargaSatuan = (data['harga_satuan'] as num?)?.toDouble() ?? 0;
        final subtotal = hargaSatuan * jumlah;

        if (!invoiceMap.containsKey(noFaktur)) {
          invoiceMap[noFaktur] = {
            'No Faktur': noFaktur,
            'Tanggal Jual': _formatDate(data['tanggal_jual']),
            'Nama Pelanggan': _safeValue(data['nama_pelanggan'], defaultValue: '-'),
            'Nama Sales': _safeValue(data['nama_sales'], defaultValue: '-'),
            'Status': _safeValue(data['status'], defaultValue: '-'),
            'Cara Bayar': _safeValue(data['cara_bayar'], defaultValue: '-'),
            'items': <Map<String, dynamic>>[],
            'total_invoice': 0.0,
          };
        }

        final item = {
          'Nama Barang': _safeValue(data['nama_barang'], defaultValue: '-'),
          'Harga Satuan': hargaSatuan,
          'Harga Satuan_formatted': _formatCurrency(hargaSatuan),
          'Jumlah': jumlah,
          'Subtotal': subtotal,
          'Subtotal_formatted': _formatCurrency(subtotal),
          'Laba': _safeValue(data['laba'], defaultValue: 0.0),
          'Laba_formatted': _formatCurrency(data['laba']),
          'Diskon': _safeValue(data['diskon'], defaultValue: 0.0),
          'Diskon_formatted': _formatCurrency(data['diskon']),
          'Ongkos Kirim': _safeValue(data['ongkos_kirim'], defaultValue: 0.0),
          'Ongkos Kirim_formatted': _formatCurrency(data['ongkos_kirim']),
          'Satuan': _safeValue(data['satuan'], defaultValue: '-'),
        };

        invoiceMap[noFaktur]!['items'].add(item);
        invoiceMap[noFaktur]!['total_invoice'] += subtotal;
        totalPenjualan += subtotal;
      }

      // Convert to list and add formatted values
      final results = invoiceMap.values.map((invoice) {
        final total = invoice['total_invoice'] as double;
        return {
          ...invoice,
          'total_invoice_formatted': _formatCurrency(total),
        };
      }).toList();

      // Add summary
      if (results.isNotEmpty) {
        results.insert(0, {
          'is_summary': true,
          'total_penjualan': totalPenjualan,
          'total_penjualan_formatted': _formatCurrency(totalPenjualan),
          'jumlah_invoice': results.length,
          'periode': 'Keseluruhan',
        });
      }

      return results;
    } catch (e) {
      throw Exception('Gagal mengambil data penjualan: $e');
    }
  }

  // Get purchases by supplier with improved grouping
  static Future<List<Map<String, dynamic>>> getPurchasesBySupplier() async {
    try {
      final querySnapshot = await _firestore
          .collection('detail_pembelian')
          .orderBy('tanggal_beli', descending: true)
          .get();

      // Group by supplier
      final Map<String, Map<String, dynamic>> supplierMap = {};
      double totalPembelian = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final namaSupplier = data['nama_supplier']?.toString().trim() ?? '';

        if (namaSupplier.isEmpty) continue;

        final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0;

        if (!supplierMap.containsKey(namaSupplier)) {
          supplierMap[namaSupplier] = {
            'nama_supplier': namaSupplier,
            'items': <Map<String, dynamic>>[],
            'total_pembelian': 0.0,
          };
        }

        final item = {
          'nama_barang': _safeValue(data['nama_barang'], defaultValue: '-'),
          'harga_satuan': _safeValue(data['harga_satuan'], defaultValue: 0.0),
          'harga_satuan_formatted': _formatCurrency(data['harga_satuan']),
          'jumlah': _safeValue(data['jumlah'], defaultValue: 0.0),
          'subtotal': subtotal,
          'subtotal_formatted': _formatCurrency(subtotal),
          'status': _safeValue(data['status'], defaultValue: '-'),
          'tanggal_beli': _formatDate(data['tanggal_beli']),
          'jatuh_tempo': _formatDate(data['jatuh_tempo']),
        };

        supplierMap[namaSupplier]!['items'].add(item);
        supplierMap[namaSupplier]!['total_pembelian'] += subtotal;
        totalPembelian += subtotal;
      }

      // Convert to list and add formatted values
      final results = supplierMap.values.map((supplier) {
        final total = supplier['total_pembelian'] as double;
        return {
          ...supplier,
          'total_pembelian_formatted': _formatCurrency(total),
        };
      }).toList();

      // Sort by total pembelian descending
      results.sort((a, b) => (b['total_pembelian'] as double).compareTo(a['total_pembelian'] as double));

      // Add summary
      if (results.isNotEmpty) {
        results.insert(0, {
          'is_summary': true,
          'total_pembelian_all': totalPembelian,
          'total_pembelian_all_formatted': _formatCurrency(totalPembelian),
          'jumlah_supplier': results.length,
          'periode': 'Keseluruhan',
        });
      }

      return results;
    } catch (e) {
      throw Exception('Gagal mengambil data pembelian: $e');
    }
  }

  // Improved product summary with better error handling
  static Future<Map<String, dynamic>> getProductSummary() async {
    try {
      final querySnapshot = await _firestore.collection('barang').get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'product_count': 0,
          'jumlahstoktotal': 0,
          'hpp_value': 0.0,
          'selling_value': 0.0,
          'total_debt': 0.0,
          'total_receivable': 0.0,
          'product_count_formatted': '0',
          'jumlahstoktotal_formatted': '0',
          'hpp_value_formatted': _formatCurrency(0),
          'selling_value_formatted': _formatCurrency(0),
          'total_debt_formatted': _formatCurrency(0),
          'total_receivable_formatted': _formatCurrency(0),
        };
      }

      int productCount = querySnapshot.docs.length;
      int jumlahStokTotal = 0;
      double hppValue = 0;
      double sellingValue = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final jumlah = (data['jumlah'] as num?)?.toInt() ?? 0;
        final hpp = (data['HPP'] as num?)?.toDouble() ?? 0;
        final hargaJual = (data['harga_pcs'] as num?)?.toDouble() ?? 0;

        jumlahStokTotal += jumlah;
        hppValue += hpp * jumlah;
        sellingValue += hargaJual * jumlah;
      }

      // Get total debt from pembelian
      double totalDebt = 0;
      try {
        final debtQuery = await _firestore
            .collection('pembelian')
            .where('status', isNotEqualTo: 'lunas')
            .get();
        
        for (var doc in debtQuery.docs) {
          final data = doc.data();
          totalDebt += (data['sisa_bayar'] as num?)?.toDouble() ?? 0;
        }
      } catch (e) {
        print('Error fetching debt data: $e');
      }

      // Get total receivable from penjualan
      double totalReceivable = 0;
      try {
        final receivableQuery = await _firestore
            .collection('penjualan')
            .where('status', isNotEqualTo: 'lunas')
            .get();
        
        for (var doc in receivableQuery.docs) {
          final data = doc.data();
          totalReceivable += (data['sisa_bayar'] as num?)?.toDouble() ?? 0;
        }
      } catch (e) {
        print('Error fetching receivable data: $e');
      }

      final potentialProfit = sellingValue - hppValue;

      return {
        'product_count': productCount,
        'jumlahstoktotal': jumlahStokTotal,
        'hpp_value': hppValue,
        'selling_value': sellingValue,
        'total_debt': totalDebt,
        'total_receivable': totalReceivable,
        'potential_profit': potentialProfit,
        // Formatted values
        'product_count_formatted': NumberFormat('#,##0').format(productCount),
        'jumlahstoktotal_formatted': NumberFormat('#,##0').format(jumlahStokTotal),
        'hpp_value_formatted': _formatCurrency(hppValue),
        'selling_value_formatted': _formatCurrency(sellingValue),
        'total_debt_formatted': _formatCurrency(totalDebt),
        'total_receivable_formatted': _formatCurrency(totalReceivable),
        'potential_profit_formatted': _formatCurrency(potentialProfit),
        'last_updated': _formatDate(Timestamp.now()),
      };
    } catch (e) {
      throw Exception('Gagal mengambil ringkasan produk: $e');
    }
  }
}
