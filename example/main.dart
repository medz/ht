import 'dart:convert';

import 'package:ht/ht.dart';

Future<void> main() async {
  final request = Request.json(
    Uri.parse('https://api.example.com/tasks'),
    method: HttpMethod.post.value,
    body: {'title': 'Ship ht', 'priority': 'high'},
  );

  print('Request: ${request.method} ${request.url}');
  print('Request content-type: ${request.headers.get('content-type')}');
  print('Request body: ${await request.text()}');

  final response = Response(
    status: HttpStatus.created,
    body: jsonEncode({'ok': true, 'id': 'task_123'}),
    headers: Headers({'content-type': MimeType.json.toString()}),
  );

  print('Response status: ${response.status} ${response.statusText}');
  print('Response ok: ${response.ok}');
  print('Response body: ${await response.text()}');
}
