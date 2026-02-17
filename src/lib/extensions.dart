import 'package:fluent_ui/fluent_ui.dart';

extension BuildContextExtensions on BuildContext {
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get mqSize => MediaQuery.sizeOf(this);

  FluentThemeData get theme => FluentTheme.of(this);

  // void pop<T extends Object?>([T? result]) {
  //   return Navigator.of(this).pop(result);
  // }
}

extension WidgetListSpacing on List<Widget> {
  /// Adds spacing between widgets in a list.
  ///
  /// Use [direction] to specify Axis.vertical (Column) or Axis.horizontal (Row).
  List<Widget> withSpacing(double spacing, {Axis direction = Axis.vertical}) {
    if (isEmpty || spacing == 0) return this;

    final spacedChildren = <Widget>[];
    for (var i = 0; i < length; i++) {
      spacedChildren.add(this[i]);
      if (i < length - 1) {
        spacedChildren.add(
          direction == Axis.vertical
              ? SizedBox(height: spacing)
              : SizedBox(width: spacing),
        );
      }
    }
    return spacedChildren;
  }
}

extension ImageCacheSize on num {
  int cacheSize(BuildContext context) {
    return (this * MediaQuery.devicePixelRatioOf(context)).round();
  }
}
