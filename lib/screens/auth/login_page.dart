import 'package:field_survey/screens/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _formkey = GlobalKey();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePass = true;

  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: Text('Login'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
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
                            Icons.lock,
                            size: 90,
                            color: Color.fromARGB(255, 30, 86, 49),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'SELAMAT DATANG KEMBALI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Masuk ke Akun Anda',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 40),
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
                            controller: passwordController,
                            obscureText: obscurePass,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.password),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscurePass = !obscurePass;
                                  });
                                },
                                icon: Icon(
                                  obscurePass
                                  ? Icons.visibility_off
                                  :Icons.visibility
                                ),
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 30),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                context.pushReplacement('/dashboard');
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 30, 86, 49)),
                              child: Text('Login', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Belum punya akun?'),
                              SizedBox(width: 2),
                              GestureDetector(
                                onTap: () {
                                  context.go('/register');
                                },
                                child: Text(
                                  'Daftar',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 30, 86, 49),
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          ),
        )
      ),
    );
  }
}