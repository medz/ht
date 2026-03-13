import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:block/block.dart' as block;

import '../_internal/stream_tee.dart';
import 'blob.dart';
import 'form_data.native.dart';
import 'url_search_params.dart';

/// Constructor input accepted by body implementations.
///
/// Standard detached forms:
/// - [String]
/// - [Uint8List]
/// - [ByteBuffer]
/// - [List<int>]
/// - [Stream<List<int>>]
/// - [Blob]
/// - [Body]
/// - [block.Block]
/// - [FormData]
/// - [URLSearchParams]
///
/// Platform-specific extensions:
/// - `dart:io File` on io
///
/// Native bodies normalize supported inputs into a detached [block.Block]
/// when possible. Platform implementations may accept additional host-backed
/// inputs before materialization.
typedef BodyInit = Object?;

/// Native detached body implementation.
///
/// This is the shared body baseline that web/io implementations can align to,
/// but it is intentionally not wired into the existing fetch types yet.
class Body extends Stream<Uint8List> {
  Body._({block.Block? blockHost, Stream<Uint8List>? streamHost})
    : assert(blockHost != null || streamHost != null),
      _blockHost = blockHost,
      _streamHost = streamHost;

  factory Body([BodyInit? init]) {
    return switch (init) {
      null => Body._(blockHost: block.Block(const [])),
      final Body body => body.clone(),
      final String text => Body._(
        blockHost: block.Block([text], type: 'text/plain;charset=utf-8'),
      ),
      final Uint8List bytes => Body._(blockHost: block.Block([bytes])),
      final ByteBuffer buffer => Body._(
        blockHost: block.Block([buffer.asUint8List()]),
      ),
      final List<int> bytes => Body._(blockHost: block.Block([bytes])),
      final Blob blob => Body._(blockHost: blob),
      final block.Block blockHost => Body._(blockHost: blockHost),
      final URLSearchParams params => Body._(
        blockHost: block.Block([
          params.toString(),
        ], type: 'application/x-www-form-urlencoded;charset=utf-8'),
      ),
      final FormData formData => Body._(
        streamHost: formData.encodeMultipart().stream,
      ),
      final Stream<List<int>> stream => Body._(
        streamHost: stream.map(
          (chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk),
        ),
      ),
      _ => throw ArgumentError.value(
        init,
        'init',
        'Unsupported body type: ${init.runtimeType}',
      ),
    };
  }

  final block.Block? _blockHost;
  Stream<Uint8List>? _streamHost;
  bool _used = false;

  Stream<Uint8List>? get stream async* {
    final blockHost = _blockHost;
    final streamHost = _streamHost;
    if (blockHost == null && streamHost == null) {
      return;
    }

    _startConsumption();

    if (blockHost != null) {
      yield* blockHost.stream();
      return;
    }

    if (streamHost != null) {
      yield* streamHost;
    }
  }

  bool get bodyUsed => _used;

  Future<Uint8List> bytes() async {
    final stream = this.stream;
    if (stream == null) return Uint8List(0);

    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }

    return builder.takeBytes();
  }

  Future<String> text([Encoding encoding = utf8]) async {
    return encoding.decode(await bytes());
  }

  Future<T> json<T>() {
    return text().then((text) => jsonDecode(text) as T);
  }

  Future<Blob> blob() async {
    final blockHost = _blockHost;
    if (blockHost != null) {
      _startConsumption();
      if (blockHost case final Blob blob) {
        return blob;
      }

      return Blob(<Object>[blockHost], blockHost.type);
    }

    return Blob(<Object>[await bytes()]);
  }

  Body clone() {
    if (_used) {
      throw StateError('Body has already been consumed.');
    }

    final blockHost = _blockHost;
    if (blockHost != null) {
      return Body._(blockHost: blockHost);
    }

    final streamHost = _streamHost;
    if (streamHost != null) {
      final (left, right) = streamTee(streamHost);
      _streamHost = left;
      return Body._(streamHost: right);
    }

    throw StateError('Body has no host.');
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final stream = this.stream;
    if (stream == null) {
      return Stream<Uint8List>.empty().listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
    }

    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void _startConsumption() {
    if (_used) {
      throw StateError('Body has already been consumed.');
    }

    _used = true;
  }
}
