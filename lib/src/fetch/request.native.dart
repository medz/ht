import 'dart:typed_data';

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

enum RequestPriority {
  auto('auto'),
  high('high'),
  low('low');

  const RequestPriority(this.value);

  final String value;
}

sealed class _RequestInput {
  const _RequestInput();
}

final class _RequestRequestInput extends _RequestInput {
  const _RequestRequestInput(this.value);

  final Request value;
}

final class _StringRequestInput extends _RequestInput {
  const _StringRequestInput(this.value);

  final String value;
}

final class _UriRequestInput extends _RequestInput {
  const _UriRequestInput(this.value);

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
    this.priority,
  });

  final String? method;
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
  final RequestPriority? priority;
}

/// Native request contract shell aligned with the MDN `Request` surface.
class Request {
  Request(Object? input, [RequestInit? init])
    : this._(_coerceInput(_requireInput(input)), init);

  Request._(_RequestInput input, [RequestInit? init])
    : method = _methodFromInput(input, init?.method),
      cache = _cacheFromInput(input, init?.cache),
      credentials = _credentialsFromInput(input, init?.credentials),
      destination = _destinationFromInput(input),
      duplex = _duplexFromInput(input, init?.duplex),
      integrity = _integrityFromInput(input, init?.integrity),
      isHistoryNavigation = _isHistoryNavigationFromInput(input),
      keepalive = _keepaliveFromInput(input, init?.keepalive),
      mode = _modeFromInput(input, init?.mode),
      priority = _priorityFromInput(input, init?.priority),
      redirect = _redirectFromInput(input, init?.redirect),
      referrer = _referrerFromInput(input, init?.referrer),
      referrerPolicy = _referrerPolicyFromInput(input, init?.referrerPolicy),
      url = _urlFromInput(input) {
    final body = _bodyFromInput(input, init?.body, method);
    final headers = _headersFromInput(input, init?.headers);
    _headers = init?.body == null
        ? headers
        : _headersWithContentTypeFromBody(headers, body);
    _body = body;
  }
  late final Headers _headers;
  late final Body? _body;

  Headers get headers => _headers;

  Body? get body => _body;

