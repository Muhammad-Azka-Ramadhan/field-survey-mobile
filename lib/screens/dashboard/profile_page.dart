import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color.fromARGB(255, 30, 86, 49),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color.fromARGB(255, 30, 86, 49),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Field Surveyor',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Nama Lengkap'),
                      subtitle: Text('Muhammad Azka Ramadhan'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.alternate_email),
                      title: Text('Username'),
                      subtitle: Text('azka123'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.email_outlined, color: Color.fromARGB(255, 30, 86, 49)),
                      title: Text('Email'),
                      subtitle: Text('azka111@gmail.com'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.phone_outlined, color: Color.fromARGB(255, 30, 86, 49)),
                      title: Text('No. Telepon'),
                      subtitle: Text('081234567890'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.wc_outlined, color: Color.fromARGB(255, 30, 86, 49)),
                      title: Text('Jenis Kelamin'),
                      subtitle: Text('Laki-laki'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}