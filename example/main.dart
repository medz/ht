import 'dart:convert';

import 'package:ht/ht.dart';

Future<void> main() async {
  final request = Request(
    RequestInput.uri(Uri.parse('https://api.example.com/tasks')),
    RequestInit(
      method: HttpMethod.post,
      headers: Headers({'content-type': 'application/json; charset=utf-8'}),
      body: jsonEncode({'title': 'Ship ht', 'priority': 'high'}),
    ),
  );

  print('Request: ${request.method} ${request.url}');
  print('Request content-type: ${request.headers.get('content-type')}');
  print('Request body: ${await request.text()}');

  final response = Response(
    jsonEncode({'ok': true, 'id': 'task_123'}),
    ResponseInit(
      status: HttpStatus.created,
      headers: Headers({'content-type': MimeType.json.toString()}),
    ),
  );

  print('Response status: ${response.status} ${response.statusText}');
  print('Response ok: ${response.ok}');
  print('Response body: ${await response.text()}');
}
