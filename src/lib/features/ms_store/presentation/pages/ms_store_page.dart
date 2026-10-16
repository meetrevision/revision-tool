import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../../../../utils_gui.dart';
import '../../domain/entities/search_product.dart';
import '../../domain/entities/store_enums.dart';

import '../providers/store_providers.dart';
import '../widgets/ms_store_product_card.dart';

class const MSStorePage({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<MSStorePage> createState() => _MSStorePageState();
}

class _MSStorePageState() extends ConsumerState<MSStorePage> {
  final _textEditingController = TextEditingController();
  static const _spacing = 18.0;
  static const _maxColumns = 6;

  static const _resultsTopGap = 18.0;

  static final EdgeInsets _horizontalPagePadding = kScaffoldPagePadding.copyWith(top: 0, bottom: 0);

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
      await ref.read(storeSearchProvider.notifier).search(query);
    }
  }

  void _openProduct(SearchProduct product) {
    if (product.id.isEmpty) return;
    unawaited(context.push('${RouteMeta.msStore.path}/product/${product.id}', extra: product));
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
    final AsyncValue<IList<SearchProduct>> searchState = ref.watch(storeSearchProvider);
    final StoreRing selectedRing = ref.watch(storeControllerProvider.select((s) => s.ring));

    return ScaffoldPage(
      padding: EdgeInsets.only(top: kScaffoldPagePadding.top),
      header: Padding(
        padding: _horizontalPagePadding,
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: TextBox(
                controller: _textEditingController,
                placeholder: t.search,
                onSubmitted: (_) => _onSearchButtonPressed(),
              ),
            ),
            Semantics(
              label: t.msstoreRing,
              child: ComboBox<StoreRing>(
                value: selectedRing,
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(storeControllerProvider.notifier).setRing(value);
                },
                items: StoreRing.values.map((ring) {
                  return ComboBoxItem(value: ring, child: Text(ring.label));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      content: searchState.when(
        data: (products) {
          if (products.isEmpty) return const SizedBox.shrink();

          return LayoutBuilder(
            builder: (context, constraints) {
              final double gridWidth = constraints.maxWidth - kScaffoldPagePadding.horizontal;
              final int crossAxisCount =
                  ((gridWidth + _spacing) / (MSStoreProductCard.idealWidth + _spacing))
                      .round()
                      .clamp(1, _maxColumns);
              final double cardWidth =
                  (gridWidth - _spacing * (crossAxisCount - 1)) / crossAxisCount;

              return GridView.builder(
                padding: kScaffoldPagePadding.copyWith(top: _resultsTopGap),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: _spacing,
                  crossAxisSpacing: _spacing,
                  mainAxisExtent: MSStoreProductCard.heightFor(
                    cardWidth,
                    MediaQuery.textScalerOf(context),
                  ),
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final SearchProduct product = products[index];
                  return MSStoreProductCard(
                    product: product,
                    onPressed: () => _openProduct(product),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: ProgressRing()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
