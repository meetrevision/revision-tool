import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:process_run/shell_run.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/core/widgets/card_highlight.dart';
import 'package:revitool/i18n/generated/strings.g.dart';
import 'package:revitool/utils_gui.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCardButtons = [
      CardHighlight(
        icon: FluentIcons.git_graph,
        label: t.homeCardGithub,
        description: t.homeCardGithubDescription,
        onPressed: () async =>
            await launchURL("https://github.com/meetrevision"),

        action: const ChevronRightAction(),
      ),
      CardHighlight(
        icon: msicons.FluentIcons.drink_coffee_20_regular,
        label: t.homeCardDonate,
        description: t.homeCardDonateDescription,
        onPressed: () async => await launchURL("https://revi.cc/donate"),
        action: const ChevronRightAction(),
      ),
      CardHighlight(
        icon: msicons.FluentIcons.chat_help_20_regular,
        label: t.homeCardDiscord,
        description: t.homeCardDiscordDescription,
        onPressed: () async => await launchURL("https://discord.gg/962y4pU"),
        action: const ChevronRightAction(),
      ),
    ];
    if (context.mqSize.width >= 800 && context.mqSize.height >= 400) {
      return Padding(
        padding: kScaffoldPagePadding,
        child: ScaffoldPage(
          content: const _HomePageContent(),
          bottomBar: Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Row(
              spacing: 5,
              children: homeCardButtons.map((e) => Expanded(child: e)).toList(),
            ),
          ),
        ),
      );
    } else {
      return ScaffoldPage.scrollable(
        padding: kScaffoldPagePadding,
        children: [
          const _HomePageContent(),
          const SizedBox(height: 5),
          Wrap(runSpacing: 5, children: homeCardButtons.map((e) => e).toList()),
        ],
      );
    }
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: context.theme.brightness.isDark
            ? const LinearGradient(
                colors: [
                  Color.fromRGBO(0, 0, 0, 0.85),
                  Color.fromRGBO(0, 0, 0, 0.43),
                  Color.fromRGBO(0, 0, 0, 0),
                ],
                stops: [0.0, 0.4, 1.0],
              )
            : const LinearGradient(
                colors: [
                  Color.fromRGBO(16, 16, 16, 0.8),
                  Color.fromRGBO(155, 155, 155, 0.5),
                  Color.fromRGBO(255, 255, 255, 0),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .start,
          children: [
            Text(
              t.homeWelcome,
              style: const TextStyle(fontSize: 16, color: Color(0xB7FFFFFF)),
            ),
            const Text(
              "Revision Tool",
              style: TextStyle(fontSize: 28, color: Color(0xFFffffff)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                t.homeDescription,
                style: const TextStyle(fontSize: 16, color: Color(0xB7FFFFFF)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              child: SizedBox(
                width: 175,
                child: Button(
                  child: Text(t.homeReviLink),
                  onPressed: () async => await run(
                    "rundll32 url.dll,FileProtocolHandler https://revi.cc",
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: SizedBox(
                width: 175,
                child: FilledButton(
                  child: Text(t.homeReviFAQLink),
                  onPressed: () async => await run(
                    "rundll32 url.dll,FileProtocolHandler https://revi.cc/docs",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
