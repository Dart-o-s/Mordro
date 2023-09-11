import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/preferences.dart';

Future<bool> loadHttpUrl(BuildContext context, Uri uri) =>
    loadDocument(context, WebDataSource(uri));

Future<bool> loadAsset(BuildContext context, String key) =>
    loadDocument(context, AssetDataSource(key));

Future<bool> loadDocument(
  BuildContext context,
  FutureOr<DataSource?> dataSource, {
  FutureOr<dynamic> Function()? onClose,
  String? target,
}) {
  // Create the future here so that it is not recreated on every build; this way
  // the result won't be recomputed e.g. on hot reload
  final parsed = Future.value(dataSource).then((source) {
    if (source != null) {
      return ParsedOrgFileInfo.from(source);
    } else {
      // There was no fileーthe user canceled so close the route. We wait until
      // here to know if the user canceled because when the user doesn't cancel
      // it is expensive to resolve the opened file.
      Navigator.pop(context);
      return Future.value(null);
    }
  });
  final push = Navigator.push<void>(
    context,
    _buildDocumentRoute(context, parsed, target),
  );
  if (onClose != null) {
    push.whenComplete(onClose);
  }
  return parsed.then((value) => value != null);
}

PageRoute _buildDocumentRoute(
  BuildContext context,
  Future<ParsedOrgFileInfo?> parsed,
  String? target,
) {
  return MaterialPageRoute<void>(
    builder: (context) => FutureBuilder<ParsedOrgFileInfo?>(
      future: parsed,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return DocumentProvider(
            doc: snapshot.data!.doc,
            child: _DocumentPageWrapper(
              dataSource: snapshot.data!.dataSource,
              target: target,
            ),
          );
        } else if (snapshot.hasError) {
          return ErrorPage(error: snapshot.error.toString());
        } else {
          return const ProgressPage();
        }
      },
    ),
    fullscreenDialog: true,
  );
}

class _DocumentPageWrapper extends StatelessWidget {
  const _DocumentPageWrapper({
    required this.dataSource,
    required this.target,
  });

  final DataSource dataSource;
  final String? target;

  @override
  Widget build(BuildContext context) {
    final prefs = Preferences.of(context);
    return RootRestorationScope(
      restorationId: 'org_page_root:${dataSource.id}',
      child: OrgController(
        root: DocumentProvider.of(context)!.doc,
        hideMarkup: prefs.readerMode,
        restorationId: 'org_page:${dataSource.id}',
        child: ViewSettings.defaults(
          context,
          child: DocumentPage(
            title: dataSource.name,
            dataSource: dataSource,
            initialTarget: target,
          ),
        ),
      ),
    );
  }
}

Future<OrgSection?> narrow(
    BuildContext context, DataSource dataSource, OrgSection section) {
  final viewSettings = ViewSettings.of(context);
  final orgController = OrgController.of(context);
  return Navigator.push<OrgSection>(
    context,
    MaterialPageRoute(
      builder: (context) => DocumentProvider(
        doc: section,
        child: Builder(builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              Navigator.pop(context, DocumentProvider.of(context)!.doc);
              return false;
            },
            child: OrgController.defaults(
              orgController,
              // Continue to use the true document root so that links to sections
              // outside the narrowed section can be resolved
              //
              // TODO(aaron): figure out how this should work with editing
              root: orgController.root,
              child: ViewSettings(
                data: viewSettings,
                child: DocumentPage(
                  title: AppLocalizations.of(context)!
                      .pageTitleNarrow(dataSource.name),
                  dataSource: dataSource,
                  initialQuery: viewSettings.queryString,
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

void showInteractive(BuildContext context, String title, Widget child) {
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (builder) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: InteractiveViewer(child: Center(child: child)),
      ),
    ),
  );
}

class DocumentProvider extends StatefulWidget {
  static DocumentProviderData? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocumentProviderData>();

  const DocumentProvider({required this.doc, required this.child, super.key});

  final OrgTree doc;
  final Widget child;

  @override
  State<DocumentProvider> createState() => _DocumentProviderState();
}

class _DocumentProviderState extends State<DocumentProvider> {
  late OrgTree _doc;

  @override
  void initState() {
    _doc = widget.doc;
    super.initState();
  }

  void _setDoc(OrgTree doc) => setState(() => _doc = doc);

  @override
  Widget build(BuildContext context) {
    return DocumentProviderData(
      doc: _doc,
      setDoc: _setDoc,
      child: widget.child,
    );
  }
}

class DocumentProviderData extends InheritedWidget {
  const DocumentProviderData({
    required this.doc,
    required this.setDoc,
    required super.child,
    super.key,
  });

  final OrgTree doc;
  final Function(OrgTree) setDoc;

  @override
  bool updateShouldNotify(DocumentProviderData oldWidget) =>
      doc != oldWidget.doc;
}
