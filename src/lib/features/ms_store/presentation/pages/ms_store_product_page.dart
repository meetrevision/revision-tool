import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/result.dart';
import '../../../../core/extensions/int_bytes.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/settings/app_settings_provider.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/card_highlight.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../../../core/widgets/pips_pager.dart';
import '../../../../core/widgets/stacked_gradients.dart';
import '../../../../extensions.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../../../../utils_gui.dart';
import '../../../appx/domain/entities/appx_package.dart';
import '../../domain/entities/download_state.dart';
import '../../domain/entities/product_details.dart';
import '../../domain/entities/search_product.dart';
import '../../domain/entities/store_download_info.dart';
import '../providers/ms_store_image_provider.dart';
import '../providers/store_providers.dart';
import '../widgets/ms_store_download_widget.dart';
import '../widgets/ms_store_product_icon.dart';

const BorderRadius _borderRadiusTop = .only(topLeft: .circular(8), topRight: .circular(8));
const _heroIconSize = 100.0;
const _heroIconRadius = 8.0;
const _heroPadding = 40.0;
const _heroWideSpacing = 23.5;
const _heroNarrowSpacing = 12.0;
const _wideScreenBreakpoint = 550.0;

Color parseHexColor(String hexColor) {
  try {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  } catch (e) {
    return Colors.transparent;
  }
}

class const MSStoreProductPage({
  super.key,
  required final String productId,
  final SearchProduct? preview,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<MSStoreProductPage> createState() => _MSStoreProductPageState();
}

class _MSStoreProductPageState() extends ConsumerState<MSStoreProductPage> {
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _showStickyCard;

  final GlobalKey<State<StatefulWidget>> _heroIconKey = GlobalKey(debugLabel: 'Product icon');

  @override
  void initState() {
    super.initState();
    _showStickyCard = ValueNotifier(false);
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    final double heroHeight = MediaQuery.heightOf(context) * 0.6;
    final bool shouldShow = _scrollController.offset > heroHeight - 80;
    if (shouldShow != _showStickyCard.value) {
      _showStickyCard.value = shouldShow;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showStickyCard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProductDetails> detailsAsync = ref.watch(
      storeProductDetailsProvider(widget.productId),
    );

    return detailsAsync.when(
      data: (details) {
        return Stack(
          children: [
            ScaffoldPage.scrollable(
              padding: kScaffoldPagePadding,
              scrollController: _scrollController,
              children: _buildContent(context, ref, details),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _showStickyCard,
              builder: (context, visible, _) => _StickyCard(
                visible: visible,
                details: details,
                scrollController: _scrollController,
                onGet: () => _showInstallDialog(context, ref),
              ),
            ),
          ],
        );
      },
      loading: () => _ProductLoadingView(preview: widget.preview, iconKey: _heroIconKey),
      error: (error, stack) => ScaffoldPage.scrollable(
        padding: kScaffoldPagePadding,
        children: [Center(child: Text(t.msstoreProductLoadError(error: error)))],
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, WidgetRef ref, ProductDetails details) {
    return [
      _HeroSection(
        details: details,
        iconKey: _heroIconKey,
        onGet: () => _showInstallDialog(context, ref),
      ),
      const SizedBox(height: 50),
      if (details.screenshots.isNotEmpty) ...[
        _ContentCards(
          title: t.msstoreScreenshots,
          content: _ScreenshotCarousel(screenshots: details.screenshots),
        ),
      ],
      if (details.description.isNotEmpty) ...[
        _ContentCards(title: t.description, content: Text(details.description)),
      ],
      if (details.averageRating != null || details.ratingCount != null) ...[
        _ContentCards(
          title: t.ratingAndReviews,
          content: _RatingSection(details: details),
        ),
      ],
      if (details.features.isNotEmpty) ...[
        _ContentCards(title: t.features, content: Text(details.features.join('\n'))),
      ],
      if (details.systemRequirements?.minimum != null) ...[
        _ContentCards(
          title: t.systemRequirements,
          content: Text(
            details.systemRequirements!.minimum!.items.isEmpty
                ? 'N/A'
                : details.systemRequirements!.minimum!.items
                      .map((item) => '${item.name}: ${item.description}')
                      .join('\n'),
          ),
        ),
      ],

      _ContentCards(
        title: t.additionalInformation,
        content: _AdditionalInfoSection(details: details),
      ),
    ].withSpacing(24);
  }

  void _showInstallDialog(BuildContext context, WidgetRef ref) {
    ref
        .read(storeControllerProvider.notifier)
        .downloadAndInstall(
          productId: widget.productId,
          ring: ref.read(storeControllerProvider).ring,
        );
  }
}

class const _ContentCards({required final String title, required final Widget content})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: 24),
      child: Card(
        borderRadius: const .all(.circular(8)),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 10.5,
          children: [
            Padding(
              padding: const .symmetric(horizontal: 12),
              child: Text(
                title,
                style: context.theme.typography.bodyStrong!.copyWith(fontSize: 18),
              ),
            ),
            const Divider(
              size: .infinity,
              style: .new(verticalMargin: .zero, horizontalMargin: .zero),
            ),
            Padding(padding: const .symmetric(horizontal: 12), child: content),
          ],
        ),
      ),
    );
  }
}

