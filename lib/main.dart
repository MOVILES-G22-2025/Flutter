// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// 🔄 Data layer
import 'package:senemarket/data/repositories/auth_repository_impl.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';
import 'package:senemarket/data/repositories/user_repository_impl.dart';
import 'package:senemarket/data/repositories/favorites_repository_impl.dart';
import 'package:senemarket/data/datasources/fcm_remote_data_source.dart';

// 🧠 Domain layer
import 'package:senemarket/domain/repositories/auth_repository.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';
import 'package:senemarket/domain/repositories/favorites_repository.dart';
import 'package:senemarket/presentation/views/favorites/favorite_page.dart';
import 'package:senemarket/presentation/views/favorites/viewmodel/favorites_viewmodel.dart';
import 'package:senemarket/presentation/views/home_page.dart';
import 'package:senemarket/presentation/views/login/login_page.dart';
import 'package:senemarket/presentation/views/products/add_product_page.dart';

// 🧩 ViewModels
import 'package:senemarket/presentation/views/products/viewmodel/add_product_viewmodel.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_search_viewmodel.dart';
import 'package:senemarket/presentation/views/login/viewmodel/sign_in_viewmodel.dart';
import 'package:senemarket/presentation/views/login/viewmodel/sign_up_viewmodel.dart';

// 🖼️ Views
import 'package:senemarket/presentation/views/login/signin_page.dart';
import 'package:senemarket/presentation/views/login/signup_page.dart';
import 'package:senemarket/presentation/views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FCMRemoteDataSource().setupFCM(); // actualizado

  runApp(const SenemarketApp());
}

class SenemarketApp extends StatelessWidget {
  const SenemarketApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositorios (Data → Domain)
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<ProductRepository>(create: (_) => ProductRepositoryImpl()),
        Provider<UserRepository>(create: (_) => UserRepositoryImpl()),
        Provider<FavoritesRepository>(create: (_) => FavoritesRepositoryImpl()),

        // ViewModels
        ChangeNotifierProvider(create: (context) => SignInViewModel(context.read<AuthRepository>())),
        ChangeNotifierProvider(create: (context) => SignUpViewModel(context.read<AuthRepository>())),
        ChangeNotifierProvider(create: (context) => ProductSearchViewModel(context.read<ProductRepository>())),
        ChangeNotifierProvider(create: (context) => AddProductViewModel(context.read<ProductRepository>())),
        ChangeNotifierProvider(create: (_) => FavoritesViewModel()),

      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginPage(),
          '/signIn': (_) => const SignInPage(),
          '/signUp': (_) => const SignUpPage(),
          '/home': (_) => const HomePage(),
          '/add_product': (_) => const AddProductPage(),
          '/favorites': (context) => const FavoritesPage(),

        },
      ),
    );
  }
}
