import 'package:revitool/i18n/generated/strings.g.dart';

class LocaleConfig {
  LocaleConfig._();

  static const languageNames = {
    'en': 'English',
    'ptBr': 'Portuguese (Brazil)',
    'ptPt': 'Portuguese (Portugal)',
    'zhCn': 'Chinese (Simplified)',
    'zhTw': 'Chinese (Traditional)',
    'de': 'German',
    'fr': 'French',
    'ru': 'Russian',
    'uk': 'Ukrainian',
    'hu': 'Hungarian',
    'tr': 'Turkish',
    'ar': 'Arabic',
    'it': 'Italian',
    'ro': 'Romanian',
  };

  static AppLocale parse(String name) {
    try {
      return AppLocale.values.byName(name);
    } catch (e) {
      return AppLocale.en;
    }
  }
}
