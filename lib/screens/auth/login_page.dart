  import 'package:flutter/material.dart';

  class LoginPage extends StatefulWidget {
    const LoginPage({super.key});

    @override
    State<LoginPage> createState() => _LoginPagesState();
  }

  class _LoginPagesState extends State<LoginPage> {
    final _formkey = GlobalKey<FormState>();

    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    bool obscurePassword = true;

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 360, maxHeight: 500),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 90,
                            color: Colors.blue,
                          ),

                          SizedBox(height: 20),

                          Text('Login ke akun Anda'),

                          SizedBox(height: 45),

                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if(value == null || value.isEmpty){
                                return "Email Wajib diisi";
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 12),

                          TextFormField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.password),
                              suffixIcon: IconButton(
                                onPressed: (){
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  obscurePassword
                                  ?Icons.visibility
                                  :Icons.visibility_off
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          SizedBox(height: 20),

                          
                        ],
                      ),
                    ],
                  )
                )
              ),
            ),
          )
        ),
      );
    }
  }