import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

const orgroVersion =
    String.fromEnvironment('ORGRO_VERSION', defaultValue: 'dev');

void openAboutDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) {
      Widget dialog = AboutDialog(
        applicationName: AppLocalizations.of(context)!.appTitle,
        applicationVersion: orgroVersion,
        applicationIcon: const Padding(
          padding: EdgeInsets.all(8),
          child: _AppIcon(),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AboutItem(
                label: AppLocalizations.of(context)!.aboutLinkSupport,
                onPressed: visitSupportLink,
              ),
              _AboutItem(
                label: AppLocalizations.of(context)!.aboutLinkChangelog,
                onPressed: visitChangelogLink,
              ),
            ],
          ),
        ],
      );
      if (Theme.of(context).brightness == Brightness.dark) {
        // Very dumb workaround for our primary color (the default label color
        // for TextButton) being too dark in dark mode
        dialog = TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
                primary: DefaultTextStyle.of(context).style.color),
          ),
          child: dialog,
        );
      }
      return dialog;
    },
  );
}

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Image.asset(
        'assets/manual/orgro-icon.png',
        scale: MediaQuery.of(context).devicePixelRatio,
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      label: Text(label.toUpperCase()),
      icon: const Icon(Icons.open_in_browser),
    );
  }
}

void visitSupportLink() => launchUrl(
      Uri.parse('https://github.com/amake/orgro/issues'),
      mode: LaunchMode.externalApplication,
    );

void visitChangelogLink() => launchUrl(
      Uri.parse('https://orgro.org/changelog/'),
      mode: LaunchMode.externalApplication,
    );
