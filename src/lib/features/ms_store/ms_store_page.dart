import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/card_highlight.dart';
import '../../i18n/generated/strings.g.dart';
import '../../utils.dart';
import '../../utils_gui.dart';
import 'models/search/search_product.dart';
import 'ms_store_enums.dart';
import 'ms_store_providers.dart';
import 'widgets/ms_store_download_widget.dart';

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
    final String query = _textEditingController.text.trim();
    if (query.isEmpty) return;

    final String? productId = _extractProductId(query);
    if (productId != null) {
      await _showDownloadDialog(productId);
    } else {
      await ref.read(mSStoreSearchProvider.notifier).search(query);
    }
  }

  String? _extractProductId(String query) {
    if (query.startsWith('9') || query.startsWith('XP')) {
      return query;
    }
    if (query.startsWith('https://') && query.contains('microsoft.com')) {
      final Uri? uri = Uri.tryParse(query);
      return uri?.pathSegments.lastOrNull;
    }
    return null;
  }

  Future<void> _showDownloadDialog(String productId) async {
    await showDialog(
      context: context,
      dismissWithEsc: false,
      builder: (context) => MSStoreDownloadWidget(
        productId: productId,
        ring: _selectedRing,
        arch: MSStoreArch.auto,
      ),
    );
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
                // suffix: IconButton(
                //   icon: const Icon(FluentIcons.search),
                //   onPressed: _onSearchButtonPressed,
                // ),
              ),
            ),
            ComboBox<MSStoreRing>(
              value: _selectedRing,
              onChanged: (value) => setState(() => _selectedRing = value!),
              items: MSStoreRing.items,
            ),
          ],
        ),
        const SizedBox(height: 20),
        searchState.when(
          data: (products) => Column(
            children: products
                .map((product) => _buildProductCard(product))
                .toList(),
          ),
          loading: () => const Center(child: ProgressRing()),
          error: (err, stack) {
            logger.e('Error searching MS Store: $err; $stack');
            return Center(child: Text(err.toString()));
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(SearchProduct product) {
    if (product.displayPrice != 'Free') return const SizedBox.shrink();

    return CardHighlight(
      label: product.title ?? 'Unknown',
      image: product.iconUrl,
      description: _firstParagraph(product.description),
      action: FilledButton(
        child: Text(t.install),
        onPressed: () => _showDownloadDialog(product.productId!),
      ),
    );
  }

  String? _firstParagraph(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    final String cleaned = text.replaceAll('\r\n', '\n').trim();
    final List<String> parts = cleaned.split(RegExp(r'\n\s*\n'));
    return parts.first.trim();
  }
}
