import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream broadcast de conectividad
  Stream<bool> get isOnline$ {
    // Primero el estado actual, luego convertimos onConnectivityChanged a broadcast
    final controller = StreamController<bool>.broadcast();

    // Emitir estado inicial
    _connectivity.checkConnectivity().then((res) {
      controller.add(res != ConnectivityResult.none);
    });

    // Escuchar cambios
    _connectivity.onConnectivityChanged
        .map((res) => res != ConnectivityResult.none)
        .listen((online) {
      controller.add(online);
    });

    return controller.stream;
  }
}
