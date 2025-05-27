import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/views/otp/viewmodel/otp_viewmodel.dart';

import '../../../constants.dart' as constants;
import '../../widgets/form_fields/custom_field.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;

  const OTPVerificationPage({Key? key, required this.email}) : super(key: key);

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OTPVerificationViewModel(widget.email)..startTimer(),
      child: Consumer<OTPVerificationViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.primary50,
            appBar: AppBar(
              backgroundColor: AppColors.primary50,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.primary0),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Enter the 6-digit code sent to your Uniandes email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cabin',
                        color: AppColors.primary0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _codeController,
                      label: 'Verification code',
                      isNumeric: true,
                      maxLength: 6,
                      onChanged: vm.updateCode,
                    ),
                    if (vm.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          vm.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      vm.timeRemainingFormatted,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: vm.isVerifying ? null : vm.verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary30,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                      ),
                      child: vm.isVerifying
                          ? const CircularProgressIndicator()
                          : const Text(
                        'Verify',
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: vm.canResend ? vm.resendCode : null,
                      child: const Text('Resend code',
                      style: TextStyle(
                        color: constants.AppColors.primary30,
                        fontFamily: 'Cabin',
                        fontSize: 18,
                      ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
