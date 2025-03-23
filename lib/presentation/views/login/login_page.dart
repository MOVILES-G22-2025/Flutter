import 'package:flutter/material.dart';
import 'package:senemarket/constants.dart';

/// Welcome screen of the app.
/// Offers navigation to "Sign in" and "Create account" pages.
class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App logo with animation when navigating
              Hero(
                tag: 'logoHero',
                child: Image.asset(
                  'assets/images/senemarket-logo.png',
                  height: 120,
                ),
              ),
              const SizedBox(height: 24),

              // App title
              const Text(
                'SeneMarket',
                style: TextStyle(
                  fontFamily: 'Cabin',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary0,
                ),
              ),
              const SizedBox(height: 8),

              // App subtitle
              const Text(
                'Find everything you need for your career in one place',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cabin',
                  fontSize: 16,
                  color: AppColors.primary0,
                ),
              ),
              const SizedBox(height: 40),

              // Button to go to sign-in screen
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signIn');
                },
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

              // Text + link to create account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New to SeneMarket? ',
                    style: TextStyle(
                      fontFamily: 'Cabin',
                      fontSize: 14,
                      color: AppColors.primary0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/signUp');
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
}
