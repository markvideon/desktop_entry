import 'dart:developer' show log;
import 'dart:io' show File;

import 'package:desktop_entry/desktop_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

final pathContext = Context(style: Style.posix);

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

  test('Map Parsed Successfully', () async {
    DesktopEntry manualDefinition = DesktopEntry(
      version: string('1.0'),
      type: string('Application'),
      entryName: localestring('Foo Viewer'),
      comment: localestring('The best viewer for Foo objects available!'),
      tryExec: string('fooview'),
      exec: string('fooview %F'),
      icon: iconstring('fooview'),
      mimeType: <string>[
        string('image/x-foo')
      ],
      actions: <DesktopAction>[
        DesktopAction(
          entryKey: string('Gallery'),
          actionName: localestring('Browse Gallery'),
          exec: string('fooview --gallery')
        ),
        DesktopAction(
          entryKey: string('Create'),
          actionName: localestring('Create a new Foo!'),
          exec: string('fooview --create-new'),
          icon: iconstring('fooview-new')
        )
      ]
    );

    DesktopEntry copyFromMap = DesktopEntry.fromMap(DesktopEntry.toMap(manualDefinition));
    expect(manualDefinition == copyFromMap, true);
  });

  test('Example Entry Written Then Read Correctly', () async {
    DesktopEntry manualDefinition = DesktopEntry(
        version: string('1.0'),
        type: string('Application'),
        entryName: localestring('Foo Viewer'),
        comment: localestring('The best viewer for Foo objects available!'),
        tryExec: string('fooview'),
        exec: string('fooview %F'),
        icon: iconstring('fooview'),
        mimeType: <string>[
          string('image/x-foo')
        ],
        actions: <DesktopAction>[
          DesktopAction(
            entryKey: string('Gallery'),
            actionName: localestring('Browse Gallery'),
            exec: string('fooview --gallery')
          ),
          DesktopAction(
            entryKey: string('Create'),
            actionName: localestring('Create a new Foo!'),
            exec: string('fooview --create-new'),
            icon: iconstring('fooview-new')
          )
        ]
    );

    final file = await DesktopEntry.toFile('test', manualDefinition);
    final parsedDefinition = DesktopEntry.fromFile(file);

    expect(manualDefinition == parsedDefinition, true);

    file.deleteSync();
    expect(file.existsSync(), false);
  });

  test('Example File Parsed Successfully', () async {
    const existingPath = 'test/example.desktop';
    final file = File(existingPath);

    DesktopEntry? entryFromFile;

    try {
      entryFromFile = DesktopEntry.fromFile(file);
    } catch (error) {
      log('$error');
    }

    // Assumes that this definition matches the contents of [example.desktop]
    DesktopEntry manualDefinition = DesktopEntry(
      version: string('1.0'),
      type: string('Application'),
      entryName: localestring('Foo Viewer'),
      comment: localestring('The best viewer for Foo objects available!'),
      tryExec: string('fooview'),
      exec: string('fooview %u'),
      icon: iconstring('fooview'),
      mimeType: <string>[
        string('image/x-foo'),
        string('x-scheme-handler/fooview')
      ],
      actions: <DesktopAction>[
        DesktopAction(
          entryKey: string('Gallery'),
          actionName: localestring('Browse Gallery'),
          exec: string('fooview --gallery')
        ),
        DesktopAction(
          entryKey: string('Create'),
          actionName: localestring('Create a new Foo!'),
          exec: string('fooview --create-new'),
          icon: iconstring('fooview-new')
        )
      ]
    );

    manualDefinition.compareWith(entryFromFile!);

    expect(manualDefinition == entryFromFile, true);
  });

  test('Uninstall Desktop Entry', () async {
    final file = File(allUsersDesktopEntryInstallationDirectoryPath);
    await uninstall(file);

    expect(file.existsSync(), false);
  });
}
