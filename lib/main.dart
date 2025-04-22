import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:senemarket/constants.dart' as constants;

// Repos
import 'package:senemarket/data/repositories/auth_repository_impl.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';
import 'package:senemarket/data/repositories/user_repository_impl.dart';
import 'package:senemarket/data/repositories/favorites_repository_impl.dart';
import 'package:senemarket/data/datasources/fcm_remote_data_source.dart';

// Interfaces
import 'package:senemarket/domain/repositories/auth_repository.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';
import 'package:senemarket/domain/repositories/favorites_repository.dart';

// Vistas
import 'package:senemarket/presentation/views/splash/splash_screen.dart';
import 'package:senemarket/presentation/views/login/login_page.dart';
import 'package:senemarket/presentation/views/login/signin_page.dart';
import 'package:senemarket/presentation/views/login/signup_page.dart';
import 'package:senemarket/presentation/views/home_page.dart';
import 'package:senemarket/presentation/views/products/add_product_page.dart';
import 'package:senemarket/presentation/views/products/edit_product_page.dart';
import 'package:senemarket/presentation/views/products/my_products_page.dart';
import 'package:senemarket/presentation/views/profile/profile_page.dart';
import 'package:senemarket/presentation/views/favorites/favorite_page.dart';

// ViewModels
import 'package:senemarket/presentation/views/login/viewmodel/sign_in_viewmodel.dart';
import 'package:senemarket/presentation/views/login/viewmodel/sign_up_viewmodel.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_search_viewmodel.dart';
import 'package:senemarket/presentation/views/products/viewmodel/add_product_viewmodel.dart';
import 'package:senemarket/presentation/views/favorites/viewmodel/favorites_viewmodel.dart';

// Eventual connectivity
import 'package:senemarket/data/local/models/operation.dart';
import 'package:senemarket/data/local/operation_queue.dart';
import 'package:senemarket/core/services/connectivity_service.dart';

import 'data/datasources/product_remote_data_source.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FCMRemoteDataSource().setupFCM();

  // Inicialización de Hive
  await Hive.initFlutter();
  Hive.registerAdapter(OperationAdapter());
  Hive.registerAdapter(OperationTypeAdapter());
  await Hive.openBox<Operation>('operation_queue');

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
    } catch (e) {
      print("Error al registrar la actividad inicial: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';
    final firestore = FirebaseFirestore.instance;
    final now = Timestamp.now();

    if (state == AppLifecycleState.resumed) {
      try {
        final docRef = await firestore.collection('activities').add({
          'userId': userId,
          'startTime': now,
          'endTime': null,
        });
        currentSessionId = docRef.id;
      } catch (e) {
        print("Error al crear actividad: $e");
      }
    } else if (state == AppLifecycleState.paused && currentSessionId != null) {
      try {
        await firestore.collection('activities').doc(currentSessionId).update({
          'endTime': now,
        });
        currentSessionId = null;
      } catch (e) {
        print("Error al actualizar actividad: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final operationQueue = OperationQueue();
    final connectivityService = ConnectivityService();
    final productRepo = ProductRepositoryImpl(
      remoteDataSource: ProductRemoteDataSource(), // 👈 asegúrate de que se pasa
      firestore: FirebaseFirestore.instance,
      operationQueue: operationQueue,
      connectivityService: connectivityService,
    );

    productRepo.startQueueProcessor();

    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<ProductRepository>(create: (_) => productRepo),
        Provider<UserRepository>(create: (_) => UserRepositoryImpl()),
        Provider<FavoritesRepository>(create: (_) => FavoritesRepositoryImpl()),
        Provider<OperationQueue>(create: (_) => operationQueue),
        Provider<ConnectivityService>(create: (_) => connectivityService),
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
          primaryColor: constants.AppColors.primary30,
          colorScheme: ColorScheme.fromSeed(
            seedColor: constants.AppColors.primary30,
            primary: constants.AppColors.primary30,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: constants.AppColors.primary30,
            selectionColor: constants.AppColors.primary30.withOpacity(0.4),
            selectionHandleColor: constants.AppColors.primary30,
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: const TextStyle(
              fontFamily: 'Cabin',
              fontSize: 16,
              color: constants.AppColors.primary0,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1),
              borderSide: const BorderSide(
                color: constants.AppColors.primary50,
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