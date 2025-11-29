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

  // Helper method to format date
  static String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      if (date is Timestamp) {
        return DateFormat('dd/MM/yyyy').format(date.toDate());
      }
      if (date is String) {
        // Try to parse various date formats
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

  // Get best selling products
  static Future<List<Map<String, dynamic>>> getBestSellingProducts({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('detail_penjualan')
          .where('tanggal_jual', isGreaterThanOrEqualTo: startDate)
          .where('tanggal_jual', isLessThanOrEqualTo: endDate)
          .get();

      Map<String, Map<String, dynamic>> productSales = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final namaBarang = data['nama_barang'] ?? '';
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
          };
        }
      }

      // Sort by total_terjual descending and take top 10
      final sortedProducts = productSales.values.toList()
        ..sort((a, b) => (b['total_terjual'] as double).compareTo(a['total_terjual'] as double));

      return sortedProducts.take(10).toList();
    } catch (e) {
      throw Exception('Failed to get best selling products: $e');
    }
  }

  // Calculate net profit
  static Future<Map<String, dynamic>> calculateNetProfit({
    required String startDate,
    required String endDate,
  }) async {
    try {
      // Get sales data
      final salesQuery = await _firestore
          .collection('detail_penjualan')
          .where('tanggal_jual', isGreaterThanOrEqualTo: startDate)
          .where('tanggal_jual', isLessThanOrEqualTo: endDate)
          .get();

      double totalPenjualan = 0;
      double labaPenjualan = 0;

      for (var doc in salesQuery.docs) {
        final data = doc.data();
        final jumlah = (data['jumlah'] as num?)?.toDouble() ?? 0;
        final hargaSatuan = (data['harga_satuan'] as num?)?.toDouble() ?? 0;
        final hpp = (data['HPP'] as num?)?.toDouble() ?? 0;

        totalPenjualan += hargaSatuan * jumlah;
        labaPenjualan += (hargaSatuan - hpp) * jumlah;
      }

      // Get commission data
      final commissionQuery = await _firestore
          .collection('komisi')
          .where('tanggal', isGreaterThanOrEqualTo: startDate)
          .where('tanggal', isLessThanOrEqualTo: endDate)
          .get();

      double totalKomisi = 0;
      for (var doc in commissionQuery.docs) {
        totalKomisi += (doc.data()['total_komisi'] as num?)?.toDouble() ?? 0;
      }

      // Get purchase data
      final purchaseQuery = await _firestore
          .collection('detail_pembelian')
          .where('tanggal_beli', isGreaterThanOrEqualTo: startDate)
          .where('tanggal_beli', isLessThanOrEqualTo: endDate)
          .get();

      double totalPembelian = 0;
      for (var doc in purchaseQuery.docs) {
        final data = doc.data();
        final jumlah = (data['jumlah'] as num?)?.toDouble() ?? 0;
        final hargaSatuan = (data['harga_satuan'] as num?)?.toDouble() ?? 0;
        totalPembelian += hargaSatuan * jumlah;
      }

      final labaBersih = labaPenjualan + totalKomisi - totalPembelian;

      return {
        'total_penjualan': totalPenjualan,
        'laba_penjualan': labaPenjualan,
        'total_komisi': totalKomisi,
        'total_pembelian': totalPembelian,
        'laba_bersih': labaBersih,
      };
    } catch (e) {
      throw Exception('Failed to calculate net profit: $e');
    }
  }

  // Get cash flow report
  static Future<List<Map<String, dynamic>>> getLaporanKas({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('kas')
          .where('tanggal', isGreaterThanOrEqualTo: startDate)
          .where('tanggal', isLessThanOrEqualTo: endDate)
          .orderBy('tanggal', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'tanggal': _formatDate(data['tanggal']),
          'keterangan': _safeValue(data['keterangan'], defaultValue: '-'),
          'kategori': _safeValue(data['kategori'], defaultValue: '-'),
          'jenis': _safeValue(data['jenis'], defaultValue: '-'), // 'masuk' or 'keluar'
          'jumlah': _safeValue(data['jumlah'], defaultValue: 0.0),
          'jumlah_formatted': _formatCurrency(data['jumlah']),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get cash flow report: $e');
    }
  }

  // Get commission report
  static Future<List<Map<String, dynamic>>> getCommissionReport({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('komisi')
          .where('tanggal', isGreaterThanOrEqualTo: startDate)
          .where('tanggal', isLessThanOrEqualTo: endDate)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'kode_barang': _safeValue(data['kode_barang'], defaultValue: '-'),
          'nama_barang': _safeValue(data['nama_barang'], defaultValue: '-'),
          'jumlah': _safeValue(data['jumlah'], defaultValue: 0.0),
          'satuan': _safeValue(data['satuan'], defaultValue: '-'),
          'nilai_komisi': _safeValue(data['nilai_komisi'], defaultValue: 0.0),
          'nilai_komisi_formatted': _formatCurrency(data['nilai_komisi']),
          'nama_komisi': _safeValue(data['nama_komisi'], defaultValue: '-'),
          'total_komisi': _safeValue(data['total_komisi'], defaultValue: 0.0),
          'total_komisi_formatted': _formatCurrency(data['total_komisi']),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get commission report: $e');
    }
  }

  // Get sales by invoice number
  static Future<List<Map<String, dynamic>>> getsalesbynofaktur({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('detail_penjualan')
          .where('tanggal_jual', isGreaterThanOrEqualTo: startDate)
          .where('tanggal_jual', isLessThanOrEqualTo: endDate)
          .orderBy('tanggal_jual', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'No Faktur': _safeValue(data['nofaktur_jual'], defaultValue: '-'),
          'Tanggal Jual': _formatDate(data['tanggal_jual']),
          'Nama Pelanggan': _safeValue(data['nama_pelanggan'], defaultValue: '-'),
          'Nama Sales': _safeValue(data['nama_sales'], defaultValue: '-'),
          'Nama Barang': _safeValue(data['nama_barang'], defaultValue: '-'),
          'Harga Satuan': _safeValue(data['harga_satuan'], defaultValue: 0.0),
          'Harga Satuan_formatted': _formatCurrency(data['harga_satuan']),
          'Jumlah_Converted': _safeValue(data['jumlah'], defaultValue: 0.0),
          'Laba': _safeValue(data['laba'], defaultValue: 0.0),
          'Laba_formatted': _formatCurrency(data['laba']),
          'Status': _safeValue(data['status'], defaultValue: '-'),
          'Cara Bayar': _safeValue(data['cara_bayar'], defaultValue: '-'),
          'Diskon': _safeValue(data['diskon'], defaultValue: 0.0),
          'Diskon_formatted': _formatCurrency(data['diskon']),
          'Ongkos Kirim': _safeValue(data['ongkos_kirim'], defaultValue: 0.0),
          'Ongkos Kirim_formatted': _formatCurrency(data['ongkos_kirim']),
          'Satuan': _safeValue(data['satuan'], defaultValue: '-'),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get sales by invoice: $e');
    }
  }

  // Get purchases by supplier
  static Future<List<Map<String, dynamic>>> getPurchasesBySupplier({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('detail_pembelian')
          .where('tanggal_beli', isGreaterThanOrEqualTo: startDate)
          .where('tanggal_beli', isLessThanOrEqualTo: endDate)
          .orderBy('tanggal_beli', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'nama_supplier': _safeValue(data['nama_supplier'], defaultValue: '-'),
          'nama_barang': _safeValue(data['nama_barang'], defaultValue: '-'),
          'harga_satuan': _safeValue(data['harga_satuan'], defaultValue: 0.0),
          'harga_satuan_formatted': _formatCurrency(data['harga_satuan']),
          'jumlah': _safeValue(data['jumlah'], defaultValue: 0.0),
          'subtotal': _safeValue(data['subtotal'], defaultValue: 0.0),
          'subtotal_formatted': _formatCurrency(data['subtotal']),
          'status': _safeValue(data['status'], defaultValue: '-'),
          'tanggal_beli': _formatDate(data['tanggal_beli']),
          'jatuh_tempo': _formatDate(data['jatuh_tempo']),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get purchases by supplier: $e');
    }
  }

  // Get product summary
  static Future<Map<String, dynamic>> getProductSummary() async {
    try {
      final querySnapshot = await _firestore.collection('barang').get();

      int productCount = querySnapshot.docs.length;
      int jumlahStokTotal = 0;
      double hppValue = 0;
      double sellingValue = 0;
      double totalDebt = 0;
      double totalReceivable = 0;

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
      final debtQuery = await _firestore.collection('pembelian').get();
      for (var doc in debtQuery.docs) {
        final data = doc.data();
        if (data['status'] != 'lunas') {
          totalDebt += (data['sisa_bayar'] as num?)?.toDouble() ?? 0;
        }
      }

      // Get total receivable from penjualan
      final receivableQuery = await _firestore.collection('penjualan').get();
      for (var doc in receivableQuery.docs) {
        final data = doc.data();
        if (data['status'] != 'lunas') {
          totalReceivable += (data['sisa_bayar'] as num?)?.toDouble() ?? 0;
        }
      }

      return {
        'product_count': productCount,
        'jumlahstoktotal': jumlahStokTotal,
        'hpp_value': hppValue,
        'selling_value': sellingValue,
        'total_debt': totalDebt,
        'total_receivable': totalReceivable,
      };
    } catch (e) {
      throw Exception('Failed to get product summary: $e');
    }
  }
}
