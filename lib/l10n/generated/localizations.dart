import 'localizations_en.dart';
import 'localizations_pt.dart';
import 'localizations_zh.dart';
import 'localizations_zh_tw.dart';

/// Callers can lookup localized strings with an instance of ReviLocalizations
/// returned by `ReviLocalizations.of(context)`.
	@@ -90,7 +91,8 @@ abstract class ReviLocalizations {
  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
    Locale('zh')
    Locale('zh_tw')
  ];

  /// The title for the unsupported build dialog
	@@ -637,7 +639,7 @@ class _ReviLocalizationsDelegate extends LocalizationsDelegate<ReviLocalizations
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt', 'zh','zh_tw'].contains(locale.languageCode);

  @override
  bool shouldReload(_ReviLocalizationsDelegate old) => false;
	@@ -650,6 +652,7 @@ ReviLocalizations lookupReviLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return ReviLocalizationsEn();
    case 'pt': return ReviLocalizationsPt();
    case 'zh': return ReviLocalizationsZh();
    case 'zh_tw': return ReviLocalizationsZh_tw();
  }

  throw FlutterError(