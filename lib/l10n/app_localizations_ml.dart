// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get homeTitle => 'DeepScan';

  @override
  String get scanHistory => 'സ്കാന്‍ ചരിത്രം';

  @override
  String get authentic => 'യഥാർത്ഥം';

  @override
  String get suspicious => ' സംശയാസ്പദം';

  @override
  String get scanAnotherCurrency => 'മറ്റൊരു കറൻസി സ്കാൻ ചെയ്യുക';

  @override
  String get scanResults => 'സ്കാൻ ഫലങ്ങൾ';

  @override
  String get confidenceLevel => 'വിശ്വാസ്യത നില';

  @override
  String get scanned => 'സ്കാൻ ചെയ്തത്';

  @override
  String get currency => 'കറൻസി';

  @override
  String get status => 'സ്ഥിതി';

  @override
  String get clearAllHistory => 'എല്ലാ ചരിത്രവും ഇല്ലാതാക്കുക';

  @override
  String get areYouSure =>
      'നിങ്ങൾ വാസ്തവത്തിൽ എല്ലാ സ്കാൻ ചരിത്രവും മായ്ക്കുവാൻ ആഗ്രഹിക്കുന്നുവോ?';

  @override
  String get cancel => 'രദ്ദാക്കുക';

  @override
  String get clearAll => 'എല്ലാം നീക്കം ചെയ്യുക';

  @override
  String get noScanHistory => 'ഇതുവരെ സ്കാൻ ചരിത്രമില്ല';

  @override
  String get startScanning => 'ചരിത്രം കാണാൻ കറൻസി സ്കാൻ ചെയ്യൽ ആരംഭിക്കുക';

  @override
  String scanSaved(String currency, String status) {
    return 'സ്കാൻ സംഭരിച്ചു: $currency - $status';
  }

  @override
  String get errorTakingPicture => 'ചിത്രം എടുക്കുന്നതിൽ പിഴവ്';

  @override
  String get settings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get language => 'ഭാഷ';

  @override
  String get support => 'സഹായം';

  @override
  String get help => 'സഹായം';

  @override
  String get about => 'കുറിച്ച്';

  @override
  String get home => 'ഹോം';

  @override
  String get scan => 'സ്കാൻ';

  @override
  String get history => 'ചരിത്രം';

  @override
  String get welcomeTitle => 'ഡിപ്സ്കാനിലേക്ക് സ്വാഗതം';

  @override
  String get welcomeSubtitle =>
      'അപ്ലിക്കേഷൻ ഉപയോഗിച്ച് നോട്ടുകള്‍ പരിശോധിക്കുക';

  @override
  String get lightingTip =>
      'ഭേദപ്പെട്ട ഫലങ്ങൾക്കായി നല്ല വിളക്കിലും നോട്ടിന്റെ അറ്റങ്ങളിൽ ചേർത്തിടലും ഉറപ്പാക്കുക';

  @override
  String get viewAll => 'എല്ലാം കാണുക';

  @override
  String get recentScans => 'സമീപകാല സ്കാനുകൾ';

  @override
  String get liveScanSubtitle => 'എജ് ഗൈഡൻസോടെ റിയൽ-ടൈം കണ്ടെത്തൽ';

  @override
  String get liveScanTitle => 'ലൈവ് ബാങ്ക്‌നോട്ട് സ്കാൻ';

  @override
  String get quickActions => 'ത്വരിത നടപടി';
}
