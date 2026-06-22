import 'package:fluent_ui/fluent_ui.dart';

extension ImageCacheSize on num {
  int cacheSize(BuildContext context) {
    return (this * MediaQuery.devicePixelRatioOf(context)).round();
  }
}
