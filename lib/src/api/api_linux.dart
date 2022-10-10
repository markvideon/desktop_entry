import 'dart:io' show File, FileSystemException, Platform, Process;

import '../model/desktop_contents.dart';
import 'package:path/path.dart' show Context, Style;

import '../const.dart';
import '../util/util.dart';

Future<String> installFromMemory({
  required DesktopContents contents,
  required String filename,
  required String installationPath
}) async {
  // Deliberate decision not to throw errors based on runtime platform at this time.
  if (Platform.isLinux == false) {
    return '';
  }

  final file = await DesktopContents.toFile(filename, contents);
  return installFromFile(file, installationDirectoryPath: installationPath);
}

Future<String> installFromFile(File file, {required String installationDirectoryPath}) async {
  // Deliberate decision not to throw errors based on runtime platform at this time.
  if (Platform.isLinux == false) {
    return '';
  }

  if (!file.existsSync()) {
    throw const FileSystemException('File not found');
  }
  final appliedDestinationDirectoryPath = installationDirectoryPath;
  print('Installing from... ${file.path}');
  print('Installing to... $appliedDestinationDirectoryPath');
  final fileInstall = await Process.run(
      'desktop-file-install',
      [
        file.path,
        '--dir=$appliedDestinationDirectoryPath'
      ],
      runInShell: true
  );

  checkProcessStdErr(fileInstall);

  if (fileInstall.exitCode < 0) {
    throw Exception('Error code on installation: ${fileInstall.exitCode}');
  }

  final updateDatabase = await Process.run(
      'update-desktop-database',
      [],
      runInShell: true
  );

  checkProcessStdErr(updateDatabase);

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