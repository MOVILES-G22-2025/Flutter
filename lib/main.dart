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
import 'package:senemarket/presentation/views/cart/cart_page.dart';
import 'package:senemarket/presentation/views/cart/viewmodel/cart_viewmodel.dart';
import 'package:senemarket/presentation/views/drafts/edit_draft_page.dart';
import 'package:senemarket/presentation/views/drafts/my_drafts_page.dart';

// Vistas
import 'package:senemarket/presentation/views/splash/splash_screen.dart';
import 'package:senemarket/presentation/views/login/login_page.dart';
import 'package:senemarket/presentation/views/login/signin_page.dart';
import 'package:senemarket/presentation/views/login/signup_page.dart';
import 'package:senemarket/presentation/views/home_page.dart';
import 'package:senemarket/presentation/views/products/add_product_page.dart';
import 'package:senemarket/presentation/views/products/my_products_page.dart';
import 'package:senemarket/presentation/views/profile/profile_page.dart';
import 'package:senemarket/presentation/views/favorites/favorite_page.dart';
import 'package:senemarket/presentation/views/chat_page.dart';

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
import 'package:senemarket/core/services/notification_service.dart';

import 'core/widgets/offline_banner.dart';
import 'data/datasources/product_remote_data_source.dart';
import 'data/local/models/cart_item.dart';
import 'data/local/models/draft_product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final notificationService = NotificationService();
  await notificationService.init();
  await FCMRemoteDataSource().setupFCM();

  // Inicialización de Hive
  await Hive.initFlutter();
  Hive.registerAdapter(OperationAdapter());
  Hive.registerAdapter(OperationTypeAdapter());
  Hive.registerAdapter(DraftProductAdapter()); // ⬅️ ¡IMPORTANTE!
  Hive.registerAdapter(CartItemAdapter());
  await Hive.openBox<CartItem>('cart');
  await Hive.openBox<Operation>('operation_queue');
  await Hive.openBox<DraftProduct>('draft_products'); // <-- Si usas esta box


  runApp(const SenemarketApp());
}

class SenemarketApp extends StatefulWidget {
  const SenemarketApp({Key? key}) : super(key: key);

  @override
  _SenemarketAppState createState() => _SenemarketAppState();
}

class _SenemarketAppState extends State<SenemarketApp> with WidgetsBindingObserver {
  String? currentSessionId;
  late final NotificationService notificationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    notificationService = NotificationService();
    notificationService.init();
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
    productRepo.startQueueProcessor(notificationService);

    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<ProductRepository>(create: (_) => productRepo),
        Provider<UserRepository>(create: (_) => UserRepositoryImpl()),
        Provider<FavoritesRepository>(create: (_) => FavoritesRepositoryImpl()),
        Provider<OperationQueue>(create: (_) => operationQueue),
        Provider<ConnectivityService>(create: (_) => connectivityService),
        Provider<NotificationService>(create: (_) => notificationService),
        ChangeNotifierProvider(create: (context) => SignInViewModel(context.read<AuthRepository>())),
        ChangeNotifierProvider(create: (context) => SignUpViewModel(context.read<AuthRepository>())),
        ChangeNotifierProvider(create: (context) => ProductSearchViewModel(context.read<ProductRepository>())),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider<AddProductViewModel>(
          create: (context) {
            final repo = context.read<ProductRepository>();
            final connectivity = context.read<ConnectivityService>();
            return AddProductViewModel(
              repo,
              connectivityStream: connectivity.isOnline$.asBroadcastStream(),
            );
          },
        ),
        ChangeNotifierProvider(create: (_) => FavoritesViewModel()),
      ],

      child: MaterialApp(
        builder: (ctx, child) {
          final connectivity = ctx.read<ConnectivityService>();
          return Column(
            children: [
              // 2) Nuestro banner
              OfflineBanner(connectivityStream: connectivity.isOnline$.asBroadcastStream()),
              // 3) El resto de la app
              Expanded(child: child!),
            ],
          );
        },
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
          '/drafts': (_) => const MyDraftsPage(),
          '/chats': (_) => const ChatsScreen(),
          '/cart': (_) => const CartPage(),
          '/edit_draft': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is DraftProduct) {
              return EditDraftPage(draft: args);
            } else {
              return const Scaffold(body: Center(child: Text('Draft not found')));
            }
          },        },
      ),
    );
  }
}