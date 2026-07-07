import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/routing/app_routes.dart';

void main() {
  test('tweak controller is exposed as a searchable tweak route', () {
    expect(RouteMeta.tweaksController.path, '/tweaks/controller');
    expect(
      AppRoutes.searchableItems.map((item) => item.key),
      contains(const ValueKey<String>('/tweaks/controller')),
    );
  });
}
