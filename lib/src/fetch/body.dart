import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';

import 'blob.dart';
import 'form_data.dart';
import 'url_search_params.dart';

/// Request/response body initializer.
typedef BodyInit = Object;

/// Fetch-like body behavior shared by request/response objects.
mixin BodyMixin {
  BodyData get bodyData;

  /// Optional MIME hint used by [blob].
  String? get bodyMimeTypeHint => null;

  Stream<Uint8List>? get body => bodyData.consumeAsStream();

  bool get bodyUsed => bodyData.isUsed;

  Future<Uint8List> bytes() => bodyData.consumeAsBytes();

  Future<String> text([Encoding encoding = utf8]) =>
      bodyData.consumeAsText(encoding);

  Future<T> json<T>() => bodyData.consumeAsJson<T>();

  Future<Blob> blob() async {
    return Blob.bytes(
      await bytes(),
      type: bodyMimeTypeHint ?? bodyData.defaultContentType ?? '',
    );
  }
}

/// Internal body storage that supports cloning and one-time consumption.
final class BodyData {
  BodyData.empty()
    : _present = false,
      _bytes = null,
      _splitter = null,
      _branch = null,
      defaultContentType = null,
      defaultContentLength = null;

  BodyData.bytes(List<int> bytes, {this.defaultContentType})
    : _present = true,
      _bytes = Uint8List.fromList(bytes),
      _splitter = null,
      _branch = null,
      defaultContentLength = bytes.length;

  BodyData.stream(
    Stream<List<int>> stream, {
    this.defaultContentType,
    this.defaultContentLength,
  }) : _present = true,
       _bytes = null,
       _splitter = StreamSplitter<Uint8List>(
         stream.map(
           (chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk),
         ),
       ),
       _branch = null {
    _branch = _splitter!.split();
  }

  BodyData._fromSplit(
    StreamSplitter<Uint8List> splitter,
    Stream<Uint8List> branch, {
    this.defaultContentType,
    this.defaultContentLength,
  }) : _present = true,
       _bytes = null,
       _splitter = splitter,
       _branch = branch;

  factory BodyData.fromInit(Object? init) {
    if (init == null) {
      return BodyData.empty();
    }

    if (init is BodyData) {
      return init.clone();
    }

    if (init is String) {
      return BodyData.bytes(
        utf8.encode(init),
        defaultContentType: 'text/plain; charset=utf-8',
      );
    }

    if (init is Uint8List) {
      return BodyData.bytes(init);
    }

    if (init is ByteBuffer) {
      return BodyData.bytes(init.asUint8List());
    }

    if (init is List<int>) {
      return BodyData.bytes(init);
    }

    if (init is Blob) {
      return BodyData.bytes(
        init.copyBytes(),
        defaultContentType: init.type.isEmpty ? null : init.type,
      );
    }

    if (init is URLSearchParams) {
      return BodyData.bytes(
        utf8.encode(init.toString()),
        defaultContentType: 'application/x-www-form-urlencoded; charset=utf-8',
      );
    }

    if (init is FormData) {
      final payload = init.encodeMultipart();
      return BodyData.bytes(
        payload.bytes,
        defaultContentType: payload.contentType,
      );
    }

    if (init is Stream<List<int>>) {
      return BodyData.stream(init);
    }

    throw ArgumentError.value(
      init,
      'init',
      'Unsupported body type: ${init.runtimeType}',
    );
  }

  final bool _present;
  final Uint8List? _bytes;
  final StreamSplitter<Uint8List>? _splitter;
  Stream<Uint8List>? _branch;

  bool _used = false;

  /// Default content type inferred from body input.
  final String? defaultContentType;

  /// Default content length inferred from body input.
  final int? defaultContentLength;

  bool get hasBody => _present;

  bool get isUsed => _used;

  Stream<Uint8List>? consumeAsStream() {
    if (!_present) {
      return null;
    }

    return _consumeAsStream();
  }

  Future<Uint8List> consumeAsBytes() async {
    _startConsumption();

    if (_bytes != null) {
      return Uint8List.fromList(_bytes);
    }

    if (_branch == null) {
      return Uint8List(0);
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in _branch!) {
      builder.add(chunk);
    }

    return builder.takeBytes();
  }

  Future<String> consumeAsText([Encoding encoding = utf8]) async {
    return encoding.decode(await consumeAsBytes());
  }

  Future<T> consumeAsJson<T>() async {
    final decoded = json.decode(await consumeAsText());
    return decoded as T;
  }

  BodyData clone() {
    if (_used) {
      throw StateError('Body has already been consumed.');
    }

    if (!_present) {
      return BodyData.empty();
    }

    if (_bytes != null) {
      return BodyData.bytes(_bytes, defaultContentType: defaultContentType);
    }

    final splitter = _splitter;
    if (splitter == null) {
      return BodyData.empty();
    }

    return BodyData._fromSplit(
      splitter,
      splitter.split(),
      defaultContentType: defaultContentType,
      defaultContentLength: defaultContentLength,
    );
  }

  Stream<Uint8List> _consumeAsStream() async* {
    _startConsumption();

    if (_bytes != null) {
      yield Uint8List.fromList(_bytes);
      return;
    }

    if (_branch != null) {
      yield* _branch!;
    }
  }

  void _startConsumption() {
    if (_used) {
      throw StateError('Body has already been consumed.');
    }

    _used = true;
  }
}
