import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart' hide DetailPenjualan;
import '../../models/penjualan_models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/dialog_helper.dart';
import 'widgets/penjualan_widgets.dart';

class PenjualanProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  bool _isLoading = false;
  List<Barang> _barangList = [];
  List<Pelanggan> _pelangganList = [];
  List<String> _salesList = [];
  List<String> _komisiList = [];
  String? _selectedPelanggan;
  String? _selectedSales;
  String? _selectedKomisi;
  String? _selectedMetodePembayaran;
  String? _selectedStatusPembayaran;
  final List<DetailPenjualan> _cartItems = [];
  double _totalBelanja = 0;

  PenjualanProvider({FirestoreService? firestoreService}) 
    : _firestoreService = firestoreService ?? FirestoreService();

  // Getters
  bool get isLoading => _isLoading;
  List<Barang> get barangList => _barangList;
  List<Pelanggan> get pelangganList => _pelangganList;
  List<String> get salesList => _salesList;
  List<String> get komisiList => _komisiList;
  String? get selectedPelanggan => _selectedPelanggan;
  String? get selectedSales => _selectedSales;
  String? get selectedKomisi => _selectedKomisi;
  String? get selectedMetodePembayaran => _selectedMetodePembayaran;
  String? get selectedStatusPembayaran => _selectedStatusPembayaran;
  List<DetailPenjualan> get cartItems => _cartItems;
  double get totalBelanja => _totalBelanja;

  // Setters
  set selectedPelanggan(String? value) {
    _selectedPelanggan = value;
    notifyListeners();
  }

  set selectedSales(String? value) {
    _selectedSales = value;
    notifyListeners();
  }

  set selectedKomisi(String? value) {
    _selectedKomisi = value;
    notifyListeners();
  }

  set selectedMetodePembayaran(String? value) {
    _selectedMetodePembayaran = value;
    notifyListeners();
  }

  set selectedStatusPembayaran(String? value) {
    _selectedStatusPembayaran = value;
    notifyListeners();
  }

  void addToCart(Barang barang, String satuan, int jumlah, double hargaSatuan, double nilaiKomisi) {
    _cartItems.add(DetailPenjualan(
      idDetailJual: DateTime.now().millisecondsSinceEpoch.toString(),
      nofakturJual: '',
      kodeBarang: barang.kodeBarang,
      jumlah: jumlah,
      hargaSatuan: hargaSatuan,
      subtotal: jumlah * hargaSatuan,
      satuan: satuan,
      nilaiKomisi: nilaiKomisi,
      namaKomisi: _selectedKomisi ?? '',
    ));
    _updateTotalBelanja();
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item.idDetailJual == id);
    _updateTotalBelanja();
    notifyListeners();
  }

  void _updateTotalBelanja() {
    _totalBelanja = _cartItems.fold(0, (sum, item) => sum + item.subtotal);
    notifyListeners();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load barang
      _barangList = await _firestoreService.getCollection(
        path: 'barang',
        fromMap: (data) => Barang.fromMap(data),
      );

      // Load pelanggan
      _pelangganList = await _firestoreService.getCollection(
        path: 'pelanggan',
        fromMap: (data) => Pelanggan.fromMap(data),
      );

      // Load sales
      final salesSnapshot = await FirebaseFirestore.instance.collection('sales').get();
      _salesList = salesSnapshot.docs
          .map((doc) => doc['nama_sales'] as String)
          .toList();

      // Load komisi
      final komisiSnapshot = await FirebaseFirestore.instance.collection('komisi').get();
      _komisiList = komisiSnapshot.docs
          .map((doc) => doc['nama_komisi'] as String)
          .toList();

      // Set default values
      if (_salesList.isNotEmpty && _selectedSales == null) {
        _selectedSales = _salesList[0];
      }
      if (_komisiList.isNotEmpty && _selectedKomisi == null) {
        _selectedKomisi = _komisiList[0];
      }
    } catch (e) {
      // Handle error appropriately
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> savePenjualan(BuildContext context) async {
    if (_selectedPelanggan == null) {
      DialogHelper.showSnackBar(
        context,
        message: 'Pilih pelanggan terlebih dahulu',
        isError: true,
      );
      return null;
    }

    if (_cartItems.isEmpty) {
      DialogHelper.showSnackBar(
        context,
        message: 'Keranjang masih kosong',
        isError: true,
      );
      return null;
    }

    if (_selectedMetodePembayaran == null) {
      DialogHelper.showSnackBar(
        context,
        message: 'Pilih metode pembayaran',
        isError: true,
      );
      return null;
    }

    final now = DateTime.now();
    return {
      'pelanggan': _selectedPelanggan,
      'tanggal': now,
      'cara_bayar': _selectedMetodePembayaran,
      'status_pembayaran': _selectedStatusPembayaran,
      'items': _cartItems.map((e) => e.toMap()).toList(),
      'sales': _selectedSales,
      'komisi': _selectedKomisi,
      'total_bayar': _totalBelanja,
    };
  }

  void clearCart() {
    _cartItems.clear();
    _updateTotalBelanja();
    notifyListeners();
  }

  void calculateTotal({
    required double diskon,
    required double ongkosKirim,
    required double biayaLain,
  }) {
    _totalBelanja = _cartItems.fold<double>(0, (sum, item) => sum + item.subtotal) - diskon + ongkosKirim + biayaLain;
    notifyListeners();
  }
}