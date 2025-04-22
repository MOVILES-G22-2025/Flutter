import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Este stream siempre emitirá al menos un valor inicial
  Stream<bool> get isOnline$ async* {
    // Emitir el estado actual primero
    final result = await _connectivity.checkConnectivity();
    yield result != ConnectivityResult.none;

    // Luego seguir escuchando cambios
    yield* _connectivity.onConnectivityChanged.map(
          (result) => result != ConnectivityResult.none,
    ).distinct();
  }
}