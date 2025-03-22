// lib/presentation/viewmodels/sign_up_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:senemarket/domain/repositories/auth_repository.dart';

/// ViewModel para manejar el proceso de registro de un nuevo usuario.
///
/// Requiere un [AuthRepository] para realizar la creación de cuenta
/// y almacenar datos del usuario en Firestore (u otra base de datos),
/// según la implementación de la capa de datos.
///
/// Ejemplo de uso en una vista:
/// ```dart
/// final signUpViewModel = context.watch<SignUpViewModel>();
/// ...
/// ElevatedButton(
///   onPressed: () async {
///     await signUpViewModel.signUp(
///       email: _emailController.text,
///       password: _passwordController.text,
///       name: _nameController.text,
///       career: _careerController.text,
///       semester: _semesterController.text,
///     );
///     if (signUpViewModel.errorMessage.isEmpty) {
///       // Registro exitoso
///       Navigator.pushReplacementNamed(context, '/home');
///     } else {
///       // Mostrar error
///     }
///   },
///   child: signUpViewModel.isLoading ? CircularProgressIndicator() : Text('Sign Up'),
/// )
/// ```
class SignUpViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  /// Indica si el proceso de registro está en curso (loading).
  bool isLoading = false;

  /// Contiene el mensaje de error en caso de fallo durante el registro.
  /// Será una cadena vacía si no hay error.
  String errorMessage = '';

  /// Constructor que requiere un [AuthRepository].
  /// Normalmente, este repositorio se inyecta desde un Provider
  /// en [main.dart] u otro punto de configuración.
  SignUpViewModel(this._authRepository);

  /// Inicia el proceso de registro de un nuevo usuario.
  ///
  /// - [email]: Correo del usuario (por ejemplo, `@uniandes.edu.co`).
  /// - [password]: Contraseña elegida por el usuario.
  /// - [name]: Nombre completo del usuario.
  /// - [career]: Carrera académica del usuario.
  /// - [semester]: Semestre actual del usuario.
  ///
  /// Si el registro falla, el mensaje de error se guarda en [errorMessage].
  /// Si el registro es exitoso, [errorMessage] permanece vacío (`''`).
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String career,
    required String semester,
  }) async {
    // Ponemos la ViewModel en modo "cargando"
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    // Llamamos al repositorio para registrar al usuario.
    final error = await _authRepository.signUpWithEmailAndPassword(
      email,
      password,
      name,
      career,
      semester,
    );

    // Si la operación retornó una cadena, es un mensaje de error;
    // de lo contrario, indica éxito (null).
    if (error != null) {
      errorMessage = error;
    }

    // Terminamos la carga
    isLoading = false;
    notifyListeners();
  }
}
