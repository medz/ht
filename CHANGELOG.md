## Next

- BREAKING: `Body` now extends the platform `Blob` implementation and implements
  `Stream<Uint8List>` directly; use `body` as a stream or call `body.stream()`
  instead of reading the previous `body.stream` getter.
- Added `Body.size` for exposing known body byte lengths without consuming the
  body.
- Added a public generative `Body` constructor so downstream wrappers can extend
  `Body` without reimplementing `BodyInit` normalization.
- Fixed `Blob` byte snapshot semantics so byte-backed parts and read buffers are
  copied consistently across native, `dart:io`, and js wrappers.

## 0.5.0

- BREAKING: `Request.method` and `RequestInit.method` now use `String` values
  instead of `HttpMethod`, allowing custom HTTP methods such as `PROPFIND`
  while keeping Fetch-style normalization and GET/HEAD body checks.
- Added `RequestPriority` and `RequestInit.priority` for modeling Fetch request
  priority hints.
- Added body-derived `Content-Type` defaults for `Request` and `Response`
  construction when typed body init values provide a media type and callers omit
  the header.
- Normalized `Blob`, `File`, and `Blob.slice(..., contentType)` MIME type
  inputs with File API semantics.
- Fixed wrapped `Response` copy semantics so init overrides are applied and
  source body state is not aliased across native, `dart:io`, and js wrappers.

## 0.4.2

- Aligned native and `dart:io` `Headers` iteration with Fetch semantics so
  repeated non-`set-cookie` headers are combined while repeated `set-cookie`
  values remain separate.

## 0.4.1

- Fixed `dart:io` `Headers(existingHeaders)` construction so it copies header
  entries instead of aliasing the source `Headers` host.

## 0.4.0

- Hardened native `FormData.parse()` `multipart/form-data` parsing for real
  HTTP interop, including quoted boundaries, strict boundary delimiters,
  duplicate header/parameter rejection, `Content-Disposition` validation,
  charset-aware text fields, and RFC 5987-style `filename*` compatibility.
- Switched native multipart parsing to stream input chunks instead of eagerly
  materializing the whole request body, while keeping parsed file parts on the
  existing lazy `Blob`/`Block` path.
- Fixed multipart boundary handling so boundary-like bytes inside binary
  payloads, including closing-boundary-like lines and split closing delimiters,
  are preserved correctly.
- Fixed Fetch constructor invariants for methods and statuses that cannot carry
  bodies.
- Fixed `URLSearchParams.sort()` ordering stability.
- Fixed repeated `dart:io` header values when adapting native headers.
- Clarified file body initialization documentation and updated request examples.
- Upgraded the `block` dependency constraint to use the newer file adapter.

## 0.3.2

- Fixed default `FormData.encodeMultipart()` boundary generation on js
  runtimes by avoiding `Random.secure()`, which is unavailable under the Dart
  Node test platform.
- Expanded CI test coverage to run the full test suite on VM, Node, and Chrome.

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
