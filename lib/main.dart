// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:senemarket/constants.dart' as constants;

// Repositorios
import 'package:senemarket/data/repositories/auth_repository_impl.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';
import 'package:senemarket/data/repositories/user_repository_impl.dart';
import 'package:senemarket/data/repositories/favorites_repository_impl.dart';
import 'package:senemarket/data/repositories/chat_repository_impl.dart';
import 'package:senemarket/data/datasources/fcm_remote_data_source.dart';

// Interfaces
import 'package:senemarket/domain/repositories/auth_repository.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';
import 'package:senemarket/domain/repositories/favorites_repository.dart';
import 'package:senemarket/domain/repositories/chat_repository.dart';

// Servicios
import 'package:senemarket/core/services/connectivity_service.dart';
import 'package:senemarket/core/services/notification_service.dart';

// Local
import 'package:senemarket/data/local/models/operation.dart';
import 'package:senemarket/data/local/operation_queue.dart';
import 'package:senemarket/data/local/models/draft_product.dart';
import 'package:senemarket/presentation/views/cart/cart_page.dart';
import 'package:senemarket/presentation/views/cart/viewmodel/cart_viewmodel.dart';

// ViewModels
import 'package:senemarket/presentation/views/login/viewmodel/sign_in_viewmodel.dart';
import 'package:senemarket/presentation/views/login/viewmodel/sign_up_viewmodel.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_search_viewmodel.dart';
import 'package:senemarket/presentation/views/products/viewmodel/add_product_viewmodel.dart';
import 'package:senemarket/presentation/views/favorites/viewmodel/favorites_viewmodel.dart';
import 'package:senemarket/presentation/views/chat/viewmodel/chat_list_viewmodel.dart';
import 'package:senemarket/presentation/views/chat/viewmodel/chat_viewmodel.dart';

// Vistas
import 'package:senemarket/presentation/views/splash/splash_screen.dart';
import 'package:senemarket/presentation/views/login/login_page.dart';
import 'package:senemarket/presentation/views/login/signin_page.dart';
import 'package:senemarket/presentation/views/login/signup_page.dart';
import 'package:senemarket/presentation/views/home_page.dart';
import 'package:senemarket/presentation/views/products/add_product_page.dart';
import 'package:senemarket/presentation/views/products/my_products_page.dart';
import 'package:senemarket/presentation/views/favorites/favorite_page.dart';
import 'package:senemarket/presentation/views/profile/profile_page.dart';
import 'package:senemarket/presentation/views/profile/edit_profile_page.dart';
import 'package:senemarket/presentation/views/drafts/edit_draft_page.dart';
import 'package:senemarket/presentation/views/drafts/my_drafts_page.dart';
import 'package:senemarket/presentation/views/chat/chat_list_page.dart';
import 'package:senemarket/presentation/views/chat/chat_page.dart';

import 'data/datasources/product_remote_data_source.dart';
import 'package:senemarket/data/local/models/cart_item.dart';
import 'package:senemarket/core/widgets/app_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Notificaciones y FCM
  final notificationService = NotificationService();
  await notificationService.init();
  await FCMRemoteDataSource().setupFCM();

  // Hive
  await Hive.initFlutter();
  Hive.registerAdapter(OperationAdapter());
  Hive.registerAdapter(OperationTypeAdapter());
  Hive.registerAdapter(DraftProductAdapter());
  Hive.registerAdapter(CartItemAdapter());
  await Hive.openBox<Operation>('operation_queue');
  await Hive.openBox<DraftProduct>('draft_products');
  await Hive.openBox<CartItem>('cart');

  runApp(const SenemarketApp());
}

class SenemarketApp extends StatefulWidget {
  const SenemarketApp({Key? key}) : super(key: key);

  @override
  _SenemarketAppState createState() => _SenemarketAppState();
}

