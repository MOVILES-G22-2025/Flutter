import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart';
import 'viewmodel/sign_up_viewmodel.dart';

/// Page to create a new user account.
/// Uses SignUpViewModel to handle registration logic.
class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers for text inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _careerController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Local error message for invalid form state
  String _localErrorMessage = '';

  // Track empty fields to show red borders if needed
  final Map<String, bool> _emptyFields = {
    'name': false,
    'email': false,
    'career': false,
    'semester': false,
    'password': false,
    'confirmPassword': false,
  };

  @override
  Widget build(BuildContext context) {
    final signUpViewModel = context.watch<SignUpViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary0),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontFamily: 'Cabin',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary0,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input fields
                  _buildTextField('Full name', _nameController, 'name'),
                  _buildTextField('Uniandes email', _emailController, 'email'),
                  _buildTextField('Career', _careerController, 'career'),
                  _buildTextField('Semester', _semesterController, 'semester', isNumeric: true),
                  _buildTextField('Password', _passwordController, 'password', obscureText: true),
                  _buildTextField('Confirm password', _confirmPasswordController, 'confirmPassword', obscureText: true),
                  const SizedBox(height: 10),

                  // Error messages
                  if (_localErrorMessage.isNotEmpty)
                    Text(
                      _localErrorMessage,
                      style: const TextStyle(color: AppColors.primary30, fontSize: 14),
                    ),
                  if (signUpViewModel.errorMessage.isNotEmpty)
                    Text(
                      signUpViewModel.errorMessage,
                      style: const TextStyle(color: AppColors.primary30, fontSize: 14),
                    ),
                  const SizedBox(height: 20),

                  // Register button
                  ElevatedButton(
                    onPressed: signUpViewModel.isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary30,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                    ),
                    child: signUpViewModel.isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                      'Register',
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Link to Sign In
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(fontFamily: 'Cabin', fontSize: 14, color: AppColors.primary0),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/signIn'),
                        child: const Text(
                          'Sign In',
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
        ),
      ),
    );
  }

  /// Handles form validation and calls the ViewModel to register the user.
  Future<void> _signUp() async {
    final signUpViewModel = context.read<SignUpViewModel>();

    setState(() {
      _localErrorMessage = '';
      signUpViewModel.errorMessage = '';
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final career = _careerController.text.trim();
    final semester = _semesterController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Mark empty fields to show red borders
    setState(() {
      _emptyFields['name'] = name.isEmpty;
      _emptyFields['email'] = email.isEmpty;
      _emptyFields['career'] = career.isEmpty;
      _emptyFields['semester'] = semester.isEmpty;
      _emptyFields['password'] = password.isEmpty;
      _emptyFields['confirmPassword'] = confirmPassword.isEmpty;
    });

    if (_emptyFields.containsValue(true)) {
      setState(() {
        _localErrorMessage = 'All fields must be filled out';
      });
      return;
    }

    if (!email.endsWith('@uniandes.edu.co')) {
      setState(() {
        _localErrorMessage = 'You must use an @uniandes.edu.co email';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _localErrorMessage = 'Passwords do not match';
      });
      return;
    }

    await signUpViewModel.signUp(
      email: email,
      password: password,
      name: name,
      career: career,
      semester: semester,
    );

    if (signUpViewModel.errorMessage.isEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  /// Builds a styled TextField with optional validation.
  Widget _buildTextField(
      String hintText,
      TextEditingController controller,
      String fieldKey, {
        bool obscureText = false,
        bool isNumeric = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
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
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
    );
  }
}
