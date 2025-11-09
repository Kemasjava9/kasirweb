import 'package:flutter/material.dart';
import '../../models/models.dart';

class UserFormPage extends StatefulWidget {
  final User? user;

  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController namaLengkapController;
  String selectedLevel = 'user';

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.user?.username ?? '');
    passwordController = TextEditingController(text: widget.user?.password ?? '');
    namaLengkapController = TextEditingController(text: widget.user?.namaLengkap ?? '');
    selectedLevel = widget.user?.level ?? 'user';
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    namaLengkapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user == null ? 'Tambah User' : 'Edit User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: namaLengkapController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                decoration: const InputDecoration(labelText: 'Level'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                ],
                onChanged: (value) {
                  if (value != null) selectedLevel = value;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Batal')),
                  ElevatedButton(
                    onPressed: () {
                      final u = User(
                        id: widget.user?.id ?? '',
                        username: usernameController.text,
                        password: passwordController.text,
                        namaLengkap: namaLengkapController.text,
                        level: selectedLevel,
                      );
                      Navigator.of(context).pop(u);
                    },
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
}
