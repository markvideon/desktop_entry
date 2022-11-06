import 'dart:developer';
import 'dart:io' if (dart.library.html) 'dart:html' show Directory, File, Platform;
import 'package:collection/collection.dart';
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
      UnrecognisedEntry(key: 'X-UnknownKey', values: ['UnknownValue'], comments: <String>[]),
      UnrecognisedEntry(key: 'X-Desktop-File-Install-Version', values: ['0.26'], comments: [''])
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
        SpecificationString('x-scheme-handler/fooview'),
      ],
    ),
    actions: SpecificationTypeList<SpecificationString>(
      <SpecificationString>[
        SpecificationString('Gallery'),
        SpecificationString('Create')
      ],
    )
  ),
  unrecognisedGroups: <UnrecognisedGroup>[
    UnrecognisedGroup(
      group: DesktopGroup(
        'X-UnknownGroup',
        comments: <String>['']
      ),
      entries: <UnrecognisedEntry>[
        UnrecognisedEntry(
          key: 'X-UnknownGroup',
          values: ['Unknown Value'],
          comments: <String>[]
        )
      ]
    ),
    UnrecognisedGroup(
      group: DesktopGroup(
        'X-EmptyGroup',
        comments: <String>['']
      ),
      entries: <UnrecognisedEntry>[

      ],
    ),
  ],
  actions: <DesktopAction>[
    DesktopAction(
      group: DesktopGroup(
        'Desktop Action Gallery',
        comments: ['', '# comment line above desktop action gallery', '']
      ),
      exec: SpecificationString('fooview --gallery'),
      name: SpecificationLocaleString('Browse Gallery'),
    ),
    DesktopAction(
      group: DesktopGroup(
        'Desktop Action Create',
        comments: ['']
      ),
      exec: SpecificationString('fooview --create-new'),
      name: SpecificationLocaleString('Create a new Foo!'),
      icon: SpecificationIconString('fooview-new')
    )
  ],
  trailingComments: <String>[]
);


