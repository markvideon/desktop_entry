import 'dart:html' show File;

import '../model/desktop_entry/desktop_contents.dart';

Future<String> installFromMemory(
    {required DesktopFileContents contents, required String filename}) async {
  return '';
}

Future<String> installFromFile(File file,
    {String? overrideInstallationDirectoryPath}) async {
  return '';
}

Future<void> uninstall(File file) async {}
