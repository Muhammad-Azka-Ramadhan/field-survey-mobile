import 'dart:convert';

import 'package:field_survey/screens/auth/login_page.dart';
import 'package:field_survey/screens/survey/survey_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
          'https://sijala.biz.id/api/v1/surveys/${widget.surveyId}',
        );
        final response = await http.delete(
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
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka Google Maps'),
          ),
        );
      }

      void copyCoordinates(double lat, double lng) {
        Clipboard.setData(ClipboardData(text: '$lat, $lng'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Koordinat berhasil disalin: $lat, $lng'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}