final firefoxDefinition = DesktopContents(
  entry: DesktopEntry(
    version: SpecificationString('1.0'),
    name: SpecificationLocaleString(
      'Firefox Web Browser',
      localisedValues: <String, SpecificationLocaleString>{
        'ar': SpecificationLocaleString('متصفح الويب فَيَرفُكْس'),
        'ca': SpecificationLocaleString('Navegador web Firefox'),
        'zh_TW': SpecificationLocaleString('Firefox 網路瀏覽器')
      }
    ),
    comment: SpecificationLocaleString(
      'Browse the World Wide Web',
      localisedValues: <String, SpecificationLocaleString>{
        'ar': SpecificationLocaleString('تصفح الشبكة العنكبوتية العالمية'),
        'ca': SpecificationLocaleString('Navegueu per la web'),
        'zh_TW': SpecificationLocaleString('瀏覽網際網路')
      }
    ),
    genericName: SpecificationLocaleString(
      'Web Browser',
      localisedValues: <String, SpecificationLocaleString>{
      'ar': SpecificationLocaleString('متصفح ويب'),
      'ca': SpecificationLocaleString('Navegador web'),
      'zh_TW': SpecificationLocaleString('網路瀏覽器')
      }
    ),
    keywords: LocalisableSpecificationTypeList(
      'Internet;WWW;Browser;Web;Explorer'
          .split(';')
          .map((e) => SpecificationLocaleString(e))
          .toList(growable: false),
      localisedValues: <String, List<SpecificationLocaleString>>{
        'ar': 'انترنت;إنترنت;متصفح;ويب;وب'
          .split(';')
          .map((e) => SpecificationLocaleString(e))
          .toList(growable: false),
        'ca': 'Internet;WWW;Navegador;Web;Explorador;Explorer'
          .split(';')
          .map((e) => SpecificationLocaleString(e))
          .toList(growable: false),
        'zh_TW': 'Internet;WWW;Browser;Web;Explorer;網際網路;網路;瀏覽器;上網;網頁;火狐'
          .split(';')
          .map((e) => SpecificationLocaleString((e)))
          .toList(growable: false)
      }
    ),
    exec: SpecificationString('firefox %u'),
    terminal: SpecificationBoolean(false),
    unrecognisedEntries: <UnrecognisedEntry>[
      UnrecognisedEntry(key: 'MultipleArgs', values: ['false'])
    ],
    type: SpecificationString('Application'),
    icon: SpecificationIconString('/default256.png'),
    categories: SpecificationTypeList<SpecificationString>(
      'GNOME;GTK;Network;WebBrowser'
        .split(';')
        .map((e) => SpecificationString(e))
        .toList(growable: false)
    ),
    mimeType: SpecificationTypeList(
      'text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall'
      .split(';')
      .map((e) => SpecificationString(e))
      .toList(growable: false)
    ),
    startupNotify: SpecificationBoolean(true),
    actions: SpecificationTypeList<SpecificationString>(
      'NewWindow;NewPrivateWindow'
      .split(';')
      .map((e) => SpecificationString(e))
      .toList(growable: false)
    )
  ),
  actions: <DesktopAction>[
    DesktopAction(
      group: DesktopGroup('Desktop Action NewWindow', comments: ['']),
      name: SpecificationLocaleString(
        'Open a New Window',
        localisedValues: {
          'ar' : SpecificationLocaleString('افتح نافذة جديدة'),
          'ca' : SpecificationLocaleString('Obre una finestra nova'),
          'zh_TW': SpecificationLocaleString('開啟新視窗')
        }
      ),
      exec: SpecificationString('firefox -new-window')
    ),
    DesktopAction(
      group: DesktopGroup('Desktop Action NewPrivateWindow', comments: ['']),
      name: SpecificationLocaleString(
        'Open a New Private Window',
        localisedValues: {
          'ar' : SpecificationLocaleString('افتح نافذة جديدة للتصفح الخاص'),
          'ca' : SpecificationLocaleString('Obre una finestra nova en mode d\'incògnit'),
          'zh_TW': SpecificationLocaleString('開啟新隱私瀏覽視窗')
        }
      ),
      exec: SpecificationString('firefox -private-window')
    )
  ],
  unrecognisedGroups: <UnrecognisedGroup>[

  ],
  trailingComments: <String>[

  ]
);

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

  test('Compare Desktop Groups', () {
    expect(DesktopGroup('') == DesktopGroup(''), true);
    final aGroup = DesktopGroup('');
    final bGroup = aGroup.copyWith();
    expect(aGroup == bGroup, true);
  });

  test('Parse Simple Desktop File Correctly', () async {
    const filename = 'example-success.desktop';
    const existingPath = 'test/$filename';
    final existingFile = File(existingPath);
    final DesktopContents contents = DesktopContents.fromFile(existingFile);

    expect(contents == manualDefinitionExample, true);
  });

  test('Write To File Correctly', () async {
    const filename = 'desktopContentsToFile.desktop';

    final file = await DesktopContents.toFile(
      filename,
      manualDefinitionExample
    );
    final contentsFromFile = DesktopContents.fromFile(file);

    expect(contentsFromFile == manualDefinitionExample, true);
  });

  test('Parse `subset-firefox.desktop` Correctly', () async {
    const filename = 'subset-firefox.desktop';
    const existingPath = 'test/$filename';
    final existingFile = File(existingPath);

    final DesktopContents contents = DesktopContents.fromFile(existingFile);

    // expect(contents.entry.name == firefoxDefinition.entry.name, true);


    // expect(const ListEquality().equals(contents.unrecognisedGroups, firefoxDefinition.unrecognisedGroups), true);
    // expect(const ListEquality().equals(contents.actions, firefoxDefinition.actions), true);
    // compareMaps(DesktopContents.toData(contents), DesktopContents.toData(firefoxDefinition));
    expect(contents == firefoxDefinition, true);
  });

  test('Write `subset-firefox.desktop` to File Correctly', () async {
    const filename = 'subsetFirefoxToFile.desktop';

    final file = await DesktopContents.toFile(
        filename,
        firefoxDefinition
    );
    final contentsFromFile = DesktopContents.fromFile(file);

    expect(contentsFromFile == firefoxDefinition, true);
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