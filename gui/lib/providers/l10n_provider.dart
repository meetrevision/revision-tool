import 'package:fluent_ui/fluent_ui.dart';

class L10nProvider with ChangeNotifier {
  L10nProvider(String initialLocale) {
    _locale = initialLocale;
  }

  late String _locale;
  String get localeStr => _locale;
  Locale get locale => Locale(_locale.split("_")[0], _locale.split("_")[1]);

  void changeLocale(String newLocale) {
    _locale = newLocale;
    notifyListeners();
  }
}
