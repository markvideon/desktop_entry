import 'dart:io' if (dart.library.html) 'dart:html' show File, Platform;

import 'package:desktop_entry/desktop_entry.dart';
import 'package:test/test.dart';
import 'package:path/path.dart';

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
    mimeType: <SpecificationString>[
      SpecificationString('image/x-foo'),
      SpecificationString('x-scheme-hander/fooview'),
    ],
    actions: <SpecificationString>[
      SpecificationString('Gallery'),
      SpecificationString('Create')
    ]
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
  test('Install Desktop Entry - Existing', () async {
    const filename = 'example-success.desktop';
    const existingPath = 'test/$filename';
    final existingFile = File(existingPath);

    final pathContext = Context(style: Style.posix);
    expect(
      Platform.environment['HOME'] is String &&
      (Platform.environment['HOME'] as String).isNotEmpty,
      true);

    print('Part 1: ${Platform.environment['HOME']}');
    print('Part 2: $localUserDesktopEntryInstallationDirectoryPath');
    final destinationFilePath = pathContext.join(Platform.environment['HOME']!, localUserDesktopEntryInstallationDirectoryPath);

    await installFromFile(existingFile, installationDirectoryPath: destinationFilePath);

    final destinationFile = File(destinationFilePath);
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

    await uninstall(filename);

    expect(file.existsSync(), false);
  });

  test('Check Example File Exists', () async {
    // Path is relative to project root.
    const existingPath = 'test/example-fail.desktop';
    final file = File(existingPath);

    expect(await file.exists(), true);
  });

  test('`example-fail.desktop` Entry Written Then Read Correctly', () async {
    final file = await DesktopContents.toFile('test', manualDefinitionExample);
    final parsedDefinition = DesktopContents.fromFile(file);

    expect(manualDefinitionExample == parsedDefinition, true);

    file.deleteSync();
    expect(file.existsSync(), false);
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
uninstall(String filename) async {
  final pathContext = Context(style: Style.posix);
  final installedPath = pathContext.join(
      Platform.environment['HOME']!,
      localUserDesktopEntryInstallationDirectoryPath,
      filename);
  final file = File(installedPath);

  if (!file.existsSync()) {
    await install(filename);
  }

  expect(file.existsSync(), false);
}