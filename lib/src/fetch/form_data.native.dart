import 'blob.dart';
import 'body.dart';
import 'file.dart';
import 'url_search_params.dart';

sealed class MultipartBody {
  const MultipartBody();

  const factory MultipartBody.text(String value) = TextMultipartBody;
  factory MultipartBody.blob(Blob value, [String? filename]) =>
      BlobMultipartBody(value, filename);
}

final class TextMultipartBody extends MultipartBody {
  const TextMultipartBody(this.value);

  final String value;
}

final class BlobMultipartBody extends File implements MultipartBody {
  BlobMultipartBody(Blob value, [String? filename])
    : filename = switch (value) {
        final File file => filename ?? file.name,
        _ => filename ?? 'blob',
      },
      super(<BlobPart>[value], value.type);

  final String filename;
}

class FormData with Iterable<MapEntry<String, MultipartBody>> {
  static Future<FormData> parse(Body body, {String? contentType}) async {
    final essence = _contentTypeEssence(contentType);
    return switch (essence) {
      'application/x-www-form-urlencoded' => _parseUrlEncoded(body),
      'multipart/form-data' => throw UnimplementedError(
        'Multipart form-data parsing is not implemented yet.',
      ),
      _ => throw UnsupportedError(
        'Unsupported form content type: ${contentType ?? '(missing)'}',
      ),
    };
  }

  final _entries = <MapEntry<String, MultipartBody>>[];

  @override
  Iterator<MapEntry<String, MultipartBody>> get iterator => _entries.iterator;

  Iterable<MapEntry<String, MultipartBody>> entries() => this;

  Iterable<String> keys() sync* {
    for (final MapEntry(:key) in _entries) {
      yield key;
    }
  }

  Iterable<MultipartBody> values() sync* {
    for (final MapEntry(:value) in _entries) {
      yield value;
    }
  }

  MultipartBody? get(String name) {
    for (final entry in _entries) {
      if (entry.key == name) {
        return entry.value;
      }
    }

    return null;
  }

  List<MultipartBody> getAll(String name) {
    return List<MultipartBody>.unmodifiable(
      _entries.where((entry) => entry.key == name).map((entry) => entry.value),
    );
  }

  bool has(String name) => _entries.any((entry) => entry.key == name);

  void append(String name, MultipartBody value) {
    _entries.add(MapEntry<String, MultipartBody>(name, value));
  }

  void delete(String name) {
    _entries.removeWhere((entry) => entry.key == name);
  }

  void set(String name, MultipartBody value) {
    delete(name);
    append(name, value);
  }

  static Future<FormData> _parseUrlEncoded(Body body) async {
    final params = URLSearchParams(await body.text());
    final formData = FormData();
    for (final MapEntry(:key, :value) in params.entries()) {
      formData.append(key, MultipartBody.text(value));
    }
    return formData;
  }

  static String _contentTypeEssence(String? contentType) {
    if (contentType == null) return '';

    final separator = contentType.indexOf(';');
    final essence = separator == -1
        ? contentType
        : contentType.substring(0, separator);
    return essence.trim().toLowerCase();
  }
}
