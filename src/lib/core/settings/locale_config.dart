import '../../i18n/generated/strings.g.dart';

final class LocaleConfig._() {
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
    'es': 'Spanish (International)',
    'pl': 'Polish',
  };

  static AppLocale parse(String name) {
    try {
      return .values.byName(name);
    } catch (e) {
      return .en;
    }
  }
}
