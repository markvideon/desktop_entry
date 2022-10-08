import 'dart:developer' show log;
import 'dart:io' if (dart.library.html) 'dart:html' show File;

import 'package:desktop_entry/desktop_entry.dart';
import 'package:flutter_test/flutter_test.dart';
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
    const filename = 'example.desktop';
    const existingPath = 'test/$filename';
    final file = File(existingPath);

    final path = await installFromFile(file);
    final destinationFile = File(path);
    expect(destinationFile.existsSync(), true);
  });

  test('Check Example File Exists', () async {
    // Path is relative to project root.
    const existingPath = 'test/example.desktop';
    final file = File(existingPath);

    expect(await file.exists(), true);
  });

  test('Manual Definition Serialised Then Parsed Successfully', () async {
    DesktopContents copyFromMap = DesktopContents.fromMap(DesktopContents.toData(manualDefinitionExample));
    expect(manualDefinitionExample == copyFromMap, true);
  });

  test('`example.desktop` Entry Written Then Read Correctly', () async {

    final file = await DesktopContents.toFile('test', manualDefinitionExample);
    final parsedDefinition = DesktopContents.fromFile(file);

    expect(manualDefinitionExample == parsedDefinition, true);

    file.deleteSync();
    expect(file.existsSync(), false);
  });

  test('`example.desktop` Parsed Successfully', () async {
    log('ayo?');
    const existingPath = 'test/example.desktop';
    final file = File(existingPath);

    DesktopContents? entryFromFile;

    try {
      entryFromFile = DesktopContents.fromFile(file);
    } catch (error) {
      log('$error');
    }

    expect(compareMaps(DesktopContents.toData(entryFromFile!), DesktopContents.toData(manualDefinitionExample)), true);
  });

  test('Uninstall Desktop Entry', () async {
    final file = File(allUsersDesktopEntryInstallationDirectoryPath);
    await uninstall(file);

    expect(file.existsSync(), false);
  });
}
