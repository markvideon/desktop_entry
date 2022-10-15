import 'dart:async';
import 'dart:developer';
import 'dart:io' show File, FileSystemException, Platform, Process;
import '../model/desktop_contents.dart';
import 'package:path/path.dart' show Context, Style;
import '../util/util.dart';

Future<String> installFromMemory({
  required DesktopContents contents,
  required String filename,
  required String installationPath,
  Future<String> Function()? getPassword
}) async {
  // Deliberate decision not to throw errors based on runtime platform at this time.
  if (Platform.isLinux == false) {
    return '';
  }

  final file = await DesktopContents.toFile(filename, contents);
  return installFromFile(
    file,
    installationDirectoryPath: installationPath,
    getPassword: getPassword
  );
}

// Locations: these correspond to the 'applications' folder of each of the
// XDG_DATA_DIRS
// /usr/share/ubuntu/applications,
// /home/mark/.local/share/flatpak/exports/share/applications,
// /var/lib/flatpak/exports/share/applications,
// /usr/local/share/applications,
// /usr/share/applications,
// /var/lib/snapd/desktop/applications

Future<String> installFromFile(File file, {
  required String installationDirectoryPath,
  Future<String> Function()? getPassword
    }) async {
  // Deliberate decision not to throw errors based on runtime platform at this time.
  if (Platform.isLinux == false) {
    return '';
  }

  if (!file.existsSync()) {
    throw const FileSystemException('File not found');
  }
  final appliedDestinationDirectoryPath = installationDirectoryPath;
  log('Installing from... ${file.path}');
  log('Installing to... $appliedDestinationDirectoryPath');

  const processName = 'desktop-file-install';
  final arguments = [
    file.path,
    '--dir=$appliedDestinationDirectoryPath'
  ];

  final fileInstall = await Process.run(
    processName,
    arguments,
    runInShell: true
  );

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
      [],
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

// todo: Allow admin permissions
Future<void> uninstall(File file) async {
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
        [],
        runInShell: true
    );
  }
}