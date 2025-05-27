import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_field.dart';
import 'package:senemarket/presentation/widgets/form_fields/password/confirm_password_field.dart';
import 'package:senemarket/presentation/widgets/global/error_text.dart';
import 'package:senemarket/presentation/views/login/viewmodel/sign_in_viewmodel.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;

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

                // Email and password fields
                CustomTextField(
                  controller: _emailController,
                  label: 'Uniandes email',
                ),
                ConfirmPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                ),
                const SizedBox(height: 10),

                // Error texts
                ErrorText(_errorMessage),
                ErrorText(signInVM.errorMessage),
                const SizedBox(height: 10),

                // Sign-in button
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
      _errorMessage = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = ErrorMessages.allFieldsRequired);
      return;
    }

    if (!email.endsWith('@uniandes.edu.co')) {
      setState(() => _errorMessage = ErrorMessages.invalidEmailDomain);
      return;
    }

    final success = await signInVM.signIn(email, password);

    if (success) {
      //Navegamos si fue exitoso
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/verify_otp');
      }
    }
  }
}
