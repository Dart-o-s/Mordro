import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';

const _kMaxUndoStackSize = 10;

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
  List<OrgTree> _docs = [];
  late int _cursor;

  @override
  void initState() {
    _docs = [widget.doc];
    _cursor = 0;
    super.initState();
  }

  void _pushDoc(OrgTree doc) {
    setState(() {
      _docs = [
        // +2 is because we keep the doc at _cursor and the new doc, so the
        // total will be _kMaxUndoStackSize.
        ..._docs.sublist(max(0, _cursor - _kMaxUndoStackSize + 2), _cursor + 1),
        doc
      ];
      _cursor = _docs.length - 1;
    });
  }

  bool get _canUndo => _cursor >= 1;

  OrgTree _undo() {
    if (!_canUndo) throw Exception("can't undo");
    final newCursor = _cursor - 1;
    setState(() => _cursor = newCursor);
    return _docs[newCursor];
  }

  bool get _canRedo => _cursor < _docs.length - 1;

  OrgTree _redo() {
    if (!_canRedo) throw Exception("can't redo");
    final newCursor = _cursor + 1;
    setState(() => _cursor = newCursor);
    return _docs[newCursor];
  }

  @override
  Widget build(BuildContext context) {
    return DocumentProviderData(
      doc: _docs[_cursor],
      pushDoc: _pushDoc,
      undo: _undo,
      redo: _redo,
      canUndo: _canUndo,
      canRedo: _canRedo,
      child: widget.child,
    );
  }
}

class DocumentProviderData extends InheritedWidget {
  const DocumentProviderData({
    required this.doc,
    required this.pushDoc,
    required this.undo,
    required this.redo,
    required this.canUndo,
    required this.canRedo,
    required super.child,
    super.key,
  });

  final OrgTree doc;
  final void Function(OrgTree) pushDoc;
  final OrgTree Function() undo;
  final OrgTree Function() redo;
  final bool canUndo;
  final bool canRedo;

  @override
  bool updateShouldNotify(DocumentProviderData oldWidget) =>
      doc != oldWidget.doc;
}
