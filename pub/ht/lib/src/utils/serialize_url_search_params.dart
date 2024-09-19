import '../web/url_search_params.dart';

String serializeURLSearchParams(URLSearchParams searchParams) {
  final buffer = StringBuffer();
  final lastIndex = searchParams.length - 1;

  for (final (index, (name, value)) in searchParams.indexed) {
    buffer.write(Uri.encodeQueryComponent(name));
    buffer.write('=');
    buffer.write(Uri.encodeQueryComponent(value));
    if (index < lastIndex) {
      buffer.write('&');
    }
  }

  return buffer.toString();
}
