import 'dart:io';

import 'package:desktop_entry/desktop_entry.dart';
import 'package:flutter_test/flutter_test.dart';

final sampleDbusService = DBusFileContents(
  dBusServiceDefinition: DBusServiceDefinition(
    name: SpecificationInterfaceName('dev.markvideon.DesktopEntryExample'),
    exec: SpecificationFilePath(
      Uri.file('/home/mark/Documents/dartdesktopentry/example/build/linux/x64/debug/bundle/example')
    ),
  ),
  unrecognisedGroups: [],
  trailingComments: []
);

// todo:
void main() async {
  //
  test('Parse D-BUS Service File Correctly', () async {
    const filename = 'example.service';
    const existingPath = 'test/$filename';
    final existingFile = File(existingPath);
    final contents = DBusFileContents.fromFile(existingFile);

    expect(contents == sampleDbusService, true);
  });

  test('Write D-BUS Service to File Correctly', () async {
    final file = await DBusFileContents.toFile('name', sampleDbusService);
    final readFromFile = DBusFileContents.fromFile(file);

    expect(readFromFile == sampleDbusService, true);
  });
}