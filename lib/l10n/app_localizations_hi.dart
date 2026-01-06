// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get homeTitle => 'DeepScan';

  @override
  String get scanHistory => 'स्कैन इतिहास';

  @override
  String get authentic => 'प्रामाणिक';

  @override
  String get suspicious => 'संदिग्ध';

  @override
  String get scanAnotherCurrency => 'दूसरी करेंसी स्कैन करें';

  @override
  String get scanResults => 'स्कैन परिणाम';

  @override
  String get confidenceLevel => 'विश्वसनीयता स्तर';

  @override
  String get scanned => 'स्कैन किया गया';

  @override
  String get currency => 'करेंसी';

  @override
  String get status => 'स्थिति';

  @override
  String get clearAllHistory => 'सभी इतिहास साफ़ करें';

  @override
  String get areYouSure => 'क्या आप वाकई सभी स्कैन इतिहास हटाना चाहते हैं?';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get clearAll => 'सभी साफ़ करें';

  @override
  String get noScanHistory => 'अभी तक कोई स्कैन इतिहास नहीं';

  @override
  String get startScanning => 'इतिहास देखने के लिए करेंसी स्कैन करना शुरू करें';

  @override
  String scanSaved(String currency, String status) {
    return 'स्कैन सेव हुआ: $currency - $status';
  }

  @override
  String get errorTakingPicture => 'तस्वीर लेने में त्रुटि';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get support => 'सहायता';

  @override
  String get help => 'मदद';

  @override
  String get about => 'के बारे में';

  @override
  String get home => 'होम';

  @override
  String get scan => 'स्कैन';

  @override
  String get history => 'इतिहास';

  @override
  String get welcomeTitle => 'डिप्स्कैन में आपका स्वागत है';

  @override
  String get welcomeSubtitle => 'नोटों के सत्यापन के लिए एमएल का उपयोग करें';

  @override
  String get lightingTip =>
      'श्रेष्ठ परिणामों के लिए अच्छी रोशनी सुनिश्चित करें और नोट के किनारों को संरेखित करें';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get recentScans => 'हाल के स्कैन';

  @override
  String get liveScanSubtitle => 'एज गाइडेंस के साथ रीयल-टाइम डिटेक्शन﻿';

  @override
  String get liveScanTitle => 'लाइव बैंकनोट स्कैन';

  @override
  String get quickActions => 'त्वरित क्रियाएं';
}
