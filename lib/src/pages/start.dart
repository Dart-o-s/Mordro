import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/platform.dart';
import 'package:url_launcher/url_launcher.dart';

class StartPage extends StatelessWidget {
  const StartPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('orgro')),
      body: PlatformOpenHandler(
        child: Center(
          child: IntrinsicWidth(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const PickFileButton(),
                const SizedBox(height: 16),
                const OrgroManualButton(),
                if (!kReleaseMode && !kScreenshotMode) ...[
                  const SizedBox(height: 16),
                  const OrgManualButton(),
                ],
                const SizedBox(height: 64),
                const SupportLink(),
                const LicensesButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PickFileButton extends StatelessWidget {
  const PickFileButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: const Text('Open File'),
      color: Theme.of(context).accentColor,
      textColor: Theme.of(context).accentTextTheme.button.color,
      onPressed: () async {
        final path = await FilePicker.getFilePath(type: FileType.any);
        if (path != null) {
          await loadPath(context, path);
        }
      },
    );
  }
}

class OrgManualButton extends StatelessWidget {
  const OrgManualButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: const Text('Open Org Manual'),
      onPressed: () => loadHttpUrl(context,
          'https://code.orgmode.org/bzg/org-mode/raw/master/doc/org-manual.org'),
    );
  }
}

class OrgroManualButton extends StatelessWidget {
  const OrgroManualButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: const Text('Open Orgro Manual'),
      onPressed: () => loadAsset(context, 'assets/orgro-manual.org'),
    );
  }
}

class SupportLink extends StatelessWidget {
  const SupportLink({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton.icon(
      icon: const Icon(Icons.help),
      label: const Text('Support · Feedback'),
      onPressed: () => launch(
        'https://github.com/amake/orgro/issues',
        forceSafariVC: false,
      ),
      textColor: Theme.of(context).disabledColor,
    );
  }
}

class LicensesButton extends StatelessWidget {
  const LicensesButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: const Text('Licenses'),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const LicensePage(),
        ),
      ),
      textColor: Theme.of(context).disabledColor,
    );
  }
}
