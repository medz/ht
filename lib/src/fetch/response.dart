export 'response.native.dart' show ResponseInit, ResponseType;
export 'response.native.dart'
    if (dart.library.io) 'response.io.dart'
    if (dart.library.js_interop) 'response.js.dart'
    show Response;
