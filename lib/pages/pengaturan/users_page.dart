import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import 'user_form_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleAddUser() async {
    final user = await Navigator.push<User?>(
      context,
      MaterialPageRoute(builder: (_) => const UserFormPage())
    );
    if (user != null) {
      await _saveUser(null, user.username, user.password, user.namaLengkap, user.level);
    }
  }

  Future<void> _saveUser(
    User? user,
    String username,
    String password,
    String namaLengkap,
    String level,
  ) async {
    if (username.isEmpty || password.isEmpty || namaLengkap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    try {
      final userData = {
        'username': username,
        'password': password, // In production, you should hash the password
        'nama_lengkap': namaLengkap,
        'level': level,
      };

      if (user == null) {
        // Check if username already exists
        final existingUser = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .get();

        if (existingUser.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username sudah digunakan')),
          );
          return;
        }

        await _firestore.collection('users').add(userData);
      } else {
        await _firestore.collection('users').doc(user.id).update(userData);
      }

      // Do not pop the settings page here. Just show feedback.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${user == null ? 'ditambahkan' : 'diupdate'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text('Yakin ingin menghapus ${user.namaLengkap}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('users').doc(user.id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildUserListItem(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.blue),
        title: Text(user.namaLengkap),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${user.username}'),
            Text('Level: ${user.level}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () async {
                final result = await Navigator.push<User?>(
                  context,
                  MaterialPageRoute(builder: (_) => UserFormPage(user: user)),
                );
                if (result != null) {
                  _saveUser(user, result.username, result.password, result.namaLengkap, result.level);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteUser(user),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan User'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddUser,
        child: const Icon(Icons.add),
        tooltip: 'Tambah User',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var userList = snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return User.fromMap(data);
            }).toList();
            return ListView.builder(
              itemCount: userList.length,
              itemBuilder: (context, index) => _buildUserListItem(userList[index]),
            );
          },
        ),
      ),
    );
  }
}
