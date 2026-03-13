@JS()
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../_internal/web_fetch_utils.dart' as web_fetch;
import '../_internal/web_stream_bridge.dart';
import '../core/http_method.dart';
import 'body.dart';
import 'blob.dart';
import 'form_data.native.dart';
import 'headers.js.dart' as js_headers;
import 'request.native.dart' as native;

sealed class RequestHost<T> {
  const RequestHost(this.value);

  final T value;
}

final class WebRequestHost extends RequestHost<web.Request> {
  const WebRequestHost(super.value);
}

final class NativeRequestHost extends RequestHost<native.Request> {
  const NativeRequestHost(super.value);
}

class Request implements native.Request {
  Request._(this._host);

  factory Request(Object? input, [native.RequestInit? init]) {
    final host = switch ((input, init)) {
      (final Request request, null) => request._host,
      (final web.Request request, null) => WebRequestHost(request),
      (final native.Request request, null) => NativeRequestHost(request),
      _ => NativeRequestHost(_toNativeRequest(input, init)),
    };

    return Request._(host);
  }

  final RequestHost _host;
  js_headers.Headers? _headers;
  Body? _body;

  @override
  js_headers.Headers get headers {
    final headers = _headers;
    if (headers != null) return headers;

    return _headers = switch (_host) {
      final WebRequestHost host => js_headers.Headers(host.value.headers),
      final NativeRequestHost host => js_headers.Headers(host.value.headers),
    };
  }

  @override
  Body? get body {
    final body = _body;
    if (body != null) return body;

    return switch (_host) {
      final WebRequestHost host => switch (host.value.body) {
        final web.ReadableStream stream => _body = Body(
          dartByteStreamFromWebReadableStream(stream),
        ),
        null => null,
      },
      final NativeRequestHost host => host.value.body,
    };
  }

  @override
  bool get bodyUsed {
    return switch (_host) {
      final WebRequestHost host => host.value.bodyUsed,
      final NativeRequestHost host => host.value.bodyUsed,
    };
  }

  @override
  native.RequestCache get cache {
    return switch (_host) {
      final WebRequestHost host => _requestCacheFromValue(host.value.cache),
      final NativeRequestHost host => host.value.cache,
    };
  }

  @override
  native.RequestCredentials get credentials {
    return switch (_host) {
      final WebRequestHost host => _requestCredentialsFromValue(
        host.value.credentials,
      ),
      final NativeRequestHost host => host.value.credentials,
    };
  }

  @override
  String get destination {
    return switch (_host) {
      final WebRequestHost host => host.value.destination,
      final NativeRequestHost host => host.value.destination,
    };
  }

  @override
  native.RequestDuplex get duplex {
    return switch (_host) {
      final WebRequestHost _ => native.RequestDuplex.half,
      final NativeRequestHost host => host.value.duplex,
    };
  }

  @override
  String get integrity {
    return switch (_host) {
      final WebRequestHost host => host.value.integrity,
      final NativeRequestHost host => host.value.integrity,
    };
  }

  @override
  bool get isHistoryNavigation {
    return switch (_host) {
      final WebRequestHost host => host.value.isHistoryNavigation,
      final NativeRequestHost host => host.value.isHistoryNavigation,
    };
  }

  @override
  bool get keepalive {
    return switch (_host) {
      final WebRequestHost host => host.value.keepalive,
      final NativeRequestHost host => host.value.keepalive,
    };
  }

  @override
  HttpMethod get method {
    return switch (_host) {
      final WebRequestHost host => HttpMethod.parse(host.value.method),
      final NativeRequestHost host => host.value.method,
    };
  }

  @override
  native.RequestMode get mode {
    return switch (_host) {
      final WebRequestHost host => _requestModeFromValue(host.value.mode),
      final NativeRequestHost host => host.value.mode,
    };
  }

  @override
  native.RequestRedirect get redirect {
    return switch (_host) {
      final WebRequestHost host => _requestRedirectFromValue(
        host.value.redirect,
      ),
      final NativeRequestHost host => host.value.redirect,
    };
  }

  @override
  String get referrer {
    return switch (_host) {
      final WebRequestHost host => host.value.referrer,
      final NativeRequestHost host => host.value.referrer,
    };
  }

  @override
  native.RequestReferrerPolicy? get referrerPolicy {
    return switch (_host) {
      final WebRequestHost host => _requestReferrerPolicyFromValue(
        host.value.referrerPolicy,
      ),
      final NativeRequestHost host => host.value.referrerPolicy,
    };
  }

  @override
  String get url {
    return switch (_host) {
      final WebRequestHost host => host.value.url,
      final NativeRequestHost host => host.value.url,
    };
  }

  @override
  Future<Uint8List> arrayBuffer() => bytes();

  @override
  Future<Blob> blob() async {
    final blob = await switch (_host) {
      final WebRequestHost host => web_fetch.blobFromWebPromise(
        host.value.blob(),
        type: headers.get('content-type'),
      ),
      _ => switch (body) {
        final Body body => body.blob(),
        null => Future<Blob>.value(Blob()),
      },
    };

    final type = headers.get('content-type');
    if (type == null || type.isEmpty || blob.type == type) {
      return blob;
    }

    return Blob(<Object>[blob], type);
  }

