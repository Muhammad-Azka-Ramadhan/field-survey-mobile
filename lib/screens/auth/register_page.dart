import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {

  final _formkey = GlobalKey();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  String? selectedGender;

  void dispose(){
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
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
                        TextFormField(
                          controller: nameController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: "Nama Lengkap",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField(
                          value: selectedGender,
                          decoration: InputDecoration(
                            labelText: "Jenis Kelamin",
                            prefixIcon: Icon(Icons.wc),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: "Laki-laki",
                              child: Text("Laki-laki"),
                            ),
                            DropdownMenuItem(
                              value: "Perempuan",
                              child: Text("Perempuan"),
                            ),
                          ],
                          onChanged: (value){
                            setState(() {
                              selectedGender = value;
                            });
                          },
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "Silahkan pilih jenis kelamin";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "No Telepon",
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (){
                              context.go('/login');
                            },
                            child: Text('Register', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 30, 86, 49)),
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