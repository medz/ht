import 'dart:typed_data';

import '../core/http_method.dart';
import 'body.dart';
import 'blob.dart';
import 'form_data.native.dart';
import 'headers.dart';

enum RequestMode {
  cors('cors'),
  navigate('navigate'),
  noCors('no-cors'),
  sameOrigin('same-origin');

  const RequestMode(this.value);

  final String value;
}

enum RequestCredentials {
  omit('omit'),
  sameOrigin('same-origin'),
  include('include');

  const RequestCredentials(this.value);

  final String value;
}

enum RequestCache {
  default_('default'),
  noStore('no-store'),
  reload('reload'),
  noCache('no-cache'),
  forceCache('force-cache'),
  onlyIfCached('only-if-cached');

  const RequestCache(this.value);

  final String value;
}

enum RequestRedirect {
  follow('follow'),
  error('error'),
  manual('manual');

  const RequestRedirect(this.value);

  final String value;
}

enum RequestReferrerPolicy {
  noReferrer('no-referrer'),
  noReferrerWhenDowngrade('no-referrer-when-downgrade'),
  sameOrigin('same-origin'),
  origin('origin'),
  strictOrigin('strict-origin'),
  originWhenCrossOrigin('origin-when-cross-origin'),
  strictOriginWhenCrossOrigin('strict-origin-when-cross-origin'),
  unsafeUrl('unsafe-url');

  const RequestReferrerPolicy(this.value);

  final String value;
}

enum RequestDuplex {
  half('half');

  const RequestDuplex(this.value);

  final String value;
}

sealed class RequestInput {
  const RequestInput();

  const factory RequestInput.request(Request value) = RequestRequestInput;
  const factory RequestInput.string(String value) = StringRequestInput;
  const factory RequestInput.uri(Uri value) = UriRequestInput;
}

final class RequestRequestInput extends RequestInput {
  const RequestRequestInput(this.value);

  final Request value;
}

final class StringRequestInput extends RequestInput {
  const StringRequestInput(this.value);

  final String value;
}

final class UriRequestInput extends RequestInput {
  const UriRequestInput(this.value);

  final Uri value;
}

/// Initialization options for [Request], aligned with the MDN Fetch
/// `RequestInit` surface.
class RequestInit {
  RequestInit({
    this.method,
    this.headers,
    this.body,
    this.referrer,
    this.referrerPolicy,
    this.mode,
    this.credentials,
    this.cache,
    this.redirect,
    this.integrity,
    this.keepalive,
    this.duplex,
  });

  final HttpMethod? method;
  final HeadersInit? headers;
  final BodyInit? body;
  final String? referrer;
  final RequestReferrerPolicy? referrerPolicy;
  final RequestMode? mode;
  final RequestCredentials? credentials;
  final RequestCache? cache;
  final RequestRedirect? redirect;
  final String? integrity;
  final bool? keepalive;
  final RequestDuplex? duplex;
}

/// Native request contract shell aligned with the MDN `Request` surface.
class Request {
  Request(RequestInput input, [RequestInit? init])
    : headers = _headersFromInput(input, init?.headers),
      body = _bodyFromInput(input, init?.body),
      cache = _cacheFromInput(input, init?.cache),
      credentials = _credentialsFromInput(input, init?.credentials),
      destination = _destinationFromInput(input),
      duplex = _duplexFromInput(input, init?.duplex),
      integrity = _integrityFromInput(input, init?.integrity),
      isHistoryNavigation = _isHistoryNavigationFromInput(input),
      keepalive = _keepaliveFromInput(input, init?.keepalive),
      method = _methodFromInput(input, init?.method),
      mode = _modeFromInput(input, init?.mode),
      redirect = _redirectFromInput(input, init?.redirect),
      referrer = _referrerFromInput(input, init?.referrer),
      referrerPolicy = _referrerPolicyFromInput(input, init?.referrerPolicy),
      url = _urlFromInput(input);

  final Headers headers;
  final Body? body;
  final RequestCache cache;
  final RequestCredentials credentials;
  final String destination;
  final RequestDuplex duplex;
  final String integrity;
  final bool isHistoryNavigation;
  final bool keepalive;
  final HttpMethod method;
  final RequestMode mode;
  final RequestRedirect redirect;
  final String referrer;
  final RequestReferrerPolicy? referrerPolicy;
  final String url;

  bool get bodyUsed => body?.bodyUsed ?? false;

  Future<Uint8List> arrayBuffer() => bytes();

  Future<Blob> blob() async {
    final blob = switch (body) {
      final Body body => await body.blob(),
      null => Blob(),
    };

    final type = headers.get('content-type');
    if (type == null || type.isEmpty || blob.type == type) {
      return blob;
    }

    return Blob(<Object>[blob], type);
  }

