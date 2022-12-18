import 'dart:async';
import 'dart:developer';
import 'dart:io' show Directory, File, FileSystemException, Platform, Process;

import 'package:desktop_entry/src/model/dbus/dbus_contents.dart';
import 'package:path/path.dart' show Context, Style;

import '../model/desktop_entry/desktop_contents.dart';
import '../util/util.dart';

// https://nyirog.medium.com/register-dbus-service-f923dfca9f1

/*
  MIME
*/
Future<void> setDefaultForMimeTypes(String applicationPath, List<String> mimeTypes) async {
  if (mimeTypes.isEmpty) {
    throw Exception('Expected MIME types to be provided.');
  }

  final defaultSet = await Process.run(
    'xdg-mime',
    <String>[
      'default',
      applicationPath,
      ...mimeTypes
    ],
    runInShell: true
  );

  try {
    checkProcessStdErr(defaultSet);
  } catch (error) {
    log('$error');
  }
}

/*
  Desktop File
*/
Future<String> installDesktopFileFromMemory({
  required DesktopFileContents contents,
  required String filenameNoExtension,
  required String installationPath,
}) async {
  final file = await DesktopFileContents.toFile(filenameNoExtension, contents);
  return installDesktopFileFromFile(
    file,
    installationDirectoryPath: installationPath,
  );
}

Future<String> installDesktopFileFromFile(File file, {
  required String installationDirectoryPath
}) async {
  if (!file.existsSync()) {
    throw const FileSystemException('File not found');
  }
  Directory(installationDirectoryPath).createSync(recursive: true);

  final appliedDestinationDirectoryPath = installationDirectoryPath;

  // Install .desktop file
  const processName = 'desktop-file-install';
  final arguments = [
    file.path,
    '--dir=$appliedDestinationDirectoryPath',
    '--rebuild-mime-info-cache'
  ];

  final fileInstall = await Process.run(
    processName,
    arguments,
    runInShell: true
  );

  print('Installing to $appliedDestinationDirectoryPath');
  try {
    checkProcessStdErr(fileInstall);
  } catch (error) {
    log('$error');
  }

  if (fileInstall.exitCode < 0) {
    throw Exception('Error code on installation: ${fileInstall.exitCode}');
  }

  final updateDatabase = await Process.run(
    'update-desktop-database',
    [
      appliedDestinationDirectoryPath
    ],
    runInShell: true
  );

  try {
    checkProcessStdErr(updateDatabase);
  } catch (error) {
    log('$error');
  }

  if (updateDatabase.exitCode < 0) {
    throw Exception('Error code on updateDatabase: ${updateDatabase.exitCode}');
  }

  final pathContext = Context(style: Style.posix);
  final destinationFilePath = pathContext.join(appliedDestinationDirectoryPath, pathContext.basename(file.path));
  if (File(destinationFilePath).existsSync()) {
    return destinationFilePath;
  } else {
    throw FileSystemException('Installation failed.', destinationFilePath);
  }
}

Future<void> uninstallDesktopFile(File file) async {
  // Deliberate decision not to throw errors based on runtime platform at this time.
  if (Platform.isLinux == false) {
    return;
  }
  if (!file.existsSync()) {
    throw const FileSystemException('File did not exist');
  }

  if (file.existsSync()) {
    file.deleteSync();

    await Process.run(
        'update-desktop-database',
        [
          file.parent.absolute.path
        ],
        runInShell: true
    );
  }
}

/*
  D-BUS
*/
Future<String> installDbusServiceFromMemory({
  required String filenameNoExtension,
  required DBusFileContents dBusServiceContents,
  required String installationPath,
}) async {
  final file = await DBusFileContents.toFile(filenameNoExtension, dBusServiceContents);
  return installDbusServiceFromFile(
    file,
    installationDirectoryPath: installationPath,
  );
}

Future<String> installDbusServiceFromFile(File file, {
  required String installationDirectoryPath,
}) async {
  Directory(installationDirectoryPath).createSync(recursive: true);
  final appliedDestinationDirectoryPath = installationDirectoryPath;

  final pathContext = Context(style: Style.posix);
  final destinationFilePath = pathContext.join(appliedDestinationDirectoryPath, pathContext.basename(file.path));

  final destinationFile = File(destinationFilePath);
  destinationFile.writeAsBytesSync(file.readAsBytesSync());

  if (destinationFile.existsSync() && destinationFile.readAsBytesSync().length == file.readAsBytesSync().length) {
    return destinationFilePath;
  } else {
    throw FileSystemException('Installation failed.', destinationFilePath);
  }
}

Future<void> uninstallDbusServiceFile(File file) async {
  if (!file.existsSync()) {
    throw const FileSystemException('File did not exist');
  }
  
  if (file.existsSync()) {
    file.deleteSync();
  }
}