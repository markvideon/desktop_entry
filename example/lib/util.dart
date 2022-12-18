import 'dart:io';

import 'package:desktop_entry/desktop_entry.dart';
import 'package:path/path.dart';

import 'const.dart';
import 'final.dart';

final pathContext = Context(style: Style.posix);

Future<void> installShellScript({
  required String dbusName,
  required String objectPath,
}) async {
  final shellScript = shellScriptFilePath();

  shellScript.writeAsStringSync("#!/bin/bash\n", mode: FileMode.writeOnly);
  shellScript.writeAsStringSync("gdbus call --session --dest $dbusName \\\n", mode: FileMode.writeOnlyAppend);
  shellScript.writeAsStringSync("--object-path $objectPath \\\n", mode: FileMode.writeOnlyAppend);
  shellScript.writeAsStringSync("--method org.freedesktop.Application.Open \"['\$1']\" {}\n", mode: FileMode.writeOnlyAppend);

  // Make executable
  await Process.run(
    'chmod',
    [
      '755',
      shellScript.absolute.path
    ],
    runInShell: true
  );
}

Future<void> uninstallShellScript() async {
  final shellScript = shellScriptFilePath();
  shellScript.deleteSync();
}

Future<void> installShellScriptDesktopEntry(String destinationPath) async {
  await installDesktopFileFromMemory(
      contents: launcher,
      filenameNoExtension: shellScriptDesktopName,
      installationPath: destinationPath
  );
}

Future<void> uninstallShellScriptDesktopEntry(e) async {
  await uninstallAppDesktopFile(e, desktopFileName: shellScriptDesktopName);
}

Future<void> installAppDesktopFile(e, {String? desktopFileName}) async {
  final pathToDirectory = pathContext.dirname(desktopEntryFilePath(e, desktopFileName ?? dbusName).path);

  await installDesktopFileFromMemory(
      contents: entry,
      filenameNoExtension: desktopFileName ?? dbusName,
      installationPath: pathToDirectory
  );
}

Future<void> uninstallAppDesktopFile(e, {String? desktopFileName}) async {
  final file = desktopEntryFilePath(e, desktopFileName ?? dbusName);
  await uninstallDesktopFile(file);
}

Future<void> installAppDbusServiceFile(e) async {
  final pathToDirectory = pathContext.dirname(dbusFilePath(e, dbusName).path);

  await installDbusServiceFromMemory(
      dBusServiceContents: dbus,
      filenameNoExtension: dbusName,
      installationPath: pathToDirectory
  );
}

Future<void> uninstallAppDbusServiceFile(e) async {
  final file = dbusFilePath(e, dbusName);
  await uninstallDbusServiceFile(file);
}

File dbusFilePath(String basePath, String dbusName) {
  final pathToFile = pathContext.join(basePath, 'dbus-1/services/$dbusName.service');
  return File(pathToFile);
}

File desktopEntryFilePath(String basePath, String desktopFileName) {
  final pathToFile = pathContext.join(basePath, 'applications/$desktopFileName.desktop');
  return File(pathToFile);
}

File shellScriptFilePath() {
  final basePath = pathContext.dirname(Platform.executable);
  final pathToFile = pathContext.join(
      basePath,
      shellScriptName,
      '.sh'
  );
  
  return File(pathToFile);
}