import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _hasConnection = true;

  @override
  void initState() {
    super.initState();
    // Do a quick connection check on startup
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      // Try a very small read from Firestore to detect connectivity
      await _firestore.collection('users').limit(1).get().timeout(const Duration(seconds: 5));
      setState(() {
        _hasConnection = true;
      });
    } catch (e) {
      setState(() {
        _hasConnection = false;
      });
      // Optionally log the error for debugging
      debugPrint('Connection check failed: $e');
    }
  }

  Future<void> _login() async {
    if (!_hasConnection) {
      _showErrorDialog('Koneksi putus. Periksa koneksi internet Anda dan coba lagi.');
      return;
    }

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Username dan password harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Cari user berdasarkan username di Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: _usernameController.text.trim())
          .where('password', isEqualTo: _passwordController.text.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        // Add document ID to the userData
        userData['id_user'] = querySnapshot.docs.first.id;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(userData: userData),
          ),
        );
      } else {
        _showErrorDialog('Username atau password salah');
      }
    } catch (e) {
      // Detect network-related exceptions and show a specific dialog
      if (e is SocketException || e is TimeoutException) {
        await _showConnectionLostDialog();
        return;
      }

      if (e is FirebaseException) {
        final code = e.code.toString().toLowerCase();
        final message = (e.message ?? '').toString().toLowerCase();
        if (code.contains('unavailable') || message.contains('network') || message.contains('failed to connect')) {
          await _showConnectionLostDialog();
          return;
        }
      }

      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showConnectionLostDialog() async {
    if (!mounted) return;
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Koneksi terputus'),
        content: const Text('Koneksi internet terputus saat proses login. Periksa koneksi Anda dan coba lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );

    if (retry == true) {
      // Re-run connection check and if OK, try login again
      await _checkConnection();
      if (_hasConnection) {
        // Slight delay to allow UI to update
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          _login();
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadApp() async {
    const url = 'output/app-realese.apk';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorDialog('Tidak dapat membuka URL download.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              const Column(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 80,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'APLIKASI PENJUALAN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Silahkan Login',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              _hasConnection
                  ? const SizedBox(height: 40)
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off, color: Colors.red),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Koneksi putus — periksa internet atau server. Tekan Refresh untuk coba lagi.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: _checkConnection,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ),
                    ),

              // Login Form
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                child: Column(
                  children: [
                    // Username Field
                    TextField(
                      controller: _usernameController,
                      enabled: _hasConnection,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      enabled: _hasConnection,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_hasConnection) ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : (!_hasConnection
                                ? const Text(
                                    'TIDAK TERHUBUNG',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                      ),
                    ),
                    if (!_hasConnection)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Periksa Internet anda.',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              ),

              const SizedBox(height: 20),

              // Footer
              const Text(
                '© 2025 Aplikasi Penjualan',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _downloadApp,
        tooltip: 'Download App',
        child: const Icon(Icons.download),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}