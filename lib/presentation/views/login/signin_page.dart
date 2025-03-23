import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/views/login/viewmodel/sign_in_viewmodel.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    final signInVM = context.watch<SignInViewModel>();
    final isLoading = signInVM.isLoading;

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
          child: SingleChildScrollView(
            child: Column(
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
                _buildTextField('Uniandes email', _emailController),
                _buildTextField('Password', _passwordController, obscureText: true),
                const SizedBox(height: 10),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: AppColors.primary30, fontSize: 14),
                  ),
                if (signInVM.errorMessage.isNotEmpty)
                  Text(
                    signInVM.errorMessage,
                    style: const TextStyle(color: AppColors.primary30, fontSize: 14),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary30,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                    'Sign in',
                    style: TextStyle(
                      fontFamily: 'Cabin',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary50,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final signInVM = context.read<SignInViewModel>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _errorMessage = '';
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'All fields must be filled out');
      return;
    }

    if (!email.endsWith('@uniandes.edu.co')) {
      setState(() => _errorMessage = 'You must use an @uniandes.edu.co email');
      return;
    }

    await signInVM.signIn(email, password);
    if (signInVM.errorMessage.isEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Widget _buildTextField(String hintText, TextEditingController controller, {bool obscureText = false}) {
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
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: AppColors.primary50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary0, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary0, width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary30, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
    );
  }
}
