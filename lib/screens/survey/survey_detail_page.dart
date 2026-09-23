import 'dart:convert';

import 'package:field_survey/screens/auth/login_page.dart';
import 'package:field_survey/screens/survey/survey_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class SurveyDetailPage extends StatefulWidget {
  final int surveyId;

  const SurveyDetailPage({super.key, required this.surveyId});

  @override
  State<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends State<SurveyDetailPage> {

  Map<String, dynamic>? survey;
  
  bool isLoading = true;

  String? errorMessage;

  Uint8List? imageBytes;
  bool isLoadingImage = false;

  static const Color primaryColor = Color.fromARGB(255, 30, 86, 49);

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async{
    setState(() {
      isLoading = true;
      errorMessage = null;
      imageBytes = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
        return;
      }

      final url = Uri.parse(
        'https://sijala.biz.id/api/v1/surveys/${widget.surveyId}',
      );
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }
      );

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == true && result['data'] != null){
          final data = Map<String, dynamic>.from(result['data']);
          setState(() {
            survey = data;
            isLoading = false;
          });

          final photoName = data['photo']?.toString();
          if (photoName != null && photoName.isNotEmpty && photoName != 'placeholder.jpg') {
            fetchImage(photoName, token);
          }
          return;
        }
      }

      throw Exception('Survey tidak ditemukan (Kode : ${response.statusCode})');
    }
    catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat detail survey. Periksa koneksi Anda.';
      });
    }
  }

  Future<void> fetchImage(String photoName, String token) async {
    setState(() {
      isLoadingImage = true;
    });

    try {
      final fileName = photoName.contains('/')
          ? photoName.split('/').last
          : photoName;
      final url = Uri.parse('https://sijala.biz.id/api/image/$fileName');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          imageBytes = response.bodyBytes;
          isLoadingImage = false;
        });
        return;
      }
    }
    catch (_) {
      if (mounted) {
        setState(() {
          isLoadingImage = false;
        });
      }
    }
  }

  Future<void> deleteSurvey() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Survey'),
          content: const Text('Apakah Anda yakin ingin menghapus survey ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? '';

        final url = Uri.parse(
          'https://sijala.biz.id/api/v1/surveys/${widget.surveyId}/delete',
        );
        final response = await http.post(
          url,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          }
        );

        if (!mounted) return;

        if (response.statusCode == 200 || response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Survey berhasil dihapus'),
              backgroundColor: Color(0xFF10B981),
            ),
          );

          Navigator.pop(context, true);
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menghapus survey (Kode: ${response.statusCode})',
              ),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
      catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat menghapus survey'),
          ),
        );
      }
    }

    Future<void> editSurvey() async {
      if (survey == null) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SurveyFormPage(survey: survey)),
      );
      if (result == true && mounted) {
        fetchDetail();
      }
    }

    Future<void> openGoogleMaps(double lat, double lng) async {
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka Google Maps'),
          ),
        );
      }
    }

    void copyCoordinates(double lat, double lng) {
        Clipboard.setData(ClipboardData(text: '$lat, $lng'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Koordinat berhasil disalin: $lat, $lng'),
          ),
        );
      }

      void showFullImageDialog(Uint8List bytes) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                InteractiveViewer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Detail Survey'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (survey != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Survey',
              onPressed: editSurvey,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Hapus Survey',
              onPressed: deleteSurvey,
            ),
          ],
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : errorMessage != null || survey == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(errorMessage ?? 'Survey tidak ditemukan'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: fetchDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isLoadingImage)
                                const SizedBox(
                                  height: 220,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                    ),
                                  ),
                                )
                              else if (imageBytes != null)
                                GestureDetector(
                                  onTap: () => showFullImageDialog(imageBytes!),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(14),
                                    ),
                                    child: Image.memory(
                                      imageBytes!,
                                      width: double.infinity,
                                      height: 220,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(14),
                                    ),
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
                                        'Tidak ada foto',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      survey!['title']?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      survey!['category']?.toString() ??
                                          survey!['category_name']?.toString() ??
                                          '-',
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deskripsi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                survey!['description']?.toString() ?? '-',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lokasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Latitude: ${survey!['latitude']?.toString() ?? '-'}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Longitude: ${survey!['longitude']?.toString() ?? '-'}',
                              ),
                              const SizedBox(height: 14),
                              if (double.tryParse(
                                        survey!['latitude']?.toString() ?? '',
                                      ) !=
                                      null &&
                                  double.tryParse(
                                        survey!['longitude']?.toString() ?? '',
                                      ) !=
                                      null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => openGoogleMaps(
                                          double.parse(
                                            survey!['latitude'].toString(),
                                          ),
                                          double.parse(
                                            survey!['longitude'].toString(),
                                          ),
                                        ),
                                        icon: const Icon(Icons.map_outlined),
                                        label: const Text('Buka Maps'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 50,
                                      height: 48,
                                      child: OutlinedButton(
                                        onPressed: () => copyCoordinates(
                                          double.parse(
                                            survey!['latitude'].toString(),
                                          ),
                                          double.parse(
                                            survey!['longitude'].toString(),
                                          ),
                                        ),
                                        child: const Icon(Icons.copy_outlined),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}