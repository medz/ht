## Next

## 0.3.1

- Fixed the broken `Request` constructor implementation shipped in `0.3.0`,
  restoring Fetch-style construction for native, `dart:io`, and js runtimes.
- Fixed wrapped-request rebuilds so `Request(existing, RequestInit(body: ...))`
  replaces the body without incorrectly depending on cloning the consumed
  upstream request body.
- Added regression coverage for native, `dart:io`, and js `Request`
  constructor/body override semantics.

## 0.3.0

- BREAKING: Aligned `Request` and `Response` constructor/factory parameter
  semantics with Fetch/Web by introducing `RequestInit` and `ResponseInit`.
- BREAKING: Reworked request/response convenience constructors to use
  web-aligned positional body/init argument order.
- BREAKING: `Request` now uses `RequestInput` for string/`Uri`/`Request`
  construction, and request metadata now follows Fetch-style inheritance and
  override rules.
- BREAKING: `BodyMixin` was replaced by a first-class `Body` type, and
  `Request.body` / `Response.body` now expose `Body?`.
- BREAKING: `Headers`, `Blob`, `Request`, `Response`, and `URLSearchParams`
  now resolve through platform-specific native/io/js implementations.
- BREAKING: Removed older copy-first request/response convenience APIs that no
  longer matched Fetch/Web semantics.
- Added runtime-backed host adapters for:
  - `Request` on js and `dart:io`
  - `Response` on js and `dart:io`
  - `Headers` on js and `dart:io`
  - `Blob` on js and `dart:io`
  - `URLSearchParams` on js
- Added native `FormData` parsing for
  `application/x-www-form-urlencoded` and `multipart/form-data`.
- Added native `FormData.encodeMultipart()` returning `EncodedFormData`, with
  stream, content type, content length, and header application helpers.
- Added stream tee and web stream bridge internals to support cloning and host
  interop without eager body materialization.
- Added browser and `dart:io` coverage for host-backed fetch behavior and
  multipart parsing edge cases.

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
