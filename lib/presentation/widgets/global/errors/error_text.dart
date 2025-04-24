import 'package:flutter/material.dart';
import 'package:senemarket/constants.dart';

class ErrorText extends StatelessWidget {
  final String? message;

  const ErrorText(this.message, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
      child: Text(
        message!,
        style: const TextStyle(
          fontFamily: 'Cabin',
          fontSize: 14,
          color: Colors.red,
        ),
      ),
    );
  }
}
