import 'dart:convert';

import 'package:field_survey/screens/auth/login_page.dart';
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {

  final _formkey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  String? selectedGender;

  bool isLoading = false;

  @override
  void dispose(){
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  Future<void> register() async{
    if(!_formkey.currentState!.validate()){
      return;
    }

    if(selectedGender == null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silahkan pilih jenis kelamin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      isLoading = true;
    });

    try{
      final response = await http.post(
        Uri.parse('https://sijala.biz.id/api/v1/register'),
        
        headers: {
          'Accept' : 'application/json',
          'Content-Type' : 'application/json'
        },
        body: jsonEncode({
          'name' : nameController.text.trim(),
          'gender' : selectedGender,
          'email' : emailController.text.trim(),
          'phone' : phoneController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);

      if(response.statusCode == 200 || response.statusCode == 201){
        if(data['status'] == true){
          if(!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Registrasi berhasil.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
        }
        else {
          throw Exception(
            data['message'] ?? 'Registrasi gagal'
          );
        }
      }
      else {
        final message = 
          data['message'] ?? 'Registrasi gagal';
          throw Exception(message);
      }
    }
    catch (e) {
      if(!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('exception', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
    finally {
      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: Text('Register'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              Card(
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formkey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 40),
                        Icon(
                          Icons.person_add,
                          size: 90,
                          color: Color.fromARGB(255, 30, 86, 49),
                        ),
                        SizedBox(height: 25),
                        Text(
                          'SELAMAT DATANG',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Buat Akun Baru',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40),
                        
                        buildTextField(
                          controller: nameController, 
                          label: 'Nama Lengkap', 
                          icon: Icons.person,
                          validator: (value){
                            if(value == null || value.trim().isEmpty){
                              return 'Nama wajin diisi';
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: DropdownButtonFormField(
                            initialValue: selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Jenis Kelamin',
                              prefixIcon: Icon(Icons.wc),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'L',
                                child: Text('Laki-laki'),
                              ),
                              DropdownMenuItem(
                                value: 'P',
                                child: Text('Perempuan'),
                              )
                            ], 
                            onChanged: (value){
                              setState(() {
                                selectedGender = value;
                              });
                            },
                            validator: (value) {
                              if(value == null){
                                return 'Jenis kelamin wajib dipilih';
                              }
                              return null;
                            },
                          ),
                        ),
                        buildTextField(
                          controller: emailController, 
                          label: 'Email', 
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value){
                            if(value == null || value.trim().isEmpty){
                              return 'Email wajib diisi';
                            }

                            if(!value.contains('@')){
                              return 'Format email tidak valid';
                            }
                            return null;
                          }
                        ),
                        buildTextField(
                          controller: phoneController, 
                          label: 'Nomor WhatsApp', 
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value){
                            if(value == null || value.trim().isEmpty){
                              return 'Nomor WhatsApp wajib diisi';
                            }
                            return null;
                          }
                        ),
                        SizedBox(height: 14),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : register,
                            child: isLoading
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                'Daftar Sekarang',
                                style: TextStyle(fontSize: 16),
                              ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 30, 86, 49),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        )
      ),
    );
  }
}