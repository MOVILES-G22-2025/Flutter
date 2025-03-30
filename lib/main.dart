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
    // Agrega el observador para recibir notificaciones del ciclo de vida
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remueve el observador al destruirse el widget para evitar fugas de memoria
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Si no hay usuario autenticado, no se registra la actividad.
      print("La aplicación cambió de estado: $state, sin usuario autenticado.");
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final userId = user.uid;
    final now = Timestamp.now();

    if (state == AppLifecycleState.resumed) {
      // Crear un nuevo documento en 'activities' con la hora de inicio.
      final docRef = await firestore.collection('activities').add({
        'userId': userId,
        'startTime': now,
        'endTime': null,
      });
      currentSessionId = docRef.id;
    } else if (state == AppLifecycleState.paused && currentSessionId != null) {
      // Actualizar el documento actual con la hora de cierre.
      await firestore.collection('activities').doc(currentSessionId).update({
        'endTime': now,
      });
      currentSessionId = null;
    }

    print("La aplicación cambió de estado: $state");
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
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: constants.AppColors.primary30,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              overlayColor: constants.AppColors.secondary20,
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all(Colors.transparent),
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
