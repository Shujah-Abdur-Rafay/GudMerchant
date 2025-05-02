import 'package:gudmerchant/controllers/auth_controller.dart';
import 'package:gudmerchant/controllers/cart_controller.dart';
import 'package:gudmerchant/controllers/order_controller.dart';
import 'package:gudmerchant/controllers/product_controller.dart';
import 'package:gudmerchant/controllers/wishlist_controller.dart';
import 'package:gudmerchant/screens/auth-ui/splashscreen.dart';
import 'package:gudmerchant/services/admin_service.dart';
import 'package:gudmerchant/services/email_verification_service.dart';
import 'package:gudmerchant/services/firebase_service.dart';
import 'package:gudmerchant/services/notification_service.dart';
import 'package:gudmerchant/services/product_import_service.dart';
import 'package:gudmerchant/services/phone_verification_service.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'firebase_options.dart';

// Set this to true to force the welcome screen, bypassing authentication
// WARNING: Set to false before production deployment!
const bool FORCE_WELCOME_SCREEN = false;

// Flag to indicate if we're in emergency mode (black screen fix)
bool isEmergencyMode = false;

// Flag to run app with minimal dependencies (for debugging only)
const bool MINIMAL_DEPENDENCIES = false;

/// Widget to handle safe initialization of the app
class SafeLoadInit extends StatefulWidget {
  final Widget child;

  const SafeLoadInit({Key? key, required this.child}) : super(key: key);

  @override
  _SafeLoadInitState createState() => _SafeLoadInitState();
}

class _SafeLoadInitState extends State<SafeLoadInit> {
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    // Start initialization in a safe way
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await initServices();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      debugPrint('Error initializing services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            title: Text('Initialization Error'),
            backgroundColor: Colors.red,
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'An error occurred during app initialization:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    _errorMessage,
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _errorMessage = "";
                      });
                      _initializeServices();
                    },
                    child: Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

void main() async {
  // Show a basic splash screen immediately before any initialization
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Starting GudMerchant...'),
              SizedBox(height: 10),
              Text(
                'Debug mode: ${MINIMAL_DEPENDENCIES ? "MINIMAL" : "FULL"}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter binding initialized');
    
    // Initialize GetStorage
    await GetStorage.init();
    print('GetStorage initialized');

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    print('System orientation set');

    // Configure system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    print('System UI style configured');

    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing Firebase: $e');
      print('Stack trace: $stackTrace');
      isEmergencyMode = true;

      // Try to initialize with default options as fallback
      try {
        print('Attempting to initialize Firebase with default options...');
        await Firebase.initializeApp();
        print('Firebase initialized with default options');
        isEmergencyMode = false;
      } catch (innerError) {
        print(
            'Failed to initialize Firebase with default options: $innerError');
      }
    }

    // Configure EasyLoading
    configureEasyLoading();
    print('EasyLoading configured');

    // Remove test mode to ensure proper OAuth flow
    // Get.testMode = true;
    print('GetX configured for production use');

    // Run the actual app
    runApp(const MyApp());
    print('Main app started');
  } catch (e, stackTrace) {
    print('Error in main: $e');
    print('Stack trace: $stackTrace');
    isEmergencyMode = true;

    // Run a simple app that displays the error
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.red[100],
          appBar: AppBar(
            title: Text('App Error'),
            backgroundColor: Colors.red,
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'An error occurred while starting the app:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    e.toString(),
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Initialize all services and controllers
Future<void> initServices() async {
  if (isEmergencyMode) {
    debugPrint(
        '⚠️ Running in emergency mode - skipping service initialization');
    return;
  }

  try {
    debugPrint('🚀 Starting service initialization...');

    // Register services first
    debugPrint('📦 Registering FirebaseService...');
    await Get.putAsync(() => FirebaseService().init());
    debugPrint('✅ FirebaseService registered successfully');

    await Get.putAsync(() => NotificationService().init());
    debugPrint('✅ Notification service initialized');

    // Register email verification service
    debugPrint('📦 Registering EmailVerificationService...');
    Get.put(EmailVerificationService(), permanent: true);
    debugPrint('✅ EmailVerificationService registered successfully');

    // Register phone verification service
    debugPrint('📦 Registering PhoneVerificationService...');
    Get.put(PhoneVerificationService(), permanent: true);
    debugPrint('✅ PhoneVerificationService registered successfully');

    if (!MINIMAL_DEPENDENCIES) {
      // Register admin service (only in development)
      debugPrint('📦 Registering AdminService...');
      await Get.putAsync(() => AdminService().init());
      debugPrint('✅ AdminService registered successfully');

      // Register product import service
      debugPrint('📦 Registering ProductImportService...');
      Get.put(ProductImportService(), permanent: true);
      debugPrint('✅ ProductImportService registered successfully');
    } else {
      debugPrint(
          '⏩ Skipping AdminService and ProductImportService in minimal mode');
    }

    // Register controllers
    debugPrint('📦 Registering AuthController...');
    Get.put(AuthController(), permanent: true);
    debugPrint('✅ AuthController registered successfully');

    if (!MINIMAL_DEPENDENCIES) {
      debugPrint('📦 Registering ProductController...');
      Get.put(ProductController(), permanent: true);
      debugPrint('✅ ProductController registered successfully');

      debugPrint('📦 Registering CartController...');
      Get.put(CartController(), permanent: true);
      debugPrint('✅ CartController registered successfully');

      debugPrint('📦 Registering OrderController...');
      Get.put(OrderController(), permanent: true);
      debugPrint('✅ OrderController registered successfully');

      debugPrint('📦 Registering WishlistController...');
      Get.put(WishlistController(), permanent: true);
      debugPrint('✅ WishlistController registered successfully');
    } else {
      debugPrint('⏩ Skipping other controllers in minimal mode');
    }

    // Log success
    debugPrint('✅ All services initialized successfully');
  } catch (e, stackTrace) {
    // Log error with stack trace
    debugPrint('❌ Error initializing services: $e');
    debugPrint('Stack trace: $stackTrace');

    // Enable emergency mode
    isEmergencyMode = true;

    // Show error on screen when possible
    Future.delayed(Duration.zero, () {
      try {
        Get.snackbar(
          'Initialization Error',
          'Error: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 10),
        );
      } catch (_) {
        // If Get.snackbar fails, at least we logged the error
      }
    });
  }
}

/// Configure EasyLoading appearance and behavior
void configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = AppTheme.mediumRadius
    ..progressColor = AppTheme.primaryColor
    ..backgroundColor = Colors.black.withOpacity(0.8)
    ..indicatorColor = AppTheme.primaryColor
    ..textColor = Colors.white
    ..userInteractions = false
    ..dismissOnTap = false
    ..maskType = EasyLoadingMaskType.black
    ..maskColor = Colors.black.withOpacity(0.5);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return GetMaterialApp(
        title: 'GudMerchant',
        debugShowCheckedModeBanner: false,
        enableLog: true,
        defaultTransition: Transition.cupertino,
        theme: AppTheme.lightTheme,
        home: SafeLoadInit(
          child: const SplashScreen(),
        ),
        builder: EasyLoading.init(),
      );
    } catch (e, stackTrace) {
      debugPrint('Error in MyApp build: $e');
      debugPrint('Stack trace: $stackTrace');

      // Return a minimal fallback UI if something goes wrong
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'An error occurred during app initialization',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Force app to restart
                    SystemNavigator.pop();
                  },
                  child: Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
