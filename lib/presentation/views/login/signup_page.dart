import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/widgets/form_fields/password/confirm_password_field.dart';
import '../../../constants.dart' as constants;
import '../../widgets/form_fields/custom_field.dart';
import '../../widgets/form_fields/password/password_field.dart';
import '../../widgets/form_fields/searchable_dropdown.dart';
import '../../widgets/global/error_text.dart';
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
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Local error message for invalid form state
  String? _localErrorMessage;
  String? _nameLengthError;
  String? _emailFormatError;
  String? _selectedCareer;
  String? _semesterRangeError;
  String? _passwordMatchError;

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
                // Full name
                CustomTextField(controller: _nameController, label: 'Full name',
                  onChanged: (value) {
                    if (value.length > 40) {
                      setState(() => _nameLengthError = ErrorMessages.maxChar);
                    } else {
                      setState(() => _nameLengthError = null);
                    }
                  },
                ),
                ErrorText(_nameLengthError),
                const SizedBox(height: 8),

                // Uniandes email
                CustomTextField(controller: _emailController, label: 'Uniandes email',
                  onChanged: (value) {
                    if (value.isNotEmpty && !value.endsWith('@uniandes.edu.co')) {
                      setState(() => _emailFormatError = ErrorMessages.invalidEmailDomain);
                    } else {
                      setState(() => _emailFormatError = null);
                    }
                  },
                ),
                ErrorText(_emailFormatError),
                const SizedBox(height: 8),

                // Career
                const SizedBox(height: 12),

                SearchableDropdown(
                  label: 'Main Career',
                  items: constants.Careers.careers,
                  selectedItem: _selectedCareer,
                  onChanged: (String? career) {
                    setState(() {
                      _selectedCareer = career;
                    });
                  },
                ),

                const SizedBox(height: 8),

                //Semester
                CustomTextField(controller: _semesterController, label: 'Semester', isNumeric: true,
                  onChanged: (value) {
                    final intSemester = int.tryParse(value);
                    if (intSemester != null && (intSemester < 1 || intSemester > 20)) {
                      setState(() => _semesterRangeError = ErrorMessages.semesterRange);
                    } else {
                      setState(() => _semesterRangeError = null);
                    }
                  },
                ),
                ErrorText(_semesterRangeError),
                const SizedBox(height: 8),

                // Password
                PasswordField(controller: _passwordController, label: 'Password',
                  onChanged: (value) {
                    if (_confirmPasswordController.text != value) {
                      setState(() => _passwordMatchError = ErrorMessages.passwordsDoNotMatch);
                    } else {
                      setState(() => _passwordMatchError = null);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ConfirmPasswordField(controller: _confirmPasswordController, label: 'Confirm password',
                  onChanged: (value) {
                    if (value != _passwordController.text) {
                      setState(() => _passwordMatchError = ErrorMessages.passwordsDoNotMatch);
                    } else {
                      setState(() => _passwordMatchError = null);
                    }
                  },
                ),
                ErrorText(_passwordMatchError),
                const SizedBox(height: 8),

                if (_localErrorMessage != null)
                  const ErrorText(ErrorMessages.allFieldsRequired),
                const SizedBox(height: 8),

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
    );
  }

  /// Handles form validation and calls the ViewModel to register the user.
  Future<void> _signUp() async {
    final signUpVM = context.read<SignUpViewModel>();

    setState(() {
      _localErrorMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final career = _selectedCareer?.trim() ?? '';
    final semester = _semesterController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if ([name, email, career, semester, password, confirmPassword].any((field) => field.isEmpty)) {
      setState(() => _localErrorMessage = ErrorMessages.allFieldsRequired);
      return;
    }

    if (!email.endsWith('@uniandes.edu.co')) {
      setState(() => _localErrorMessage = ErrorMessages.invalidEmailDomain);
      return;
    }

    final intSemester = int.tryParse(semester);
    if (intSemester == null || intSemester < 1 || intSemester > 20) {
      setState(() => _localErrorMessage = ErrorMessages.semesterRange);
      return;
    }

    if (password != confirmPassword) {
      setState(() => _localErrorMessage = ErrorMessages.passwordsDoNotMatch);
      return;
    }

    if (name.length > 40) {
      setState(() => _localErrorMessage = ErrorMessages.maxChar);
      return;
    }

    await signUpVM.signUp(
      email: email,
      password: password,
      name: name,
      career: career,
      semester: semester,
    );

    if (signUpVM.errorMessage.isEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}