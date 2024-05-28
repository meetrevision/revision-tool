import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/models/ms_store/packages_info.dart';
import 'package:revitool/models/ms_store/search_response.dart';
import 'package:revitool/services/msstore_service.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:revitool/widgets/dialogs/msstore_dialogs.dart';
import 'package:revitool/widgets/download_widget.dart';

class MSStorePage extends StatefulWidget {
  const MSStorePage({super.key});

  @override
  State<MSStorePage> createState() => _MSStorePageState();
}

class _MSStorePageState extends State<MSStorePage>
    with AutomaticKeepAliveClientMixin<MSStorePage> {
  final _textEditingController = TextEditingController();
  List<ProductsList> _productsList = [];
  final _msStoreService = MSStoreService();
  String _selectedRing = "RP";

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _onSearchButtonPressed() async {
    final query = _textEditingController.text;

    if (query.startsWith("9") || query.startsWith("XP")) {
      await showInstallDialog(
          context, context.l10n.msstoreSearchingPackages, query, _selectedRing);
    } else if (query.startsWith('https://') &&
        query.contains('microsoft.com')) {
      final uri = Uri.parse(query);
      final productId = uri.pathSegments.last;
      // debugPrint(productId);
      await showInstallDialog(context, context.l10n.msstoreSearchingPackages,
          productId, _selectedRing);
    } else {
      final data = await _msStoreService.searchProducts(query, _selectedRing);

      setState(() {
        _productsList = data;
      });
    }
  }

  static const items2 = [
    ComboBoxItem(
      value: "Retail",
      child: Text("Retail (Base)"),
    ),
    ComboBoxItem(
      value: "RP",
      child: Text("Release Preview"),
    ),
    ComboBoxItem(
      value: "WIS",
      child: Text("Insider Slow"),
    ),
    ComboBoxItem(
      value: "WIF",
      child: Text("Insider Fast"),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: InfoLabel(
          labelStyle: context.theme.typography.title,
          label: context.l10n.pageMSStore,
          child: Text(
            context.l10n.experimental,
            style: context.theme.typography.body,
          ),
        ),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: TextBox(
                controller: _textEditingController,
                placeholder: context.l10n.search,
                expands: false,
                onSubmitted: (value) async => await _onSearchButtonPressed(),
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
          if (product.displayPrice == "Free") ...[
            CardHighlight(
              label: product.title,
              image: product.iconUrl!,
              description: product.description,
              child: FilledButton(
                child: Text(context.l10n.install),
                onPressed: () async {
                  await showInstallDialog(
                    context,
                    context.l10n.msstoreSearchingPackages,
                    product.productId!,
                    _selectedRing,
                  );
                },
              ),
            )
          ],
        ]
      ],
    );
  }

  Future<void> showInstallDialog(BuildContext context, String loadingTitle,
      String productID, String ring) async {
    showLoadingDialog(context, context.l10n.msstoreSearchingPackages);

    await _msStoreService.startProcess(productID, _selectedRing);

    if (!context.mounted) return;
    Navigator.pop(context);

    if (_msStoreService.packages.isEmpty) {
      showNotFound(context);
      return;
    }
    showSelectPackages(productID);
  }

  void showSelectPackages(String productId) async {
    final packages = _msStoreService.packages;
    final List<TreeViewItem> items = List.generate(
      packages.length,
      (index) => TreeViewItem(
        value: index,
        selected: packages.elementAt(index).name!.contains("neutral") ||
            packages.elementAt(index).name!.contains("x64"),
        content: Text(packages.elementAt(index).name!),
      ),
    );

    // TODO: Add checkbox to clean up after install
    bool cleanUp = true;

    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 600),
        title: Text(context.l10n.msstorePackagesPrompt),
        content: TreeView(
          selectionMode: TreeViewSelectionMode.multiple,
          shrinkWrap: true,
          items: items,
        ),
        actions: [
          FilledButton(
            child: Text(context.l10n.okButton),
            onPressed: () async {
              final downloadList = <PackagesInfo>[];
              for (final item in items) {
                if (item.selected!) {
                  downloadList.add(packages.elementAt(item.value));
                }
              }
              if (downloadList.isEmpty) {
                Navigator.pop(context, 'Download list is empty');
                return;
              }

              if (!context.mounted) return;
              Navigator.pop(context);

              await showDialog(
                context: context,
                dismissWithEsc: false,
                builder: (context) => DownloadWidget(
                  items: downloadList,
                  productId: productId,
                  cleanUpAfterInstall: cleanUp,
                  ring: _selectedRing,
                ),
              );

              if (!context.mounted) return;
              Navigator.pop(context, 'Successfully downloaded');
            },
          ),
          Button(
            child: Text(context.l10n.close),
            onPressed: () => Navigator.pop(context, 'User canceled dialog'),
          ),
        ],
      ),
    );
    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;
}
