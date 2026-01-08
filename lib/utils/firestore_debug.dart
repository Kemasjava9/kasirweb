import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility untuk debug dan verifikasi data di Firestore
class FirestoreDebug {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cek data supplier di database
  static Future<void> checkSupplierData() async {
    try {
      print('=== CEK DATA SUPPLIER ===');
      final supplierSnapshot = await _firestore.collection('supplier').get();

      if (supplierSnapshot.docs.isEmpty) {
        print('❌ Tidak ada supplier di database');
        return;
      }

      print('✅ Total supplier: ${supplierSnapshot.docs.length}');
      print('');

      for (var doc in supplierSnapshot.docs) {
        final data = doc.data();
        print('📋 Supplier:');
        print('   ID Doc: ${doc.id}');
        print('   Kode: ${data['kode_supplier']}');
        print('   Nama: ${data['nama_supplier']}');
        print('   Alamat: ${data['alamat_supplier']}');
        print('   Telp: ${data['telp_supplier']}');
        print('---');
      }
    } catch (e) {
      print('❌ Error saat cek supplier: $e');
    }
  }

  /// Cek data pembelian dan verifikasi nama supplier
  static Future<void> checkPembelianSupplierData() async {
    try {
      print('\n=== CEK DATA PEMBELIAN & SUPPLIER ===');
      final pembelianSnapshot = await _firestore.collection('pembelian').get();

      if (pembelianSnapshot.docs.isEmpty) {
        print('❌ Tidak ada pembelian di database');
        return;
      }

      print('✅ Total pembelian: ${pembelianSnapshot.docs.length}');
      print('');

      // Load supplier untuk referensi
      final supplierSnapshot = await _firestore.collection('supplier').get();
      final supplierMap = {
        for (var doc in supplierSnapshot.docs)
          doc.data()['kode_supplier']: doc.data()['nama_supplier'],
      };

      for (var doc in pembelianSnapshot.docs) {
        final data = doc.data();
        final idBeli = data['id_beli'] ?? 'N/A';
        final kodeSupplier = data['kode_supplier'] ?? 'N/A';
        final namaSupplierDi = data['nama_supplier'] ?? 'KOSONG';
        final namaSupplierSeharusnya =
            supplierMap[kodeSupplier] ?? 'TIDAK DITEMUKAN';

        final isCorrect = namaSupplierDi == namaSupplierSeharusnya;
        final icon = isCorrect ? '✅' : '⚠️';

        print('$icon Pembelian #$idBeli');
        print('   Kode Supplier: $kodeSupplier');
        print('   Nama di DB: $namaSupplierDi');
        print('   Seharusnya: $namaSupplierSeharusnya');
        print('   Status: ${isCorrect ? "BENAR" : "SALAH"}');
        print('   Tanggal: ${data['tanggal_beli']}');
        print('---');
      }
    } catch (e) {
      print('❌ Error saat cek pembelian: $e');
    }
  }

  /// Update nama supplier di pembelian yang belum ter-update
  static Future<void> updateMissingSupplierNames() async {
    try {
      print('\n=== UPDATE NAMA SUPPLIER DI PEMBELIAN ===');

      final pembelianSnapshot = await _firestore.collection('pembelian').get();
      final supplierSnapshot = await _firestore.collection('supplier').get();

      // Buat map supplier
      final supplierMap = {
        for (var doc in supplierSnapshot.docs)
          doc.data()['kode_supplier']: doc.data()['nama_supplier'],
      };

      int updated = 0;
      final batch = _firestore.batch();

      for (var doc in pembelianSnapshot.docs) {
        final data = doc.data();
        final kodeSupplier = data['kode_supplier'];
        final namaSupplierDi = data['nama_supplier'];
        final namaSupplierSeharusnya = supplierMap[kodeSupplier];

        // Jika nama kosong atau berbeda, update
        if (namaSupplierSeharusnya != null &&
            namaSupplierDi != namaSupplierSeharusnya) {
          print('📝 Update: $kodeSupplier -> $namaSupplierSeharusnya');
          batch.update(doc.reference, {
            'nama_supplier': namaSupplierSeharusnya,
          });
          updated++;
        }
      }

      if (updated > 0) {
        await batch.commit();
        print('✅ Berhasil update $updated pembelian');
      } else {
        print('✅ Semua pembelian sudah benar');
      }
    } catch (e) {
      print('❌ Error saat update: $e');
    }
  }
}
