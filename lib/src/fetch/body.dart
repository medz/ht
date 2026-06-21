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
/// On IO, `dart:io File` values are supported as [Blob] parts. Wrap files in a
/// [Blob] before passing them as [BodyInit], for example `Body(Blob([file]))`.
///
/// Native bodies normalize supported inputs into a detached [block.Block]
/// when possible. Platform implementations may accept additional host-backed
/// inputs before materialization.
typedef BodyInit = Object?;

const _textPlainUtf8 = 'text/plain;charset=UTF-8';
const _urlEncodedUtf8 = 'application/x-www-form-urlencoded;charset=UTF-8';

/// Native detached body implementation.
///
/// This is the shared body baseline that web/io implementations align to.
class Body extends Stream<Uint8List> {
  Body._({
    block.Block? blockHost,
    Stream<Uint8List>? streamHost,
    this.contentType,
  }) : assert(blockHost != null || streamHost != null),
       _blockHost = blockHost,
       _streamHost = streamHost;

  factory Body([BodyInit? init]) {
    switch (init) {
      case null:
        return Body._(blockHost: block.Block(const []));
      case final Body body:
        return body.clone();
      case final String text:
        return Body._(
          blockHost: block.Block([text], type: _textPlainUtf8),
          contentType: _textPlainUtf8,
        );
      case final Uint8List bytes:
        return Body._(blockHost: block.Block([bytes]));
      case final ByteBuffer buffer:
        return Body._(blockHost: block.Block([buffer.asUint8List()]));
      case final List<int> bytes:
        return Body._(blockHost: block.Block([Uint8List.fromList(bytes)]));
      case final Blob blob:
        return Body._(blockHost: blob, contentType: _contentType(blob.type));
      case final block.Block blockHost:
        return Body._(
          blockHost: blockHost,
          contentType: _contentType(blockHost.type),
        );
      case final URLSearchParams params:
        return Body._(
          blockHost: block.Block([params.toString()], type: _urlEncodedUtf8),
          contentType: _urlEncodedUtf8,
        );
      case final FormData formData:
        final encoded = formData.encodeMultipart();
        return Body._(
          streamHost: encoded.stream,
          contentType: encoded.contentType,
        );
      case final Stream<List<int>> stream:
        return Body._(
          streamHost: stream.map(
            (chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk),
          ),
        );
      default:
        throw ArgumentError.value(
          init,
          'init',
          'Unsupported body type: ${init.runtimeType}',
        );
    }
  }

  final block.Block? _blockHost;
  Stream<Uint8List>? _streamHost;
  bool _used = false;

  /// The body-derived media type, when extracting the body produced one.
  final String? contentType;

  Stream<Uint8List> get stream async* {
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
      return Body._(blockHost: blockHost, contentType: contentType);
    }

    final streamHost = _streamHost;
    if (streamHost != null) {
      final (left, right) = streamTee(streamHost);
      _streamHost = left;
      return Body._(streamHost: right, contentType: contentType);
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

  static String? _contentType(String type) => type.isEmpty ? null : type;
}
