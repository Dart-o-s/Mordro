import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/preferences.dart';

const _kMaxUndoStackSize = 10;

class DocumentProvider extends StatefulWidget {
  static InheritedDocumentProvider of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedDocumentProvider>()!;

  const DocumentProvider({
    required this.doc,
    required this.dataSource,
    required this.child,
    this.onDocChanged,
    super.key,
  });

  final OrgTree doc;
  final DataSource dataSource;
  final Widget child;
  final void Function(OrgTree)? onDocChanged;

  @override
  State<DocumentProvider> createState() => _DocumentProviderState();
}

class _DocumentProviderState extends State<DocumentProvider> {
  List<OrgTree> _docs = [];
  List<DocumentAnalysis> _analyses = [];
  late DataSource _dataSource;
  List<String> _accessibleDirs = [];
  int _cursor = 0;

  @override
  void initState() {
    super.initState();
    _docs = [widget.doc];
    _analyses = [const DocumentAnalysis()];
    _analyze(widget.doc).then((analysis) {
      setState(() => _analyses[0] = analysis);
    });
    _dataSource = widget.dataSource;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _accessibleDirs = Preferences.of(context).accessibleDirs;
    _resolveDataSourceParent(_accessibleDirs).then((dataSource) {
      if (dataSource != null) {
        setState(() => _dataSource = dataSource);
      }
    });
  }

  Future<DataSource?> _resolveDataSourceParent(
      List<String> accessibleDirs) async {
    final dataSource = _dataSource;
    if (dataSource is NativeDataSource && dataSource.needsToResolveParent) {
      return dataSource.resolveParent(accessibleDirs);
    }
    return null;
  }

  Future<void> _addAccessibleDir(String dir) async {
    final accessibleDirs = _accessibleDirs..add(dir);
    await Preferences.of(context).setAccessibleDirs(accessibleDirs);
    final dataSource = await _resolveDataSourceParent(accessibleDirs);
    setState(() {
      if (dataSource != null) {
        _dataSource = dataSource;
      }
      _accessibleDirs = accessibleDirs;
    });
  }

  Future<void> _pushDoc(OrgTree doc) async {
    widget.onDocChanged?.call(doc);
    final analysis = await _analyze(doc);
    setState(() {
      _docs = _pushAtIndexAndTrim(_docs, doc, _cursor, _kMaxUndoStackSize);
      _analyses =
          _pushAtIndexAndTrim(_analyses, analysis, _cursor, _kMaxUndoStackSize);
      _cursor = _docs.length - 1;
    });
  }

  static List<T> _pushAtIndexAndTrim<T>(
    List<T> list,
    T item,
    int idx,
    int maxLen,
  ) =>
      [
        // +2 is because we keep the item at idx and the new item, so the total
        // will be maxLen
        ...list.sublist(max(0, idx - maxLen + 2), idx + 1), item,
      ];

  bool get _canUndo => _cursor >= 1;

  OrgTree _undo() {
    if (!_canUndo) throw Exception("can't undo");
    final newCursor = _cursor - 1;
    setState(() => _cursor = newCursor);
    final newDoc = _docs[newCursor];
    widget.onDocChanged?.call(newDoc);
    return newDoc;
  }

  bool get _canRedo => _cursor < _docs.length - 1;

  OrgTree _redo() {
    if (!_canRedo) throw Exception("can't redo");
    final newCursor = _cursor + 1;
    setState(() => _cursor = newCursor);
    final newDoc = _docs[newCursor];
    widget.onDocChanged?.call(newDoc);
    return newDoc;
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDocumentProvider(
      doc: _docs[_cursor],
      dataSource: _dataSource,
      analysis: _analyses[_cursor],
      addAccessibleDir: _addAccessibleDir,
      pushDoc: _pushDoc,
      undo: _undo,
      redo: _redo,
      canUndo: _canUndo,
      canRedo: _canRedo,
      child: widget.child,
    );
  }
}

class InheritedDocumentProvider extends InheritedWidget {
  const InheritedDocumentProvider({
    required this.doc,
    required this.dataSource,
    required this.analysis,
    required this.addAccessibleDir,
    required this.pushDoc,
    required this.undo,
    required this.redo,
    required this.canUndo,
    required this.canRedo,
    required super.child,
    super.key,
  });

  final OrgTree doc;
  final DataSource dataSource;
  final DocumentAnalysis analysis;
  final Future<void> Function(String) addAccessibleDir;
  final Future<void> Function(OrgTree) pushDoc;
  final OrgTree Function() undo;
  final OrgTree Function() redo;
  final bool canUndo;
  final bool canRedo;

  @override
  bool updateShouldNotify(InheritedDocumentProvider oldWidget) =>
      doc != oldWidget.doc ||
      dataSource != oldWidget.dataSource ||
      analysis != oldWidget.analysis;
}

Future<DocumentAnalysis> _analyze(OrgTree doc) => time('analyze', () async {
      final canResolveRelativeLinks =
          await canObtainNativeDirectoryPermissions();
      var hasRemoteImages = false;
      var hasRelativeLinks = false;
      doc.visit<OrgLink>((link) {
        hasRemoteImages |=
            looksLikeImagePath(link.location) && looksLikeUrl(link.location);
        try {
          hasRelativeLinks |= OrgFileLink.parse(link.location).isRelative;
        } on Exception {
          // Not a file link
        }
        return !hasRemoteImages ||
            (!hasRelativeLinks && canResolveRelativeLinks);
      });
      return DocumentAnalysis(
        hasRemoteImages: hasRemoteImages,
        hasRelativeLinks: hasRelativeLinks,
      );
    });

class DocumentAnalysis {
  const DocumentAnalysis({
    this.hasRemoteImages,
    this.hasRelativeLinks,
  });

  final bool? hasRemoteImages;
  final bool? hasRelativeLinks;

  @override
  bool operator ==(Object other) =>
      other is DocumentAnalysis &&
      hasRemoteImages == other.hasRemoteImages &&
      hasRelativeLinks == other.hasRelativeLinks;

  @override
  int get hashCode => Object.hash(hasRemoteImages, hasRelativeLinks);
}
