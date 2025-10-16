import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'database/database_service.dart';
import 'providers/locale_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.init();

  // Open settings box for locale storage
  await Hive.openBox('settings');

  // Get available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(VeriScanProApp(camera: firstCamera));
}

class VeriScanProApp extends StatelessWidget {
  final CameraDescription camera;

  const VeriScanProApp({super.key, required this.camera});

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
          return MaterialApp(
            title: 'VeriScan Pro',
            debugShowCheckedModeBanner: false,

            // Localization
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
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textDark,
              ),
            ),
            home: HomeScreen(camera: camera),
          );
        },
      ),
    );
  }
}