  final RequestCache cache;
  final RequestCredentials credentials;
  final String destination;
  final RequestDuplex duplex;
  final String integrity;
  final bool isHistoryNavigation;
  final bool keepalive;
  final String method;
  final RequestMode mode;
  final RequestPriority priority;
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
      this,
      RequestInit(
        method: method,
        headers: Headers(headers),
        referrer: referrer,
        referrerPolicy: referrerPolicy,
        mode: mode,
        credentials: credentials,
        cache: cache,
        redirect: redirect,
        integrity: integrity,
        keepalive: keepalive,
        duplex: duplex,
        priority: priority,
      ),
    );
  }

  static Headers _headersFromInput(_RequestInput input, HeadersInit? init) {
    if (init != null) return Headers(init);
    return switch (input) {
      _RequestRequestInput(:final value) => Headers(value.headers),
      _ => Headers(),
    };
  }

  static Body? _bodyFromInput(
    _RequestInput input,
    BodyInit? init,
    String method,
  ) {
    if (init != null) {
      _validateRequestBodyMethod(method);
      return Body(init);
    }

    final body = switch (input) {
      _RequestRequestInput(:final value) => value.body,
      _ => null,
    };
    if (body != null) {
      _validateRequestBodyMethod(method);
    }
    return body?.clone();
  }

  static Headers _headersWithContentTypeFromBody(Headers headers, Body? body) {
    final contentType = body?.contentType;
    if (contentType == null || headers.has('content-type')) {
      return headers;
    }

    return Headers(headers.entries())..set('content-type', contentType);
  }

  static RequestCache _cacheFromInput(_RequestInput input, RequestCache? init) {
    if (init != null) return init;
    return switch (input) {
      _RequestRequestInput(:final value) => value.cache,
      _ => RequestCache.default_,
    };
  }

  static RequestCredentials _credentialsFromInput(
    _RequestInput input,
    RequestCredentials? init,
  ) {
    if (init != null) return init;
    return switch (input) {
      _RequestRequestInput(:final value) => value.credentials,
      _ => RequestCredentials.sameOrigin,
    };
  }

  static String _destinationFromInput(_RequestInput input) {
    return switch (input) {
      _RequestRequestInput(:final value) => value.destination,
      _ => '',
    };
  }

  static RequestDuplex _duplexFromInput(
    _RequestInput input,
    RequestDuplex? init,
  ) {
    if (init != null) return init;
    return switch (input) {
      _RequestRequestInput(:final value) => value.duplex,
      _ => RequestDuplex.half,
    };
  }

  static String _integrityFromInput(_RequestInput input, String? init) {
    if (init != null) return init;
    return switch (input) {
      _RequestRequestInput(:final value) => value.integrity,
      _ => '',
    };
  }

  static bool _isHistoryNavigationFromInput(_RequestInput input) {
    return switch (input) {
      _RequestRequestInput(:final value) => value.isHistoryNavigation,
      _ => false,
    };
  }

  static bool _keepaliveFromInput(_RequestInput input, bool? init) {
    if (init != null) return init;
    return switch (input) {
      _RequestRequestInput(:final value) => value.keepalive,
      _ => false,
    };
  }

  static String _methodFromInput(_RequestInput input, String? init) {
    if (init != null) return _normalizeMethod(init);
    return switch (input) {
      _RequestRequestInput(:final value) => value.method,
      _ => 'GET',
    };
  }

  static void _validateRequestBodyMethod(String method) {
    if (method != 'GET' && method != 'HEAD') {
      return;
    }

    throw ArgumentError.value(
      method,
      'method',
      '$method requests cannot have a body.',
    );
  }

  static String _normalizeMethod(String method) {
    if (!_methodPattern.hasMatch(method)) {
      throw ArgumentError.value(method, 'method', 'Invalid HTTP method');
    }

    final upper = method.toUpperCase();
    if (upper == 'CONNECT' || upper == 'TRACE' || upper == 'TRACK') {
      throw ArgumentError.value(method, 'method', 'Forbidden HTTP method');
    }

    return switch (upper) {
      'DELETE' || 'GET' || 'HEAD' || 'OPTIONS' || 'POST' || 'PUT' => upper,
      _ => method,
    };
  }

  static final _methodPattern = RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$");

  static RequestMode _modeFromInput(_RequestInput input, RequestMode? init) {
    if (init != null) return init;
    return switch (input) {
      _RequestRequestInput(:final value) => value.mode,
      _ => RequestMode.cors,
    };
  }

  static RequestRedirect _redirectFromInput(
    _RequestInput input,
    RequestRedirect? init,
  ) {
    if (init != null) return init;
    return switch (input) {
      _RequestRequestInput(:final value) => value.redirect,
      _ => RequestRedirect.follow,
    };
  }

  static RequestPriority _priorityFromInput(
    _RequestInput input,
    RequestPriority? init,
  ) {
    if (init != null) return init;
    return switch (input) {
      _RequestRequestInput(:final value) => value.priority,
      _ => RequestPriority.auto,
    };
  }

  static String _referrerFromInput(_RequestInput input, String? init) {
    if (init != null) return init;
    return switch (input) {
      _RequestRequestInput(:final value) => value.referrer,
      _ => 'about:client',
    };
  }

  static RequestReferrerPolicy? _referrerPolicyFromInput(
    _RequestInput input,
    RequestReferrerPolicy? init,
  ) {
    if (init != null) return init;
    return switch (input) {
      _RequestRequestInput(:final value) => value.referrerPolicy,
      _ => null,
    };
  }

  static String _urlFromInput(_RequestInput input) {
    return switch (input) {
      _RequestRequestInput(:final value) => value.url,
      _StringRequestInput(:final value) => Uri.parse(value).toString(),
      _UriRequestInput(:final value) => value.toString(),
    };
  }

  static _RequestInput _coerceInput(Object input) {
    return switch (input) {
      final Request value => _RequestRequestInput(value),
      final String value => _StringRequestInput(value),
      final Uri value => _UriRequestInput(value),
      _ => throw ArgumentError.value(
        input,
        'input',
        'Unsupported request input: ${input.runtimeType}',
      ),
    };
  }

  static Object _requireInput(Object? input) {
    if (input == null) {
      throw ArgumentError.value(
        input,
        'input',
        'Unsupported request input: ${input.runtimeType}',
      );
    }

    return input;
  }
}
