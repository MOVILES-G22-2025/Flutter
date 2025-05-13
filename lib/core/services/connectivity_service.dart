import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

// Service to handle network connectivity status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream that broadcasts connectivity status
  Stream<bool> get isOnline$ {
    final controller = StreamController<bool>.broadcast();

    // Emit initial state
    _connectivity.checkConnectivity().then((res) {
      controller.add(res != ConnectivityResult.none);
    });

    // Listen for changes
    _connectivity.onConnectivityChanged
        .map((res) => res != ConnectivityResult.none)
        .listen(controller.add);

    return controller.stream;
  }

  /// Check if there is internet connection right now
  Future<bool> get isOnline async {
    final res = await _connectivity.checkConnectivity();
    return res != ConnectivityResult.none;
  }
}
