import 'dart:async';

import 'package:flutter/foundation.dart';

Future<T> time<T>(String tag, FutureOr<T> Function() func) async {
  final start = DateTime.now();
  final ret = await func();
  final end = DateTime.now();
  debugPrint('$tag: ${end.difference(start).inMilliseconds} ms');
  return ret;
}

Future logError(Object e, StackTrace s) async {
  debugPrint(e.toString());
  debugPrint(s.toString());
  return e;
}
