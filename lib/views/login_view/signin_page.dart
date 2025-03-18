import 'package:flutter/material.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/services/auth_service.dart';
import 'signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String _errorMessage = '';

  //Track which fields are empty
  final Map<String, bool> _emptyFields = {
    'email': false,
    'password': false,
  };

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    //Check for empty fields and update the status
    setState(() {
      _emptyFields['email'] = email.isEmpty;
      _emptyFields['password'] = password.isEmpty;
    });

    if (_emptyFields.containsValue(true)) {
      setState(() {
        _errorMessage = 'All fields must be filled out';
      });
      return;
    }
    String? error =
        await _authService.signInWithEmailAndPassword(email, password);

    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary0),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontFamily: 'Cabin',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary0,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('Uniandes email', _emailController, 'email'),
              _buildTextField('Password', _passwordController, 'password',
                  obscureText: true),
              const SizedBox(height: 10),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style:
                      const TextStyle(color: AppColors.primary30, fontSize: 14),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontFamily: 'Cabin',
                      fontSize: 14,
                      color: AppColors.primary30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary30,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                ),
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    fontFamily: 'Cabin',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary50,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New to SeneMarket? ',
                    style: TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 14,
                        color: AppColors.primary0),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                      );
                    },
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary30,
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
  }

  Widget _buildTextField(
      String hintText, TextEditingController controller, String fieldKey,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontFamily: 'Cabin',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.primary0,
        ),
        onChanged: (value) {
          setState(() {
            _emptyFields[fieldKey] = value.isEmpty;
          });
        },
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: AppColors.primary50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _emptyFields[fieldKey]! ? Colors.red : AppColors.primary0,
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _emptyFields[fieldKey]! ? Colors.red : AppColors.primary0,
              width: 2.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _emptyFields[fieldKey]! ? Colors.red : AppColors.primary30,
              width: 2.0,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
    );
  }
}