class _SenemarketAppState extends State<SenemarketApp> with WidgetsBindingObserver {
  String? _currentSessionId;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationService = NotificationService();
    _notificationService.init();
    _logInitialActivity();
  }

  Future<void> _logInitialActivity() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final now = Timestamp.now();
    try {
      final docRef = await FirebaseFirestore.instance.collection('activities').add({
        'userId': userId,
        'startTime': now,
        'endTime': null,
      });
      _currentSessionId = docRef.id;
    } catch (e) {
      print('Error al registrar la actividad inicial: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final now = Timestamp.now();
    final firestore = FirebaseFirestore.instance;
    if (state == AppLifecycleState.resumed) {
      final docRef = await firestore.collection('activities').add({
        'userId': userId,
        'startTime': now,
        'endTime': null,
      });
      _currentSessionId = docRef.id;
    } else if (state == AppLifecycleState.paused && _currentSessionId != null) {
      await firestore.collection('activities').doc(_currentSessionId!).update({
        'endTime': now,
      });
      _currentSessionId = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Instancias compartidas
    final operationQueue = OperationQueue();
    final connectivityService = ConnectivityService();
    final productRepo = ProductRepositoryImpl(
      remoteDataSource: ProductRemoteDataSource(),
      firestore: FirebaseFirestore.instance,
      operationQueue: operationQueue,
      connectivityService: connectivityService,
    );
    productRepo.startQueueProcessor(_notificationService);

    return MultiProvider(
      providers: [
        // Repositorios
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<ProductRepository>(create: (_) => productRepo),
        Provider<UserRepository>(create: (_) => UserRepositoryImpl()),
        Provider<FavoritesRepository>(create: (_) => FavoritesRepositoryImpl()),
        Provider<ChatRepository>(create: (_) => ChatRepositoryImpl()),

        // Servicios
        Provider<OperationQueue>(create: (_) => operationQueue),
        Provider<ConnectivityService>(create: (_) => connectivityService),
        Provider<NotificationService>(create: (_) => _notificationService),

        // ViewModels
        ChangeNotifierProvider(create: (_) => ChatListViewModel()),
        ChangeNotifierProvider(create: (ctx) => SignInViewModel(ctx.read<AuthRepository>())),
        ChangeNotifierProvider(create: (ctx) => SignUpViewModel(ctx.read<AuthRepository>())),
        ChangeNotifierProvider(create: (ctx) => ProductSearchViewModel(ctx.read<ProductRepository>())),
        ChangeNotifierProvider(create: (ctx) => CartViewModel()),

        ChangeNotifierProvider(
          create: (ctx) => AddProductViewModel(
            ctx.read<ProductRepository>(),
            connectivityStream: ctx.read<ConnectivityService>().isOnline$,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => FavoritesViewModel(ctx.read<FavoritesRepository>()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        theme: ThemeData(
          fontFamily: 'Cabin',
          scaffoldBackgroundColor: constants.AppColors.primary30,
          colorScheme: ColorScheme.fromSeed(seedColor: constants.AppColors.primary30),
        ),
        builder: (context, child) {
          return AppWrapper(child: child!);
        },
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginPage(),
          '/signIn': (_) => const SignInPage(),
          '/signUp': (_) => const SignUpPage(),
          '/home': (_) => const HomePage(),
          '/cart': (_) => ChangeNotifierProvider(
            create: (_) => CartViewModel(),
            child: const CartPage(),
          ),
          '/add_product': (_) => const AddProductPage(),
          '/my_products': (_) => const MyProductsPage(),
          '/favorites': (_) => const FavoritesPage(),
          '/profile': (_) => const ProfilePage(),
          '/edit_profile': (_) => const EditProfilePage(),
          '/cart': (_) => const CartPage(),
          '/drafts': (_) => const MyDraftsPage(),
          '/edit_draft': (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments;
            if (args is DraftProduct) return EditDraftPage(draft: args);
            return const Scaffold(body: Center(child: Text('Draft not found')));
          },
          '/chats': (_) => const ChatListPage(),
          '/chat': (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
            final currentUserId = FirebaseAuth.instance.currentUser!.uid;
            final receiverId = args['receiverId'] as String;
            final receiverName = args['receiverName'] as String;
            return ChangeNotifierProvider(
              create: (_) => ChatViewModel(
                ctx.read<ChatRepository>(),
                ctx.read<ConnectivityService>(),
                ctx.read<OperationQueue>(),
                currentUserId,
                receiverId,
              ),
              child: ChatPage(receiverName: receiverName),
            );
          },
        },
      ),
    );
  }
}