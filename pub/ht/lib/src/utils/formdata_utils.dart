import 'dart:convert';
import 'dart:typed_data';
import 'package:mime/mime.dart';
import '../web/file.dart';
import '../web/formdata.dart';
import '../web/headers.dart';
import '../web/blob.dart';
import '../mime.dart';
import 'create_boundary.dart';

Future<FormData> parseFormData(
    String boundary, Stream<Uint8List> stream) async {
  final transformer = MimeMultipartTransformer(boundary);
  final formData = FormData();

  await for (final part in transformer.bind(stream)) {
    final headers = Headers(part.headers);
    final contentType = MimeType.parse(headers.get('content-type')!);
    final contentDisposition = headers.get('content-disposition')?.trim();
    if (contentDisposition == null) {
      continue;
    }
    final {'name': String name, 'filename': String? filename} =
        MimeType.parse('ht/$contentDisposition').params;
    if (filename == null && contentType.essence == MimeType.plain.essence) {
      formData.append(name, await utf8.decodeStream(part));
      continue;
    }

    final bytes = await part.fold<Uint8List>(Uint8List(0),
        (previous, element) => Uint8List.fromList([...previous, ...element]));
    final blob = Blob.bytes(bytes, type: contentType.toString());

    formData.append(name, blob, filename ?? 'blob');
  }

  return formData;
}

/// Serializes a [FormData] object into a [Blob] object.
Blob serializeFromData(FormData formData) {
  final boundary = createBoundary();
  final blobs = formData.map((e) => e.$2 is StringFormDataEntry
      ? _createStringMultipart(boundary, e.$1, e.$2.value)
      : _createFileMultipart(boundary, e.$1, e.$2.value));
  final size =
      blobs.fold<int>(0, (previous, element) => previous + element.size);
  final type = MimeType('multipart', 'form-data', {'boundary': boundary});

  Stream<Uint8List> stream() async* {
    for (final blob in blobs) {
      yield* blob.stream();
    }
  }

  return Blob.stream(stream(), size: size, type: type.toString());
}

Blob _createFileMultipart(String boundary, String name, File file) {
  final buffer = StringBuffer('--$boundary\r\n');
  buffer.write(
      'content-disposition: form-data; name="$name"; filename="${file.name}"\r\n');
  buffer.write('content-type: ${file.type}\r\n\r\n');

  final bytes = utf8.encode(buffer.toString());
  Stream<Uint8List> stream() async* {
    yield bytes;
    yield* file.stream();
    yield utf8.encode('\r\n');
  }

  return Blob.stream(stream(), size: bytes.lengthInBytes + file.size + 2);
}

Blob _createStringMultipart(String boundary, String name, String value) {
  final buffer = StringBuffer('--$boundary\r\n');
  buffer.write('content-disposition: form-data; name="$name"\r\n\r\n');
  buffer.write(value);
  buffer.write('\r\n');

  return Blob.text(buffer.toString());
}
