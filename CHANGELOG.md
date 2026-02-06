## 0.2.0

- BREAKING: Reworked `Blob` to a `block`-backed implementation and removed
  synchronous `Blob.copyBytes()`.
- Added direct `Blob` <-> `block.Block` compatibility (`Blob` now implements
  `Block`).
- BREAKING: `Blob.slice` now follows Web Blob semantics (negative indexes are
  resolved from the end).
- BREAKING: `FormData.encodeMultipart()` now returns a stream-first
  `MultipartBody`, and `MultipartBody.bytes` is now async method `bytes()`.
- Added stream-first `MultipartBody` with `stream`, `contentLength`,
  `contentType`, and async `bytes()`.
- Added `BodyInit` support for `package:block` `Block` values in `Request` and
  `Response`.

## 0.1.0

- Rebuilt the package as a fetch-first HTTP type layer.
- Added core protocol types: `HttpMethod`, `HttpStatus`, `HttpVersion`, `MimeType`.
- Added fetch primitives: `Request`, `Response`, `Headers`, `URLSearchParams`, `Blob`, `File`, `FormData`.
- Added CI workflow and runnable `example/main.dart`.
- Upgraded SDK and dependencies to current stable constraints.
- Expanded tests to stabilize API behavior and edge-case contracts.

## 0.0.0

- Initial release.
