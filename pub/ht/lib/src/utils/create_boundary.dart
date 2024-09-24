import 'dart:math';

const chars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
final random = Random.secure();

String createBoundary() {
  final buffer = StringBuffer('-');
  buffer.write(DateTime.now().millisecondsSinceEpoch.toRadixString(36));
  buffer.write('-');
  for (var i = 0; i < 16; i++) {
    buffer.write(chars[random.nextInt(chars.length)]);
  }

  return buffer.toString();
}
