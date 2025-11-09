import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../pengaturan/user_form_page.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Pengaturan User',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
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
                  itemBuilder: (context, index) => _buildUserListItem(context, userList[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(BuildContext context, User user) {
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
              onPressed: () => _editUser(context, user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteUser(context, user),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editUser(BuildContext context, User user) async {
    final result = await Navigator.push<User?>(
      context,
      MaterialPageRoute(builder: (_) => UserFormPage(user: user)),
    );
    if (result != null) {
      await _saveUser(context, user, result);
    }
  }

  Future<void> _saveUser(BuildContext context, User? existingUser, User newUser) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    
    try {
      final userData = {
        'username': newUser.username,
        'password': newUser.password,
        'nama_lengkap': newUser.namaLengkap,
        'level': newUser.level,
      };

      if (existingUser == null) {
        final existingUserCheck = await _firestore
            .collection('users')
            .where('username', isEqualTo: newUser.username)
            .get();
        
        if (existingUserCheck.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username sudah digunakan')),
          );
          return;
        }

        await _firestore.collection('users').add(userData);
      } else {
        await _firestore.collection('users').doc(existingUser.id).update(userData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${existingUser == null ? 'ditambahkan' : 'diupdate'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteUser(BuildContext context, User user) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    
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

  static Future<void> handleAddUser(BuildContext context) async {
    final user = await Navigator.push<User?>(
      context, 
      MaterialPageRoute(builder: (_) => const UserFormPage())
    );
    if (user != null) {
      await UsersTab()._saveUser(context, null, user);
    }
  }
}