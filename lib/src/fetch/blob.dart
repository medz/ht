export 'blob.native.dart' show BlobPart;
export 'blob.native.dart'
    if (dart.library.io) 'blob.io.dart'
    if (dart.library.js_interop) 'blob.js.dart'
    show Blob;
