// lib/presentation/views/login_view/login_page.dart

import 'package:flutter/material.dart';
import 'package:senemarket/constants.dart';

/// Pantalla de “inicio” o “welcome” para tu app,
/// mostrando botones "Sign in" y "Create account".
/// Navega a las rutas '/signIn' y '/signUp'.
class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          // Para centrar el contenido verticalmente, usa un Column dentro de un Expanded
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo o imagen principal
              Hero(
                tag: 'logoHero',
                child: Image.asset(
                  'assets/images/senemarket-logo.png',
                  height: 120,
                ),
              ),
              const SizedBox(height: 24),

              // Título principal
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

              // Subtítulo
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

              // Botón para Sign in
              ElevatedButton(
                onPressed: () {
                  // Usamos rutas nombradas en vez de instanciar la página directamente
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

              // Texto para navegar a crear cuenta
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
