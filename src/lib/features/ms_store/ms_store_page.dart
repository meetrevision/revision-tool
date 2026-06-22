import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../i18n/generated/strings.g.dart';
import '../../utils_gui.dart';
import 'models/search/search_product.dart';
import 'store_enums.dart';
import 'store_providers.dart';
import 'widgets/ms_store_product_card.dart';

class MSStorePage extends ConsumerStatefulWidget {
  const MSStorePage({super.key});

  @override
  ConsumerState<MSStorePage> createState() => _MSStorePageState();
}

class _MSStorePageState extends ConsumerState<MSStorePage> {
  final _textEditingController = TextEditingController();
  static const _spacing = 16.0;

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
      await ref.read(storeControllerProvider.notifier).search(query);
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
      storeControllerProvider.select((s) => s.search),
    );
    final StoreRing selectedRing = ref.watch(
      storeControllerProvider.select((s) => s.ring),
    );

    return ScaffoldPage(
      padding: kScaffoldPagePadding,
      header: Padding(
        padding: kScaffoldPagePadding.copyWith(bottom: 20.45),
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
            ComboBox<StoreRing>(
              value: selectedRing,
              onChanged: (value) {
                if (value == null) return;
                ref.read(storeControllerProvider.notifier).setRing(value);
              },
              items: StoreRing.values.map((ring) {
                return ComboBoxItem(value: ring, child: Text(ring.label));
              }).toList(),
            ),
          ],
        ),
      ),

      content: searchState.when(
        data: (products) {
          if (products.isEmpty) return const SizedBox.shrink();

          return LayoutBuilder(
            builder: (context, constraints) {
              final int crossAxisCount =
                  (constraints.maxWidth /
                          (MSStoreProductCard.cardHeight / 1.22 + _spacing))
                      .floor()
                      .clamp(1, 6);

              return GridView.count(
                padding: kScaffoldPagePadding,
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: _spacing,
                crossAxisSpacing: _spacing,
                children: products
                    .map((p) {
                      return MSStoreProductCard(
                        product: p,
                        onPressed: () {
                          if (p.productId == null || p.productId!.isEmpty) {
                            return;
                          }
                          context.push(
                            '${RouteMeta.msStore.path}/product/${p.productId}',
                            extra: p,
                          );
                        },
                      );
                    })
                    .toList(growable: false),
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