  @override
  Future<Uint8List> bytes() {
    return switch (_host) {
      final WebRequestHost host => web_fetch.bytesFromWebPromise(
        host.value.bytes(),
      ),
      _ => switch (body) {
        final Body body => body.bytes(),
        null => Future<Uint8List>.value(Uint8List(0)),
      },
    };
  }

  @override
  Future<FormData> formData() {
    return switch (_host) {
      final WebRequestHost host => host.value.formData().toDart.then(
        web_fetch.formDataFromWebHost,
      ),
      _ => switch (body) {
        final Body body => FormData.parse(
          body,
          contentType: headers.get('content-type'),
        ),
        null => Future<FormData>.error(
          const FormatException('Cannot decode form data from an empty body.'),
        ),
      },
    };
  }

  @override
  Future<T> json<T>() {
    return switch (body) {
      final Body body => body.json<T>(),
      null => Future<T>.error(
        const FormatException('Cannot decode JSON from an empty body.'),
      ),
    };
  }

  @override
  Future<String> text() {
    return switch (_host) {
      final WebRequestHost host => web_fetch.textFromWebPromise(
        host.value.text(),
      ),
      _ => switch (body) {
        final Body body => body.text(),
        null => Future<String>.value(''),
      },
    };
  }

  @override
  Request clone() {
    return switch (_host) {
      final WebRequestHost host => Request(host.value.clone()),
      final NativeRequestHost host => Request(host.value.clone()),
    };
  }

  static native.Request _toNativeRequest(
    Object? input,
    native.RequestInit? init,
  ) {
    return switch (input) {
      final native.Request request when init == null => request,
      final native.Request request => native.Request(request, init),
      final String _ => native.Request(input, init),
      final Uri _ => native.Request(input, init),
      final web.Request request => _nativeRequestFromWebRequest(request, init),
      _ => throw ArgumentError.value(input, 'input'),
    };
  }

  static native.Request _nativeRequestFromWebRequest(
    web.Request request,
    native.RequestInit? init,
  ) {
    final wrapped = Request(request);
    final body = wrapped.body;

    return native.Request(
      wrapped.url,
      native.RequestInit(
        method: init?.method ?? wrapped.method,
        headers: init?.headers ?? js_headers.Headers(wrapped.headers),
        body: init?.body ?? body?.clone(),
        referrer: init?.referrer ?? wrapped.referrer,
        referrerPolicy: init?.referrerPolicy ?? wrapped.referrerPolicy,
        mode: init?.mode ?? wrapped.mode,
        credentials: init?.credentials ?? wrapped.credentials,
        cache: init?.cache ?? wrapped.cache,
        redirect: init?.redirect ?? wrapped.redirect,
        integrity: init?.integrity ?? wrapped.integrity,
        keepalive: init?.keepalive ?? wrapped.keepalive,
        duplex: init?.duplex ?? wrapped.duplex,
      ),
    );
  }

  static native.RequestMode _requestModeFromValue(String value) {
    return switch (value) {
      'navigate' => native.RequestMode.navigate,
      'no-cors' => native.RequestMode.noCors,
      'same-origin' => native.RequestMode.sameOrigin,
      _ => native.RequestMode.cors,
    };
  }

  static native.RequestCredentials _requestCredentialsFromValue(String value) {
    return switch (value) {
      'omit' => native.RequestCredentials.omit,
      'include' => native.RequestCredentials.include,
      _ => native.RequestCredentials.sameOrigin,
    };
  }

  static native.RequestCache _requestCacheFromValue(String value) {
    return switch (value) {
      'no-store' => native.RequestCache.noStore,
      'reload' => native.RequestCache.reload,
      'no-cache' => native.RequestCache.noCache,
      'force-cache' => native.RequestCache.forceCache,
      'only-if-cached' => native.RequestCache.onlyIfCached,
      _ => native.RequestCache.default_,
    };
  }

  static native.RequestRedirect _requestRedirectFromValue(String value) {
    return switch (value) {
      'error' => native.RequestRedirect.error,
      'manual' => native.RequestRedirect.manual,
      _ => native.RequestRedirect.follow,
    };
  }

  static native.RequestReferrerPolicy? _requestReferrerPolicyFromValue(
    String value,
  ) {
    return switch (value) {
      '' => null,
      'no-referrer' => native.RequestReferrerPolicy.noReferrer,
      'no-referrer-when-downgrade' =>
        native.RequestReferrerPolicy.noReferrerWhenDowngrade,
      'same-origin' => native.RequestReferrerPolicy.sameOrigin,
      'origin' => native.RequestReferrerPolicy.origin,
      'strict-origin' => native.RequestReferrerPolicy.strictOrigin,
      'origin-when-cross-origin' =>
        native.RequestReferrerPolicy.originWhenCrossOrigin,
      'strict-origin-when-cross-origin' =>
        native.RequestReferrerPolicy.strictOriginWhenCrossOrigin,
      'unsafe-url' => native.RequestReferrerPolicy.unsafeUrl,
      _ => null,
    };
  }
}
