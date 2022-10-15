import 'dart:convert';
import 'dart:developer';
import 'dart:io' if (dart.library.html) 'dart:html' show Directory, File, Platform;

import 'package:desktop_entry/desktop_entry.dart';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'package:xdg_directories/xdg_directories.dart';

final pathContext = Context(style: Style.posix);

final manualDefinitionExample = DesktopContents(
  entry: DesktopEntry(
    group: DesktopGroup('Desktop Entry'),
    version: SpecificationString('1.0'),
    unrecognisedEntries: <UnrecognisedEntry>[
      UnrecognisedEntry(key: 'UnknownKey', values: ['UnknownValue'])
    ],
    type: SpecificationString('Application'),
    name: SpecificationLocaleString('Foo Viewer'),
    comment: SpecificationLocaleString('The best viewer for Foo objects available!'),
    tryExec: SpecificationString('fooview'),
    exec: SpecificationString('fooview %u'),
    icon: SpecificationIconString('fooview'),
    mimeType: SpecificationTypeList<SpecificationString>(
      <SpecificationString>[
        SpecificationString('image/x-foo'),
        SpecificationString('x-scheme-hander/fooview'),
      ],
      elementConstructor: () => SpecificationString('')
    ),
    actions: SpecificationTypeList<SpecificationString>(
      <SpecificationString>[
        SpecificationString('Gallery'),
        SpecificationString('Create')
      ],
      elementConstructor: () => SpecificationString('')
    )
  ),
  unrecognisedGroups: <UnrecognisedGroup>[
    UnrecognisedGroup(
      group: DesktopGroup('UnknownGroup'),
      entries: <UnrecognisedEntry>[
        UnrecognisedEntry(key: 'UnknownGroup', values: ['Unknown Value'])
      ]
    ),
    UnrecognisedGroup(
      group: DesktopGroup('EmptyGroup'),
      entries: <UnrecognisedEntry>[

      ]
    ),
  ],
  actions: <DesktopAction>[
    DesktopAction(
      group: DesktopGroup(
        'Desktop Action Gallery',
        comments: ['', 'comment line above desktop action gallery', '']
      ),
      exec: SpecificationString('fooview --gallery'),
      name: SpecificationLocaleString('Browse Gallery'),
    ),
    DesktopAction(
      group: DesktopGroup(
        'Desktop Action Create'
      ),
      exec: SpecificationString('fooview --create-new'),
      name: SpecificationLocaleString('Create a new Foo!'),
      icon: SpecificationIconString('fooview-new')
    )
  ],
  trailingComments: <String>[]
);

/*
final firefoxDefinition = DesktopContents(
  entry: entry,
  actions: actions,
  unrecognisedGroups: unrecognisedGroups,
  trailingComments: trailingComments
);*/

void main() async {
  test('Check XDG Directory Exists', () async {
    final pathContext = Context(style: Style.posix);

    final existsLookup = <String, bool>{};
    for (var element in dataDirs) {
      final pathToApplicationSubfolder = pathContext.join(element.path, 'applications');
      log(pathToApplicationSubfolder);
      existsLookup[pathToApplicationSubfolder] = Directory(pathToApplicationSubfolder).existsSync();
      if (existsLookup[pathToApplicationSubfolder] == false) {
        log('$pathToApplicationSubfolder DNE');
      }
    }

    expect(existsLookup.values.contains(false), false);
  });

  test('Can Create Missing XDG Directories', () async {
    final pathContext = Context(style: Style.posix);

    final existsLookup = <String, bool>{};
    for (var element in dataDirs) {
      final pathToApplicationSubfolder = pathContext.join(element.path, 'applications');
      final directory = Directory(pathToApplicationSubfolder);
      log(pathToApplicationSubfolder);
      existsLookup[pathToApplicationSubfolder] = directory.existsSync();
      if (existsLookup[pathToApplicationSubfolder] == false) {
        await createDirectoryIfDne(pathToApplicationSubfolder);
        expect(directory.existsSync(), true);
        await deleteExistingDirectory(pathToApplicationSubfolder);
      }
    }
  });

  test('Install Desktop Entry - Existing', () async {
    const filename = 'example-success.desktop';
    const existingPath = 'test/$filename';
    final existingFile = File(existingPath);

    final pathContext = Context(style: Style.posix);
    expect(
      Platform.environment['HOME'] is String &&
      (Platform.environment['HOME'] as String).isNotEmpty,
      true);

    final destinationFolderPath = pathContext.join(
        Platform.environment['HOME']!,
        localUserDesktopEntryInstallationDirectoryPath);

    await installFromFile(
        existingFile,
        installationDirectoryPath: destinationFolderPath);

    final destinationFilePath = pathContext.join(destinationFolderPath, filename);
    final destinationFile = File(destinationFilePath);
    log('Destination file: ${destinationFile.path}');
    expect(destinationFile.existsSync(), true);
  });

  test('Uninstall Desktop Entry - Existing', () async {
    const filename = 'example-success.desktop';

    final pathContext = Context(style: Style.posix);
    final sourceFilePath = pathContext.join(
        Platform.environment['HOME']!,
        localUserDesktopEntryInstallationDirectoryPath,
        filename);
    final file = File(sourceFilePath);

    expect(file.existsSync(), true);

    await _uninstall(filename);

    expect(file.existsSync(), false);
  });

  test('Parse Desktop File Correctly', () async {
    const filename = 'example-success.desktop';
    const existingPath = 'test/$filename';
    final existingFile = File(existingPath);

    final DesktopContents contents = DesktopContents.fromFile(existingFile);
    print(compareMaps(DesktopContents.toData(contents), DesktopContents.toData(manualDefinitionExample)));
    expect(contents == manualDefinitionExample, true);
  });
}

/*
  Test Util functions
*/
/// Install the Desktop file at [projectRoot]/test/[filename]
install(String filename, {File? file}) async {
  final existingPath = 'test/$filename';
  final existingFile = file ?? File(existingPath);

  final pathContext = Context(style: Style.posix);
  final destinationFilePath = pathContext.join(Platform.environment['HOME']!, localUserDesktopEntryInstallationDirectoryPath, filename);

  await installFromFile(existingFile, installationDirectoryPath: destinationFilePath);
}

/// Install the Desktop file at [projectRoot]/test/[filename]
/// if it does not already exist.
/// Uninstall the file.
_uninstall(String filename) async {
  final pathContext = Context(style: Style.posix);
  final installedPath = pathContext.join(
      Platform.environment['HOME']!,
      localUserDesktopEntryInstallationDirectoryPath,
      filename);
  final file = File(installedPath);
  log('About to uninstall file at ${file.path}');
  await uninstall(file);
  expect(file.existsSync(), false);
}

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