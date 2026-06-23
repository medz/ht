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
/// - [ByteData]
/// - [List<int>]
/// - [Stream<List<int>>]
/// - [Blob]
/// - [Body]
/// - [block.Block]
/// - [FormData]
/// - [URLSearchParams]
///
/// On IO, `dart:io File` values are supported through the platform [Blob]
/// implementation.
///
/// Bodies normalize supported inputs into a detached [Blob] when
/// possible. Platform implementations may accept additional host-backed inputs
/// before materialization.
typedef BodyInit = Object?;

const _textPlainUtf8 = 'text/plain;charset=UTF-8';
const _urlEncodedUtf8 = 'application/x-www-form-urlencoded;charset=UTF-8';
const _defaultBlobChunkSize = 16 * 1024;

/// Detached body implementation.
///
/// This is the shared body baseline that web/io implementations align to.
class Body extends Blob with Stream<Uint8List> implements Stream<Uint8List> {
  /// Creates a body from [init].
  ///
  /// This constructor is generative so downstream wrappers can extend [Body]
  /// and call `super(init)` without reimplementing [BodyInit] normalization.
  Body([BodyInit? init]) : this._fromState(_BodyState.from(init));

  Body._fromState(_BodyState state)
    : assert(state.streamSize == null || state.streamSize! >= 0),
      _streamHost = state.streamHost,
      _streamSize = state.streamSize,
      contentType = state.contentType,
      super(state.blobParts, state.type);

  Stream<Uint8List>? _streamHost;
  int? _streamSize;
  bool _used = false;

  /// The body-derived media type, when extracting the body produced one.
  final String? contentType;

  @override
  int get size {
    final streamHost = _streamHost;
    if (streamHost == null) {
      return super.size;
    }

    final streamSize = _streamSize;
    if (streamSize != null) {
      return streamSize;
    }

    throw UnsupportedError(
      'Body.size is unavailable for stream-backed bodies with unknown length.',
    );
  }

  @override
  Stream<Uint8List> stream({int chunkSize = _defaultBlobChunkSize}) {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be > 0');
    }

    return _stream(chunkSize);
  }

  Stream<Uint8List> _stream(int chunkSize) async* {
    _startConsumption();

    final streamHost = _streamHost;
    if (streamHost != null) {
      yield* streamHost;
      return;
    }

    yield* super.stream(chunkSize: chunkSize);
  }

  bool get bodyUsed => _used;

  @override
  Future<Uint8List> bytes() => arrayBuffer();

  @override
  Future<Uint8List> arrayBuffer() async {
    _startConsumption();

    final streamHost = _streamHost;
    if (streamHost == null) {
      return super.arrayBuffer();
    }

    return _readStream(streamHost);
  }

  @override
  Future<String> text([Encoding encoding = utf8]) async {
    return encoding.decode(await bytes());
  }

  Future<T> json<T>() {
    return text().then((text) => jsonDecode(text) as T);
  }

  Future<Blob> blob() async {
    if (_streamHost == null) {
      _startConsumption();
      return Blob(<BlobPart>[super.slice(0, null, type)], type);
    }

    return Blob(<BlobPart>[await bytes()], type);
  }

  Body clone() {
    return Body._fromState(_cloneState());
  }

  _BodyState _cloneState() {
    if (_used) {
      throw StateError('Body has already been consumed.');
    }

    final streamHost = _streamHost;
    if (streamHost == null) {
      return _BodyState(
        blobParts: <BlobPart>[super.slice(0, null, type)],
        type: type,
        contentType: contentType,
      );
    }

    final (left, right) = streamTee(streamHost);
    _streamHost = left;
    return _BodyState(
      streamHost: right,
      streamSize: _streamSize,
      type: type,
      contentType: contentType,
    );
  }

  @override
  Blob slice(int start, [int? end, String? contentType]) {
    if (_streamHost != null) {
      throw UnsupportedError(
        'Body.slice is unavailable for stream-backed bodies.',
      );
    }

    final sliced = super.slice(start, end, contentType);
    return Blob(<BlobPart>[sliced], sliced.type);
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return stream().listen(
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

  static _BodyState _fromBlobInit(BodyInit init, String type) {
    return _BodyState(
      blobParts: init == null ? const <BlobPart>[] : <BlobPart>[init],
      type: type,
      contentType: _contentType(type),
    );
  }

  static _BodyState _fromFormData(FormData formData) {
    final encoded = formData.encodeMultipart();
    return _BodyState(
      streamHost: encoded.stream,
      streamSize: encoded.contentLength,
      type: encoded.contentType,
      contentType: encoded.contentType,
    );
  }

  static _BodyState _fromStream(Stream<List<int>> stream) {
    return _BodyState(streamHost: stream.map(Uint8List.fromList));
  }

  static Future<Uint8List> _readStream(Stream<Uint8List> stream) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }

    return builder.takeBytes();
  }

  static String _blobInitType(BodyInit init) {
    return switch (init) {
      final String _ => _textPlainUtf8,
      final URLSearchParams _ => _urlEncodedUtf8,
      final Blob blob => blob.type,
      final block.Block blockHost => blockHost.type,
      _ => '',
    };
  }

  static String? _contentType(String type) => type.isEmpty ? null : type;
}

final class _BodyState {
  const _BodyState({
    this.blobParts = const <BlobPart>[],
    this.streamHost,
    this.streamSize,
    this.type = '',
    this.contentType,
  }) : assert(streamSize == null || streamSize >= 0);

  final Iterable<BlobPart> blobParts;
  final Stream<Uint8List>? streamHost;
  final int? streamSize;
  final String type;
  final String? contentType;

  static _BodyState from(BodyInit? init) {
    return switch (init) {
      // Constructor-copy path for subclasses calling super(init). Dispatching
      // through clone() here would recurse for clone() methods that rebuild
      // the subclass from the current instance.
      final Body body => body._cloneState(),
      final FormData formData => Body._fromFormData(formData),
      final Stream<List<int>> stream => Body._fromStream(stream),
      final String text => Body._fromBlobInit(text, _textPlainUtf8),
      final URLSearchParams params => Body._fromBlobInit(
        params.toString(),
        _urlEncodedUtf8,
      ),
      _ => Body._fromBlobInit(init, Body._blobInitType(init)),
    };
  }
}
