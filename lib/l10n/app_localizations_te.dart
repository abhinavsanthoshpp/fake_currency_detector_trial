// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get homeTitle => 'DeepScan';

  @override
  String get scanHistory => 'స్కాన్ చరిత్ర';

  @override
  String get authentic => 'ప్రామాణికమైన';

  @override
  String get suspicious => 'అనుమానాస్పదం';

  @override
  String get scanAnotherCurrency => 'మరో కరెన్సీని స్కాన్ చేయండి';

  @override
  String get scanResults => 'స్కాన్ ఫలితాలు';

  @override
  String get confidenceLevel => 'విశ్వసనీయత స్థాయి';

  @override
  String get scanned => 'స్కాన్ చేయబడింది';

  @override
  String get currency => 'కరెన్సీ';

  @override
  String get status => 'స్థితి';

  @override
  String get clearAllHistory => 'అన్ని చరిత్రను క్లియర్ చేయండి';

  @override
  String get areYouSure =>
      'మీరు నిజంగా అన్ని స్కాన్ చరిత్రను తొలగించాలనుకుంటున్నారా?';

  @override
  String get cancel => 'రద్దు చేయండి';

  @override
  String get clearAll => 'అన్నీ క్లియర్ చేయండి';

  @override
  String get noScanHistory => 'ఇంకా స్కాన్ చరిత్ర లేదు';

  @override
  String get startScanning =>
      'చరిత్రను చూడటానికి కరెన్సీ స్కాన్ చేయడం ప్రారంభించండి';

  @override
  String scanSaved(String currency, String status) {
    return 'స్కాన్ సేవ్ చేయబడింది: $currency - $status';
  }

  @override
  String get errorTakingPicture => 'చిత్రం తీయడంలో లోపం';

  @override
  String get settings => 'సెట్టింగులు';

  @override
  String get language => 'భాష';

  @override
  String get support => 'మద్దతు';

  @override
  String get help => 'సహాయం';

  @override
  String get about => 'గురించి';

  @override
  String get home => 'హోమ్';

  @override
  String get scan => 'స్కాన్';

  @override
  String get history => 'చరిత్ర';

  @override
  String get welcomeTitle => 'డీప్‌స్కాన్‌కు స్వాగతం';

  @override
  String get welcomeSubtitle => 'ఉపయోగించి నోట్లను ధృవీకరించండి';

  @override
  String get lightingTip =>
      'మంచి ఫలితాల కోసం ఉత్తమ లైటింగ్‌ను నిర్ధారించండి మరియు నోట్ ఎడ్జ్‌లను సరిపోసుకోండి';

  @override
  String get viewAll => 'అన్నీ చూడండి';

  @override
  String get recentScans => 'తాజా స్కాన్‌లు';

  @override
  String get liveScanSubtitle => 'ఎడ్జ్ గైడెన్స్‌తో రియల్-టైమ్ డిటెక్షన్';

  @override
  String get liveScanTitle => 'లైవ్ బ్యాంక్‌నోట్ స్కాన్';

  @override
  String get quickActions => 'త్వరిత చర్యలు';
}
