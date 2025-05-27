import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/views/otp/viewmodel/otp_viewmodel.dart';

class OTPVerificationPage extends StatelessWidget {
  final String email;

  const OTPVerificationPage({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OTPVerificationViewModel(email)..startTimer(),
      child: Consumer<OTPVerificationViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.primary50,
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
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      onChanged: vm.updateCode,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        border: OutlineInputBorder(),
                      ),
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
                      child: vm.isVerifying
                          ? const CircularProgressIndicator()
                          : const Text('Verify'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: vm.canResend ? vm.resendCode : null,
                      child: const Text('Resend code'),
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
