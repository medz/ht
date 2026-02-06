import 'blob.dart';

/// File metadata wrapper over [Blob].
class File extends Blob {
  File(Iterable<Object> parts, this.name, {String type = '', int? lastModified})
    : lastModified = lastModified ?? DateTime.now().millisecondsSinceEpoch,
      super(parts, type);

  final String name;
  final int lastModified;
}
