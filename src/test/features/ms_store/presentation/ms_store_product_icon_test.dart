import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/ms_store/presentation/widgets/ms_store_product_icon.dart';

void main() {
  test('hero tag ignores the case of the product ID', () {
    expect(MSStoreProductIcon.heroTag('9nblggh5r558'), MSStoreProductIcon.heroTag('9NBLGGH5R558'));
  });

  test('hero tags differ between products', () {
    expect(
      MSStoreProductIcon.heroTag('9NBLGGH5R558'),
      isNot(MSStoreProductIcon.heroTag('9WZDNCRFJ3TJ')),
    );
  });

  testWidgets('shows the placeholder and no hero when there is no icon', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: .ltr,
        child: MSStoreProductIcon(
          productId: '9NBLGGH5R558',
          iconUrl: '',
          size: 64,
          placeholder: Text('placeholder'),
        ),
      ),
    );

    expect(find.text('placeholder'), findsOneWidget);
    expect(find.byType(Hero), findsNothing);
  });
}
