import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'database/database_service.dart';
import 'providers/locale_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/welcome_page.dart';
import 'services/security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.init();

  // Open settings box for locale storage
  await Hive.openBox('settings');

  // Verify Model Integrity (SHA-256 Check)
  bool isIntegrityOk = await SecurityService.verifyModelIntegrity();

  // Get available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    VeriScanProApp(
      camera: firstCamera,
      isSecurityOk: isIntegrityOk,
    ),
  );
}

class VeriScanProApp extends StatelessWidget {
  final CameraDescription camera;
  final bool isSecurityOk;

  const VeriScanProApp({
    super.key,
    required this.camera,
    required this.isSecurityOk,
  });

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          // BLOCK ACCESS IF TAMPERED
          if (!isSecurityOk) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: SecurityErrorScreen(),
            );
          }

          return MaterialApp(
            title: 'DeepScan',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('te'),
              Locale('ml'),
            ],
            locale: localeProvider.locale,
            theme: ThemeData(
              primaryColor: AppColors.primaryBlue,
              scaffoldBackgroundColor: AppColors.backgroundColor,
              fontFamily: 'Roboto',
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.textDark),
                titleTextStyle: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textDark,
              ),
            ),
            home: Builder(
              builder: (BuildContext context) {
                return WelcomePage(
                  onContinue: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => HomeScreen(camera: camera)),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SecurityErrorScreen extends StatelessWidget {
  const SecurityErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDECEA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_update_warning, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                "SECURITY ALERT",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                "The application models have been tampered with or are corrupted. The app cannot function in this state for your safety.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Exit Application", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
