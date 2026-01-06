// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeTitle => 'DeepScan';

  @override
  String get scanHistory => 'Scan History';

  @override
  String get authentic => 'Authentic';

  @override
  String get suspicious => 'Suspicious';

  @override
  String get scanAnotherCurrency => 'Scan Another Currency';

  @override
  String get scanResults => 'Scan Results';

  @override
  String get confidenceLevel => 'Confidence Level';

  @override
  String get scanned => 'Scanned';

  @override
  String get currency => 'Currency';

  @override
  String get status => 'Status';

  @override
  String get clearAllHistory => 'Clear All History';

  @override
  String get areYouSure => 'Are you sure you want to delete all scan history?';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearAll => 'Clear All';

  @override
  String get noScanHistory => 'No scan history yet';

  @override
  String get startScanning => 'Start scanning currency to see history';

  @override
  String scanSaved(String currency, String status) {
    return 'Scan saved: $currency - $status';
  }

  @override
  String get errorTakingPicture => 'Error taking picture';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get support => 'Support';

  @override
  String get help => 'Help';

  @override
  String get about => 'About';

  @override
  String get home => 'Home';

  @override
  String get scan => 'Scan';

  @override
  String get history => 'History';

  @override
  String get welcomeTitle => 'Welcome to DeepScan';

  @override
  String get welcomeSubtitle => 'verify notes using ml';

  @override
  String get lightingTip =>
      'Ensure good lighting and align note edges for best results';

  @override
  String get viewAll => 'View all';

  @override
  String get recentScans => 'Recent Scans';

  @override
  String get liveScanSubtitle => 'Real-time detection with edge guidance';

  @override
  String get liveScanTitle => 'Live Banknote Scan';

  @override
  String get quickActions => 'Quick Actions';
}
