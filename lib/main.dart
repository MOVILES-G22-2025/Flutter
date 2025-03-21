// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// ====== Data layer ======
import 'package:senemarket/data/services/fcm_service.dart';
import 'package:senemarket/data/repositories/auth_repository_impl.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';
import 'package:senemarket/data/repositories/user_repository_impl.dart';

// ====== Domain layer ======
import 'package:senemarket/domain/repositories/auth_repository.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';

// ====== ViewModels ======
import 'package:senemarket/presentation/viewmodels/add_product_viewmodel.dart';
import 'package:senemarket/presentation/viewmodels/product_search_viewmodel.dart';
import 'package:senemarket/presentation/viewmodels/sign_in_viewmodel.dart';
import 'package:senemarket/presentation/viewmodels/sign_up_viewmodel.dart';

// ====== Views ======
import 'package:senemarket/presentation/views/splash_screen.dart';
import 'package:senemarket/presentation/views/home_page.dart';
import 'package:senemarket/presentation/views/login_view/login_page.dart';
import 'package:senemarket/presentation/views/login_view/signin_page.dart';
import 'package:senemarket/presentation/views/login_view/signup_page.dart';
import 'package:senemarket/presentation/views/product_view/add_product_page.dart';

// Opcional: constantes globales

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp();

  // Inicializa el servicio de notificaciones (FCM)
  await FCMService.setupFCM();

  runApp(const SenemarketApp());
}

class SenemarketApp extends StatelessWidget {
  const SenemarketApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Inyectamos repositorios concretos (data -> domain)
        Provider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(),
        ),
        Provider<ProductRepository>(
          create: (_) => ProductRepositoryImpl(),
        ),
        Provider<UserRepository>(
          create: (_) => UserRepositoryImpl(),
        ),

        // Inyectamos los ViewModels (presentation)
        ChangeNotifierProvider<ProductSearchViewModel>(
          create: (context) => ProductSearchViewModel(
            context.read<ProductRepository>(),
          ),
        ),
        ChangeNotifierProvider<SignInViewModel>(
          create: (context) => SignInViewModel(
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<SignUpViewModel>(
          create: (context) => SignUpViewModel(
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<AddProductViewModel>(
          create: (context) => AddProductViewModel(
            context.read<ProductRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        // Primera pantalla que se muestra
        initialRoute: '/splash',

        // Rutas nombradas
        routes: {
          // Pantalla de inicio (Splash)
          '/splash': (context) => const SplashScreen(),

          // Login principal (si lo usas como pantalla de bienvenida)
          '/login': (context) => const LoginPage(),

          // Pantalla de SignIn (logueo con email/password)
          '/signIn': (context) => const SignInPage(),

          // Pantalla de SignUp (registro de usuario)
          '/signUp': (context) => const SignUpPage(),

          // Pantalla principal (Home)
          '/home': (context) => const HomePage(),

          // Pantalla para agregar un producto
          '/add_product': (context) => const AddProductPage(),
        },

        // Ejemplo de navegación a la pantalla de detalles de producto
        // si quisieras nombrar la ruta, podrías hacerlo con onGenerateRoute
        // en lugar de `routes`, o directamente con Navigator.push(...)
      ),
    );
  }
}
