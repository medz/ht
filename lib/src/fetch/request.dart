export 'request.native.dart'
    show
        RequestInit,
        RequestInput,
        RequestRequestInput,
        StringRequestInput,
        UriRequestInput,
        RequestMode,
        RequestCredentials,
        RequestCache,
        RequestRedirect,
        RequestReferrerPolicy,
        RequestDuplex;
export 'request.native.dart'
    if (dart.library.io) 'request.io.dart'
    show Request;
