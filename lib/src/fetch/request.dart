export 'request.native.dart'
    show
        RequestInit,
        RequestMode,
        RequestCredentials,
        RequestCache,
        RequestRedirect,
        RequestReferrerPolicy,
        RequestDuplex;
export 'request.native.dart'
    if (dart.library.js_interop) 'request.js.dart'
    if (dart.library.io) 'request.io.dart'
    show Request;
