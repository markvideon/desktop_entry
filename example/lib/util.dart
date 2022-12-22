import 'dart:io';

import 'package:desktop_entry/desktop_entry.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'const.dart';
import 'entry.dart';

final pathContext = Context(style: Style.posix);

Future<void> installShellScript({
  required String dbusName,
  required String objectPath,
}) async {
  final shellScript = await shellScriptFilePath();

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
  final shellScript = await shellScriptFilePath();
  shellScript.deleteSync();
}

Future<void> installShellScriptDesktopEntry(String destinationPath) async {
  final pathToDirectory = pathContext.dirname(desktopEntryFilePath(destinationPath, shellScriptDesktopName).path);

  final launcherContents = await launcher();
  final tempDir = await getTemporaryDirectory();
  final desktopFilePath = await installDesktopFileFromMemory(
    tempDir: tempDir,
    contents: launcherContents,
    filenameNoExtension: shellScriptDesktopName,
    installationPath: pathToDirectory
  );

  await setDefaultForMimeTypes(
    desktopFilePath,
      launcherContents.entry.mimeType!.map((element) => element.value).toList(growable: false)
  );
}

Future<void> uninstallShellScriptDesktopEntry(e) async {
  final file = desktopEntryFilePath(e, shellScriptDesktopName);
  await uninstallDesktopFile(file);
}

Future<void> installAppDesktopFile(e, {String? desktopFileName}) async {
  final pathToDirectory = pathContext.dirname(desktopEntryFilePath(e, desktopFileName ?? dbusName).path);
  final tempDir = await getTemporaryDirectory();

  await installDesktopFileFromMemory(
      tempDir: tempDir,
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
  final tempDir = await getTemporaryDirectory();

  await installDbusServiceFromMemory(
    tempDir: tempDir,
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

// todo: Move this file to another directory. Each time the app builds the
//  file will be removed if it is set to the executable directory.
Future<File> shellScriptFilePath() async {
  final supportDir = await getApplicationSupportDirectory();

  final basePath = supportDir.path;
  final pathToFile = pathContext.join(
      basePath,
      '$shellScriptName.sh',
  );

  return File(pathToFile);
}