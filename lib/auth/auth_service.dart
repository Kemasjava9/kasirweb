import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  
  // Cache untuk menyimpan data user
  Map<String, dynamic>? _userData;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Cari user berdasarkan email di Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Email tidak terdaftar',
        );
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _userData = querySnapshot.docs.first.data();
      
      // Update last login
      await _firestore.collection('users').doc(_user!.uid).update({
        'lastLogin': DateTime.now(),
      });

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat login';
      
      if (e.code == 'user-not-found') {
        errorMessage = 'Email tidak ditemukan';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Password salah';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid';
      }
      
      throw Exception(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;

      // Simpan data user ke Firestore
      await _firestore.collection('users').doc(_user!.uid).set({
        'username': username,
        'password': password, // Note: In production, consider more secure password storage
        'nama_lengkap': '', // Empty by default, can be updated later
        'level': 'user', // Default level
        'email': email,
        'createdAt': DateTime.now(),
        'lastLogin': DateTime.now(),
      });

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat registrasi';
      
      if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah digunakan';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid';
      }
      
      throw Exception(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat reset password';
      
      if (e.code == 'user-not-found') {
        errorMessage = 'Email tidak ditemukan';
      }
      
      throw Exception(errorMessage);
    }
  }
}