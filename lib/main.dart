import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:senemarket/data/repositories/auth_repository_impl.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';
import 'package:senemarket/data/repositories/user_repository_impl.dart';
import 'package:senemarket/data/repositories/favorites_repository_impl.dart';
import 'package:senemarket/data/datasources/fcm_remote_data_source.dart';

import 'package:senemarket/domain/repositories/auth_repository.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';
import 'package:senemarket/domain/repositories/favorites_repository.dart';

import 'package:senemarket/presentation/views/favorites/favorite_page.dart';
import 'package:senemarket/presentation/views/favorites/viewmodel/favorites_viewmodel.dart';
import 'package:senemarket/presentation/views/home_page.dart';
import 'package:senemarket/presentation/views/login/login_page.dart';
import 'package:senemarket/presentation/views/products/add_product_page.dart';
import 'package:senemarket/presentation/views/login/signin_page.dart';
import 'package:senemarket/presentation/views/login/signup_page.dart';
import 'package:senemarket/presentation/views/products/edit_product_page.dart';
import 'package:senemarket/presentation/views/products/my_products_page.dart';
import 'package:senemarket/presentation/views/profile/profile_page.dart';
import 'package:senemarket/presentation/views/splash/splash_screen.dart';

import 'package:senemarket/presentation/views/products/viewmodel/add_product_viewmodel.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_search_viewmodel.dart';
import 'package:senemarket/presentation/views/login/viewmodel/sign_in_viewmodel.dart';
import 'package:senemarket/presentation/views/login/viewmodel/sign_up_viewmodel.dart';

import 'package:senemarket/constants.dart' as constants;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FCMRemoteDataSource().setupFCM();

  runApp(const SenemarketApp());
}

class SenemarketApp extends StatefulWidget {
  const SenemarketApp({Key? key}) : super(key: key);

  @override
  _SenemarketAppState createState() => _SenemarketAppState();
}

class _SenemarketAppState extends State<SenemarketApp> with WidgetsBindingObserver {
  String? currentSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("Observador del ciclo de vida agregado.");

    // Registra la actividad inicial, ya que didChangeAppLifecycleState no se dispara al iniciar.
    _logInitialActivity();
  }

  Future<void> _logInitialActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';
    final now = Timestamp.now();
    try {
      final docRef = await FirebaseFirestore.instance.collection('activities').add({
        'userId': userId,
        'startTime': now,
        'endTime': null,
      });
      currentSessionId = docRef.id;
      print("Actividad inicial registrada, ID: $currentSessionId");
    } catch (e) {
      print("Error al registrar la actividad inicial: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    print("Observador del ciclo de vida removido.");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print("La aplicación cambió de estado: $state");

    // Siempre asigna 'anonymous' si no hay usuario autenticado.
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';
    final firestore = FirebaseFirestore.instance;
    final now = Timestamp.now();

    if (state == AppLifecycleState.resumed) {
      try {
        // Registra una nueva actividad al volver a primer plano.
        final docRef = await firestore.collection('activities').add({
          'userId': userId,
          'startTime': now,
          'endTime': null,
        });
        currentSessionId = docRef.id;
        print("Actividad iniciada, ID: $currentSessionId");
      } catch (e) {
        print("Error al crear actividad: $e");
      }
    } else if (state == AppLifecycleState.paused && currentSessionId != null) {
      try {
        // Actualiza la actividad actual con la hora de cierre.
        await firestore.collection('activities').doc(currentSessionId).update({
          'endTime': now,
        });
        print("Actividad actualizada, ID: $currentSessionId");
        currentSessionId = null;
      } catch (e) {
        print("Error al actualizar actividad: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<ProductRepository>(create: (_) => ProductRepositoryImpl()),
        Provider<UserRepository>(create: (_) => UserRepositoryImpl()),
        Provider<FavoritesRepository>(create: (_) => FavoritesRepositoryImpl()),
        ChangeNotifierProvider(create: (context) => SignInViewModel(context.read<AuthRepository>())),
        ChangeNotifierProvider(create: (context) => SignUpViewModel(context.read<AuthRepository>())),
        ChangeNotifierProvider(create: (context) => ProductSearchViewModel(context.read<ProductRepository>())),
        ChangeNotifierProvider(create: (context) => AddProductViewModel(context.read<ProductRepository>())),
        ChangeNotifierProvider(create: (_) => FavoritesViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        theme: ThemeData(
          fontFamily: 'Cabin',
          scaffoldBackgroundColor: constants.AppColors.primary30,
          primaryColor: constants.AppColors.primary30, // << añade esto
          colorScheme: ColorScheme.fromSeed(
            seedColor: constants.AppColors.primary30, // afecta cursor y campos activos
            primary: constants.AppColors.primary30,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: constants.AppColors.primary30,       // ← cursor “|” morado → primary30
            selectionColor: constants.AppColors.primary30.withOpacity(0.4),
            selectionHandleColor: constants.AppColors.primary30,
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: const TextStyle(
              fontFamily: 'Cabin',
              fontSize: 16,
              color: constants.AppColors.primary0, // ← label normal
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1),
              borderSide: const BorderSide(
                color: constants.AppColors.primary50, // ← label activo y borde
                width: 2.0,
              ),
            ),
          ),
        ),
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginPage(),
          '/signIn': (_) => const SignInPage(),
          '/signUp': (_) => const SignUpPage(),
          '/home': (_) => const HomePage(),
          '/add_product': (_) => const AddProductPage(),
          '/favorites': (_) => const FavoritesPage(),
          '/profile': (_) => const ProfilePage(),
          '/my_products': (_) => const MyProductsPage(),
        },
      ),
    );
  }
}