  Future<Uint8List> bytes() {
    return switch (body) {
      final Body body => body.bytes(),
      null => Future<Uint8List>.value(Uint8List(0)),
    };
  }

  Future<FormData> formData() {
    return switch (body) {
      final Body body => FormData.parse(
        body,
        contentType: headers.get('content-type'),
      ),
      null => Future<FormData>.error(
        const FormatException('Cannot decode form data from an empty body.'),
      ),
    };
  }

  Future<T> json<T>() {
    return switch (body) {
      final Body body => body.json<T>(),
      null => Future<T>.error(
        const FormatException('Cannot decode JSON from an empty body.'),
      ),
    };
  }

  Future<String> text() {
    return switch (body) {
      final Body body => body.text(),
      null => Future<String>.value(''),
    };
  }

  Request clone() {
    return Request(
      RequestInput.string(url),
      RequestInit(
        method: method,
        headers: Headers(headers),
        body: body?.clone(),
        referrer: referrer,
        referrerPolicy: referrerPolicy,
        mode: mode,
        credentials: credentials,
        cache: cache,
        redirect: redirect,
        integrity: integrity,
        keepalive: keepalive,
        duplex: duplex,
      ),
    );
  }

  static Headers _headersFromInput(RequestInput input, HeadersInit? init) {
    if (init != null) return Headers(init);
    return switch (input) {
      RequestRequestInput(:final value) => Headers(value.headers),
      _ => Headers(),
    };
  }

  static Body? _bodyFromInput(RequestInput input, BodyInit? init) {
    if (init != null) return Body(init);
    return switch (input) {
      RequestRequestInput(:final value) => value.body?.clone(),
      _ => null,
    };
  }

  static RequestCache _cacheFromInput(RequestInput input, RequestCache? init) {
    if (init != null) return init;
    return switch (input) {
      RequestRequestInput(:final value) => value.cache,
      _ => RequestCache.default_,
    };
  }

  static RequestCredentials _credentialsFromInput(
    RequestInput input,
    RequestCredentials? init,
  ) {
    if (init != null) return init;
    return switch (input) {
      RequestRequestInput(:final value) => value.credentials,
      _ => RequestCredentials.sameOrigin,
    };
  }

  static String _destinationFromInput(RequestInput input) {
    return switch (input) {
      RequestRequestInput(:final value) => value.destination,
      _ => '',
    };
  }

  static RequestDuplex _duplexFromInput(
    RequestInput input,
    RequestDuplex? init,
  ) {
    if (init != null) return init;
    return switch (input) {
      RequestRequestInput(:final value) => value.duplex,
      _ => RequestDuplex.half,
    };
  }

  static String _integrityFromInput(RequestInput input, String? init) {
    if (init != null) return init;
    return switch (input) {
      RequestRequestInput(:final value) => value.integrity,
      _ => '',
    };
  }

  static bool _isHistoryNavigationFromInput(RequestInput input) {
    return switch (input) {
      RequestRequestInput(:final value) => value.isHistoryNavigation,
      _ => false,
    };
  }

  static bool _keepaliveFromInput(RequestInput input, bool? init) {
    if (init != null) return init;
    return switch (input) {
      RequestRequestInput(:final value) => value.keepalive,
      _ => false,
    };
  }

  static HttpMethod _methodFromInput(RequestInput input, HttpMethod? init) {
    if (init != null) return init;
    return switch (input) {
      RequestRequestInput(:final value) => value.method,
      _ => HttpMethod.get,
    };
  }

  static RequestMode _modeFromInput(RequestInput input, RequestMode? init) {
    if (init != null) return init;
    return switch (input) {
      RequestRequestInput(:final value) => value.mode,
      _ => RequestMode.cors,
    };
  }

  static RequestRedirect _redirectFromInput(
    RequestInput input,
    RequestRedirect? init,
  ) {
    if (init != null) return init;
    return switch (input) {
      RequestRequestInput(:final value) => value.redirect,
      _ => RequestRedirect.follow,
    };
  }

  static String _referrerFromInput(RequestInput input, String? init) {
    if (init != null) return init;
    return switch (input) {
      RequestRequestInput(:final value) => value.referrer,
      _ => 'about:client',
    };
  }

  static RequestReferrerPolicy? _referrerPolicyFromInput(
    RequestInput input,
    RequestReferrerPolicy? init,
  ) {
    if (init != null) return init;
    return switch (input) {
      RequestRequestInput(:final value) => value.referrerPolicy,
      _ => null,
    };
  }

  static String _urlFromInput(RequestInput input) {
    return switch (input) {
      RequestRequestInput(:final value) => value.url,
      StringRequestInput(:final value) => Uri.parse(value).toString(),
      UriRequestInput(:final value) => value.toString(),
    };
  }
}
