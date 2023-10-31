import 'package:fluent_ui/fluent_ui.dart';
import '../../l10n/generated/localizations.dart';
import '../../models/ms_store/search_response.dart';
import '../../widgets/card_highlight.dart';
import '../../models/ms_store/packages_info.dart';
import '../../services/msstore_service.dart';
import '../../widgets/dialogs/msstore_dialogs.dart';
import '../../widgets/download_widget.dart';

class MSStorePage extends StatefulWidget {
  const MSStorePage({super.key});

  @override
  State<MSStorePage> createState() => _MSStorePageState();
}

class _MSStorePageState extends State<MSStorePage>
    with AutomaticKeepAliveClientMixin<MSStorePage> {
  final TextEditingController _textEditingController = TextEditingController();
  List<ProductsList> _productsList = [];
  final MSStoreService _msStoreService = MSStoreService();
  String _selectedRing = "Retail";

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _onSearchButtonPressed() async {
    final query = _textEditingController.text;
    final data = await _msStoreService.searchProducts(query);

    setState(() {
      _productsList = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: InfoLabel(
          labelStyle: FluentTheme.of(context).typography.title,
          label: ReviLocalizations.of(context).pageMSStore,
          child: Text(ReviLocalizations.of(context).experimental,
              style: FluentTheme.of(context).typography.body),
        ),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: TextBox(
                  controller: _textEditingController,
                  placeholder: ReviLocalizations.of(context).search,
                  expands: false,
                  onSubmitted: (value) => _onSearchButtonPressed()),
            ),
            const SizedBox(width: 10),
            ComboBox<String>(
              value: _selectedRing,
              onChanged: (value) {
                setState(() {
                  _selectedRing = value!;
                });
              },
              items: const [
                ComboBoxItem(
                  value: "Retail",
                  child: Text("Retail (Stable)"),
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
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var product in _productsList) ...[
          if (product.displayPrice == "Free") ...[
            CardHighlight(
              label: product.title,
              image: product.iconUrl!,
              description: product.description,
              child: FilledButton(
                child: Text(ReviLocalizations.of(context).install),
                onPressed: () async {
                  showLoadingDialog(context,
                      ReviLocalizations.of(context).msstoreSearchingPackages);

                  final List<PackagesInfo> packages = await _msStoreService
                      .startProcess(product.productId!, _selectedRing);

                  if (!mounted) return;
                  Navigator.pop(context);
                  if (packages.isNotEmpty) {
                    showSelectPackages(product.productId!, packages);
                  } else {
                    showNotFound(context);
                  }
                },
              ),
            )
          ],
        ]
      ],
    );
  }

  void showSelectPackages(String productId, List<PackagesInfo> packages) async {
    final List<TreeViewItem> items = List.generate(
      packages.length,
      (index) => TreeViewItem(
        value: index,
        selected: packages[index].name!.contains("neutral") ||
            packages[index].name!.contains("x64"),
        content: Text(packages[index].name!),
      ),
    );

    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 600),
        title: Text(ReviLocalizations.of(context).msstorePackagesPrompt),
        content: TreeView(
          selectionMode: TreeViewSelectionMode.multiple,
          shrinkWrap: true,
          items: items,
        ),
        actions: [
          Button(
            child: Text(ReviLocalizations.of(context).okButton),
            onPressed: () async {
              final List<PackagesInfo> downloadList = [];
              for (var item in items) {
                if (item.selected!) {
                  downloadList.add(packages[item.value]);
                }
              }
              if (downloadList.isEmpty) {
                Navigator.pop(context, 'Download list is empty');
                return;
              }

              if (!mounted) return;
              Navigator.pop(context);

              await showDialog(
                context: context,
                dismissWithEsc: false,
                builder: (context) =>
                    DownloadWidget(items: downloadList, productId: productId),
              );

              if (!mounted) return;
              Navigator.pop(context, 'Successfully downloaded');
              // Delete file here
            },
          ),
          FilledButton(
            child: Text(ReviLocalizations.of(context).close),
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
