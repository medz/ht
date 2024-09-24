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

/// Parses a query string into a [URLSearchParams] object.
URLSearchParams parseURLSearchParams(String queryString) {
  final searchParams = URLSearchParams();
  final pairs = queryString.split('&');

  for (final pair in pairs) {
    final index = pair.indexOf('=');
    if (index == -1) {
      searchParams.append(Uri.decodeQueryComponent(pair), '');
      continue;
    }

    final name = pair.substring(0, index);
    final value = pair.substring(index + 1);
    searchParams.append(
        Uri.decodeQueryComponent(name), Uri.decodeQueryComponent(value));
  }

  return searchParams;
}
