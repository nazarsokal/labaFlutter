import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'main_diasry_page.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  static final ButtonStyle _signInButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10), 
    ),
    elevation: 0,
  );

  static final ButtonStyle _createAccountButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    minimumSize: const Size(double.infinity, 50),
    side: const BorderSide(color: Colors.grey, width: 1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
         FirebaseAnalytics.instance.logLogin(loginMethod: 'email_password');
         
         Navigator.pushReplacement(
             context,
             MaterialPageRoute(
                 builder: (context) => const MainDiaryPage(),
             ),
         );
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Помилка входу. Перевірте свої дані.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Неправильна електронна пошта або пароль.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Виникла невідома помилка: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }
  
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 100),

            const Icon(CupertinoIcons.music_note, size: 50, color: Colors.black),
            const SizedBox(height: 8),
            const Text('Music Diary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Sign in to track your musical journey', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),

            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[

                      const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _InputField(controller: _emailController, hintText: 'Enter your email', keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 20),

                      const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _InputField(controller: _passwordController, hintText: 'Enter your password', obscureText: true),
                      const SizedBox(height: 30),

                      ElevatedButton(
                          onPressed: _isLoading ? null : _signInUser, 
                          style: _signInButtonStyle,
                          child: _isLoading 
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0),
                                )
                              : const Text('Sign In', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 40),
                      
                      const Divider(height: 1, color: Colors.grey),
                      const SizedBox(height: 30),

                      const Center(
                        child: Text("Don't have an account?", style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () { 
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RegistrationPage(),
                              ),
                          );
                        },
                        style: _createAccountButtonStyle,
                        child: const Text('Create an Account', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 40.0),
              child: Text(
                'By signing in, you agree to our Terms of Service and\nPrivacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(height: 50),
            ElevatedButton(
                onPressed: () {
                    FirebaseCrashlytics.instance.crash();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('GENERATE CRASH (TEST ONLY)', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 50),
            
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  String? _validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Це поле не може бути порожнім';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: _validator,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2), 
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        errorStyle: const TextStyle(fontSize: 10),
      ),
    );
  }
}