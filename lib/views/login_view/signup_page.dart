import 'package:flutter/material.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/services/auth_service.dart';
import 'package:senemarket/views/login_view/signin_page.dart';
import 'package:flutter/services.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _careerController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  String _errorMessage = '';

  //Track which fields are empty
  final Map<String, bool> _emptyFields = {
    'name': false,
    'email': false,
    'career': false,
    'semester': false,
    'password': false,
    'confirmPassword': false,
  };

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final career = _careerController.text.trim();
    final semester = _semesterController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    //Check for empty fields and update the status
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
        _errorMessage = 'All fields must be filled out';
      });
      return;
    }

    //Check for uniandes email domain
    if (!email.endsWith('@uniandes.edu.co')) {
      setState(() {
        _errorMessage = 'You must use an @uniandes.edu.co email';
      });
      return;
    }

    //Check if passwords match
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    //Try to register the user
    String? error = await _authService.signUpWithEmailAndPassword(
        email, password, name, career, semester);

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
                  _buildTextField('Full name', _nameController, 'name'),
                  _buildTextField('Uniandes email', _emailController, 'email'),
                  _buildTextField('Career', _careerController, 'career'),
                  _buildTextField('Semester', _semesterController, 'semester',
                      isNumeric: true),
                  _buildTextField('Password', _passwordController, 'password',
                      obscureText: true),
                  _buildTextField('Confirm password',
                      _confirmPasswordController, 'confirmPassword',
                      obscureText: true),
                  const SizedBox(height: 10),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                          color: AppColors.primary30, fontSize: 14),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary30,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 24.0),
                    ),
                    child: const Text(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style:
                            TextStyle(fontSize: 14, color: AppColors.primary0),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignInPage()),
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
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

  Widget _buildTextField(
      String hintText, TextEditingController controller, String fieldKey,
      {bool obscureText = false, bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters:
            isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
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
