import 'package:ht/src/fetch/body.dart';
import 'package:ht/src/fetch/form_data.native.dart';
import 'package:test/test.dart';

void main() {
  group('FormData.parse (native)', () {
    test('parses application/x-www-form-urlencoded bodies', () async {
      final formData = await FormData.parse(
        Body('a=1&a=2&hello=world+x'),
        contentType: 'application/x-www-form-urlencoded',
      );

      expect(formData.get('a'), isA<TextMultipartBody>());
      expect((formData.get('a')! as TextMultipartBody).value, '1');
      expect(
        formData.getAll('a').map((value) => (value as TextMultipartBody).value),
        ['1', '2'],
      );
      expect((formData.get('hello')! as TextMultipartBody).value, 'world x');
    });

    test('accepts content-type parameters when parsing urlencoded bodies', () async {
      final formData = await FormData.parse(
        Body('name=seven+du'),
        contentType:
            'application/x-www-form-urlencoded; charset=utf-8',
      );

      expect((formData.get('name')! as TextMultipartBody).value, 'seven du');
    });
  });
}
