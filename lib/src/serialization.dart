import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/debug.dart';

Future<String> serialize(OrgNode node) =>
    time('serialize', () => compute(_doc2markup, node));

String _doc2markup(OrgNode node) => node.toMarkup();

Future<String?> serializeWithProgressUI(
  BuildContext context,
  OrgNode node,
) async {
  var canceled = false;
  serialize(node).then((value) {
    if (!canceled) Navigator.pop(context, value);
  }).onError((error, stackTrace) {
    showErrorSnackBar(context, error);
    logError(error, stackTrace);
    if (!canceled) Navigator.pop(context);
  });
  final willEncrypt = node.find<OrgDecryptedContent>((_) => true) != null;
  final result = await showDialog<String>(
    context: context,
    builder: (context) => ProgressIndicatorDialog(
      title: willEncrypt
          ? AppLocalizations.of(context)!.encryptingProgressDialogTitle
          : AppLocalizations.of(context)!.serializingProgressDialogTitle,
    ),
  );
  return result;
}
