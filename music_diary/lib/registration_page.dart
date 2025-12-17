import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_diasry_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Ключ для доступу до стану форми та її валідації
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  static final ButtonStyle _createAccountButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    elevation: 0,
  );

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    // 1. ПЕРЕВІРКА ВАЛІДАЦІЇ ФОРМИ
    if (!_formKey.currentState!.validate()) {
      return; // Зупиняємо, якщо є помилки валідації
    }

    // 2. Додаткова перевірка паролів
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Паролі не співпадають.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await credential.user?.updateDisplayName(_fullNameController.text.trim());

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Реєстрація успішна!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainDiaryPage())); 
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Помилка реєстрації. Спробуйте ще раз.';
      if (e.code == 'weak-password') {
        errorMessage = 'Пароль занадто слабкий.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Обліковий запис з такою поштою вже існує.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Некоректна адреса електронної пошти.';
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
            // ... (Інші заголовки та текст)

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
                // Обгортаємо форму віджетом Form з ключем
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Поле Full Name
                      const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // Використовуємо _CustomTextFormField
                      _CustomTextFormField(controller: _fullNameController, hintText: 'Enter your full name'),
                      const SizedBox(height: 20),

                      // Поле Email
                      const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _CustomTextFormField(controller: _emailController, hintText: 'Enter your email', keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 20),

                      // Поле Password
                      const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _CustomTextFormField(
                        controller: _passwordController, 
                        hintText: 'Create a password', 
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),

                      // Поле Confirm Password
                      const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _CustomTextFormField(
                        controller: _confirmPasswordController, 
                        hintText: 'Confirm your password', 
                        obscureText: true,
                        // Можна додати додаткову валідацію тут, але це робиться в _registerUser для відображення SnackBar
                      ),
                      const SizedBox(height: 30),

                      // Кнопка Create Account
                      _CreateAccountButton(
                        style: _createAccountButtonStyle,
                        isLoading: _isLoading,
                        onPressed: _registerUser,
                      ),
                      const SizedBox(height: 30),
                      
                      const Divider(height: 1, color: Colors.grey),
                      const SizedBox(height: 30),

                      const _BackToSignInButton(),
                    ],
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(top: 10.0, bottom: 40.0),
              child: Text(
                'By creating an account, you agree to our Terms of Service\nand Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Оновлений віджет поля вводу, тепер це TextFormField для валідації
class _CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;

  const _CustomTextFormField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  // Функція валідації: повертає повідомлення про помилку, якщо поле порожнє
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
      validator: _validator, // Призначаємо функцію валідації
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        // Стиль для обводки при фокусі
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black, width: 2), // Чорна обводка при фокусі
        ),
        // Стиль для обводки при помилці (буде червоною за замовчуванням при валідації)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2), // Червона обводка при помилці
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        
        border: OutlineInputBorder( // Базова обводка
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        errorStyle: const TextStyle(fontSize: 10), // Зменшуємо розмір тексту помилки
      ),
    );
  }
}

// ... (Віджети _CreateAccountButton та _BackToSignInButton залишаються без змін)
class _CreateAccountButton extends StatelessWidget {
  final ButtonStyle style;
  final bool isLoading;
  final VoidCallback onPressed;

  const _CreateAccountButton({
    required this.style,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed, 
      style: style,
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3.0,
              ),
            )
          : const Text('Create Account', style: TextStyle(fontSize: 16)),
    );
  }
}

class _BackToSignInButton extends StatelessWidget {
  const _BackToSignInButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
        label: const Text(
          'Back to Sign In',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }
}