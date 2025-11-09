import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/models.dart';
import '../../../models/penjualan_models.dart';

class CartItemWidget extends StatelessWidget {
  final DetailPenjualan item;
  final String barangName;
  final NumberFormat currencyFormat;
  final Function(int) onDelete;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.barangName,
    required this.currencyFormat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(barangName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.jumlah} ${item.satuan} @ ${currencyFormat.format(item.hargaSatuan)}',
            ),
            Text(
              'Komisi: ${currencyFormat.format(item.nilaiKomisi)} / unit',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormat.format(item.subtotal),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => onDelete(int.parse(item.idDetailJual)),
            ),
          ],
        ),
      ),
    );
  }
}

class PenjualanItemList extends StatelessWidget {
  final List<DetailPenjualan> items;
  final List<Barang> barangList;
  final NumberFormat currencyFormat;
  final Function(int) onDeleteItem;

  const PenjualanItemList({
    super.key,
    required this.items,
    required this.barangList,
    required this.currencyFormat,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
            Text('Keranjang Anda kosong. Tambahkan produk!'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final barang = barangList.firstWhere(
          (b) => b.kodeBarang == item.kodeBarang,
          orElse: () => Barang(
            kodeBarang: item.kodeBarang,
            namaBarang: 'Unknown',
            satuanPcs: 'pcs',
            satuanDus: 'dus',
            isiDus: 1,
            hargaPcs: 0,
            hargaDus: 0,
            jumlah: 0,
            hpp: 0,
            hppDus: 0,
          ),
        );

        return CartItemWidget(
          item: item,
          barangName: barang.namaBarang,
          currencyFormat: currencyFormat,
          onDelete: onDeleteItem,
        );
      },
    );
  }
}

class PaymentSummaryWidget extends StatelessWidget {
  final double totalBelanja;
  final NumberFormat currencyFormat;
  final VoidCallback onPaymentTap;
  final bool isValid;
  final VoidCallback onFinishTap;

  const PaymentSummaryWidget({
    super.key,
    required this.totalBelanja,
    required this.currencyFormat,
    required this.onPaymentTap,
    required this.isValid,
    required this.onFinishTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Pembayaran'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: onPaymentTap,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Selesaikan Penjualan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: isValid ? onFinishTap : null,
            ),
          ),
        ],
      ),
    );
  }
}