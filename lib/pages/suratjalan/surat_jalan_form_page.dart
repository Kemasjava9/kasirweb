import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/surat_jalan_models.dart';
import '../../utils/code_generator.dart';

class SuratJalanFormPage extends StatefulWidget {
  final SuratJalan? suratJalan;

  const SuratJalanFormPage({super.key, this.suratJalan});

  @override
  State<SuratJalanFormPage> createState() => _SuratJalanFormPageState();
}

class _SuratJalanFormPageState extends State<SuratJalanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late TextEditingController _noSuratJalanController;
  late TextEditingController _tanggalController;
  late TextEditingController _noPenjualanController;
  late TextEditingController _pelangganController;
  late TextEditingController _alamatController;
  late TextEditingController _keteranganController;
  
  DateTime _selectedDate = DateTime.now();
  final List<ItemSuratJalan> _items = [];
  String _selectedStatus = 'draft';
  Map<String, dynamic>? _selectedPelanggan;
  
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.suratJalan != null) {
      _loadSuratJalanData();
    }
  }

  void _initializeControllers() {
    _noSuratJalanController = TextEditingController();
    _tanggalController = TextEditingController(text: _dateFormat.format(DateTime.now()));
    _noPenjualanController = TextEditingController();
    _pelangganController = TextEditingController();
    _alamatController = TextEditingController();
    _keteranganController = TextEditingController();
  }

  void _loadSuratJalanData() {
    final sj = widget.suratJalan!;
    _noSuratJalanController.text = sj.noSuratJalan;
    _tanggalController.text = _dateFormat.format(sj.tanggal);
    _selectedDate = sj.tanggal;
    _noPenjualanController.text = sj.noPenjualan;
    _pelangganController.text = sj.namaPelanggan;
    _alamatController.text = sj.alamat;
    _keteranganController.text = sj.keterangan;
    _selectedStatus = sj.status;
    _items.addAll(sj.items);
  }

  @override
  void dispose() {
    _noSuratJalanController.dispose();
    _tanggalController.dispose();
    _noPenjualanController.dispose();
    _pelangganController.dispose();
    _alamatController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.suratJalan == null ? 'Buat Surat Jalan' : 'Edit Surat Jalan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _noSuratJalanController,
                decoration: const InputDecoration(
                  labelText: 'No Surat Jalan',
                  hintText: 'Akan dibuat otomatis jika kosong',
                ),
                enabled: widget.suratJalan == null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tanggalController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noPenjualanController,
                decoration: const InputDecoration(
                  labelText: 'No Penjualan',
                  suffixIcon: Icon(Icons.search),
                ),
                readOnly: true,
                onTap: _selectPenjualan,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pelangganController,
                decoration: const InputDecoration(
                  labelText: 'Pelanggan',
                  suffixIcon: Icon(Icons.person_search),
                ),
                readOnly: true,
                onTap: _selectPelanggan,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: 'Alamat Pengiriman'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Status: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    items: ['draft', 'terkirim', 'selesai'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value[0].toUpperCase() + value.substring(1)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedStatus = newValue!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildItemsList(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Item'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keteranganController,
                decoration: const InputDecoration(labelText: 'Keterangan'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveSuratJalan,
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItemsList() {
    return _items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(item.namaBarang),
          subtitle: Text('${item.jumlah} ${item.satuan}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeItem(index),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = _dateFormat.format(picked);
      });
    }
  }

  void _selectPenjualan() async {
    // TODO: Implement penjualan selection
    // This should show a dialog with a list of penjualan that don't have surat jalan yet
  }

  void _selectPelanggan() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PelangganSearchDialog(_firestore),
    );

    if (result != null) {
      setState(() {
        _selectedPelanggan = result;
        _pelangganController.text = result['nama_pelanggan'];
        _alamatController.text = result['alamat'] ?? '';
      });
    }
  }

  void _addItem() async {
    final result = await showDialog<ItemSuratJalan>(
      context: context,
      builder: (context) => _ItemSuratJalanDialog(_firestore),
    );

    if (result != null) {
      setState(() {
        _items.add(result);
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _saveSuratJalan() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu item')),
      );
      return;
    }

    try {
      String noSuratJalan = _noSuratJalanController.text;
      if (noSuratJalan.isEmpty) {
        noSuratJalan = await CodeGenerator.nextSequentialCode(
          _firestore,
          'surat_jalan',
          'no_surat_jalan',
          'SJ',
          5,
        );
      }

      final suratJalan = SuratJalan(
        noSuratJalan: noSuratJalan,
        tanggal: _selectedDate,
        noPenjualan: _noPenjualanController.text,
        pelangganId: _selectedPelanggan?['id'] ?? '',
        namaPelanggan: _pelangganController.text,
        alamat: _alamatController.text,
        items: _items,
        keterangan: _keteranganController.text,
        status: _selectedStatus,
      );

      await _firestore
          .collection('surat_jalan')
          .doc(noSuratJalan)
          .set(suratJalan.toMap());

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class _PelangganSearchDialog extends StatelessWidget {
  final FirebaseFirestore _firestore;
  final _searchController = TextEditingController();

  _PelangganSearchDialog(this._firestore, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Pelanggan'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari pelanggan...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('pelanggan').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pelangganList = snapshot.data!.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .where((pelanggan) {
                    final searchQuery = _searchController.text.toLowerCase();
                    return pelanggan['nama_pelanggan'].toString().toLowerCase().contains(searchQuery) ||
                           pelanggan['alamat'].toString().toLowerCase().contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: pelangganList.length,
                    itemBuilder: (context, index) {
                      final pelanggan = pelangganList[index];
                      return ListTile(
                        title: Text(pelanggan['nama_pelanggan']),
                        subtitle: Text(pelanggan['alamat'] ?? ''),
                        onTap: () => Navigator.pop(context, pelanggan),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  void setState(void Function() fn) {
    fn();
    // This is a simplified setState for the dialog
    // In a real app, you might want to use a StatefulWidget
  }
}

class _ItemSuratJalanDialog extends StatelessWidget {
  final FirebaseFirestore _firestore;
  final _searchController = TextEditingController();
  final _jumlahController = TextEditingController(text: '1');

  _ItemSuratJalanDialog(this._firestore, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Item'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari barang...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('barang').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final barangList = snapshot.data!.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .where((barang) {
                    final searchQuery = _searchController.text.toLowerCase();
                    return barang['nama_barang'].toString().toLowerCase().contains(searchQuery) ||
                           barang['kode_barang'].toString().toLowerCase().contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: barangList.length,
                    itemBuilder: (context, index) {
                      final barang = barangList[index];
                      return ListTile(
                        title: Text(barang['nama_barang']),
                        subtitle: Text('Stok: ${barang['jumlah']} ${barang['satuan_pcs']}'),
                        onTap: () => _showJumlahDialog(context, barang),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  void _showJumlahDialog(BuildContext context, Map<String, dynamic> barang) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jumlah'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Barang: ${barang['nama_barang']}'),
            const SizedBox(height: 8),
            TextField(
              controller: _jumlahController,
              decoration: InputDecoration(
                labelText: 'Jumlah',
                suffixText: barang['satuan_pcs'],
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final jumlah = int.tryParse(_jumlahController.text) ?? 0;
              if (jumlah <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jumlah harus lebih dari 0')),
                );
                return;
              }

              final item = ItemSuratJalan(
                kodeBarang: barang['kode_barang'],
                namaBarang: barang['nama_barang'],
                jumlah: jumlah,
                satuan: barang['satuan_pcs'],
              );

              Navigator.pop(context); // Close jumlah dialog
              Navigator.pop(context, item); // Close barang dialog with result
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void setState(void Function() fn) {
    fn();
    // This is a simplified setState for the dialog
    // In a real app, you might want to use a StatefulWidget
  }
}