import '../../../../utils/crypto_utils.dart';              // hashPassword
import 'package:senemarket/data/local/credential_hive_service.dart'; // CredentialHiveService
import 'package:senemarket/core/services/connectivity_service.dart';   // ConnectivityService

import 'package:flutter/foundation.dart'; // para ChangeNotifier & kDebugMode
import 'package:senemarket/domain/repositories/auth_repository.dart'; // AuthRepository
import 'package:senemarket/data/local/database/services/sync_service.dart'; // SyncService


import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';                // para FirebaseAuth.instance.currentUser
              // hashPassword
import 'package:senemarket/data/local/services/local_storage_service.dart';
import 'package:senemarket/data/local/models/user_session.dart';

class SignInViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final ConnectivityService _connectivityService;
  final SyncService _syncService;
  final CredentialHiveService _credentialService;
  final LocalStorageService _localStorage;

  bool isLoading = false;
  String errorMessage = '';

  SignInViewModel(
      this._authRepository,
      this._connectivityService,
      this._syncService,
      )   : _credentialService = CredentialHiveService(),
        _localStorage    = LocalStorageService();

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    final passwordHash = hashPassword(password);

    if (await _connectivityService.isOnline) {
      // —— LOGIN ONLINE ——
      final error = await _authRepository.signInWithEmailAndPassword(email, password);
      if (error != null) {
        errorMessage = error;
      } else {
        // Guardar hash para login offline
        await _credentialService.saveCredentials(email, passwordHash);

        // Sincronizar usuario remoto
        await _syncService.sincronizarUsuarioPorEmail(email);

        // ** Guardar sesión activa localmente **
        final fbUser = FirebaseAuth.instance.currentUser!;
        final session = UserSessionModel(
          uid: fbUser.uid,
          email: fbUser.email!,
          name: fbUser.displayName ?? '',
          isLoggedIn: true,
        );
        await _localStorage.saveActiveSession(session);
      }
    } else {
      // —— LOGIN OFFLINE ——
      final storedHash = _credentialService.getStoredHash(email);
      if (storedHash == null) {
        errorMessage = 'No hay credenciales guardadas para $email';
      } else if (storedHash == passwordHash) {
        // Éxito offline: guardamos la sesión local
        final session = UserSessionModel(
          uid: email,                    // usa email como UID si no tienes otro
          email: email,
          name: email.split('@').first,  // o el nombre que prefieras
          isLoggedIn: true,
        );
        await _localStorage.saveActiveSession(session);
      } else {
        errorMessage = 'Contraseña incorrecta (offline)';
      }
    }

    isLoading = false;
    notifyListeners();
  }
}
