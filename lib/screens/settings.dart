import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:revitool/theme.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode theme;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Settings'),
      ),
      children: [
        CardHighlight(
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(
                FluentIcons.brush,
                size: 24,
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'Choose your mode'),
                      Text(
                        "Change the theme mode that appears in Revision Tool",
                        // style: TextStyle(fontSize: 11, color: Color.fromARGB(255, 207, 207, 207), overflow: TextOverflow.ellipsis),
                        style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
                    ],
                  ),
                ),
              ),
              ComboBox(
                value: appTheme.mode,
                items: [
                  ComboBoxItem(
                    value: ThemeMode.system,
                    child: Text(ThemeMode.system.name.uppercaseFirst()),
                    onTap: () => setState(() {
                      theme = ThemeMode.system;
                    }),
                  ),
                  ComboBoxItem(
                    value: ThemeMode.light,
                    child: Text(ThemeMode.light.name.uppercaseFirst()),
                    onTap: () => setState(() {
                      theme = ThemeMode.light;
                    }),
                  ),
                  ComboBoxItem(
                    value: ThemeMode.dark,
                    child: Text(ThemeMode.dark.name.uppercaseFirst()),
                    onTap: () => setState(() {
                      theme = ThemeMode.dark;
                    }),
                  ),
                ],
                onChanged: (value) {
                  appTheme.mode = theme;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 5.0),
        CardHighlight(
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(FluentIcons.picture_library, size: 24),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'Experimental tweaks'),
                      // Text(
                      //   "Experimental",
                      //   style: FluentTheme.of(context).brightness.isDark
                      //       ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                      //       : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      // )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Text(expBool ? "On" : "Off"),
              const SizedBox(width: 10.0),
              ToggleSwitch(
                checked: expBool,
                onChanged: (bool value) async {
                  setState(() {
                    expBool = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
