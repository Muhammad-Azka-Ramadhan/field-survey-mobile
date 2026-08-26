import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_survey/screens/auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<ProfilePage> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingPhoto = false;
  String? errorMessage;

  final Color primaryColor = const Color.fromARGB(255, 30, 86, 49);

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Menerjemahkan value gender dari API ke label, toleran terhadap variasi
  // format (huruf besar/kecil, spasi, atau sudah berupa teks penuh).
  String _genderLabel(dynamic rawGender) {
    if (rawGender == null) return '-';
    final value = rawGender.toString().trim().toUpperCase();
    if (value.isEmpty) return '-';
    if (value == 'L' || value == 'LAKI-LAKI' || value == 'LAKI LAKI' || value == 'MALE') {
      return 'Laki-laki';
    }
    if (value == 'P' || value == 'PEREMPUAN' || value == 'FEMALE') {
      return 'Perempuan';
    }
    return '-';
  }

  // ================== GET PROFILE ==================
  Future<void> getProfile() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Token login tidak ditemukan.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        // Cek di console: apakah field 'gender' benar-benar ada dan bagaimana formatnya
        debugPrint('GET /profile response: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        dynamic result = data['data'];

        // API bisa mengembalikan objek langsung atau array berisi 1 objek
        if (result is List) {
          result = result.isNotEmpty ? result[0] : null;
        }

        setState(() {
          profile = result != null ? Map<String, dynamic>.from(result) : null;
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = data['message'] ?? 'Gagal mengambil data profil.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan koneksi.';
      });
    }
  }

  // ================== PILIH & UPLOAD FOTO PROFIL ==================
  Future<void> pickAndUploadPhoto() async {
    // Pilih sumber gambar
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: primaryColor),
                title: const Text('Ambil Foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: primaryColor),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    await uploadPhoto(File(pickedFile.path));
  }

  Future<void> uploadPhoto(File imageFile) async {
    try {
      setState(() => isUploadingPhoto = true);

      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token login tidak ditemukan.');
      }

      // Sesuaikan endpoint ini dengan endpoint upload foto profil di API kamu
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://sijala.biz.id/api/v1/profile/photo'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && (data['status'] ?? true) == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui.')),
        );

        await getProfile();
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal mengunggah foto profil.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah foto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isUploadingPhoto = false);
      }
    }
  }

  // ================== EDIT PROFILE DIALOG ==================
  Future<void> showEditProfile() async {
    final nameController = TextEditingController(text: profile?['name']?.toString() ?? '');
    final usernameController = TextEditingController(text: profile?['username']?.toString() ?? '');
    final emailController = TextEditingController(text: profile?['email']?.toString() ?? '');
    final phoneController = TextEditingController(text: profile?['phone']?.toString() ?? '');
    String gender = _genderLabel(profile?['gender']) == 'Perempuan' ? 'P' : 'L';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.edit_outlined, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Edit Profil',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          hintText: 'Nama Lengkap',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Username', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.alternate_email),
                          hintText: 'Username',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          hintText: 'Email',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('No. Telepon', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_outlined),
                          hintText: 'No. Telepon',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Jenis Kelamin', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: gender,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.wc_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                          DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                        ],
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() => gender = value);
                                }
                              },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Batal', style: TextStyle(color: Colors.black87)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      // Validasi ringan sebelum submit
                                      if (nameController.text.trim().isEmpty ||
                                          usernameController.text.trim().isEmpty ||
                                          emailController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Nama, username, dan email wajib diisi.'),
                                          ),
                                        );
                                        return;
                                      }
                                      updateProfile(
                                        name: nameController.text.trim(),
                                        username: usernameController.text.trim(),
                                        email: emailController.text.trim(),
                                        phone: phoneController.text.trim(),
                                        gender: gender,
                                        dialogContext: dialogContext,
                                        setDialogState: setDialogState,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                minimumSize: const Size.fromHeight(48),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  // ================== UPDATE PROFILE (PUT) ==================
  Future<void> updateProfile({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String gender,
    required BuildContext dialogContext,
    required StateSetter setDialogState,
  }) async {
    try {
      setDialogState(() => isSaving = true);

      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token login tidak ditemukan.');
      }

      // Body disesuaikan dengan struktur field API: id, name, username, email, phone, gender
      final response = await http.put(
        Uri.parse('https://sijala.biz.id/api/v1/profile'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (profile?['id'] != null) 'id': profile!['id'],
          'name': name,
          'username': username,
          'email': email,
          'phone': phone,
          'gender': gender,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;

        Navigator.pop(dialogContext);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui.')),
        );

        setState(() => isLoading = true);
        await getProfile();
      } else {
        setDialogState(() => isSaving = false);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal memperbarui profil.')),
        );
      }
    } catch (e) {
      setDialogState(() => isSaving = false);

      if (!mounted) return;

      final isFetchError = e.toString().contains('Failed to fetch') ||
          e.toString().contains('ClientException');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFetchError
                ? 'Tidak bisa terhubung ke server. Jika ini dijalankan di web, kemungkinan server belum mengizinkan CORS untuk request PUT.'
                : 'Gagal memperbarui profil: $e',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ================== LOGOUT ==================
  Future<void> logout() async {
    // Konfirmasi sebelum logout
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await getToken();

      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse('https://sijala.biz.id/api/v1/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 8));
      }
    } catch (e) {
      // Tetap lanjut logout secara lokal walaupun request ke server gagal/timeout
      if (kDebugMode) {
        debugPrint('Logout request gagal (diabaikan, tetap lanjut logout lokal): $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (!mounted) return;

    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Navigator.pushReplacement gagal: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil logout, tapi gagal pindah halaman: $e')),
      );
    }
  }

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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              errorMessage = null;
                            });
                            getProfile();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: getProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: primaryColor,
                                    backgroundImage: (profile?['photo'] != null && (profile!['photo'] as String).isNotEmpty)
                                        ? NetworkImage(profile!['photo'])
                                        : null,
                                    child: (profile?['photo'] == null || (profile!['photo'] as String).isEmpty)
                                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                                        : null,
                                  ),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: primaryColor,
                                      child: isUploadingPhoto
                                          ? const Padding(
                                              padding: EdgeInsets.all(3),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                              onPressed: pickAndUploadPhoto,
                                              tooltip: 'Ganti Foto Profil',
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                profile?['name']?.toString() ?? '-',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile?['username']?.toString() ?? '-',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.person_outline),
                                  title: const Text('Nama Lengkap'),
                                  subtitle: Text(profile?['name']?.toString() ?? '-'),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.alternate_email),
                                  title: const Text('Username'),
                                  subtitle: Text(profile?['username']?.toString() ?? '-'),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: Icon(Icons.email_outlined, color: primaryColor),
                                  title: const Text('Email'),
                                  subtitle: Text(profile?['email']?.toString() ?? '-'),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: Icon(Icons.phone_outlined, color: primaryColor),
                                  title: const Text('No. Telepon'),
                                  subtitle: Text(profile?['phone']?.toString() ?? '-'),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: Icon(Icons.wc_outlined, color: primaryColor),
                                  title: const Text('Jenis Kelamin'),
                                  subtitle: Text(_genderLabel(profile?['gender'])),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tombol Edit Profil
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: showEditProfile,
                            icon: const Icon(Icons.edit_outlined, color: Colors.white),
                            label: const Text(
                              'Edit Profil',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tombol Logout
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: logout,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              'Keluar dari Akun',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
