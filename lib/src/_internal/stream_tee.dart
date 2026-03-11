import 'dart:async';

import 'package:async/async.dart';

/// Splits [source] into two output streams.
///
/// Both branches observe the same source events and can be consumed
/// independently as single-subscription streams.
(Stream<T>, Stream<T>) streamTee<T>(Stream<T> source) {
  final streams = StreamSplitter.splitFrom(source, 2);
  return (streams[0], streams[1]);
}
