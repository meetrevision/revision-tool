import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/int_bytes.dart';
import '../../core/routing/app_router.dart' show rootNavigatorKey;
import '../../core/settings/app_settings_provider.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/card_highlight.dart';
import '../../core/widgets/pips_pager.dart';
import '../../core/widgets/stacked_gradients.dart';
import '../../extensions.dart';
import '../../i18n/generated/strings.g.dart';
import '../../utils_gui.dart';
import 'models/download_state.dart';
import 'models/product_details/product_details.dart';
import 'models/search/search_product.dart';
import 'store_providers.dart';
import 'widgets/ms_store_download_widget.dart';

const BorderRadius _borderRadiusTop = .only(
  topLeft: .circular(8),
  topRight: .circular(8),
);

Color parseHexColor(String hexColor) {
  try {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  } catch (e) {
    return Colors.transparent;
  }
}

class MSStoreProductPage extends ConsumerStatefulWidget {
  const MSStoreProductPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<MSStoreProductPage> createState() => _MSStoreProductPageState();
}

class _MSStoreProductPageState extends ConsumerState<MSStoreProductPage> {
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _showStickyCard;

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
      loading: () => ScaffoldPage.scrollable(
        padding: kScaffoldPagePadding,
        children: const [Center(child: ProgressRing())],
      ),
      error: (error, stack) => ScaffoldPage.scrollable(
        padding: kScaffoldPagePadding,
        children: [
          Center(child: Text(t.msstoreProductLoadError(error: error))),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    WidgetRef ref,
    ProductDetails details,
  ) {
    return [
      _HeroSection(
        details: details,
        onGet: () => _showInstallDialog(context, ref),
      ),
      const SizedBox(height: 50),
      if (details.screenshots?.isNotEmpty ?? false) ...[
        _ContentCards(
          title: t.msstoreScreenshots,
          content: _ScreenshotCarousel(screenshots: details.screenshots!),
        ),
      ],
      if (details.description?.isNotEmpty ?? false) ...[
        _ContentCards(
          title: t.description,
          content: Text(details.description!),
        ),
      ],
      if (details.averageRating != null || details.ratingCount != null) ...[
        _ContentCards(
          title: t.ratingAndReviews,
          content: _RatingSection(details: details),
        ),
      ],
      if (details.features?.isNotEmpty ?? false) ...[
        _ContentCards(
          title: t.features,
          content: Text(details.features!.join('\n')),
        ),
      ],
      if (details.systemRequirements != null) ...[
        _ContentCards(
          title: t.systemRequirements,
          content: Text(
            details.systemRequirements!.minimum!.when(
              (title, items) => items != null
                  ? items
                        .map((item) => '${item.name}: ${item.description}')
                        .join('\n')
                  : 'N/A',
            ),
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

class _ContentCards extends StatelessWidget {
  const _ContentCards({required this.title, required this.content});

  final String title;
  final Widget content;

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
                style: context.theme.typography.bodyStrong!.copyWith(
                  fontSize: 18,
                ),
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

class _HeroSection extends ConsumerWidget {
  const _HeroSection({required this.details, required this.onGet});

  final ProductDetails details;
  final VoidCallback onGet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluentThemeData theme = context.theme;

    final FluentThemeData darkTheme = ref
        .read(appSettingsProvider.notifier)
        .buildDarkTheme(theme.accentColor, is10footScreen(context));

    const divider = Divider(size: 16, direction: .vertical);

    final bool isWideScreen = MediaQuery.widthOf(context) >= 550;
    final AsyncValue<List<Color>?> paletteAsync = details.heroImageUrl != null
        ? ref.watch(
            msStoreProductPaletteProvider(
              details.productId!,
              details.heroImageUrl!,
            ),
          )
        : const AsyncValue.data(null);
    final Color iconUrlBackgroundColor = parseHexColor(
      details.iconUrlBackground ?? '',
    );

    final decoratedBox = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: .topCenter,
          end: .bottomCenter,
          colors: [
            iconUrlBackgroundColor,
            context.theme.scaffoldBackgroundColor,
          ],
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
            if (details.heroImageUrl != null)
              Positioned.fill(
                child: Align(
                  alignment: .centerRight,
                  child: ClipRRect(
                    clipBehavior: .hardEdge,
                    borderRadius: _borderRadiusTop,
                    child: Image.network(
                      details.heroImageUrl!,
                      alignment: .centerRight,
                      gaplessPlayback: true,
                      cacheHeight: minHeight.toInt(),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: ClipRRect(
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
                                stops: isWideScreen
                                    ? null
                                    : const [0, 0.1, 0.2],
                              ),
                              LinearGradient(
                                begin: .center,
                                end: .bottomCenter,
                                colors: [
                                  palette.first.withAlpha(140),
                                  darkTheme.scaffoldBackgroundColor.withAlpha(
                                    50,
                                  ),
                                ],
                              ),
                              LinearGradient(
                                begin: .topLeft,
                                end: .bottomRight,
                                stops: const [0, 0.5, 1],
                                colors: [
                                  darkTheme.scaffoldBackgroundColor.withAlpha(
                                    250,
                                  ),
                                  Colors.transparent,
                                  darkTheme.scaffoldBackgroundColor.withAlpha(
                                    250,
                                  ),
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
            ),
            Padding(
              padding: const .all(40),
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
                    spacing: isWideScreen ? 23.5 : 12,
                    children: [
                      _HeroIcon(
                        iconUrl: details.iconUrl,
                        color: parseHexColor(details.iconUrlBackground ?? ''),
                      ),
                      Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: isWideScreen ? .start : .center,
                        children: [
                          Text(
                            details.title ?? '',
                            style: darkTheme.typography.title!.copyWith(
                              fontSize: 32,
                            ),
                            maxLines: 2,
                            textAlign: isWideScreen ? .start : .center,
                          ),
                          if (details.publisherName != null)
                            Text(
                              details.publisherName!,
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
                                  color: darkTheme
                                      .resources
                                      .textFillColorSecondary,
                                ),
                                divider,
                                Text(
                                  details.ratingCountFormatted!,
                                  style: darkTheme.typography.caption,
                                ),
                                divider,
                              ],
                              if (details.categories?.isNotEmpty ?? false) ...[
                                Text(
                                  details.categories!.first,
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
                      if (details.description?.isNotEmpty ?? false)
                        Padding(
                          padding: isWideScreen
                              ? .only(right: MediaQuery.widthOf(context) * 0.3)
                              : .zero,
                          child: Text(
                            details.description!,
                            maxLines: 2,
                            overflow: .ellipsis,
                            style: darkTheme.typography.body,
                          ),
                        ),

                      _InstallActionBar(
                        productId: details.productId!,
                        onGet: onGet,
                      ),

                      if (details.productRatings != null &&
                          details.productRatings!.isNotEmpty &&
                          details.productRatings!.first.ratingId !=
                              'Microsoft:E')
                        Wrap(
                          spacing: 12,
                          crossAxisAlignment: .end,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: AppImage(
                                fetchPadding: 0,
                                baseUrl: details
                                    .productRatings!
                                    .first
                                    .ratingValueLogoUrl!,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: .start,
                              mainAxisSize: .min,
                              children: [
                                Text(
                                  details.productRatings?.first.longName ?? '',
                                  style: theme.typography.bodyStrong,
                                ),
                                Text(
                                  details
                                          .productRatings
                                          ?.first
                                          .ratingDescriptors
                                          ?.join(', ') ??
                                      '',
                                  style: theme.typography.caption!.copyWith(
                                    color:
                                        theme.resources.textFillColorDisabled,
                                  ),
                                ),
                                Text(
                                  details
                                          .productRatings
                                          ?.first
                                          .interactiveElements
                                          ?.join(', ') ??
                                      '',
                                  style: theme.typography.caption!.copyWith(
                                    color:
                                        theme.resources.textFillColorDisabled,
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

class _ShareButton extends StatefulWidget {
  const _ShareButton({required this.productId});
  final String productId;

  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton> {
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
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _finished
              ? const IconButton(
                  icon: Icon(
                    msicons.FluentIcons.checkmark_20_regular,
                    size: 20,
                  ),
                  key: ValueKey('checkmark'),
                  onPressed: null,
                )
              : IconButton(
                  key: const ValueKey('share'),
                  icon: const Icon(
                    msicons.FluentIcons.share_20_regular,
                    size: 20,
                  ),
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
                                    text:
                                        'https://apps.microsoft.com/detail/${widget.productId}',
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
    );
  }
}

class _InstallActionBar extends ConsumerWidget {
  const _InstallActionBar({required this.productId, required this.onGet});

  final String productId;
  final VoidCallback onGet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StoreDownloadState state = ref.watch(
      storeControllerProvider.select((s) => s.download),
    );
    final bool active = state.isForProduct(productId);

    final bool isWideScreen = MediaQuery.widthOf(context) >= 550;

    return Wrap(
      crossAxisAlignment: .center,
      direction: isWideScreen ? .horizontal : .vertical,
      spacing: 10,
      runSpacing: 8,
      children: [
        _InstallPrimaryAction(
          productId: productId,
          state: active ? state : const .idle(),
          onGet: onGet,
        ),
        Row(
          mainAxisSize: .min,
          children: [
            _ShareButton(productId: productId),
            _InstallMoreButton(productId: productId),
          ],
        ),
      ],
    );
  }
}

class _InstallPrimaryAction extends ConsumerWidget {
  const _InstallPrimaryAction({
    required this.productId,
    required this.state,
    required this.onGet,
  });

  final String productId;
  final StoreDownloadState state;
  final VoidCallback onGet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget child = state.maybeWhen(
      preparing: (_, message) {
        final installing = message == t.msstoreInstalling;
        return _InstallProgressCard(
          key: const ValueKey('preparing'),
          progress: 0,
          title: installing
              ? t.msstoreInstalling
              : t.msstorePreparingToDownload,
          subtitle: installing ? t.msstorePreparingInstaller : message ?? '',
          onCancel: () => ref.read(storeControllerProvider.notifier).cancel(),
        );
      },
      downloading:
          (_, progress, completed, total, downloadedBytes, totalBytes) =>
              _InstallProgressCard(
                key: const ValueKey('downloading'),
                progress: _overallProgress(
                  progress,
                  downloadedBytes,
                  totalBytes,
                ),
                title: t.msstoreDownloading,
                subtitle: totalBytes > 0
                    ? t.msstoreDownloadedBytesProgress(
                        downloaded: downloadedBytes.formatBytes(),
                        total: totalBytes.formatBytes(),
                      )
                    : t.msstoreDownloadingPackages(
                        completed: completed,
                        total: total,
                      ),
                onPause: () =>
                    ref.read(storeControllerProvider.notifier).pause(),
                onCancel: () =>
                    ref.read(storeControllerProvider.notifier).cancel(),
              ),
      paused: (_, progress, _, _, downloadedBytes, totalBytes) =>
          _InstallProgressCard(
            key: const ValueKey('paused'),
            progress: _overallProgress(progress, downloadedBytes, totalBytes),
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
              : () => ref
                    .read(storeControllerProvider.notifier)
                    .installCurrentDownload(),
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
            child: Text(
              t.msstoreRetry,
              style: const TextStyle(fontWeight: .bold),
            ),
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
          final Animation<double> scale = Tween<double>(
            begin: 0.98,
            end: 1,
          ).animate(animation);
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

class _InstallProgressCard extends StatelessWidget {
  const _InstallProgressCard({
    super.key,
    required this.progress,
    required this.title,
    required this.subtitle,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  final double progress;
  final String title;
  final String subtitle;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = context.theme;
    final ResourceDictionary resources = theme.resources;
    final double clampedProgress = progress.clamp(0, 1).toDouble();
    final Color surfaceColor = Color.alphaBlend(
      theme.accentColor.lightest.withAlpha(theme.brightness == .dark ? 10 : 18),
      resources.cardBackgroundFillColorDefault.withAlpha(
        theme.brightness == .dark ? 220 : 238,
      ),
    );

    return SizedBox(
      width: 360,
      height: 52,
      child: ClipRRect(
        borderRadius: .circular(6),
        child: AnimatedContainer(
          duration: theme.fastAnimationDuration,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: .circular(6),
            border: .all(
              color: resources.cardStrokeColorDefault.withAlpha(120),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ProgressBar(value: clampedProgress * 100),
              ),
              Padding(
                padding: const .fromLTRB(14, 6, 8, 6),
                child: Row(
                  spacing: 6,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: .center,
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: context.theme.typography.bodyStrong,
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: context.theme.typography.caption,
                          ),
                        ],
                      ),
                    ),
                    if (onPause != null)
                      Tooltip(
                        message: t.msstorePause,
                        child: IconButton(
                          icon: const Icon(msicons.FluentIcons.pause_20_filled),
                          onPressed: onPause,
                        ),
                      ),
                    if (onResume != null)
                      Tooltip(
                        message: t.msstoreResume,
                        child: IconButton(
                          icon: const Icon(msicons.FluentIcons.play_20_filled),
                          onPressed: onResume,
                        ),
                      ),
                    if (onCancel != null)
                      Tooltip(
                        message: t.msstoreCancel,
                        child: IconButton(
                          icon: const Icon(
                            msicons.FluentIcons.dismiss_20_regular,
                          ),
                          onPressed: onCancel,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstallMoreButton extends StatefulWidget {
  const _InstallMoreButton({required this.productId});

  final String productId;

  @override
  State<_InstallMoreButton> createState() => _InstallMoreButtonState();
}

class _InstallMoreButtonState extends State<_InstallMoreButton> {
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
              builder: (context) =>
                  _MoreMenuFlyout(productId: widget.productId),
            );
          },
        ),
      ),
    );
  }
}

class _MoreMenuFlyout extends StatelessWidget {
  const _MoreMenuFlyout({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return MenuFlyout(
      items: [
        MenuFlyoutItem(
          leading: const Icon(msicons.FluentIcons.line_horizontal_3_20_regular),
          text: Text(t.msstoreChoosePackagesEllipsis),
          onPressed: () {
            showDialog(
              context: context,
              dismissWithEsc: false,
              builder: (context) =>
                  StorePackagePickerDialog(productId: productId),
            );
          },
        ),
      ],
    );
  }
}

double _overallProgress(
  Map<String, double> fileProgress,
  int downloadedBytes,
  int totalBytes,
) {
  if (totalBytes > 0) return downloadedBytes / totalBytes;
  if (fileProgress.isEmpty) return 0;
  final double totalProgress = fileProgress.values.fold<double>(
    0,
    (sum, progress) => sum + progress,
  );
  return totalProgress / fileProgress.length;
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.iconUrl, this.color});

  final String? iconUrl;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return iconUrl != null && iconUrl!.isNotEmpty
        ? SizedBox(
            width: 100,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color ?? Colors.transparent,
                borderRadius: .circular(8),
              ),
              child: AppImage(
                fetchPadding: 0,
                baseUrl: iconUrl!,
                errorWidget: _placeholder(),
              ),
            ),
          )
        : _placeholder();
  }

  Widget _placeholder() {
    return const DecoratedBox(decoration: BoxDecoration(color: Colors.grey));
  }
}

class _StickyCard extends StatelessWidget {
  const _StickyCard({
    required this.visible,
    required this.details,
    required this.scrollController,
    required this.onGet,
  });

  final bool visible;
  final ProductDetails details;
  final ScrollController scrollController;
  final VoidCallback onGet;

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
                backgroundColor: context
                    .theme
                    .resources
                    .systemFillColorSolidNeutralBackground,
                image: details.iconUrl,
                label: details.title ?? t.msstoreUnknown,
                description:
                    details.publisherName ?? details.productFamilyName ?? '',
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

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.details});

  final ProductDetails details;

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

class _ScreenshotCarousel extends StatefulWidget {
  const _ScreenshotCarousel({required this.screenshots});

  final List<SearchProductPreviews> screenshots;

  @override
  State<_ScreenshotCarousel> createState() => _ScreenshotCarouselState();
}

class _ScreenshotCarouselState extends State<_ScreenshotCarousel> {
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
        final String? url = screenshot.url;
        if (url == null) return const SizedBox.shrink();

        // return AppImage(baseUrl: url, fit: .fill, borderRadius: .circular(8));
        return ClipRRect(
          borderRadius: .circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const DecoratedBox(
              decoration: BoxDecoration(color: Colors.grey),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AdditionalInfoSection extends StatelessWidget {
  const _AdditionalInfoSection({required this.details});

  final ProductDetails details;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[];

    items.add((
      WindowsIcons.package,
      t.msstorePublishedBy,
      details.publisherName ?? t.msstoreNotAvailable,
    ));

    items.add((
      msicons.FluentIcons.arrow_sync_16_regular,
      t.msstoreLastUpdatedDate,
      _formatDate(details.lastUpdateDateUtc!),
    ));

    items.add((
      WindowsIcons.calendar,
      t.msstoreReleaseDate,
      _formatDate(details.releaseDateUtc ?? t.msstoreNotAvailable),
    ));

    items.add((
      msicons.FluentIcons.bookmark_16_regular,
      t.msstoreCategory,
      details.categories?.join(', ') ?? t.msstoreNotAvailable,
    ));

    items.add((
      msicons.FluentIcons.tag_16_regular,
      t.msstoreApproximateSize,
      (details.approximateSizeInBytes ?? 0).formatBytes(),
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
        leading: Align(
          alignment: const .xy(1, -0.8),
          child: Icon(item.$1, size: 16),
        ),
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
