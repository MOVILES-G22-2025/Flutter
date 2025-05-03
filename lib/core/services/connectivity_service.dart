// lib/core/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream broadcast de conectividad
  Stream<bool> get isOnline$ {
    final controller = StreamController<bool>.broadcast();

    // Emitir estado inicial
    _connectivity.checkConnectivity().then((res) {
      controller.add(res != ConnectivityResult.none);
    });

    // Escuchar cambios
    _connectivity.onConnectivityChanged
        .map((res) => res != ConnectivityResult.none)
        .listen(controller.add);

    return controller.stream;
  }

  /// Comprueba **ahora mismo** si hay conexión
  Future<bool> get isOnline async {
    final res = await _connectivity.checkConnectivity();
    return res != ConnectivityResult.none;
  }
}
