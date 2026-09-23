import 'dart:convert';
import 'dart:typed_data';

import 'package:field_survey/screens/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/foundation.dart';

class SurveyFormPage extends StatefulWidget {
  final Map<String, dynamic>? survey;
  const SurveyFormPage({super.key, this.survey});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {

  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  
  int? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  Uint8List? ExistingImageBytes;

  bool isSubmitting = false;

  bool get isEdit => widget.survey != null;

  static const Color primaryColor = Color.fromARGB(255, 30, 86, 49);

  // String get photo => null;

  @override
  void initState(){
    super.initState();

    if(isEdit) {
      final s = widget.survey!;
      titleController.text = s['title']?.toString() ?? '';
      descriptionController.text = s['description']?.toString() == '-'
          ? ''
          : s['description']?.toString() ?? '';
      latitudeController.text = s['latitude']?.toString() ?? '';
      longitudeController.text = s['longitude']?.toString() ?? '';
      selectedCategoryId = int.tryParse(s['category_id']?.toString() ?? '');

      final photoName = s['photo']?.toString();
      if(photoName != null && photoName.isNotEmpty && photoName != 'placeholder.jpg'){
        fetchExistingImage(photoName);
      }
    }

    fetchCategories();
  }

  @override
  void dispose(){
    titleController.dispose();
    descriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async{
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/categories'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List){
          final List rawList = decoded['data'];
          if(!mounted) return;
          setState(() {
            categories = rawList
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            isLoadingCategories = false;
          });
          return;
        }
      }
    }
    catch (_) {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> fetchExistingImage(String photoName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final fileName = photoName.contains('/') ? photoName.split('/').last : photoName;
      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/image/$fileName'),
        headers: {
          'Accept' : 'application/json',
          'Authorization': 'Bearer $token'
        }
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          ExistingImageBytes = response.bodyBytes;
        });
      }
    }
    catch (_) {}
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final PickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (PickedFile != null) {
        final bytes = await PickedFile.readAsBytes();
        if(!mounted) return;
        setState(() {
          selectedImage = PickedFile;
          selectedImageBytes = bytes;
        });
      }
    }
    catch (e) {
      showErrorSnackBar('Gagal memilih foto.');
    }
  }

  void removeSelectedImage() {
    setState(() {
      selectedImage = null;
      selectedImageBytes = null;
      ExistingImageBytes = null;
    });
  }

  void showImageSourceDialog() {
    showModalBottomSheet(
      context: context, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: primaryColor),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const  Icon(Icons.camera_alt, color: primaryColor),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveSurvey() async {
    if (!formKey.currentState!.validate()) {
      showErrorSnackBar('Lengkapi data yang wajib diisi');
      return;
    }

    if (selectedCategoryId == null || selectedCategoryId == 0) {
      showErrorSnackBar('Kategori survey wajib dipilih');
      return;
    }
    setState(() {
      isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      final uri = Uri.parse('https://sijala.biz.id/api/v1/surveys/save');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['title'] = titleController.text.trim();
      request.fields['category_id'] = selectedCategoryId.toString();
      request.fields['description'] = descriptionController.text.toString();

      if (latitudeController.text.trim().isNotEmpty) {
        request.fields['latitude'] = latitudeController.text.trim();
      }

      if (longitudeController.text.trim().isNotEmpty) {
        request.fields['longitude'] = longitudeController.text.trim();
      }

      if (isEdit) {
        request.fields['id'] = widget.survey!['id'].toString();
        request.fields['_method'] = 'PUT';
      }

      if (selectedImage != null && selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedImageBytes!,
            filename: selectedImage!.name,
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Survey berhasil diperbarui'
                  : 'Survey berhasil disimpan'
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      if (response.statusCode == 422) {
        print('STATUS: ${response.statusCode}');
        print('RESPONSE: ${response.body}');

        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'Data yang dikirim tidak valid.';
        throw Exception(message);
      }
      throw Exception('Gagal menyimpan (Kode: ${response.statusCode})');
    }
    catch (e) {
      if (!mounted) return;
      showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
    finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }




  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade100,
    appBar: AppBar(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        isEdit ? 'Edit Survey' : 'Tambah Survey',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    body: SafeArea(
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Judul Survey',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Masukkan judul survey',
                  prefixIcon: const Icon(Icons.title_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul survey wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              isLoadingCategories
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Memuat kategori...'),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      decoration: InputDecoration(
                        hintText: 'Pilih kategori',
                        prefixIcon: const Icon(Icons.category_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: categories.map((category) {
                        final id = int.tryParse(
                          category['id']?.toString() ?? '',
                        );

                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(
                            category['name']?.toString() ??
                                category['nama']?.toString() ??
                                '-',
                          ),
                        );
                      }).toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                selectedCategoryId = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Kategori wajib dipilih';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 18),
              const Text(
                'Deskripsi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Masukkan deskripsi survey',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 75),
                    child: Icon(Icons.description_outlined),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Lokasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Latitude',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Longitude',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Foto Survey',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (selectedImageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          selectedImageBytes!,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (ExistingImageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          ExistingImageBytes!,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 55,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Belum ada foto',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSubmitting
                                ? null
                                : showImageSourceDialog,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: Text(
                              selectedImage != null
                                  ? 'Ganti Foto'
                                  : 'Pilih Foto',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: const BorderSide(
                                color: primaryColor,
                              ),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        if (selectedImage != null ||
                            ExistingImageBytes != null) ...[
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 50,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : removeSelectedImage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                  color: Colors.red,
                                ),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Icon(Icons.delete_outline),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : saveSurvey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: Colors.grey.shade400,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEdit
                                  ? Icons.save_outlined
                                  : Icons.add_circle_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEdit
                                  ? 'Simpan Perubahan'
                                  : 'Simpan Survey',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}
}