import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Duración total de 3 segundos para combinar ambas animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Animación de escalado: de tamaño completo (1.0) a 0.6 para que el logo pase de 200 a ~120 (siendo 200 y 120, respectivamente)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.66, curve: Curves.easeInOut),
      ),
    );

    // Animación de deslizamiento: se mueve ligeramente hacia arriba en el último tercio de la animación.
    // El valor de Offset(0, -0.2) es un ejemplo; ajústalo para que coincida exactamente con la posición del logo en el login.
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.2)).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();

    // Al finalizar la animación (3 segundos) se navega a la pantalla de login.
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Hero(
              tag: 'logoHero', // Tag común para la animación Hero
              child: Image.asset(
                'assets/images/senemarket-logo.png', // Asegúrate de que el asset esté declarado en pubspec.yaml
                width: 200,
                height: 200,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
