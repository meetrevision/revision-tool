import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';

extension BuildContextExtensions on BuildContext {
  ReviLocalizations get l10n => ReviLocalizations.of(this);

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  FluentThemeData get theme => FluentTheme.of(this);

  void pop<T extends Object?>([T? result]) {
    return Navigator.of(this).pop(result);
  }
}
