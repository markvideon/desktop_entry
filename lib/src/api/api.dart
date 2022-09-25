import 'dart:io' show File, FileSystemException, Platform, Process;
import 'package:path/path.dart' show Context, Style;
import '../const.dart';
import '../model/desktop_entry.dart';

Future<String> installFromMemory({required DesktopEntry entry, required String filename}) async {
  // Deliberate decision not to throw errors based on runtime platform at this time.
  if (Platform.isLinux == false) {
    return '';
  }

  final file = await DesktopEntry.toFile(filename, entry);
  return installFromFile(file);
}

Future<String> installFromFile(File file, {String? overrideInstallationDirectoryPath}) async {
  // Deliberate decision not to throw errors based on runtime platform at this time.
  if (Platform.isLinux == false) {
    return '';
  }

  if (!file.existsSync()) {
    throw const FileSystemException('File not found');
  }
  final appliedDestinationDirectoryPath = overrideInstallationDirectoryPath ?? allUsersDesktopEntryInstallationDirectoryPath;

  final fileInstall = await Process.run(
      'desktop-file-install',
      [
        file.path,
        '--dir=$appliedDestinationDirectoryPath'
      ],
      runInShell: true
  );

  if (fileInstall.exitCode < 0) {
    throw Exception('Error code on installation: ${fileInstall.exitCode}');
  }

  final updateDatabase = await Process.run(
      'update-desktop-database',
      [],
      runInShell: true
  );

  if (updateDatabase.exitCode < 0) {
    throw Exception('Error code on updateDatabase: ${updateDatabase.exitCode}');
  }

  final pathContext = Context(style: Style.posix);
  final destinationFilePath = pathContext.join(appliedDestinationDirectoryPath, pathContext.basename(file.path));
  if (File(destinationFilePath).existsSync()) {
    return destinationFilePath;
  } else {
    throw const FileSystemException('Installation failed');
  }
}

Future<void> uninstall(File file) async {
  // Deliberate decision not to throw errors based on runtime platform at this time.
  if (Platform.isLinux == false) {
    return;
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