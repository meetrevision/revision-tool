import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/win_registry_service.dart';
import '../../core/widgets/card_highlight.dart';
import '../../i18n/generated/strings.g.dart';
import '../../utils_gui.dart';
import 'msstore_service.dart';
import 'packages_info_dto.dart';
import 'search_response_dto.dart';
import 'widgets/ms_store_packages_download_widget.dart';
import 'widgets/msstore_dialogs.dart';

class MSStorePage extends StatefulWidget {
  const MSStorePage({super.key});

  @override
  State<MSStorePage> createState() => _MSStorePageState();
}

class _MSStorePageState extends State<MSStorePage> {
  final _textEditingController = TextEditingController();
  List<ProductsList> _productsList = [];
  final _msStoreService = MSStoreService();
  String _selectedRing = 'RP';

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _onSearchButtonPressed() async {
    final String query = _textEditingController.text;

    if (query.startsWith('9') || query.startsWith('XP')) {
      await showInstallDialog(
        context,
        t.msstoreSearchingPackages,
        query,
        _selectedRing,
      );
    } else if (query.startsWith('https://') &&
        query.contains('microsoft.com')) {
      final Uri uri = Uri.parse(query);
      final String productId = uri.pathSegments.last;
      // debugPrint(productId);
      await showInstallDialog(
        context,
        t.msstoreSearchingPackages,
        productId,
        _selectedRing,
      );
    } else {
      final List<ProductsList> data = await _msStoreService.searchProducts(
        query,
        _selectedRing,
      );

      setState(() {
        _productsList = data;
      });
    }
  }

  static const List<ComboBoxItem<String>> items2 = [
    ComboBoxItem(value: 'Retail', child: Text('Retail (Base)')),
    ComboBoxItem(value: 'RP', child: Text('Release Preview')),
    ComboBoxItem(value: 'WIS', child: Text('Insider Slow')),
    ComboBoxItem(value: 'WIF', child: Text('Insider Fast')),
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      children: [
        Row(
          children: [
            Expanded(
              child: TextBox(
                controller: _textEditingController,
                placeholder: t.search,
                onSubmitted: (value) async => _onSearchButtonPressed(),
              ),
            ),
            const SizedBox(width: 10),
            ComboBox<String>(
              value: _selectedRing,
              onChanged: (value) => setState(() => _selectedRing = value!),
              items: items2,
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final product in _productsList) ...[
          if (product.displayPrice == 'Free') ...[
            CardHighlight(
              label: product.title!,
              image: product.iconUrl,
              description: product.description,
              action: FilledButton(
                child: Text(t.install),
                onPressed: () async {
                  await showInstallDialog(
                    context,
                    t.msstoreSearchingPackages,
                    product.productId!,
                    _selectedRing,
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> showInstallDialog(
    BuildContext context,
    String loadingTitle,
    String productID,
    String ring,
  ) async {
    try {
      unawaited(showLoadingDialog(context, t.msstoreSearchingPackages));

      await _msStoreService.startProcess(productID, _selectedRing);

      if (!context.mounted) return;
      Navigator.pop(context);

      if (_msStoreService.packages.isEmpty) {
        await showNotFound(context);
        return;
      }
      await showSelectPackages(productID);
    } catch (e, _) {
      if (!context.mounted) return;
      context.pop(context);
      unawaited(
        showDialog(
          context: context,
          builder: (context) {
            return ContentDialog(
              content: Text('$e'),
              actions: [
                Button(
                  child: Text(t.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  Future<void> showSelectPackages(String productId) async {
    final Set<MSStorePackagesInfoDTO> packages = _msStoreService.packages;
    final List<TreeViewItem> items = List.generate(
      packages.length,
      (index) => TreeViewItem(
        value: index,
        selected:
            packages
                .elementAt(index)
                .fileModel!
                .fileName!
                .contains('neutral') ||
            packages
                .elementAt(index)
                .fileModel!
                .fileName!
                .contains(
                  WinRegistryService.cpuArch == 'amd64' ? 'x64' : 'arm64',
                ),
        content: Text(packages.elementAt(index).fileModel!.fileName!),
      ),
    );

    // TODO: Add checkbox to clean up after install
    // ignore: prefer_final_locals, omit_obvious_local_variable_types
    bool cleanUp = true;

    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 600),
        title: Text(t.msstorePackagesPrompt),
        content: TreeView(
          selectionMode: TreeViewSelectionMode.multiple,
          items: items,
        ),
        actions: [
          FilledButton(
            child: Text(t.okButton),
            onPressed: () async {
              final downloadList = <MSStorePackagesInfoDTO>[];
              for (final item in items) {
                if (item.selected!) {
                  downloadList.add(packages.elementAt(item.value as int));
                }
              }
              if (downloadList.isEmpty) {
                context.pop('Download list is empty');
                return;
              }

              if (!context.mounted) return;
              context.pop();

              await showDialog(
                context: context,
                dismissWithEsc: false,
                builder: (context) => MsStorePackagesDownloadWidget(
                  items: downloadList,
                  productId: productId.trim(),
                  cleanUpAfterInstall: cleanUp,
                  ring: _selectedRing,
                ),
              );

              if (!context.mounted) return;
              context.pop('Successfully downloaded');
            },
          ),
          Button(
            child: Text(t.close),
            onPressed: () => context.pop('User canceled dialog'),
          ),
        ],
      ),
    );
    setState(() {});
  }
}
