import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() async {
  test('Write Shell Script', () async {
    final file = File('test.sh');
    expect(file.existsSync(), true);

    file.deleteSync();
    expect(file.existsSync(), false);
  });

  test('File path', () {
    expect(true, true);
  });
}