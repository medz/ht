import 'dart:async';

import 'package:ht/src/_internal/stream_tee.dart';
import 'package:test/test.dart';

void main() {
  group('streamTee', () {
    test('duplicates a single-subscription stream', () async {
      final (left, right) = streamTee<int>(Stream<int>.fromIterable([1, 2, 3]));

      expect(await left.toList(), [1, 2, 3]);
      expect(await right.toList(), [1, 2, 3]);
    });

    test('duplicates a broadcast stream', () async {
      final controller = StreamController<int>.broadcast(sync: true);
      final (left, right) = streamTee<int>(controller.stream);

      final leftFuture = left.toList();
      final rightFuture = right.toList();

      controller.add(1);
      controller.add(2);
      controller.add(3);
      await controller.close();

      expect(await leftFuture, [1, 2, 3]);
      expect(await rightFuture, [1, 2, 3]);
    });
  });
}
