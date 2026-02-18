import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../i18n/generated/strings.g.dart';
import '../../utils.dart';
import '../../utils_gui.dart';
import 'models/search/search_product.dart';
import 'ms_store_enums.dart';
import 'ms_store_providers.dart';
import 'widgets/ms_store_product_card.dart';

class MSStorePage extends ConsumerStatefulWidget {
  const MSStorePage({super.key});

  @override
  ConsumerState<MSStorePage> createState() => _MSStorePageState();
}

class _MSStorePageState extends ConsumerState<MSStorePage> {
  final _textEditingController = TextEditingController();
  MSStoreRing _selectedRing = .releasePreview; // Default to RP

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _onSearchButtonPressed() async {
    final String query = _textEditingController.text.toLowerCase().trim();
    if (query.isEmpty) return;

    final String? productId = _extractProductId(query);
    if (productId != null) {
      await context.push('${RouteMeta.msStore.path}/product/$productId');
    } else {
      await ref.read(mSStoreSearchProvider.notifier).search(query);
    }
  }

  String? _extractProductId(String query) {
    if (query.startsWith('9') || query.startsWith('xp')) {
      return query;
    }
    if (query.startsWith('https://') && query.contains('microsoft.com')) {
      final Uri? uri = Uri.tryParse(query);
      return uri?.pathSegments.lastOrNull;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<SearchProduct>> searchState = ref.watch(
      mSStoreSearchProvider,
    );

    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      children: [
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: TextBox(
                controller: _textEditingController,
                placeholder: t.search,
                onSubmitted: (_) => _onSearchButtonPressed(),
              ),
            ),
            ComboBox<MSStoreRing>(
              value: _selectedRing,
              onChanged: (value) => setState(() => _selectedRing = value!),
              items: MSStoreRing.values
                  .map(
                    (ring) =>
                        ComboBoxItem(value: ring, child: Text(ring.label)),
                  )
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        searchState.when(
          data: (products) => _ProductGrid(products: products),
          loading: () => const Center(child: ProgressRing()),
          error: (err, stack) {
            logger.e('Error searching MS Store: $err; $stack');
            return Center(child: Text(err.toString()));
          },
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<SearchProduct> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cardWidth = 366.0;
        const spacing = 15.0;
        final double maxWidth = constraints.maxWidth;

        final int columns = ((maxWidth + spacing) / (cardWidth + spacing))
            .floor()
            .clamp(1, 4);

        final double actualWidth =
            (maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final product in products)
              if (product.displayPrice == 'Free')
                // Mandatory to prevent unnecessary rebuilds of the entire grid when an item is in extended hover state (_extendedHoverNotifier)
                RepaintBoundary(
                  child: SizedBox(
                    width: actualWidth,
                    child: _ProductCard(product: product),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final SearchProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MSStoreProductCard(
      product: product,
      onPressed: () => _openProductDetails(context, product),
    );
  }

  void _openProductDetails(BuildContext context, SearchProduct product) {
    final String? productId = product.productId;
    if (productId == null || productId.isEmpty) return;
    context.push(
      '${RouteMeta.msStore.path}/product/$productId',
      extra: product,
    );
  }
}
