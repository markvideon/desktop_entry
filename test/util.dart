import 'dart:io';

/*
  Test Util functions
*/

Future<void> createDirectoryIfDne(String path) async {
  final directory = Directory(path);

  if (!directory.existsSync()) {
    await Directory(path).create(recursive: true);
  }
}

Future<void> deleteExistingDirectory(String path) async {
  final directory = Directory(path);

  if (directory.existsSync()) {
    await Directory(path).delete(recursive: true);
  }
}
