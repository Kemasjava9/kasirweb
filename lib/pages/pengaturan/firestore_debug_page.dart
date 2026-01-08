import 'package:flutter/material.dart';
import '../../utils/firestore_debug.dart';

class FirestoreDebugPage extends StatefulWidget {
  const FirestoreDebugPage({super.key});

  @override
  State<FirestoreDebugPage> createState() => _FirestoreDebugPageState();
}

class _FirestoreDebugPageState extends State<FirestoreDebugPage> {
  String _logOutput = '';
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logOutput += '$message\n';
    });
    print(message);
  }

  void _clearLog() {
    setState(() {
      _logOutput = '';
    });
  }

  Future<void> _checkSupplier() async {
    _clearLog();
    setState(() => _isLoading = true);
    _addLog('🔍 Mengecek data supplier...\n');

    try {
      await FirestoreDebug.checkSupplierData();
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _checkPembelian() async {
    _clearLog();
    setState(() => _isLoading = true);
    _addLog('🔍 Mengecek data pembelian & supplier...\n');

    try {
      await FirestoreDebug.checkPembelianSupplierData();
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateSupplier() async {
    _clearLog();
    setState(() => _isLoading = true);
    _addLog('🔄 Update nama supplier yang kosong...\n');

    try {
      await FirestoreDebug.updateMissingSupplierNames();
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Firestore'), elevation: 0),
      body: Column(
        children: [
          // Button Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _checkSupplier,
                  icon: const Icon(Icons.search),
                  label: const Text('Cek Data Supplier'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _checkPembelian,
                  icon: const Icon(Icons.search),
                  label: const Text('Cek Pembelian & Supplier'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateSupplier,
                  icon: const Icon(Icons.update),
                  label: const Text('Update Nama Supplier'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearLog,
                  icon: const Icon(Icons.clear),
                  label: const Text('Bersihkan Log'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
          // Log Output
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SelectableText(
                          _logOutput.isEmpty
                              ? '📋 Log akan muncul di sini...'
                              : _logOutput,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