class const _HeroSection({
  required final ProductDetails details,
  required final Key iconKey,
  required final VoidCallback onGet,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluentThemeData theme = context.theme;

    final FluentThemeData darkTheme = ref
        .read(appSettingsProvider.notifier)
        .buildDarkTheme(theme.accentColor, is10footScreen(context));

    const divider = Divider(size: 16, direction: .vertical);

    final bool isWideScreen = MediaQuery.widthOf(context) >= _wideScreenBreakpoint;
    final AsyncValue<IList<Color>?> paletteAsync = details.heroImageUrl.isNotEmpty
        ? ref.watch(msStoreProductPaletteProvider(details.id, details.heroImageUrl))
        : const AsyncValue.data(null);
    final Color iconUrlBackgroundColor = parseHexColor(details.iconUrlBackground);

    final decoratedBox = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: .topCenter,
          end: .bottomCenter,
          colors: [iconUrlBackgroundColor, context.theme.scaffoldBackgroundColor],
        ),
      ),
    );

    final double minHeight = MediaQuery.heightOf(context) * 0.6;

    return FluentTheme(
      data: darkTheme,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Stack(
          children: [
            Positioned.fill(
              child: _HeroBackground(
                builder: (_, onBannerFrame) => Stack(
                  fit: .expand,
                  children: [
                    if (details.heroImageUrl.isNotEmpty)
                      Align(
                        alignment: .centerRight,
                        child: ClipRRect(
                          clipBehavior: .hardEdge,
                          borderRadius: _borderRadiusTop,
                          child: _HeroBanner(
                            url: details.heroImageUrl,
                            height: minHeight,
                            onFrame: onBannerFrame,
                          ),
                        ),
                      ),
                    ClipRRect(
                      clipBehavior: .hardEdge,
                      borderRadius: _borderRadiusTop,
                      child: paletteAsync.when(
                        data: (palette) {
                          return palette != null && palette.isNotEmpty
                              ? Transform.scale(
                                  // without this and ClipRRect's clipBehavior set to hardEdge, RadialGradient renders edge border lines when the gradient's focal point is near the edge
                                  scale: 1.01,
                                  child: StackedGradient([
                                    RadialGradient(
                                      // center: const Alignment(0.99, 0.0),
                                      center: .centerRight,
                                      radius: 1.5,
                                      focal: isWideScreen ? .center : .topRight,
                                      colors: [
                                        Colors.transparent,
                                        palette.elementAt(1),
                                        palette.elementAt(1),
                                      ],
                                      stops: isWideScreen ? null : const [0, 0.1, 0.2],
                                    ),
                                    LinearGradient(
                                      begin: .center,
                                      end: .bottomCenter,
                                      colors: [
                                        palette.first.withAlpha(140),
                                        darkTheme.scaffoldBackgroundColor.withAlpha(50),
                                      ],
                                    ),
                                    LinearGradient(
                                      begin: .topLeft,
                                      end: .bottomRight,
                                      stops: const [0, 0.5, 1],
                                      colors: [
                                        darkTheme.scaffoldBackgroundColor.withAlpha(250),
                                        Colors.transparent,
                                        darkTheme.scaffoldBackgroundColor.withAlpha(250),
                                      ],
                                    ),
                                    LinearGradient(
                                      begin: .center,
                                      end: .bottomCenter,
                                      stops: const [0.2, 1],
                                      colors: [
                                        Colors.transparent,
                                        context.theme.scaffoldBackgroundColor,
                                      ],
                                    ),
                                  ]),
                                )
                              : decoratedBox;
                        },
                        loading: () => decoratedBox,
                        error: (_, _) => decoratedBox,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const .all(_heroPadding),
              child: Wrap(
                crossAxisAlignment: isWideScreen ? .start : .center,
                alignment: isWideScreen ? .start : .center,
                runSpacing: isWideScreen ? 16 : 0,
                spacing: 16,
                children: [
                  Flex(
                    direction: isWideScreen ? .horizontal : .vertical,
                    mainAxisSize: .min,
                    crossAxisAlignment: isWideScreen ? .start : .center,
                    spacing: isWideScreen ? _heroWideSpacing : _heroNarrowSpacing,
                    children: [
                      _HeroIcon(
                        key: iconKey,
                        productId: details.id,
                        iconUrl: details.iconUrl,
                        color: parseHexColor(details.iconUrlBackground),
                      ),
                      Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: isWideScreen ? .start : .center,
                        children: [
                          Text(
                            details.title.isEmpty ? t.msstoreUnknown : details.title,
                            style: darkTheme.typography.title!.copyWith(fontSize: 32),
                            maxLines: 2,
                            textAlign: isWideScreen ? .start : .center,
                          ),
                          if (details.publisherName.isNotEmpty)
                            Text(
                              details.publisherName,
                              style: darkTheme.typography.body!.copyWith(
                                fontSize: 14,
                                color: darkTheme.accentColor.lightest,
                              ),
                              textAlign: isWideScreen ? .start : .center,
                            ),
                          Row(
                            mainAxisSize: .min,
                            mainAxisAlignment: isWideScreen ? .start : .center,
                            spacing: 8,
                            children: [
                              if (details.averageRating != null) ...[
                                Text(
                                  details.averageRating!.toStringAsFixed(1),
                                  style: darkTheme.typography.body,
                                ),
                                Icon(
                                  msicons.FluentIcons.star_16_filled,
                                  size: 16,
                                  color: darkTheme.resources.textFillColorSecondary,
                                ),
                                divider,
                                Text(
                                  details.ratingCountFormatted!,
                                  style: darkTheme.typography.caption,
                                ),
                                divider,
                              ],
                              if (details.categories.isNotEmpty) ...[
                                Text(
                                  details.categories.first,
                                  style: darkTheme.typography.body!.copyWith(
                                    color: theme.accentColor.lightest,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: isWideScreen ? .start : .center,
                    spacing: 10,
                    children: [
                      if (details.description.isNotEmpty)
                        Padding(
                          padding: isWideScreen
                              ? .only(right: MediaQuery.widthOf(context) * 0.3)
                              : .zero,
                          child: Text(
                            details.description,
                            maxLines: 2,
                            overflow: .ellipsis,
                            style: darkTheme.typography.body,
                          ),
                        ),

                      _InstallActionBar(
                        productId: details.id,
                        title: details.title.isEmpty ? t.msstoreUnknown : details.title,
                        onGet: onGet,
                      ),

                      if (details.productRatings.isNotEmpty &&
                          details.productRatings.first.ratingId != 'Microsoft:E')
                        Wrap(
                          spacing: 12,
                          crossAxisAlignment: .end,
                          children: [
                            if (details.productRatings.first.ratingValueLogoUrl != null)
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: AppImage(
                                  fetchPadding: 0,
                                  baseUrl: details.productRatings.first.ratingValueLogoUrl!,
                                ),
                              ),
                            Column(
                              crossAxisAlignment: .start,
                              mainAxisSize: .min,
                              children: [
                                Text(
                                  details.productRatings.first.longName ?? '',
                                  style: theme.typography.bodyStrong,
                                ),
                                Text(
                                  details.productRatings.first.ratingDescriptors.join(', '),
                                  style: theme.typography.caption!.copyWith(
                                    color: theme.resources.textFillColorDisabled,
                                  ),
                                ),
                                Text(
                                  details.productRatings.first.interactiveElements.join(', '),
                                  style: theme.typography.caption!.copyWith(
                                    color: theme.resources.textFillColorDisabled,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _ShareButton({required final String productId}) extends StatefulWidget {
  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState() extends State<_ShareButton> {
  late final FlyoutController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = FlyoutController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (_finished) {
          setState(() => _finished = false);
        }
      },
      child: FlyoutTarget(
        controller: _controller,
        child: AnimatedSwitcher(
          duration: context.theme.fastAnimationDuration,
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: _finished
              ? const IconButton(
                  icon: Icon(msicons.FluentIcons.checkmark_20_regular, size: 20),
                  key: ValueKey('checkmark'),
                  onPressed: null,
                )
              : Tooltip(
                  message: t.share,
                  child: IconButton(
                    key: const ValueKey('share'),
                    icon: const Icon(msicons.FluentIcons.share_20_regular, size: 20),
                    onPressed: () {
                      _controller.showFlyout<void>(
                        autoModeConfiguration: .new(preferredMode: .bottomLeft),
                        barrierColor: Colors.transparent,
                        navigatorKey: rootNavigatorKey.currentState,
                        builder: (context) {
                          return MenuFlyout(
                            items: [
                              MenuFlyoutItem(
                                leading: const WindowsIcon(WindowsIcons.copy),
                                text: Text(t.msstoreCopyLink),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: 'https://apps.microsoft.com/detail/${widget.productId}',
                                    ),
                                  );
                                  setState(() => _finished = true);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class const _InstallActionBar({
  required final String productId,
  required final String title,
  required final VoidCallback onGet,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StoreDownloadState state = ref.watch(storeControllerProvider.select((s) => s.download));
    final bool active = state.isForProduct(productId);

    final String? familyName = ref.watch(storeProductPackageFamilyNameProvider(productId)).value;
    final AsyncValue<AppxPackage?> installedPackage = switch (familyName) {
      final name? => ref.watch(appxInstalledPackageProvider(name)),
      null => const .data(null),
    };
    final String? installedFamilyName = installedPackage.value != null ? familyName : null;

    final bool updateAvailable = switch ((installedFamilyName, installedPackage.value?.version)) {
      (final String name?, final String version?) =>
        ref.watch(storeProductUpdateAvailableProvider(productId, name, version)).value ?? false,
      _ => false,
    };

    if (familyName case final name?) {
      ref.listen(storeControllerProvider.select((s) => s.download), (_, next) {
        if (next.isForProduct(productId) && _isFinishedInstall(next)) {
          ref.invalidate(appxInstalledPackageProvider(name));
        }
      });
    }

    final bool staleInstall =
        familyName != null &&
        installedFamilyName == null &&
        !installedPackage.isLoading &&
        _isFinishedInstall(state);

    final VoidCallback? onOpen = switch (installedFamilyName) {
      final name? => () => unawaited(_openApp(context, ref, familyName: name)),
      null => null,
    };
    final VoidCallback? onUninstall = switch (installedFamilyName) {
      final name? => () => unawaited(_uninstallApp(context, ref, familyName: name, title: title)),
      null => null,
    };

    final bool isWideScreen = MediaQuery.widthOf(context) >= _wideScreenBreakpoint;

    return Wrap(
      crossAxisAlignment: .center,
      direction: isWideScreen ? .horizontal : .vertical,
      spacing: 10,
      runSpacing: 8,
      children: [
        _InstallPrimaryAction(
          productId: productId,
          state: active && !staleInstall ? state : const .idle(),
          onGet: onGet,
          onUpdate: updateAvailable ? onGet : null,
          onOpen: onOpen,
        ),
        Row(
          mainAxisSize: .min,
          children: [
            _ShareButton(productId: productId),
            _InstallMoreButton(
              productId: productId,
              onOpen: updateAvailable ? onOpen : null,
              onUninstall: onUninstall,
            ),
          ],
        ),
      ],
    );
  }
}

bool _isFinishedInstall(StoreDownloadState state) =>
    state.maybeWhen(completed: (_, _, installed) => installed, orElse: () => false);

bool _isSettled(StoreDownloadState state) => state.maybeWhen(
  preparing: (_, _) => false,
  downloading: (_, _, _, _, _, _) => false,
  paused: (_, _, _, _, _, _) => false,
  error: (_, _) => false,
  orElse: () => true,
);

Future<void> _openApp(BuildContext context, WidgetRef ref, {required String familyName}) async {
  final Result<void> result = await ref.read(appxServiceProvider).launch(familyName: familyName);
  if (!context.mounted) return;
  if (result case Failure(:final exception)) {
    await _showAppxError(context, t.msstoreOpenFailed(error: exception.message));
  }
}

Future<void> _uninstallApp(
  BuildContext context,
  WidgetRef ref, {
  required String familyName,
  required String title,
}) async {
  final bool confirmed =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: Text(t.msstoreUninstallTitle(name: title)),
          content: Text(t.msstoreUninstallDescription),
          actions: [
            FilledButton(
              child: Text(t.msstoreUninstall),
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
            Button(
              autofocus: true,
              child: Text(t.msstoreCancel),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) return;

  final NavigatorState dialogNavigator = Navigator.of(context, rootNavigator: true);
  unawaited(showLoadingDialog(context, t.msstoreUninstalling));
  final Result<Object?> result = await ref
      .read(appxServiceProvider)
      .uninstall(familyName: familyName);
  dialogNavigator.pop();

  if (!context.mounted) return;
  ref.invalidate(appxInstalledPackageProvider(familyName));
  if (result case Failure(:final exception)) {
    await _showAppxError(context, t.msstoreUninstallFailed(error: exception.message));
  } else {
    await SemanticsService.sendAnnouncement(
      View.of(context),
      t.msstoreUninstalled(name: title),
      Directionality.of(context),
    );
  }
}

Future<void> _showAppxError(BuildContext context, String message) {
  return displayInfoBar(
    context,
    builder: (context, close) => Semantics(
      liveRegion: true,
      child: InfoBar(
        title: Text(t.msstoreError),
        content: Text(message),
        severity: .error,
        onClose: close,
      ),
    ),
  );
}

class const _InstallPrimaryAction({
  required final String productId,
  required final StoreDownloadState state,
  required final VoidCallback onGet,
  final VoidCallback? onUpdate,
  final VoidCallback? onOpen,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget? installedAction = !_isSettled(state)
        ? null
        : switch ((onUpdate, onOpen)) {
            (final VoidCallback update?, _) => _PrimaryButton(
              key: const ValueKey('installed'),
              label: t.msstoreUpdate,
              onPressed: update,
            ),
            (null, final VoidCallback open?) => _PrimaryButton(
              key: const ValueKey('installed'),
              label: t.msstoreOpen,
              onPressed: open,
            ),
            (null, null) => null,
          };
    final Widget child =
        installedAction ??
        state.maybeWhen(
          preparing: (_, message) {
            final installing = message == t.msstoreInstalling;
            return _InstallProgressCard(
              key: const ValueKey('preparing'),
              progress: null,
              title: installing ? t.msstoreInstalling : t.msstorePreparingToDownload,
              subtitle: installing ? t.msstorePreparingInstaller : message ?? '',
              onCancel: () => ref.read(storeControllerProvider.notifier).cancel(),
            );
          },
          downloading: (_, progress, completed, total, downloadedBytes, totalBytes) =>
              _InstallProgressCard(
                key: const ValueKey('downloading'),
                progress: _overallProgress(progress, downloadedBytes, totalBytes),
                title: t.msstoreDownloading,
                subtitle: totalBytes > 0
                    ? t.msstoreDownloadedBytesProgress(
                        downloaded: downloadedBytes.formatBytes(),
                        total: totalBytes.formatBytes(),
                      )
                    : t.msstoreDownloadingPackages(completed: completed, total: total),
                onPause: () => ref.read(storeControllerProvider.notifier).pause(),
                onCancel: () => ref.read(storeControllerProvider.notifier).cancel(),
              ),
          paused: (_, progress, _, _, downloadedBytes, totalBytes) => _InstallProgressCard(
            key: const ValueKey('paused'),
            progress: _overallProgress(progress, downloadedBytes, totalBytes),
            paused: true,
            title: t.msstorePaused,
            subtitle: totalBytes > 0
                ? t.msstorePausedBytesProgress(
                    downloaded: downloadedBytes.formatBytes(),
                    total: totalBytes.formatBytes(),
                  )
                : t.msstorePaused,
            onResume: () => ref.read(storeControllerProvider.notifier).resume(),
            onCancel: () => ref.read(storeControllerProvider.notifier).cancel(),
          ),
          completed: (_, _, installed) => SizedBox(
            key: ValueKey(installed ? 'installed' : 'downloaded'),
            height: 52,
            width: 200,
            child: FilledButton(
              onPressed: installed
                  ? null
                  : () => ref.read(storeControllerProvider.notifier).installCurrentDownload(),
              child: Align(
                alignment: .centerLeft,
                child: Text(
                  installed ? t.msstoreInstalled : t.install,
                  style: const TextStyle(fontWeight: .bold),
                ),
              ),
            ),
          ),
          error: (_, _) => SizedBox(
            key: const ValueKey('error'),
            height: 52,
            width: 200,
            child: FilledButton(
              onPressed: onGet,
              child: Align(
                alignment: .centerLeft,
                child: Text(t.msstoreRetry, style: const TextStyle(fontWeight: .bold)),
              ),
            ),
          ),
          orElse: () => SizedBox(
            key: const ValueKey('get'),
            height: 52,
            width: 200,
            child: FilledButton(
              onPressed: onGet,
              child: Align(
                alignment: .centerLeft,
                child: Text(t.get, style: const TextStyle(fontWeight: .bold)),
              ),
            ),
          ),
        );

    return AnimatedSize(
      duration: context.theme.mediumAnimationDuration,
      curve: Curves.easeOutCubic,
      alignment: .centerLeft,
      child: AnimatedSwitcher(
        duration: context.theme.mediumAnimationDuration,
        reverseDuration: context.theme.fastAnimationDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final Animation<Offset> offset = Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: .zero,
          ).animate(animation);
          final Animation<double> scale = Tween<double>(begin: 0.98, end: 1).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offset,
              child: ScaleTransition(scale: scale, child: child),
            ),
          );
        },
        child: child,
      ),
    );
  }
}

/// Inline download/install status shown in place of the "Get" button.
///
/// Styled after the Microsoft Store: a neutral card with primary/secondary
/// text, a thin accent progress bar along the bottom edge, and subtle icon
/// buttons. Always rendered inside the hero's forced dark theme.
class const _InstallProgressCard({
  super.key,

  /// 0..1, or `null` for an indeterminate bar (preparing / installing).
  required final double? progress,
  required final String title,
  required final String subtitle,
  final bool paused = false,
  final VoidCallback? onPause,
  final VoidCallback? onResume,
  final VoidCallback? onCancel,
}) extends StatelessWidget {
  static const _width = 360.0;
  static const _height = 52.0;
  static const _barHeight = 3.0;
  static const _borderRadius = BorderRadius.all(Radius.circular(6));

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = context.theme;
    final ResourceDictionary resources = theme.resources;
    final double? clampedProgress = progress?.clamp(0, 1).toDouble();

    // Fluent fill/stroke tokens are already translucent (e.g. 5% white in dark
    // mode), so never override their alpha with withAlpha(): that is what made
    // this card an opaque light-gray slab under white text. Instead, lay the
    // control fill over an opaque base so the card stays readable on top of
    // busy hero artwork, then keep it just slightly see-through.
    final Color surfaceColor = Color.alphaBlend(
      resources.controlFillColorDefault,
      resources.solidBackgroundFillColorBase,
    ).withAlpha(235);

    final TextStyle titleStyle = theme.typography.bodyStrong!.copyWith(
      color: resources.textFillColorPrimary,
    );
    final TextStyle subtitleStyle = theme.typography.caption!.copyWith(
      color: resources.textFillColorSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return SizedBox(
      width: _width,
      height: _height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: _borderRadius,
          border: .all(color: resources.controlStrokeColorDefault),
        ),
        child: ClipRRect(
          borderRadius: _borderRadius,
          child: Stack(
            children: [
              Padding(
                padding: const .fromLTRB(14, 0, 6, _barHeight),
                child: Row(
                  spacing: 2,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: .center,
                        crossAxisAlignment: .start,
                        children: [
                          Row(
                            spacing: 8,
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                  style: titleStyle,
                                ),
                              ),
                              if (clampedProgress != null)
                                Text('${(clampedProgress * 100).floor()}%', style: subtitleStyle),
                            ],
                          ),
                          Text(subtitle, maxLines: 1, overflow: .ellipsis, style: subtitleStyle),
                        ],
                      ),
                    ),
                    if (onPause != null)
                      Tooltip(
                        message: t.msstorePause,
                        child: IconButton(
                          icon: const Icon(msicons.FluentIcons.pause_20_regular, size: 16),
                          onPressed: onPause,
                        ),
                      ),
                    if (onResume != null)
                      Tooltip(
                        message: t.msstoreResume,
                        child: IconButton(
                          icon: const Icon(msicons.FluentIcons.play_20_regular, size: 16),
                          onPressed: onResume,
                        ),
                      ),
                    if (onCancel != null)
                      Tooltip(
                        message: t.msstoreCancel,
                        child: IconButton(
                          icon: const Icon(msicons.FluentIcons.dismiss_20_regular, size: 16),
                          onPressed: onCancel,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ProgressBar(
                  value: clampedProgress == null ? null : clampedProgress * 100,
                  strokeWidth: _barHeight,
                  backgroundColor: resources.controlStrokeColorDefault,
                  // Matches WinUI's paused ProgressBar state.
                  activeColor: paused ? resources.systemFillColorCaution : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _InstallMoreButton({
  required final String productId,
  final VoidCallback? onOpen,
  final VoidCallback? onUninstall,
}) extends StatefulWidget {
  @override
  State<_InstallMoreButton> createState() => _InstallMoreButtonState();
}

class _InstallMoreButtonState() extends State<_InstallMoreButton> {
  late final FlyoutController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FlyoutController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: _controller,
      child: Tooltip(
        message: t.msstoreMoreInstallOptions,
        child: IconButton(
          icon: const Icon(msicons.FluentIcons.more_horizontal_20_regular),
          onPressed: () {
            _controller.showFlyout<void>(
              autoModeConfiguration: .new(preferredMode: .bottomLeft),
              barrierColor: Colors.transparent,
              navigatorKey: rootNavigatorKey.currentState,
              builder: (context) => _MoreMenuFlyout(
                productId: widget.productId,
                onOpen: widget.onOpen,
                onUninstall: widget.onUninstall,
              ),
            );
          },
        ),
      ),
    );
  }
}

class const _MoreMenuFlyout({
  required final String productId,
  final VoidCallback? onOpen,
  final VoidCallback? onUninstall,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MenuFlyout(
      items: [
        if (onOpen case final open?)
          MenuFlyoutItem(
            leading: const Icon(msicons.FluentIcons.open_20_regular),
            text: Text(t.msstoreOpen),
            onPressed: open,
          ),
        if (onUninstall case final uninstall?)
          MenuFlyoutItem(
            leading: const Icon(msicons.FluentIcons.delete_20_regular),
            text: Text(t.msstoreUninstall),
            onPressed: uninstall,
          ),
        if (onOpen != null || onUninstall != null) const MenuFlyoutSeparator(),
        MenuFlyoutItem(
          leading: const Icon(msicons.FluentIcons.line_horizontal_3_20_regular),
          text: Text(t.msstoreChoosePackagesEllipsis),
          onPressed: () {
            showDialog(
              context: context,
              dismissWithEsc: false,
              builder: (context) => StorePackagePickerDialog(productId: productId),
            );
          },
        ),
      ],
    );
  }
}

class const _PrimaryButton({
  super.key,
  required final String label,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  static const _height = 52.0;
  static const _width = 200.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      width: _width,
      child: FilledButton(
        onPressed: onPressed,
        child: Align(
          alignment: .centerLeft,
          child: Text(label, style: const TextStyle(fontWeight: .bold)),
        ),
      ),
    );
  }
}

double _overallProgress(IMap<String, double> fileProgress, int downloadedBytes, int totalBytes) {
  if (totalBytes > 0) return downloadedBytes / totalBytes;
  // Cached on the IMap instance, so repeated rebuilds within one 300ms
  // progress flush do not re-fold the whole map.
  return fileProgress.averageProgress;
}

/// Draws the banner and its gradients into an image once, so scrolling doesn't
/// redraw them every frame. Redrawn when it rebuilds or the banner loads.
class const _HeroBackground({
  required final Widget Function(BuildContext context, VoidCallback onBannerFrame) builder,
}) extends StatefulWidget {
  @override
  State<_HeroBackground> createState() => _HeroBackgroundState();
}

class _HeroBackgroundState() extends State<_HeroBackground> {
  final _snapshotController = SnapshotController(allowSnapshotting: true);

  @override
  void didUpdateWidget(_HeroBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _snapshotController.clear();
  }

  @override
  void dispose() {
    _snapshotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SnapshotWidget(
      controller: _snapshotController,
      mode: .permissive,
      autoresize: true,
      child: widget.builder(context, _snapshotController.clear),
    );
  }
}

class const _HeroBanner({
  required final String url,
  required final double height,
  required final VoidCallback onFrame,
}) extends StatelessWidget {
  static const double _aspectRatio = 16 / 9;

  static const _fetchStep = 120;

  @override
  Widget build(BuildContext context) {
    final double pixelHeight = height * MediaQuery.devicePixelRatioOf(context);
    final int fetchHeight = (pixelHeight / _fetchStep).ceil() * _fetchStep;

    return Image(
      image: MSStoreImageProvider(
        baseUrl: url,
        width: (fetchHeight * _aspectRatio).round(),
        height: fetchHeight,
        fetchPadding: 0,
      ),
      height: height,
      fit: .cover,
      alignment: .centerRight,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, _) {
        if (frame != null) onFrame();
        return child;
      },
    );
  }
}

class const _HeroIcon({
  super.key,
  required final String productId,
  required final String iconUrl,
  final Color? color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MSStoreProductIcon(
      productId: productId,
      iconUrl: iconUrl,
      size: _heroIconSize,
      borderRadius: _heroIconRadius,
      backgroundColor: color,
      placeholder: const DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
    );
  }
}

class const _StickyCard({
  required final bool visible,
  required final ProductDetails details,
  required final ScrollController scrollController,
  required final VoidCallback onGet,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          // padding: const .fromLTRB(12, 8, 12, 0),
          padding: kScaffoldPagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: CardHighlight(
                onPressed: () {
                  scrollController.animateTo(
                    0,
                    duration: context.theme.fastAnimationDuration,
                    curve: Curves.easeInOut,
                  );
                },
                backgroundColor: context.theme.resources.systemFillColorSolidNeutralBackground,
                image: details.iconUrl,
                label: details.title.isEmpty ? t.msstoreUnknown : details.title,
                description: details.publisherName.isEmpty
                    ? (details.categories.isNotEmpty ? details.categories.first : '')
                    : details.publisherName,
                action: IgnorePointer(
                  child: FilledButton(onPressed: () {}, child: Text(t.get)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class const _RatingSection({required final ProductDetails details}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double ratingValue = details.averageRating ?? 0;

    return Column(
      crossAxisAlignment: .start,
      spacing: 8,
      children: [
        Row(
          spacing: 12,
          children: [
            Column(
              children: [
                Text(
                  ratingValue.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 64, fontWeight: .bold),
                ),
                Text(
                  details.ratingCountFormatted.toString(),
                  style: TextStyle(
                    color: context.theme.resources.textFillColorSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            RatingBar(
              rating: ratingValue,
              ratedIconColor: context.theme.resources.systemFillColorCaution,
            ),
          ],
        ),
      ],
    );
  }
}

class const _ScreenshotCarousel({required final IList<ProductImage> screenshots})
    extends StatefulWidget {
  @override
  State<_ScreenshotCarousel> createState() => _ScreenshotCarouselState();
}

class _ScreenshotCarouselState() extends State<_ScreenshotCarousel> {
  final _pageController = PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PipsPager(
      itemExtent: 369,
      controller: _pageController,
      padEnds: false,
      previousButtonVisibility: .visibleOnPointerOver,
      nextButtonVisibility: .visibleOnPointerOver,
      onPageChanged: (_) {},
      children: widget.screenshots.map((screenshot) {
        final String url = screenshot.url;
        if (url.isEmpty) return const SizedBox.shrink();

        return ClipRRect(
          borderRadius: .circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
          ),
        );
      }).toList(),
    );
  }
}

class const _AdditionalInfoSection({required final ProductDetails details})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[];

    items.add((
      WindowsIcons.package,
      t.msstorePublishedBy,
      details.publisherName.isEmpty ? t.msstoreNotAvailable : details.publisherName,
    ));

    items.add((
      msicons.FluentIcons.arrow_sync_16_regular,
      t.msstoreLastUpdatedDate,
      _formatDate(details.lastUpdateUtc ?? t.msstoreNotAvailable),
    ));

    items.add((
      WindowsIcons.calendar,
      t.msstoreReleaseDate,
      _formatDate(details.releaseDateUtc ?? t.msstoreNotAvailable),
    ));

    items.add((
      msicons.FluentIcons.bookmark_16_regular,
      t.msstoreCategory,
      details.categories.isEmpty ? t.msstoreNotAvailable : details.categories.join(', '),
    ));

    items.add((
      msicons.FluentIcons.tag_16_regular,
      t.msstoreApproximateSize,
      (details.approximateSizeBytes ?? 0).formatBytes(),
    ));

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      spacing: 5,
      children: [
        for (var i = 0; i < items.length; i += 2)
          Row(
            spacing: 5,
            crossAxisAlignment: .start,
            children: [
              Expanded(child: _infoTile(items[i])),
              if (i + 1 < items.length)
                Expanded(child: _infoTile(items[i + 1]))
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
      ],
    );
  }

  Widget _infoTile((IconData, String, String) item) {
    return SizedBox(
      height: 50,
      child: CardListTile(
        contentPadding: .zero,
        leading: Align(alignment: const .xy(1, -0.8), child: Icon(item.$1, size: 16)),
        title: item.$2,
        description: item.$3,
        trailing: const SizedBox.shrink(),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return date.toString().split(' ').first;
    } catch (_) {
      return dateString;
    }
  }
}

class const _ProductLoadingView({required final SearchProduct? preview, required final Key iconKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      children: [
        if (preview case final product?) _HeroPreview(product: product, iconKey: iconKey),
        Center(child: ProgressRing(semanticLabel: t.msstoreWait)),
      ],
    );
  }
}

class const _HeroPreview({required final SearchProduct product, required final Key iconKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = context.theme;
    final bool isWideScreen = MediaQuery.widthOf(context) >= _wideScreenBreakpoint;
    final TextAlign textAlign = isWideScreen ? .start : .center;

    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const .all(_heroPadding),
        child: Wrap(
          crossAxisAlignment: isWideScreen ? .start : .center,
          alignment: isWideScreen ? .start : .center,
          children: [
            Flex(
              direction: isWideScreen ? .horizontal : .vertical,
              mainAxisSize: .min,
              crossAxisAlignment: isWideScreen ? .start : .center,
              spacing: isWideScreen ? _heroWideSpacing : _heroNarrowSpacing,
              children: [
                _HeroIcon(key: iconKey, productId: product.id, iconUrl: product.iconUrl),
                Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: isWideScreen ? .start : .center,
                  children: [
                    Text(
                      product.title.isEmpty ? t.msstoreUnknown : product.title,
                      style: theme.typography.title?.copyWith(fontSize: 32),
                      maxLines: 2,
                      textAlign: textAlign,
                    ),
                    if (product.publisherName.isNotEmpty)
                      Text(
                        product.publisherName,
                        style: theme.typography.body?.copyWith(
                          fontSize: 14,
                          color: theme.resources.textFillColorSecondary,
                        ),
                        textAlign: textAlign,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
