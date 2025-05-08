import 'dart:async';
import 'package:flutter/material.dart';

// → tu servicio de sincronización
import '/data/local/database/services/sync_service.dart';
// → tu repositorio (para leer la tabla)
import '/data/local/database/repositories/product_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final SyncService _syncService = SyncService();
  final ProductRepository _repo = ProductRepository(); // <─ nuevo

  @override
  void initState() {
    super.initState();

    // 1) Sincronización puntual; al terminar, volcamos la tabla
    _syncService.verificarConectividadYSincronizar().then((_) {
      _dumpLocalProducts();          // <─ imprime la tabla
    });

    // 2) Escucha en tiempo real
    _syncService.escucharCambiosEnFirebase();

    // Animaciones -----------------------------------------------------------
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.66, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.2)).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.66, 1.0, curve: Curves.easeInOut),
          ),
        );

    _animationController.forward();

    // Navega a /login después de 3 s
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  /// Imprime en consola cuántas filas hay y el contenido de la tabla `products`
  Future<void> _dumpLocalProducts() async {
    final rows = await _repo.getProducts();
    print('➡️  SQLite contiene ${rows.length} productos:');
    for (final r in rows) {
      print('• ${r['id']} | ${r['name']} | \$${r['price']}');
    }
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
              tag: 'logoHero',
              child: Image.asset(
                'assets/images/senemarket-logo.png',
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
