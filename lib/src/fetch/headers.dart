export 'headers.native.dart' show HeadersInit;
export 'headers.native.dart'
    if (dart.library.io) 'headers.io.dart'
    if (dart.library.js_interop) 'headers.js.dart'
    show Headers;
